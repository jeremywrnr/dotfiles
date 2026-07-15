#!/usr/bin/env bash
# Claude Code statusline: cwd + git branch | model | session cost | context %
set -uo pipefail

input=$(cat)

cwd=$(jq -r '.workspace.current_dir // .cwd // "?"' <<<"$input")
display_cwd="${cwd/#$HOME/~}"

model=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // 0' <<<"$input")
pct=$(jq -r '.context_window.used_percentage // 0' <<<"$input")

branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
fi

cost_fmt=$(printf '$%.2f' "$cost")
pct_fmt=$(printf '%.0f%%' "$pct")

line="$display_cwd"
if [ -n "$branch" ]; then
  line="$line  $branch"
fi
line="$line | $model | $cost_fmt | ctx $pct_fmt"

echo "$line"
