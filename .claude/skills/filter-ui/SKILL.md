---
name: filter-ui
description: Workflow for adding, fixing, or verifying a uBlock Origin cosmetic filter in ublock/filters.txt: "hide X on site Y", "this filter stopped working", turning a uBO element-picker filter into a stable one. Inspects the live site in the filters browser (Chrome for Testing + uBO Lite on :9223), proves the selector with match counts and before/after screenshots, writes the filter block, and tests it end to end through uBO Lite.
---

# Cosmetic filter development

Sites use generated class names and change their markup without notice. Never
guess a selector, and never keep a filter just because the uBO element picker
produced it: find the stable handle in the live page, prove it, then ship it.

## 1. Inspect live

- Work in `ublock/`. Every command below runs from there.
- Browser: the filters browser. Run `just browser <url>`. It is a no-op if
  the browser is already running, and its profile persists sign-ins. It runs
  on **:9223**, separate from the default chrome-dev on :9222. The
  `chrome-devtools` MCP tools point at :9222, so drive this browser with the
  scripts.
- Scripts (Node 24, no install needed; `<tab>` is a URL substring):
  - `node scripts/locate.mjs <tab> '<selector>'` lists every match: element and
    attributes, classes, visible or not, size, heading and text, the custom
    elements, `data-`/`aria-` handles and link shapes inside it, and its
    ancestors. **This is the main tool.**
  - `node scripts/eval.mjs <tab> '<js expr>'` prints the JSON result. Wrap
    statements in `(() => { … })()`. Navigate with `location.href = "…"`.
  - `node scripts/screenshot.mjs <tab> <scratchpad>/x.png [height]`, then `Read`
    the image.
  - `node scripts/click.mjs <tab> '<selector | text:Label>'` sends real mouse
    events.
- When given a picker filter, run `locate.mjs` on its tag alone (for example
  `grid-shelf-view-model`, not the class chain). It shows the siblings the
  picker missed and what they have in common.
- Check every page type where the target appears: on YouTube, search, home,
  watch and channel. Signed out, YouTube's home has no feed. Ask the user to sign
  in to the filters browser when a page needs it.

## 2. Choose a stable selector

In order of preference:

1. Semantic custom elements or component attributes (`grid-shelf-view-model`,
   `ytd-rich-shelf-renderer[is-shorts]`)
2. Stable attributes: `data-testid`, `aria-label`, `role`, `href` shapes
   (`a[href^="/shorts/"]`), non-generated ids
3. `:has()` to target the container that holds a telltale child
   (`grid-shelf-view-model:has(ytm-shorts-lockup-view-model)`), so no empty
   frame or gap is left behind
4. Procedural operators (`:has-text()`, `:upward()`, `:matches-css()`) only when
   text or style is the only handle. These need a `! probe:` CSS selector
5. Generated or utility classes (`css-1x2y3z`, `ytGridShelf…Host…`) last, and
   say why in the block's description

- Never use `:nth-child`, `:nth-of-type` or long class chains.
- Scope to the registrable domain (`youtube.com##`, which covers www. and m.)
  unless narrowing is the point.
- Generic filters (no site) are not allowed. Lint rejects them.

## 3. Prove it is specific

- Count matches on each page type. Use `locate.mjs` with the candidate, and
  compare it with the broad tag to see what the candidate leaves out.
- Read the matches' `heading`/`text`. Nothing you want to keep may match.
- Try a few different pages of the same type (several search queries, several
  videos). Lazy-loaded content appears after scrolling: use `scrollTo(0, 6000)`,
  wait, then count again.

## 4. Prototype

```sh
just diff <tab> '<selector>' <scratchpad>/diff
```

This scrolls the first match into view, captures the viewport with and without
an injected `<style id="uf-proto">` hiding every match, and writes `diff.png`
(off | on | changed pixels in red). It also prints the match and pixel counts.
`Read` the diff and check that:

- the target is gone,
- the content below moved up with no gap,
- nothing else changed.

It touches neither uBO Lite nor the page's state, so iterate freely. It only
handles plain CSS: test procedural filters through step 6.

Show the user the before/after when the target was described loosely ("the
shelf thing"), and confirm it is what they meant before writing it.

## 5. Write the block

Add it to `ublock/filters.txt` under the site's `! === site ===` section, in this format:

```
! <what it hides; why this handle, especially if the picker's version was different>
! test: <URL where it normally shows up>    (one or more)
! probe: <CSS selector>                     (only if procedural, or the filter's selector can't be queried)
! verified: <today, YYYY-MM-DD>
site.com##<selector>
```

## 6. Verify through real uBO Lite

```sh
just lint   # uBO Lite's parser accepts it; metadata is complete
just test   # serves filters.txt, uBO Lite re-imports it, each test page is checked
```

- **Pass**: the probe matched and nothing matching is visible.
- **Fail**: something matching is visible. uBO Lite didn't apply the filter,
  or the probe is wider than the filter.
- **Skip** ("matched nothing"): the site didn't render the target this time,
  or the selector is stale. Rerun, or pick a test URL where it always shows.

After `just test`, uBO Lite in the filters browser runs the working copy. Load
the test URL and take a screenshot to see the actual result, with no prototype
style involved. `node scripts/ubol.mjs status` shows what is imported.

## 7. Ship

- Commit on a branch and open a PR. Lint runs in CI, but `just test` doesn't,
  so mention in the PR that it passed locally. Devices pick up `main` within a
  day (`! Expires: 1 day`), or at once with "update now".
- Remind the user to delete the picker-made filter this replaces from "My
  filters" (uBO, Firefox) or the custom filters (uBO Lite, Chrome) on each
  device.

## Fixing a broken filter

When `just test` skips a filter, or the user says something is back:

1. Load its `test:` URL and run `locate.mjs` with the old selector, then with
   broader guesses (the tag alone, or the telltale child) to see what changed.
2. Repeat steps 2–6.
3. Update `verified:`.
