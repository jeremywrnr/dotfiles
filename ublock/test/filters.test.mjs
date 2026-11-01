// End-to-end: serve the working copy of filters.txt, have uBO Lite in the filters
// browser (re)import it by URL (the path the real devices use with the GitHub
// URL), then open every block's test page and check each filter's target.
//
// For every filter, its probe (the block's "! probe:", else the filter's own CSS
// selector) must match at least one element, and none of them may be visible:
//   visible match    -> fail (uBO Lite didn't hide it: filter rejected or broken)
//   no match at all  -> skip (stale selector, or the site didn't show it this time)
//
// Needs `just browser` running. Run with `just test`.
import { after, before, describe, test } from "node:test";
import assert from "node:assert/strict";
import { setTimeout as sleep } from "node:timers/promises";
import { openTab } from "#cdp";
import { readList } from "../scripts/list.mjs";
import { LIST_URL, serve } from "../scripts/serve.mjs";
import { importList } from "../scripts/ubol.mjs";

const { blocks } = await readList(new URL("../filters.txt", import.meta.url));
// How long a test page gets to render its target before the probe counts as absent.
const RENDER_MS = Number(process.env.RENDER_MS || 15000);

let server;
before(async () => {
  server = await serve();
  await importList(LIST_URL);
});
after(() => server?.close());

const probeState = (probe) => `(() => {
  const all = [...document.querySelectorAll(${JSON.stringify(probe)})];
  return { count: all.length, visible: all.filter((e) => e.checkVisibility()).length };
})()`;

for (const block of blocks) {
  const title = `${block.notes[0] || block.filters[0].filter} (line ${block.line})`;
  describe(title, () => {
    for (const url of block.tests) {
      describe(url, () => {
        let page;
        before(async () => {
          page = await openTab(url);
        });
        after(() => page?.close());

        for (const f of block.filters) {
          const probe = block.probe || f.selector;
          test(f.filter, async (t) => {
            let state;
            for (
              const end = Date.now() + RENDER_MS;
              Date.now() < end;
              await sleep(500)
            ) {
              state = await page.evaluate(probeState(probe));
              if (state.count > 0) break;
            }
            if (state.count === 0)
              return t.skip(
                `${probe} matched nothing (stale, or not shown this time)`,
              );
            // Give uBO's procedural filtering a moment to catch up with late renders.
            await sleep(1000);
            state = await page.evaluate(probeState(probe));
            assert.equal(
              state.visible,
              0,
              `${state.visible} of ${state.count} elements matching ${probe} are still visible`,
            );
          });
        }
      });
    }
  });
}
