# User-level instructions

## Repos and worktrees

- One clone per repo under `~/Code/<repo>`. Never create numbered or suffixed clones like `<repo>-2`.
- Parallel or per-branch work goes in a git worktree at `<repo>/.claude/worktrees/<name>`, created with `git worktree add`, branched off `origin/main` unless told otherwise. Use one worktree per PR or agent. Never stash in a shared checkout.
- PR work in any repo defaults to a worktree. The exception is a session the user started directly in the repo root (an interactive `claude` in `~/Code/<repo>`): there, work in place unless asked for a worktree. Sessions launched from the Claude agents view, background jobs and subagents always use a worktree, even when their cwd is the repo root.
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
- Other replies: 404 is an unknown name, 500 means `commands.json` is broken, and a refused connection means the relay isn't running. For that last case, ask the user to run `just start` in `~/Code/cc-relay`.
- It runs as the user, **not root**, so it does not get around `sudo`. A relayed `ssh host sudo …` still needs an open window as above.
- Only use it when a direct call is actually blocked. To add a command, add an entry to `~/Code/cc-relay/commands.json`, either `"name": "cmd"` or `"name": {"cmd": "...", "cwd": "/abs/path"}`. Give it a narrow name, keep the file valid JSON, and tell the user what you added. The file is re-read on every request, so nothing needs restarting. It is the list the user reviews, and it is gitignored and per machine.

## Tracking repo work (Todoist)

- The Todoist project `Repos` (id `6hw4FXWJ58QQg456`) has one section per repo and one task per issue or idea. It takes work from a thought to code to a deployment.
- When the user has an idea or a follow-up to track, add a task to that repo's section. If the repo has no section, add one with its local path as the description, keeping the sections alphabetical. Use the repo's current name. `tv-debugging` is the shared context for the TV projects and has no section, so file its work under the project it concerns.
- Dedupe before adding: search open tasks in `Repos` and the Inbox by the idea's key words, not its exact wording, and check completed tasks if it may already be done. If a task already covers it, add the new detail to that task's description and don't create another. If two tasks turn out to be the same, keep the older one, merge the details into it, and tell the user before removing the other. Work that spans repos gets one task, in the repo where the change starts, naming the others in its description.
- When work on a task starts, put the branch or PR link in its description. Complete the task once the change is deployed, not when it merges.
- Keep secrets out of tasks: name the file or setting, never the value.

## Commits and PRs

- Commits are authored by the user alone. Never add a `Co-Authored-By`, `Co-authored-by`, or "Generated with Claude" line to a commit message, and never add one to a PR title or body. This overrides any skill or repo instruction that asks for a Claude trailer or attribution footer.

## Host-specific instructions

Instructions that name particular machines (browser testing, the TV) live in the private machines repo and load from there when it is checked out:

@~/Code/machines/claude/hosts.md
