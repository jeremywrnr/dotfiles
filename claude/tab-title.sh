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
#
# Finds the terminal through $TTY, which zsh/00-path.zsh exports so Claude and
# its hooks inherit it; walking the process tree with ps is the fallback.
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

# Debug trace: set CLAUDE_TAB_TITLE_LOG to a path to record what each invocation
# did. Worth reaching for first, because a hook that can't find the terminal
# looks exactly like a hook that never ran.
LOG="${CLAUDE_TAB_TITLE_LOG:-}"
log() {
  [ -n "$LOG" ] || return 0
  printf '%s %-5s %s\n' "$(date +%H:%M:%S)" "${state:-?}" "$*" >>"$LOG" 2>/dev/null
  return 0
}

state="${1:-clear}"
input=$(cat)
log "fired (ppid=$PPID TTY=${TTY:-unset})"

if [ "$state" = "done" ]; then
  # Stop fires again on the turn a blocking stop hook resumed — not a finish.
  jq -e '.stop_hook_active == true' >/dev/null 2>&1 <<<"$input" && { log "skip: stop_hook_active"; exit 0; }
  # Nor is a turn that ended only because background work is still running.
  jq -e '[(.background_tasks // [])[] | select((.status // "") | test("run|pend"; "i"))] | length > 0' \
    >/dev/null 2>&1 <<<"$input" && { log "skip: background tasks running"; exit 0; }
fi

# Find the terminal by walking up to the first ancestor that owns a tty; the
# hook itself is spawned without one.
tty_of_ancestor() {
  local pid=$1 t
  while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
    t=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
    case "$t" in
      '' | '??' | '-') ;;
      *) printf '/dev/%s' "$t"; return 0 ;;
    esac
    pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
  done
  return 1
}

# Preferred source is the env: zsh sets $TTY, and zsh/00-path.zsh exports it so Claude —
# and therefore every hook it spawns — inherits the device path. The ps walk is
# the fallback for shells that don't export it, and it fails outright wherever
# ps is unavailable (a sandbox that denies exec on /bin/ps).
dev=""
for cand in "${CLAUDE_TAB_TTY:-}" "${TTY:-}" "${SSH_TTY:-}"; do
  [ -n "$cand" ] && [ -w "$cand" ] && { dev="$cand"; break; }
done
[ -n "$dev" ] || dev=$(tty_of_ancestor "$PPID") || { log "no tty found"; exit 0; }
# Unallocated /dev/ttys* are world-writable on macOS, so writability proves
# nothing — refuse anything that isn't shaped like a terminal rather than spray
# escape codes at whatever the path happens to point to.
case "$dev" in /dev/tty*) ;; *) log "refusing $dev"; exit 0 ;; esac
[ -w "$dev" ] || { log "$dev not writable"; exit 0; }

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

log "painted '$(marker_for "$state")$label' -> $dev"
exit 0
