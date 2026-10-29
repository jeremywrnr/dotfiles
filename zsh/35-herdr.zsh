# herdr: report which repo this pane is in to the sidebar. A herdr space takes
# its label from the cwd it was created in and never updates, so an agent
# launched after a `cd` shows up filed under the wrong repo. The $dir token in
# herdr.toml's agent rows reads what this reports. Backgrounded and disowned --
# it must never make the prompt wait on a socket round-trip.
[ -n "$HERDR_ENV" ] || return 0

# The repo is named after the main clone, not the cwd: --git-common-dir points
# at the clone's .git from any of its worktrees, so an agent in
# <repo>/.claude/worktrees/<slug> is filed under <repo> rather than its slug.
# Outside a repo it falls back to the directory name.
herdr-report-dir() {
  {
    local common repo
    common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [[ -n $common ]]; then
      repo=${${common:h}:t}
    else
      repo=${PWD##*/}
    fi
    "$HERDR_BIN_PATH" pane report-metadata "$HERDR_PANE_ID" \
      --source zsh-cwd --token "dir=$repo"
  } &>/dev/null &!
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd herdr-report-dir
herdr-report-dir

# hwt <slug> [base]: open a worktree of the current repo as its own herdr space,
# linked to the repo's primary space so the sidebar groups them. Worktrees go
# under <clone>/.claude/worktrees/<slug> on branch <slug>, cut from origin/main
# unless a base is given; an existing one is reopened rather than recreated.
# Works from inside another worktree too, since the clone is found the same
# way herdr-report-dir finds it. herdr's JSON reply is dropped; errors still
# reach stderr. A Python repo also gets its venv, via uv sync.
hwt() {
  local slug=$1 base=${2:-origin/main} common root wt
  [[ -n $slug ]] || { print -u2 "usage: hwt <slug> [base]"; return 2; }
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) ||
    { print -u2 "hwt: not in a git repo"; return 1; }
  root=${common:h}
  wt=$root/.claude/worktrees/$slug
  if [[ -d $wt ]]; then
    "$HERDR_BIN_PATH" worktree open --cwd "$root" --path "$wt" \
      --label "${root:t}-$slug" --focus >/dev/null
  else
    [[ $base == origin/* ]] && git -C "$root" fetch -q origin "${base#origin/}"
    "$HERDR_BIN_PATH" worktree create --cwd "$root" --path "$wt" \
      --branch "$slug" --base "$base" --label "${root:t}-$slug" --focus >/dev/null
  fi || return
  # Commit hooks run from the worktree's own venv, so a Python repo isn't
  # usable until it has one. Skipped once .venv exists, so a reopen is free.
  if [[ -f $wt/pyproject.toml && ! -d $wt/.venv ]] && (( $+commands[uv] )); then
    uv sync --directory "$wt"
  fi
}
