# CLAUDE.md

Personal dotfiles, shared by every machine (macOS, Linux, WSL). `install.sh`
links them into place; `readme.md` has the layout.

## This repo is public

It is on GitHub as a public repo. Nothing here may identify the user's
machines or network: no hostnames, LAN IPs, tunnel or service domains, ssh
hosts, key fingerprints, or notes about a particular box. Write comments
generically ("a NAS", "a remote host") rather than naming one.

Anything per-host or private goes in the sibling private repo
`~/Code/machines` (self-hosted Gitea), which has its own CLAUDE.md:

- ssh hosts → `machines/ssh/config` (`~/.ssh/config` only `Include`s it)
- shell aliases/functions for specific hosts → `machines/zsh/*.zsh`, which
  `zshrc` sources when that repo is checked out beside this one
- personal Homebrew extras → `machines/Brewfile`
- herdr's saved machines → `machines/herdr-machines`

Known, accepted exceptions: git history holds some old host names, and
`claude/settings.json`'s `autoMode` block names the Gitea host and the
`machines` repo so auto mode trusts them.

## Conventions

- Platform differences live in `zsh/10-darwin.zsh` / `zsh/10-linux.zsh`, not
  per-machine branches: one commit works everywhere.
- `install.sh` must stay safe to re-run, and `brew bundle` never upgrades;
  upgrades go through `bin/brewup`.
- Comments say why, in full sentences, at the density of the surrounding file.
- Commit messages: `area: what changed`, lowercase area (`zsh:`, `install:`,
  `brew:`, `herdr:`, `claude:`), no trailing period.

## Gotchas

- `claude/settings.json` goes through a clean/smudge filter
  (`claude/herdr-hook-filter`) that swaps the herdr hook's absolute path.
  `git status` can show it modified with an empty diff;
  `git update-index --refresh` clears that.
- Its `autoMode` block is Claude's own permission config. Claude can't edit
  it; give the user the exact change to apply.
- Other machines push here too. `git pull --rebase` before pushing, and commit
  only the files you changed (no `git commit -a`).
