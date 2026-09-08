# herdr: report this pane's directory to the sidebar. A herdr space takes its
# label from the cwd it was created in and never updates, so an agent launched
# after a `cd` shows up filed under the wrong repo. The $dir token in
# herdr.toml's agent rows reads what this reports. Backgrounded and disowned --
# it must never make the prompt wait on a socket round-trip.
[ -n "$HERDR_ENV" ] || return 0

herdr-report-dir() {
  "$HERDR_BIN_PATH" pane report-metadata "$HERDR_PANE_ID" \
    --source zsh-cwd --token "dir=${PWD##*/}" &>/dev/null &!
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd herdr-report-dir
herdr-report-dir
