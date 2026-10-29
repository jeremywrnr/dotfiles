#!/usr/bin/env bash
# Claude Code statusline: LOCAL or REMOTE(host), cwd + git branch + PR | model | context % | session cost
set -uo pipefail

input=$(cat)

# One jq for every field; this runs on each render.
IFS=$'\t' read -r cwd model cost pct < <(jq -r '[
  .workspace.current_dir // .cwd // "?",
  .model.display_name // .model.id // "?",
  .cost.total_cost_usd // 0,
  .context_window.used_percentage // 0
] | @tsv' <<<"$input")
# Via a variable: bash 3.2 (macOS's /bin/bash) keeps quotes around a literal
# "~" replacement, and an unquoted one would tilde-expand right back to $HOME.
tilde='~'
display_cwd="${cwd/#$HOME/$tilde}"

reset=$'\033[0m'
bright_white=$'\033[1;97m'
green=$'\033[32m'
bold_green=$'\033[1;32m'
bold_blue=$'\033[1;34m'
yellow=$'\033[33m'
red=$'\033[31m'
grey=$'\033[90m'

base_name="${display_cwd##*/}"
dir_prefix="${display_cwd%/*}"
if [ "$dir_prefix" = "$display_cwd" ]; then
  dir_prefix=""
fi
if [ -z "$base_name" ]; then
  base_name="/"
  dir_prefix=""
fi
if [ -n "$dir_prefix" ]; then
  cwd_display="${dir_prefix}/${bright_white}${base_name}${reset}"
else
  cwd_display="${bright_white}${base_name}${reset}"
fi

# Branch and dirty state from one status call; --no-optional-locks so a render
# never takes index.lock out from under a git command running alongside it.
branch=""
branch_display=""
repo_root=""
if status=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  branch=$(sed -n 's/^# branch\.head //p' <<<"$status")
  [ "$branch" = "(detached)" ] && branch=""
  if [ -n "$branch" ]; then
    repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    if [ -f "$(git -C "$cwd" rev-parse --absolute-git-dir)/MERGE_HEAD" ]; then
      color="$red"
    elif grep -qv '^#' <<<"$status"; then
      color="$yellow"
    else
      color="$green"
    fi
    branch_display="${color}${branch}${reset}"
  fi
fi

# Open PR for the current branch, coloured by CI rollup. `gh pr view` costs a
# network round trip, which the statusline cannot afford on every render, so
# the answer is cached per (worktree, branch) and refreshed by a detached
# background job — this render paints whatever was cached last.
pr_num=""
pr_status=""

