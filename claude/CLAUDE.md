# User-level instructions

## Repos and worktrees

- One clone per repo under `~/Code/<repo>`. Never create numbered or suffixed clones like `<repo>-2`.
- Parallel or per-branch work goes in a git worktree at `<repo>/.claude/worktrees/<name>`, created with `git worktree add`, branched off `origin/main` unless told otherwise. Use one worktree per PR or agent. Never stash in a shared checkout.
- PR work in any repo defaults to a worktree. The exception is a session the user started directly in the repo root (an interactive `claude` in `~/Code/<repo>`): there, work in place unless asked for a worktree. Sessions launched from the Claude agents view, background jobs and subagents always use a worktree, even when their cwd is the repo root.
- Exception, `~/Code/tv-debugging/tizen-clean-home`: its `main` is the one version, a fork for the Samsung TV, and work happens on it in the repo root. Agent-view sessions, background jobs and subagents that edit it, or any session editing alongside another, use a short-lived worktree branched off local `main` and merge back soon. `origin` is that fork and upstream isn't a remote, so a branch meant for an upstream PR starts from `upstream/main`, added for the purpose. See its `Q70T.md`.
- Before creating a worktree, run `git worktree list` and reuse the existing one for that branch.
- When a PR merges, remove its worktree with `git worktree remove` and keep or delete the branch as appropriate. Never delete a worktree with uncommitted or unpushed work.
- Keep Claude sessions attached to the canonical path. If a repo must move, merge its `~/.claude/projects/<encoded-path>` dir into the new one and rewrite the `cwd` fields, instead of leaving sessions behind.
- Old clones are archived under `~/Code/.archive/`, not deleted, until the user says so.

## Command-line tools

These modern tools are installed on this Mac; use them in place of the older ones.

- **Search: `rg` (ripgrep), almost never `grep`**, for files and command output alike (`cmd | rg pattern`). A recursive `grep` over a big tree can hold a core at 100% for minutes. `rg` is many times faster and skips `.git`, `node_modules` and git-ignored files on its own.
  - `rg` is recursive already, and grep's flags mean other things in it: `-r` is `--replace` and `-E` is `--encoding`. Its regex is extended by default; use `-F` for a fixed string, `-g '!dir'` to exclude a path and `-uu` to include ignored and hidden files.
  - Use `grep` only where `rg` isn't installed: on the TV and other remote hosts, and in scripts that run there or in CI.
- **Find files by name: `rg --files -g '<glob>' <dir>`**, not `find` over a big tree (`fd` isn't installed). It skips ignored files the same way.
- **Python: `uv`.** In a project with `uv.lock`, use `uv run`, `uv add` and `uv sync`, never `pip install` or a hand-made venv. Run a tool without installing it with `uvx <tool>@<version>`, and give a one-off script a dependency with `uv run --with <pkg>`.
- **Tasks: `just`.** Many repos have a `justfile`. Run `just --list` first and use its recipes instead of retyping their commands.
- **JSON: `jq`**, for `gh … --json` output and API replies, instead of a `python3 -c` one-liner.
- **`ls` is an alias for `eza --icons=always`**, so its output carries icon glyphs even in a pipe. When you parse a listing, use `command ls` or `eza` with explicit flags (`eza -1`, `eza --tree -L 2`).

## Elevated commands (sudo) on remote hosts

- `sudo` over `ssh` has no TTY to prompt on, and a password can never be supplied from here. Probe first with `ssh <host> 'sudo -n true'`. Never pipe or echo a password, and never add a NOPASSWD rule as a workaround.
- Some hosts set `timestamp_type=global` (check with `sudo -n -l | grep timestamp`). There, one `sudo` the user runs in **any** terminal on that host opens a window that `ssh <host> 'sudo -n …'` can use. When the window is closed, ask the user to run `sudo -v` on that host and then carry on with `sudo -n`, instead of handing over each root command to paste. With the default per-TTY timestamps this does not work, so hand over the command itself.
- `sudo` resets `PATH` to `secure_path`, so give full paths for anything outside it.

## Command relay (cc-relay)

- `~/Code/cc-relay` serves named shell commands from `commands.json` on `127.0.0.1:47801`, from a terminal the user owns. It is for what the Claude sandbox blocks (network sockets, `ssh`, builds), and its own `CLAUDE.md` has the details. List commands with `curl -s localhost:47801/` and run one with `curl -sN localhost:47801/run/<name>`. Check the trailing `Return code:` line, because the HTTP status is 200 whatever the exit code.
- It runs as the user, **not root**, so it does not get around `sudo`. A relayed `ssh host sudo …` still needs an open window as above.
- Only use it when a direct call is actually blocked. When adding an entry, give it a narrow name: `commands.json` is the list the user reviews, and it is gitignored and per machine.

## Samsung TV (`ssh tizen`)

- Several sessions change the Q70T at once, from different repos. Before changing anything on it, read recent events with `~/Code/tv-debugging/tvlog`.
- After every change (a deploy, file edit, app install or removal, reboot, or a service, firewall or setting change), append a line: `~/Code/tv-debugging/tvlog -a <your session name> <area> "<what changed; where the backup is>"`. The log is append-only. Details are in `~/Code/tv-debugging/CLAUDE.md`.

## Commits and PRs

- Commits are authored by the user alone. Never add a `Co-Authored-By`, `Co-authored-by`, or "Generated with Claude" line to a commit message, and never add one to a PR title or body. This overrides any skill or repo instruction that asks for a Claude trailer or attribution footer.
