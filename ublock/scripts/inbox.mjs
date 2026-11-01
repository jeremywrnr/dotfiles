// Filter requests are GitHub issues labeled "ublock": filed from the "Hide
// something" issue form (from any device), by `just hide`, or by the weekly CI
// check when a filter breaks. This works them one at a time, each in its own
// worktree and Claude Code session running the filter-ui skill, which ends with
// a PR that closes the issue.
//
//   node scripts/inbox.mjs                      list open requests, then work them oldest first
//   node scripts/inbox.mjs <number>             work one request
//   node scripts/inbox.mjs --list               only list
//   node scripts/inbox.mjs hide <url> <what> [picker filter]   file a request, then work it
//   --dry-run                                   print what would run instead of running it
//
// The repo is public, so only issues opened by its owner (or the weekly check)
// count as requests; anyone else's are listed as ignored and never worked.
import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { createInterface } from "node:readline/promises";

const LABEL = "ublock";
const BOTS = ["app/github-actions", "github-actions", "github-actions[bot]"];
const args = process.argv.slice(2);
const dryRun = args.includes("--dry-run");
const [cmd, ...rest] = args.filter((a) => a !== "--dry-run");

function fail(msg) {
  console.error(msg);
  process.exit(1);
}
const run = (bin, argv, opts = {}) =>
  execFileSync(bin, argv, { encoding: "utf8", ...opts }).trim();
const gh = (...argv) => run("gh", argv);
const git = (...argv) => run("git", argv);

// The main checkout, even when this runs inside a worktree.
const ROOT = dirname(
  git("rev-parse", "--path-format=absolute", "--git-common-dir"),
);
const repo = JSON.parse(gh("repo", "view", "--json", "nameWithOwner,owner"));
const OWNER = repo.owner.login;

function age(iso) {
  const h = (Date.now() - Date.parse(iso)) / 36e5;
  return h < 24 ? `${Math.max(1, Math.round(h))}h` : `${Math.round(h / 24)}d`;
}

// Open requests, oldest first, each with the open PR that closes it (if any).
function requests() {
  const issues = JSON.parse(
    gh(
      "issue",
      "list",
      "--label",
      LABEL,
      "--state",
      "open",
      "--limit",
      "100",
      "--json",
      "number,title,body,author,createdAt,url",
    ),
  ).sort((a, b) => a.number - b.number);
  const prs = JSON.parse(
    gh("pr", "list", "--state", "open", "--json", "number,body,headRefName"),
  );
  const closes = new Map();
  for (const pr of prs) {
    for (const m of (pr.body || "").matchAll(
      /\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#(\d+)/gi,
    ))
      closes.set(Number(m[1]), pr.number);
    const branch = /^ublock-(\d+)$/.exec(pr.headRefName);
    if (branch) closes.set(Number(branch[1]), pr.number);
  }
  return issues.map((i) => ({
    ...i,
    trusted: i.author.login === OWNER || BOTS.includes(i.author.login),
    pr: closes.get(i.number),
  }));
}

function show(list) {
  const mine = list.filter((r) => r.trusted);
  const ignored = list.length - mine.length;
  if (mine.length === 0) console.log(`No open ${LABEL} requests.`);
  for (const r of mine) {
    const note = r.pr
      ? `  (in review: PR #${r.pr})`
      : BOTS.includes(r.author.login)
        ? "  (weekly check)"
        : "";
    console.log(
      `  #${r.number}  ${age(r.createdAt).padStart(3)}  ${r.title}${note}`,
    );
  }
  if (ignored)
    console.log(
      `  (${ignored} opened by someone else, ignored: the repo is public)`,
    );
  return mine.filter((r) => !r.pr);
}

// A worktree per request, on branch ublock-<n> made from origin/main. Reused
// if it already exists, so stopping halfway and running again picks it back up.
function worktree(n) {
  const dir = join(ROOT, ".claude/worktrees", `ublock-${n}`);
  const branch = `ublock-${n}`;
  if (existsSync(dir)) return { dir, branch, resumed: true };
  const steps = [["fetch", "-q", "origin", "main"]];
  const hasBranch =
    spawnSync("git", [
      "-C",
      ROOT,
      "rev-parse",
      "--verify",
      "-q",
      `refs/heads/${branch}`,
    ]).status === 0;
  steps.push(
    hasBranch
      ? ["worktree", "add", dir, branch]
      : ["worktree", "add", "--no-track", "-b", branch, dir, "origin/main"],
  );
  for (const s of steps) {
    if (dryRun) console.log(`[dry run] git -C ${ROOT} ${s.join(" ")}`);
    else git("-C", ROOT, ...s);
  }
  return { dir, branch, resumed: false };
}

