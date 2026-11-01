// End-to-end: have uBO Lite in the filters browser (re)import the list by URL,
// the path the real devices use, then open every block's test page and check it.
// The list is the working copy of filters.txt, served locally, unless
// FILTERS_URL points somewhere else (CI uses it to test the published list).
//
// For every filter, its probe (the block's "! probe:", else the filter's own CSS
// selector) must match at least one element, and none of them may be visible:
//   visible match    -> fail (uBO Lite didn't hide it: filter rejected or broken)
//   no match at all  -> skip (stale selector, or the site didn't show it this time)
// For every "! keep:" selector, something matching must still be visible:
//   all hidden       -> fail (a filter hides more than it should)
//   no match at all  -> skip (the keep selector is stale, or the page differed)
//
// In CI (CI=true), blocks marked "! signed-in: yes" are skipped as "local": the
// CI browser has no account, so only `just test` on a signed-in browser checks them.
//
// With REPORT_DIR set, each test page is also screenshotted before the list is
// imported and after, and REPORT_DIR gets index.html, summary.md and
// results.json describing the run.
//
// Needs the filters browser (`just browser`). Run with `just test` or `just report`.
import { after, before, describe, test } from "node:test";
import assert from "node:assert/strict";
import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { openTab } from "#cdp";
import { readList } from "../scripts/list.mjs";
import { LIST_URL, serve } from "../scripts/serve.mjs";
import {
  assertBrowser,
  importList,
  removeList,
  status,
} from "../scripts/ubol.mjs";

const { blocks, lines } = await readList(
  new URL("../filters.txt", import.meta.url),
);
const TITLE = lines
  .find((l) => l.startsWith("! Title:"))
  ?.slice(8)
  .trim();
const LIST = process.env.FILTERS_URL || LIST_URL;
const REPORT_DIR = process.env.REPORT_DIR;
// How long a test page gets to render its target before the probe counts as absent.
const RENDER_MS = Number(process.env.RENDER_MS || 15000);
const localOnly = (block) => Boolean(process.env.CI) && block.signedIn;

// One entry per test page: its block, URL, report folder and results.
const pages = blocks.flatMap((block) =>
  block.tests.map((url) => ({ block, url, results: [] })),
);
pages.forEach((p, i) => (p.dir = `${i + 1}-${new URL(p.url).hostname}`));

const matchState = (selector) => `(() => {
  const all = [...document.querySelectorAll(${JSON.stringify(selector)})];
  return { count: all.length, visible: all.filter((e) => e.checkVisibility()).length };
})()`;

// Polls until `selector` matches something or RENDER_MS runs out.
async function waitForMatch(tab, selector) {
  let state;
  for (const end = Date.now() + RENDER_MS; Date.now() < end; await sleep(500)) {
    state = await tab.evaluate(matchState(selector));
    if (state.count > 0) break;
  }
  return state;
}

async function shoot(tab, file) {
  const { data } = await tab.send("Page.captureScreenshot", { format: "png" });
  await writeFile(file, Buffer.from(data, "base64"));
}

// The "before" half of the report: each test page with the list not imported,
// scrolled so the first probe match sits near the top. The "after" shot reuses
// the same scroll position, so it shows what moved up into the gap.
async function shootBefore(page) {
  await mkdir(join(REPORT_DIR, page.dir), { recursive: true });
  const tab = await openTab(page.url);
  try {
    const probe = page.block.probe || page.block.filters[0].selector;
    await waitForMatch(tab, probe);
    page.scrollY = await tab.evaluate(`(() => {
      const el = document.querySelector(${JSON.stringify(probe)});
      if (el) { el.scrollIntoView({ block: "start" }); scrollBy(0, -80); }
      return scrollY;
    })()`);
    await sleep(500);
    await shoot(tab, join(REPORT_DIR, page.dir, "before.png"));
  } finally {
    await tab.close();
  }
}

let server;
before(async () => {
  await assertBrowser();
  if (!process.env.FILTERS_URL) server = await serve();
  // Another imported copy of this list (local vs published) would hide the same
  // things and mask a broken copy, so only the one under test stays imported.
  for (const l of (await status()).imported)
    if (l.name === TITLE && l.url !== LIST) await removeList(l.url);
  if (REPORT_DIR) {
    await removeList(LIST);
    for (const page of pages)
      if (!localOnly(page.block)) await shootBefore(page);
  }
  await importList(LIST);
});

after(async () => {
  server?.close();
  if (REPORT_DIR) await writeReport();
});

// Records each check's outcome for the report, then passes it on to node:test.
async function check(page, t, label, fn) {
  const result = { label, status: "pass", detail: "" };
  page.results.push(result);
  if (localOnly(page.block)) {
    const why = "signed-in page: checked by `just test` locally, not in CI";
    Object.assign(result, { status: "local", detail: why });
    return t.skip(why);
  }
  try {
    const skip = await fn();
    if (skip) {
      Object.assign(result, { status: "skip", detail: skip });
      t.skip(skip);
    }
  } catch (err) {
    Object.assign(result, { status: "fail", detail: err.message });
    throw err;
  }
}

