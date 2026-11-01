# ublock

My uBlock Origin cosmetic filters, as one list that every device subscribes to.

uBO's element picker writes a filter for the exact element you clicked, usually
a long chain of generated class names scoped to one subdomain, and saves it to
the "My filters" of that one browser. Those filters break when the site changes
and miss look-alike elements. For example, the picker's
`www.youtube.com##grid-shelf-view-model.ytGridShelfViewModelHostHasBottomButton…`
hid 1 of the 5 Shorts shelves on a YouTube search page.

Every filter here was found in the live page instead: its stable handle
identified, its matches counted on each page type, its effect checked in
before/after screenshots, and then tested end to end through real uBO Lite.

## Subscribe (once per device)

List URL:

```
https://raw.githubusercontent.com/jeremywrnr/dotfiles/main/ublock/filters.txt
```

**uBO Lite (Chrome and other Chromium browsers)**

1. uBO Lite dashboard → **Filter lists** → **Add filter list…** → paste the URL.
2. `chrome://extensions` → uBlock Origin Lite → **Details** → turn on **Allow
   user scripts**. uBO Lite applies cosmetic filters from imported lists as user
   scripts, so without this the list imports but hides nothing.

**uBlock Origin (Firefox)**

1. Dashboard → **Filter lists** → **Import…** (at the bottom, under Custom) →
   paste the URL → **Apply changes**.

Both re-fetch the list daily (`! Expires: 1 day`). Use "update now" in uBO
(or remove and re-add the list in uBO Lite) to pick up a change at once. Once a
filter here replaces a picker-made one, delete the old one from "My filters"
(uBO) or the custom filters (uBO Lite) on each device.

## Asking for a filter

From any device, open a [**Hide something**](https://github.com/jeremywrnr/dotfiles/issues/new?template=ublock.yml)
issue: the page URL, what to hide, and the picker filter if you made one. Or,
at a terminal, in this directory:

```
just hide <url> "<what to hide>" ['<picker filter>']   # files the same issue and starts on it
just inbox                # work open requests, oldest first
just inbox --list         # just list them
just inbox <number>       # work one
```

A request is an open issue labeled `ublock`, opened by the repo owner (the repo
is public, so anyone else's are ignored) or by the weekly check. `just inbox`
gives each one a worktree (`.claude/worktrees/ublock-<n>`, branch `ublock-<n>`
from `origin/main`) and a Claude Code session running the `filter-ui` skill.
Running it again resumes an unfinished one. The session ends with a PR that
closes the issue, with before/after screenshots. Merge it, and the devices
have it within a day.

## Working on filters

The workflow lives in the `filter-ui` Claude Code skill
(`.claude/skills/filter-ui/SKILL.md` at the root of dotfiles). Run these from
this directory:

```
just ubol                 # download/upgrade uBO Lite
just browser [url]        # filters browser: Chrome for Testing + uBO Lite on :9223
just lint                 # every filter parses in uBO Lite, has a test page, no generic filters
just unit                 # tests for the tooling: the list parser and each lint rule
just test                 # load filters.txt into uBO Lite, open each test page, check every filter
just report [dir]         # just test, plus before/after screenshots of each test page (dir/index.html)
just diff <tab> '<sel>'   # screenshot a tab with and without a candidate selector
node scripts/locate.mjs <tab> '<sel>'   # describe every match: handles, links, ancestors, visibility
node scripts/ubol.mjs status            # what uBO Lite has imported
```

The filters browser is a second `chrome-dev` instance (Chrome for Testing,
DevTools on port 9223) with its own profile in `~/.local/share/chrome-dev-filters`.
It shares the browser binary with the default instance on :9222 but nothing
else, so the two run side by side. uBO Lite is downloaded beside that profile
rather than into the repo. Chrome derives an unpacked extension's ID from its
path, so keeping one fixed path keeps uBO Lite's settings whichever checkout
launches the browser.

`just test` serves the working copy of `filters.txt` on `127.0.0.1:47811` and
has uBO Lite import it by URL, the same path the devices use with the GitHub
URL. It also turns on uBO Lite's "Allow user scripts" in the filters browser.
`FILTERS_URL=<url> just test` tests another copy, such as the published one.

### filters.txt format

```
! Shorts shelves in search results.              <- what it hides, and why this selector
! test: https://www.youtube.com/results?search_query=cats
! keep: ytd-video-renderer                       <- optional; must stay visible
! probe: grid-shelf-view-model                   <- optional; required for procedural filters
! signed-in: yes                                 <- optional; only shows up signed in
! verified: 2026-10-31
youtube.com##grid-shelf-view-model:has(ytm-shorts-lockup-view-model)
```

A block is the comment lines plus the filters right after them, up to a blank
line. `test:` is a page where the target normally shows up (several are allowed).
`probe:` is the CSS selector the test checks, defaulting to each filter's own
selector. For every probe, at least one element must match and none may be
visible. `keep:` (several allowed) is the opposite check, against a filter
that's too broad: something matching it must still be visible. If a probe or
keep matches nothing, the check is skipped and reported as possibly stale.

Lint (also run in CI) rejects anything uBO Lite's own parser
(`js/static-filtering-parser.js` in its build) rejects. It also rejects network
filters, exceptions, generic filters (no site), blocks without a test page, and
test pages on a site the filter doesn't cover. uBO Lite accepts a subset of
classic uBO's syntax, so a filter that passes here works in both.

## Checks

The `ublock` workflow (`.github/workflows/ublock.yml`) runs:

| When | What |
|---|---|
| Pull request | lint, unit tests, and `just test` of the branch's list in headless Chrome for Testing with uBO Lite, a fresh profile each run |
| Push to main | the same, against the published raw URL once it serves the new commit, i.e. what the devices fetch |
| Weekly (Monday) | `just test` of the published list with the latest Chrome and uBO Lite. If anything fails or matches nothing, it opens (or updates) a "weekly check found problems" issue for `just inbox`, and closes it once all pass again |

Each run's summary has a pass/skip/fail table, and its `ublock-report` artifact
has the before/after screenshots. Blocks marked `! signed-in: yes` are left to
local runs, since the CI browser has no account. Firefox isn't tested: classic
uBO accepts everything uBO Lite does, so spot-check a filter there only when it
uses syntax beyond plain CSS.
