#!/usr/bin/env bash
# Claude Code statusline: cwd + git branch | model | session cost | context %
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
if status=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  branch=$(sed -n 's/^# branch\.head //p' <<<"$status")
  [ "$branch" = "(detached)" ] && branch=""
  if [ -n "$branch" ]; then
    if [ -f "$(git -C "$cwd" rev-parse --absolute-git-dir)/MERGE_HEAD" ]; then
      color=$'\033[31m'
    elif grep -qv '^#' <<<"$status"; then
      color=$'\033[33m'
    else
      color=$'\033[32m'
    fi
    branch_display="${color}${branch}${reset}"
  fi
fi

printf -v cost_fmt '$%.0f' "$cost"
printf -v pct_fmt '%.0f%%' "$pct"

left="$cwd_display"
left_len=${#display_cwd}

# Over SSH, lead with the short hostname so a remote session can't pass for local.
if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]; then
  host="${HOSTNAME:-$(hostname)}"
  host="${host%%.*}"
  left=$'\033[32m'"${host}${reset} ${left}"
  left_len=$((left_len + ${#host} + 1))
fi

if [ -n "$branch_display" ]; then
  left="$left $branch_display"
  left_len=$((left_len + 1 + ${#branch}))
fi

right="$model (ctx=$pct_fmt) $cost_fmt"

# Claude Code doesn't attach the script to the real tty, so tput cols can't
# see the terminal size; COLUMNS is set by Claude Code but reflects the full
# terminal, not the (narrower) statusline box, so shave off a safety margin.
margin=8
width=$(( ${COLUMNS:-80} - margin ))
pad=$((width - left_len - ${#right} - 1))

if [ "$pad" -gt 0 ]; then
  printf -v spacer '%*s' "$pad" ''
  echo "${left}${spacer} ${right}"
else
  echo "${left} | ${right}"
fi