for (const block of blocks) {
  const title = `${block.notes[0] || block.filters[0].filter} (line ${block.line})`;
  describe(title, () => {
    for (const page of pages.filter((p) => p.block === block)) {
      describe(page.url, () => {
        let tab;
        before(async () => {
          if (!localOnly(block)) tab = await openTab(page.url);
        });
        after(async () => {
          if (REPORT_DIR && tab) {
            await tab.evaluate(`scrollTo(0, ${page.scrollY || 0})`);
            await sleep(500);
            await shoot(tab, join(REPORT_DIR, page.dir, "after.png"));
          }
          await tab?.close();
        });

        for (const f of block.filters) {
          const probe = block.probe || f.selector;
          test(`hides ${f.filter}`, (t) =>
            check(page, t, `hides \`${f.filter}\``, async () => {
              let state = await waitForMatch(tab, probe);
              if (state.count === 0)
                return `${probe} matched nothing (stale, or not shown this time)`;
              // Give uBO's procedural filtering a moment to catch up with late renders.
              await sleep(1000);
              state = await tab.evaluate(matchState(probe));
              assert.equal(
                state.visible,
                0,
                `${state.visible} of ${state.count} elements matching ${probe} are still visible`,
              );
            }));
        }

        for (const keep of block.keep) {
          test(`keeps ${keep}`, (t) =>
            check(page, t, `keeps \`${keep}\``, async () => {
              const state = await waitForMatch(tab, keep);
              if (state.count === 0)
                return `keep: ${keep} matched nothing (stale, or not shown this time)`;
              assert.ok(
                state.visible > 0,
                `all ${state.count} elements matching keep: ${keep} are hidden; a filter is too broad`,
              );
            }));
        }
      });
    }
  });
}

// uBO Lite applies an imported list's cosmetic filters through a registered user
// script. It has been seen to drop that registration seconds after an import
// while keeping the list, leaving pages opened later unfiltered. Every check
// above runs right after the import, so check once more on a page opened after
// a pause, the way a device sees it.
const PAUSE_MS = 8000;
const later = pages.find((p) => !localOnly(p.block));
if (later)
  describe("after a pause", () => {
    test(`still applies to a page opened later: ${later.url}`, (t) =>
      check(later, t, "still applies to a page opened later", async () => {
        await sleep(PAUSE_MS);
        const tab = await openTab(later.url);
        try {
          const probe = later.block.probe || later.block.filters[0].selector;
          let state = await waitForMatch(tab, probe);
          if (state.count === 0)
            return `${probe} matched nothing (stale, or not shown this time)`;
          await sleep(1000);
          state = await tab.evaluate(matchState(probe));
          assert.equal(
            state.visible,
            0,
            `${state.visible} of ${state.count} elements matching ${probe} are visible ${PAUSE_MS / 1000}s after the import: uBO Lite stopped applying the list (\`node scripts/ubol.mjs status\` shows its registered user scripts)`,
          );
        } finally {
          await tab.close();
        }
      }));
  });

async function writeReport() {
  const all = pages.flatMap((p) => p.results.map((r) => ({ ...r, page: p })));
  const n = (s) => all.filter((r) => r.status === s).length;
  const counts = {
    pass: n("pass"),
    skip: n("skip"),
    fail: n("fail"),
    local: n("local"),
  };
  const icon = { pass: "✅", skip: "⚠️", fail: "❌", local: "💻" };
  const short = (url) => url.replace(/^https?:\/\//, "");
  const heading =
    `ublock filters: ${counts.pass} passed, ${counts.skip} skipped, ${counts.fail} failed` +
    (counts.local ? `, ${counts.local} left to local runs` : "");
  const md = [
    `### ${heading}`,
    "",
    `List: ${LIST}`,
    "",
    "| | Check | Test page | Line | Detail |",
    "|---|---|---|---|---|",
    ...all.map(
      (r) =>
        `| ${icon[r.status]} ${r.status} | ${r.label} | ${short(r.page.url)} | ${r.page.block.line} | ${r.detail.replace(/\|/g, "\\|")} |`,
    ),
    "",
  ].join("\n");
  const esc = (s) =>
    String(s).replace(
      /[&<>"]/g,
      (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c],
    );
  const section = (p) => `<section>
<h2>${esc(p.block.notes[0] || p.block.filters[0].filter)}</h2>
<p><a href="${esc(p.url)}">${esc(p.url)}</a> (filters.txt line ${p.block.line})</p>
<ul>${p.results
    .map(
      (r) =>
        `<li class="${r.status}">${r.status}: ${esc(r.label.replace(/`/g, ""))}${r.detail ? ` (${esc(r.detail)})` : ""}</li>`,
    )
    .join("")}</ul>
${
  p.scrollY === undefined
    ? ""
    : `<div class="row">
<figure><figcaption>Without the list</figcaption><img src="${p.dir}/before.png" alt=""></figure>
<figure><figcaption>With the list, in uBO Lite</figcaption><img src="${p.dir}/after.png" alt=""></figure>
</div>`
}
</section>`;
  const html = `<!doctype html>
<meta charset="utf-8">
<title>ublock filters report</title>
<style>
body { font: 14px system-ui, sans-serif; margin: 16px; background: #fff; color: #111; }
section { margin: 32px 0; }
.row { display: flex; gap: 12px; }
figure { margin: 0; flex: 1; }
img { width: 100%; border: 1px solid #ccc; }
.fail { color: #b00; } .skip { color: #a60; }
</style>
<h1>${esc(heading)}</h1>
<p>List: ${esc(LIST)}</p>
${pages.map(section).join("\n")}
`;
  await mkdir(REPORT_DIR, { recursive: true });
  await writeFile(join(REPORT_DIR, "summary.md"), md);
  await writeFile(join(REPORT_DIR, "index.html"), html);
  await writeFile(
    join(REPORT_DIR, "results.json"),
    JSON.stringify(
      {
        list: LIST,
        counts,
        results: all.map(({ page, ...r }) => ({
          ...r,
          url: page.url,
          line: page.block.line,
        })),
      },
      null,
      2,
    ),
  );
}