// Claude Code keeps a directory's sessions in ~/.claude/projects/<path with every
// non-alphanumeric character turned into "-">.
function hasSession(dir) {
  const projects = join(
    process.env.CLAUDE_CONFIG_DIR || join(homedir(), ".claude"),
    "projects",
    dir.replace(/[^a-zA-Z0-9]/g, "-"),
  );
  return (
    existsSync(projects) &&
    readdirSync(projects).some((f) => f.endsWith(".jsonl"))
  );
}

function work(r) {
  const { dir, branch, resumed } = worktree(r.number);
  const name = `ublock #${r.number}`;
  let argv;
  if (resumed && hasSession(dir)) {
    console.log(`Resuming #${r.number} in ${dir}`);
    argv = ["--continue", "-n", name];
  } else {
    const prompt = [
      `/filter-ui Work filter request #${r.number} (${r.url}), opened by ${r.author.login}.`,
      `This session is in a worktree for it, on branch ${branch} from origin/main.` +
        (resumed
          ? " The worktree already existed: check git status and git log for earlier work first."
          : ""),
      'Follow "Requests" in the skill: end with a PR whose body says "Closes #' +
        r.number +
        "\", or a comment on the issue saying why it can't be done.",
      "",
      `Title: ${r.title}`,
      "",
      r.body.trim(),
    ].join("\n");
    argv = ["-n", name, prompt];
  }
  if (dryRun) {
    console.log(
      `[dry run] (cd ${dir} && claude ${argv.map((a) => JSON.stringify(a)).join(" ")})`,
    );
    return;
  }
  console.log(`\n→ #${r.number} ${r.title}\n`);
  spawnSync("claude", argv, { cwd: dir, stdio: "inherit" });
}

async function confirm(question) {
  if (dryRun || !process.stdin.isTTY) return true;
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const answer = await rl.question(question);
  rl.close();
  return !/^(q|n)/i.test(answer.trim());
}

function hide(url, what, picker) {
  if (!url || !what)
    fail("usage: just hide <url> \"<what to hide>\" ['<picker filter>']");
  if (!URL.canParse(url)) fail(`not a URL: ${url}`);
  // Same shape as the issue form's output, so both kinds of request read alike.
  const body = [
    "### Page URL",
    "",
    url,
    "",
    "### What to hide",
    "",
    what,
    "",
    "### Picker filter (optional)",
    "",
    picker ? "```adblock\n" + picker + "\n```" : "_No response_",
    "",
    "_Filed with `just hide`._",
  ].join("\n");
  const title = `ublock: hide ${what.length > 60 ? what.slice(0, 57) + "…" : what}`;
  if (dryRun) {
    console.log(
      `[dry run] gh issue create --label ${LABEL} --title ${JSON.stringify(title)}\n${body}`,
    );
    return {
      number: 0,
      title,
      body,
      url: "(dry run)",
      author: { login: OWNER },
    };
  }
  const issueUrl = gh(
    "issue",
    "create",
    "--label",
    LABEL,
    "--title",
    title,
    "--body",
    body,
  );
  console.log(`Filed ${issueUrl}`);
  const number = Number(issueUrl.split("/").pop());
  return { number, title, body, url: issueUrl, author: { login: OWNER } };
}

if (cmd === "hide") {
  work(hide(...rest));
} else if (cmd === "--list") {
  show(requests());
} else if (cmd && /^#?\d+$/.test(cmd)) {
  const n = Number(cmd.replace("#", ""));
  const r = requests().find((i) => i.number === n);
  if (!r) fail(`#${n} is not an open ${LABEL} request`);
  if (!r.trusted)
    fail(`#${n} was opened by ${r.author.login}, not ${OWNER}; not working it`);
  work(r);
} else if (!cmd) {
  let todo = show(requests());
  const done = new Set();
  while ((todo = todo.filter((r) => !done.has(r.number))).length) {
    const next = todo[0];
    if (
      !(await confirm(`\nWork #${next.number} next? [Enter = yes, q = stop] `))
    )
      break;
    work(next);
    done.add(next.number);
    if (!dryRun) todo = requests().filter((r) => r.trusted && !r.pr);
  }
} else {
  fail(
    "usage: node scripts/inbox.mjs [<number> | --list | hide <url> <what> [picker]] [--dry-run]",
  );
}
