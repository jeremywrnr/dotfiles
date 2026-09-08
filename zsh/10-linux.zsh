# Linux only.
[[ "$OSTYPE" == linux* ]] || return 0

alias brew="sudo apt-get"
alias brewup="sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y && sudo apt-get autoclean && sudo snap refresh"

export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"

# Muscle memory from macOS mole (tw93/Mole). Only the status view ports:
# mole's cleanup/uninstall half is built on ~/Library and .app bundles and has
# no Ubuntu analogue -- use `apt autoremove --purge` and `journalctl --vacuum`.
# Lives here, not in 30-functions.zsh, so it cannot shadow the real mole
# binary on macOS -- this file returns early off Linux.
mo() {
  case "$1" in
    ""|status) btop ;;
    # Not nvtop: Noble ships 3.0.2, which on i915 reports utilization only and
    # says so in a modal on every launch. Needs cap_perfmon (see install.sh).
    gpu)       intel_gpu_top ;;
    *) echo "mo: only 'status' and 'gpu' ported from mole" >&2; return 1 ;;
  esac
}
