# User-level instructions

## Repos and worktrees

- One clone per repo under `~/Code/<repo>`. Never create numbered or suffixed clones like `<repo>-2`.
- Parallel or per-branch work goes in a git worktree at `<repo>/.claude/worktrees/<name>`, created with `git worktree add`, branched off `origin/main` unless told otherwise. Use one worktree per PR or agent. Never stash in a shared checkout.
- PR work in any repo defaults to a worktree. The exception is a session the user started directly in the repo root (an interactive `claude` in `~/Code/<repo>`): there, work in place unless asked for a worktree. Sessions launched from the Claude agents view, background jobs and subagents always use a worktree, even when their cwd is the repo root.
- Before creating a worktree, run `git worktree list` and reuse the existing one for that branch.
- When a PR merges, remove its worktree with `git worktree remove` and keep or delete the branch as appropriate. Never delete a worktree with uncommitted or unpushed work.
- Keep Claude sessions attached to the canonical path. If a repo must move, merge its `~/.claude/projects/<encoded-path>` dir into the new one and rewrite the `cwd` fields, instead of leaving sessions behind.
- Old clones are archived under `~/Code/.archive/`, not deleted, until the user says so.

## Elevated commands (sudo) on remote hosts

- `sudo` over `ssh` has no TTY to prompt on, and a password can never be supplied from here. Probe first with `ssh <host> 'sudo -n true'`. Never pipe or echo a password, and never add a NOPASSWD rule as a workaround.
- Some hosts set `timestamp_type=global` (check with `sudo -n -l | grep timestamp`). There, one `sudo` the user runs in **any** terminal on that host opens a window that `ssh <host> 'sudo -n …'` can use. When the window is closed, ask the user to run `sudo -v` on that host and then carry on with `sudo -n`, instead of handing over each root command to paste. With the default per-TTY timestamps this does not work, so hand over the command itself.
- `sudo` resets `PATH` to `secure_path`, so give full paths for anything outside it.

## Command relay (cc-relay)

- `~/Code/cc-relay` serves named shell commands from `commands.json` on `127.0.0.1:47801`, from a terminal the user owns. It is for what the Claude sandbox blocks (network sockets, `ssh`, builds), and its own `CLAUDE.md` has the details. List commands with `curl -s localhost:47801/` and run one with `curl -sN localhost:47801/run/<name>`. Check the trailing `Return code:` line, because the HTTP status is 200 whatever the exit code.
- It runs as the user, **not root**, so it does not get around `sudo`. A relayed `ssh host sudo …` still needs an open window as above.
- Only use it when a direct call is actually blocked. When adding an entry, give it a narrow name: `commands.json` is the list the user reviews, and it is gitignored and per machine.

## Commits and PRs

- Commits are authored by the user alone. Never add a `Co-Authored-By`, `Co-authored-by`, or "Generated with Claude" line to a commit message, and never add one to a PR title or body. This overrides any skill or repo instruction that asks for a Claude trailer or attribution footer.
