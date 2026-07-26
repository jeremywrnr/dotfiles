#!/usr/bin/env bash
# Claude Code statusline: cwd + git branch | model | session cost | context %
set -uo pipefail

input=$(cat)

cwd=$(jq -r '.workspace.current_dir // .cwd // "?"' <<<"$input")
display_cwd="${cwd/#$HOME/"~"}"

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

model=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // 0' <<<"$input")

branch=""
branch_display=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    green=$'\033[32m'
    yellow=$'\033[33m'
    red=$'\033[31m'

    if git -C "$cwd" rev-parse -q --verify MERGE_HEAD &>/dev/null; then
      color="$red"
    elif [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
      color="$yellow"
    else
      color="$green"
    fi

    branch_display="${color}${branch}${reset}"
  fi
fi

cost_fmt=$(printf '$%.0f' "$cost")
pct_fmt=$(printf '%.0f%%' "$pct")

left="$cwd_display"
left_len=${#display_cwd}
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
  spacer=$(printf '%*s' "$pad" '')
  echo "${left}${spacer} ${right}"
else
  echo "${left} | ${right}"
fi
