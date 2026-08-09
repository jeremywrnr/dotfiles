#!/usr/bin/env bash
# Claude Code hook: mark the Alacritty tab when Claude wants you.
#
# macOS draws Alacritty's tab bar natively and labels each tab with that
# window's title, so OSC 0 is the only lever — there's no urgency/attention
# primitive like X11's.
#
# Claude owns the title while it works (that's the auto-generated topic you
# see). These markers land in the gaps: on Stop and on Notification it's idle
# and won't repaint, so the marker sticks. UserPromptSubmit wipes it again the
# moment you answer.
#
# Usage: tab-title.sh needs|done|clear   (hook JSON on stdin)
set -uo pipefail

marker_for() {
  case "$1" in
    needs) printf '\xf0\x9f\x94\xb4 ' ;;  # red circle
    done)  printf '\xe2\x9c\x85 ' ;;      # check mark
    *)     printf '' ;;
  esac
}

# Blink the marker this many times before settling. 0 = write it once and stop.
# Alacritty exposes no way to ask which tab is focused, so a blink fires even
# when you're staring straight at it; that's why the quiet default.
FLASHES=0

state="${1:-clear}"
input=$(cat)

if [ "$state" = "done" ]; then
  # Stop fires again on the turn a blocking stop hook resumed — not a finish.
  jq -e '.stop_hook_active == true' >/dev/null 2>&1 <<<"$input" && exit 0
  # Nor is a turn that ended only because background work is still running.
  jq -e '[(.background_tasks // [])[] | select((.status // "") | test("run|pend"; "i"))] | length > 0' \
    >/dev/null 2>&1 <<<"$input" && exit 0
fi

# Find the terminal by walking up to the first ancestor that owns a tty; the
# hook itself is spawned without one.
tty_of_ancestor() {
  local pid=$1 t
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
    t=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
    case "$t" in
      '' | '??' | '-') ;;
      *) printf '%s' "$t"; return 0 ;;
    esac
    pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
  done
  return 1
}

tty=$(tty_of_ancestor "$PPID") || exit 0
dev="/dev/$tty"
[ -w "$dev" ] || exit 0

cwd=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
label="${cwd:-$PWD}"
label="${label##*/}"

set_title() { printf '\033]0;%s%s\007' "$1" "$label" >"$dev"; }

# Hooks block the turn, so anything with a sleep in it has to detach.
paint() {
  local mark
  mark=$(marker_for "$state")
  for ((i = 0; i < FLASHES; i++)); do
    set_title "$mark"
    sleep 0.35
    set_title '   '
    sleep 0.35
  done
  set_title "$mark"
}

if [ "$FLASHES" -gt 0 ]; then
  paint >/dev/null 2>&1 &
  disown
else
  paint
fi

exit 0
