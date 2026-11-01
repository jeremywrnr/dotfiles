// Reads filters.txt into blocks for lint and the tests. A block is a run of
// "!" comment lines followed by the filters they describe, ended by a blank line:
//
//   ! Shorts shelves in search results        <- description (free text)
//   ! test: https://www.youtube.com/results?search_query=cats
//   ! probe: grid-shelf-view-model             <- optional
//   ! keep: ytd-video-renderer                 <- optional, must stay visible
//   ! signed-in: yes                           <- optional, CI can't check it
//   ! verified: 2026-10-31
//   youtube.com##grid-shelf-view-model:has(ytm-shorts-lockup-view-model)
//
// Filters are parsed with uBO Lite's own parser (from the build `just ubol`
// downloads), so a filter that passes here is one uBO Lite accepts.
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

// uBO Lite lives beside the filters browser's profile, not in the repo: Chrome
// derives an unpacked extension's ID from its path, so one fixed path keeps its
// settings no matter which checkout or worktree launches the browser.
export const UBOL_DIR =
  process.env.UBOL_DIR ||
  join(homedir(), ".local/share/chrome-dev-filters/ubol");
const PARSER = pathToFileURL(join(UBOL_DIR, "js/static-filtering-parser.js"));

export async function loadParser() {
  let sfp;
  try {
    sfp = await import(PARSER);
  } catch (err) {
    throw new Error(
      `can't load uBO Lite's parser (run \`just ubol\`): ${err.message}`,
    );
  }
  // Same options as uBO Lite's filter editor, minus trust: a subscribed list is
  // not a trusted source, so trusted-only syntax must fail here too.
  const parser = new sfp.AstFilterParser({
    nativeCssHas: true,
    trustedSource: false,
  });
  return (line) => {
    parser.parse(line);
    const cosmetic = parser.isCosmeticFilter();
    const result = cosmetic ? parser.result : undefined;
    return {
      error:
        parser.hasError() || parser.getFlags(sfp.AST_FLAG_UNSUPPORTED) !== 0
          ? result?.error || "rejected by uBO Lite's parser"
          : null,
      cosmetic,
      exception: parser.isException(),
      // uBO compiles procedural filters (:has-text(), :upward(), ...) to JSON.
      procedural: Boolean(result?.compiled?.startsWith("{")),
    };
  };
}

// Splits "a.com,~b.a.com##sel" into its parts. Cosmetic separators: ## #@# #?# #@?#
export function splitCosmetic(filter) {
  const m = /^([^#]*)(#@?\??#)(.*)$/.exec(filter);
  if (!m) return null;
  return {
    hosts: m[1] ? m[1].split(",").map((h) => h.trim()) : [],
    separator: m[2],
    selector: m[3],
  };
}

export async function readList(file) {
  const text = await readFile(file, "utf8");
  const parse = await loadParser();
  const lines = text.split(/\r?\n/);
  const blocks = [];
  let block = null;
  const flush = () => {
    if (block?.filters.length) blocks.push(block);
    block = null;
  };
  const start = (line) => ({
    line,
    notes: [],
    tests: [],
    keep: [],
    probe: null,
    verified: null,
    signedIn: false,
    filters: [],
  });
  lines.forEach((raw, i) => {
    const line = raw.trim();
    const lineNo = i + 1;
    if (line === "") return flush();
    if (line.startsWith("!")) {
      // A comment after filters starts a new block.
      if (block?.filters.length) flush();
      block ??= start(lineNo);
      const meta = /^!\s*(test|keep|probe|verified|signed-in):\s*(.*)$/i.exec(
        line,
      );
      if (!meta) {
        block.notes.push(line.replace(/^!\s?/, ""));
        return;
      }
      const key = meta[1].toLowerCase();
      const value = meta[2].trim();
      // test: and keep: may repeat; probe: and verified: take the last value.
      if (key === "test") block.tests.push(value);
      else if (key === "keep") block.keep.push(value);
      else if (key === "signed-in")
        block.signedIn = /^(yes|true)$/i.test(value);
      else block[key] = value;
      return;
    }
    block ??= start(lineNo);
    block.filters.push({
      line: lineNo,
      filter: line,
      ...splitCosmetic(line),
      ...parse(line),
    });
  });
  flush();
  return { text, lines, blocks };
}
