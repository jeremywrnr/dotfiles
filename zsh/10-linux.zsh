# Linux only.
[[ "$OSTYPE" == linux* ]] || return 0

alias brew="sudo apt-get"
alias brewup="sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y && sudo apt-get autoclean && { ! command -v snap >/dev/null || sudo snap refresh; }"

export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"

# WSL appends the Windows PATH only to shells wsl.exe starts. An ssh login
# into WSL comes from sshd instead, so powershell.exe, cmd.exe and friends were
# "command not found" there even though interop runs them fine by full path.
# The WSLInterop binfmt entry is the cheap tell that interop is on; the /mnt/c
# check skips shells that already inherited Windows' own (longer) PATH.
if [[ -e /proc/sys/fs/binfmt_misc/WSLInterop && ${path[(I)/mnt/c/*]} -eq 0 ]]; then
  for _wdir in /mnt/c/Windows/System32 /mnt/c/Windows /mnt/c/Windows/System32/Wbem \
      /mnt/c/Windows/System32/WindowsPowerShell/v1.0 /mnt/c/Windows/System32/OpenSSH \
      "/mnt/c/Users/$USER/AppData/Local/Microsoft/WindowsApps"; do
    [[ -d $_wdir ]] && path+=("$_wdir")
  done
  unset _wdir
fi

# Muscle memory from macOS mole (tw93/Mole). Only the status view ports:
# mole's cleanup/uninstall half is built on ~/Library and .app bundles and has
# no Ubuntu analogue -- use `apt autoremove --purge` and `journalctl --vacuum`.
# Lives here, not in 30-functions.zsh, so it cannot shadow the real mole
# binary on macOS -- this file returns early off Linux.
mo() {
  case "$1" in
    ""|status) btop ;;
    # Not nvtop: Noble ships 3.0.2, which on i915 reports utilization only and
    # says so in a modal on every launch. Needs cap_perfmon: sudo setcap cap_perfmon+ep "$(command -v intel_gpu_top)".
    gpu)       intel_gpu_top ;;
    *) echo "mo: only 'status' and 'gpu' ported from mole" >&2; return 1 ;;
  esac
}
