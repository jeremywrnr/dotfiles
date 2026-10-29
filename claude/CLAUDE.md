# User-level instructions

## Repos and worktrees

- One clone per repo under `~/Code/<repo>`. Never create numbered or suffixed clones like `<repo>-2`.
- Parallel or per-branch work goes in a git worktree at `<repo>/.claude/worktrees/<name>`, created with `git worktree add`, branched off `origin/main` unless told otherwise. Use one worktree per PR or agent. Never stash in a shared checkout.
- PR work in any repo defaults to a worktree. The exception is a session the user started directly in the repo root (an interactive `claude` in `~/Code/<repo>`): there, work in place unless asked for a worktree. Sessions launched from the Claude agents view, background jobs and subagents always use a worktree, even when their cwd is the repo root.
- Before creating a worktree, run `git worktree list` and reuse the existing one for that branch.
- When a PR merges, remove its worktree with `git worktree remove` and keep or delete the branch as appropriate. Never delete a worktree with uncommitted or unpushed work.
- Keep Claude sessions attached to the canonical path. If a repo must move, merge its `~/.claude/projects/<encoded-path>` dir into the new one and rewrite the `cwd` fields, instead of leaving sessions behind.
- Old clones are archived under `~/Code/.archive/`, not deleted, until the user says so.

## Commits and PRs

- Commits are authored by the user alone. Never add a `Co-Authored-By`, `Co-authored-by`, or "Generated with Claude" line to a commit message, and never add one to a PR title or body. This overrides any skill or repo instruction that asks for a Claude trailer or attribution footer.