pr_lookup() {
  [ -n "$branch" ] && [ -n "$repo_root" ] && command -v gh &>/dev/null || return

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
  local cache_file="$cache_dir/pr${repo_root//\//_}__${branch//\//_}"
  local stamp=0 ttl lock waited

  # no cache file leaves stamp at 0, which reads as "never fetched"
  if [ -f "$cache_file" ]; then
    IFS='|' read -r stamp pr_num pr_status < "$cache_file"
  fi
  case "$stamp" in *[!0-9]* | '') stamp=0 ;; esac

  # a run still waiting on checks is the one worth re-asking about often
  case "$pr_status" in pending) ttl=30 ;; *) ttl=90 ;; esac
  [ $(( $(date +%s) - stamp )) -ge "$ttl" ] || return

  lock="$cache_file.lock"
  mkdir -p "$cache_dir"
  # reclaim a lock left behind by a refresh that was killed mid-flight; the
  # test is a builtin, so the usual no-lock case never pays for the fork
  [ -d "$lock" ] && find "$lock" -maxdepth 0 -mmin +2 -delete 2>/dev/null

  if mkdir "$lock" 2>/dev/null; then
    (
      cd "$repo_root" || exit
      # NEUTRAL/SKIPPED checks are not failures; a StatusContext has no
      # status/conclusion pair, only a state.
      line=$(gh pr view --json state,number,statusCheckRollup 2>/dev/null | jq -r '
        if .state != "OPEN" then "|" else
          [ .statusCheckRollup[]? |
            if .__typename == "CheckRun" then
              if .status != "COMPLETED" then "pending"
              elif .conclusion | IN("SUCCESS", "NEUTRAL", "SKIPPED") then "success"
              else "failure" end
            else
              if .state | IN("PENDING", "EXPECTED") then "pending"
              elif .state == "SUCCESS" then "success"
              else "failure" end
            end
          ] as $checks |
          (.number | tostring) + "|" + (
            if   $checks | index("failure") then "failure"
            elif $checks | index("pending") then "pending"
            elif $checks | length == 0      then "none"
            else "success" end
          )
        end')
      # cache misses too, so a repo without PRs is not re-queried every render
      printf '%s|%s\n' "$(date +%s)" "${line:-|}" > "$cache_file.tmp" &&
        mv -f "$cache_file.tmp" "$cache_file"
      rmdir "$lock"
      # branches and worktrees come and go; drop entries nothing has asked
      # about in a fortnight rather than growing the directory forever
      find "$cache_dir" -maxdepth 1 -type f -name 'pr_*' -mtime +14 -delete 2>/dev/null
    ) >/dev/null 2>&1 &
    disown 2>/dev/null
  fi

  # Nothing cached means nothing to paint, and the statusline only redraws on
  # session activity — so a fresh branch would sit blank until some later
  # redraw happened by. Wait out the first fetch, whichever render started it.
  [ "$stamp" -eq 0 ] || return
  waited=0
  while [ ! -f "$cache_file" ] && [ "$waited" -lt 25 ]; do
    sleep 0.1
    waited=$((waited + 1))
  done
  if [ -f "$cache_file" ]; then
    IFS='|' read -r stamp pr_num pr_status < "$cache_file"
  fi
}

pr_lookup

pr_display=""
pr_text=""
if [ -n "$pr_num" ]; then
  case "$pr_status" in
    failure) pr_color="$red" ;;
    pending) pr_color="$yellow" ;;
    success) pr_color="$green" ;;
    *)       pr_color="$grey" ;;
  esac
  pr_text="#$pr_num"
  pr_display="${pr_color}${pr_text}${reset}"
fi

printf -v cost_fmt '$%.0f' "$cost"
printf -v pct_fmt '%.0f%%' "$pct"

left="$cwd_display"
left_len=${#display_cwd}

# Lead with where the session runs, so neither kind can pass for the other.
# The remote side never sees the ssh alias the client typed, so the short
# hostname stands in for it, unless CLAUDE_STATUSLINE_HOST names a shorter one.
if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]; then
  host="${CLAUDE_STATUSLINE_HOST:-${HOSTNAME:-$(hostname)}}"
  host="${host%%.*}"
  left="${bold_blue}REMOTE(${host})${reset} ${left}"
  left_len=$((left_len + ${#host} + 9))
else
  left="${bold_green}LOCAL${reset} ${left}"
  left_len=$((left_len + 6))
fi

if [ -n "$branch_display" ]; then
  left="$left $branch_display"
  left_len=$((left_len + 1 + ${#branch}))
fi
if [ -n "$pr_display" ]; then
  left="$left $pr_display"
  left_len=$((left_len + 1 + ${#pr_text}))
fi

right="$model (ctx=$pct_fmt) $cost_fmt"
right_len=${#right}

# Claude Code doesn't attach the script to the real tty, so tput cols can't
# see the terminal size; COLUMNS is set by Claude Code but reflects the full
# terminal, not the (narrower) statusline box, so shave off a safety margin.
margin=8
width=$(( ${COLUMNS:-80} - margin ))
pad=$((width - left_len - right_len - 1))

if [ "$pad" -gt 0 ]; then
  printf -v spacer '%*s' "$pad" ''
  echo "${left}${spacer} ${right}"
else
  echo "${left} | ${right}"
fi
