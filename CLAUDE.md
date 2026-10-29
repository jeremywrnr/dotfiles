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

## Checking a LaunchAgent is loaded

`launchctl list` returns nothing under the sandbox these sessions run in, so an
agent that is loaded and healthy reads as missing. Ask about it by label
instead, which works sandboxed:

    launchctl print gui/$UID/com.jeremy.screenshot-clip

`state = not running` is the right answer for a `WatchPaths` job — it is
on-demand, and launchd only starts it when the watched path changes.

Anything that has to actually fire an agent — writing into a watched directory,
`screencapture`, `defaults write` — needs the sandbox off, or it will look like
the agent never ran.

## Screenshots

`install.sh` pins `com.apple.screencapture` and loads
`com.jeremy.screenshot-clip`, which mirrors each new capture onto the clipboard;
macOS will write a file or copy to the clipboard, never both. So the two halves
fail independently: `defaults read com.apple.screencapture` covers the file
side, and `~/Library/Caches/com.jeremy.screenshot-clip` plus
`osascript -e 'clipboard info'` (expect `«class PNGf»`) covers the clipboard
side. `/tmp/screenshot-clip.err` has the agent's stderr.

To test it end to end, capture into the watched directory and delete the file
after — an old shot reaching the clipboard is worse than a missed one, so
`screenshot-clip.sh` ignores any file more than 60s old and will not copy the
same one twice.

Note what that test does *not* prove. `screencapture` requires a destination
argument, and passing one bypasses the location preference entirely, so a
passing test says the agent works while saying nothing about whether captures
arrive in the watched directory. Only the Cmd-Shift-4 hotkey consults the
preference. Check both halves separately: `stat` the newest file in the watched
directory to confirm real captures still land there, then the state file and
`clipboard info` for the mirror.

## The location preference is split per capture type

macOS 27 reads `com.apple.screencapture location-screenshot`, not the bare
`location`, the same way `target` has long been split into `target-screenshot`
and `target-screenrecording`. With `location-screenshot` unset the capture UI
ignores `location` and silently saves to the Desktop — `defaults read location`
still reports the path you set, so the preference looks correct while nothing
honors it. Neither a `killall SystemUIServer` nor a reboot changes this.

`defaults write` can set the key, but the value has to be in tilde form
(`~/Pictures/Screenshots`), because that is the spelling the capture UI writes
and anything comparing against `defaults read` will otherwise see a difference
that is not one and rewrite it on every run. Setting the folder through
Cmd-Shift-5 → Options → Save to → Other Location writes `location`,
`location-last`, `location-screenshot` and `location-screenrecording` together
and is the quickest way to repair a machine by hand.
