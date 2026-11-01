# ublock

`filters.txt` is a uBlock Origin cosmetic filter list, subscribed to by URL on the
user's devices (uBO Lite on Chrome, classic uBO on Firefox). Whatever lands on
`main` reaches every device within a day, and the repo is public.

- Use the `filter-ui` skill (`.claude/skills/filter-ui/` at the dotfiles root)
  for any change to `filters.txt`. Never guess a selector or keep one made by
  uBO's element picker: find it in the live page, prove it, then add it.
- Browser: the filters browser on **:9223** (`just browser`), not the default
  chrome-dev on :9222. Drive it with the scripts in `scripts/` (`#cdp` defaults
  to 9223). The `chrome-devtools` MCP server points at :9222, so its tools see the
  other browser.
- Run `just` recipes from this directory. Before pushing, run `just lint` (also
  run in CI) and `just test` (local only: it needs the filters browser).
