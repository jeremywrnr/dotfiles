// usage: node scripts/lint.mjs [filters.txt]
// Fails on anything that would make the list wrong or untestable:
// - a filter uBO Lite's parser rejects
// - a filter that isn't a site-specific cosmetic hide filter (this list only
//   holds those, and `just test` only knows how to check those)
// - a block with no "! test:" URL, or one on a site the filter doesn't apply to
// - a procedural filter with no "! probe:" (the test can't run it as CSS)
// - duplicates, and a missing list header
import { readList } from "./list.mjs";

const file = process.argv[2] || "filters.txt";
const { lines, blocks } = await readList(file);
const problems = [];
const report = (line, msg) => problems.push(`${file}:${line}: ${msg}`);

for (const key of ["Title", "Expires"])
  if (!lines.some((l) => l.startsWith(`! ${key}:`)))
    report(1, `missing "! ${key}:" header`);

const seen = new Map();
let count = 0;
for (const block of blocks) {
  if (block.tests.length === 0)
    report(block.line, 'block has no "! test:" URL');
  const testHosts = [];
  for (const t of block.tests) {
    try {
      testHosts.push(new URL(t).hostname);
    } catch {
      report(block.line, `bad test URL: ${t}`);
    }
  }
  for (const f of block.filters) {
    count++;
    if (seen.has(f.filter))
      report(f.line, `duplicate of line ${seen.get(f.filter)}`);
    seen.set(f.filter, f.line);
    if (f.error) {
      report(f.line, `uBO Lite rejects this filter: ${f.error.split("\n")[0]}`);
      continue;
    }
    if (!f.cosmetic || f.separator?.includes("@") || f.exception) {
      report(
        f.line,
        "only cosmetic hide filters (host##selector) belong in this list",
      );
      continue;
    }
    const include = f.hosts.filter((h) => !h.startsWith("~"));
    if (include.length === 0) {
      report(f.line, "generic filter: scope it to a site (site.com##selector)");
      continue;
    }
    if (f.procedural && !block.probe)
      report(
        f.line,
        'procedural filter needs a "! probe:" CSS selector for the test',
      );
    for (const host of testHosts)
      if (!include.some((h) => host === h || host.endsWith(`.${h}`)))
        report(
          f.line,
          `test URL host ${host} is not covered by ${include.join(",")}`,
        );
  }
}

if (problems.length) {
  console.error(problems.join("\n"));
  console.error(`\n${problems.length} problem(s)`);
  process.exit(1);
}
console.log(`${file}: ${count} filters in ${blocks.length} blocks, all OK`);
