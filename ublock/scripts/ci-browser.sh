#!/usr/bin/env bash
# CI: start the filters browser headless. Installs Chrome for Testing (stable),
# then launches it with a throwaway profile and uBO Lite from $UBOL_DIR,
# DevTools on $CHROME_DEV_PORT (default 9223), as `just browser` does locally.
# Returns once DevTools answers; the browser keeps running for later steps.
#
# CHROME_BIN skips the install (to try this locally with an existing build).
set -euo pipefail

: "${UBOL_DIR:?set UBOL_DIR to uBO Lite unpacked by scripts/get-ubol.sh}"
port="${CHROME_DEV_PORT:-9223}"
base="${RUNNER_TEMP:-$(mktemp -d)}/filters-browser"
mkdir -p "$base"

chrome="${CHROME_BIN:-}"
if [ -z "$chrome" ]; then
  # Pinned: this runs with the job's token in the environment.
  chrome=$(npx -y @puppeteer/browsers@3.2.6 install chrome@stable \
    --path "$base/cft" --format '{{path}}' | tail -n 1)
fi
"$chrome" --version

# --no-sandbox: Ubuntu runners block the unprivileged user namespaces Chrome's
# sandbox needs. The browser only ever loads the test pages.
nohup "$chrome" \
  --headless=new \
  --no-sandbox \
  --remote-debugging-port="$port" \
  --user-data-dir="$base/profile" \
  --no-first-run \
  --no-default-browser-check \
  --window-size=1280,900 \
  --disable-extensions-except="$UBOL_DIR" \
  --load-extension="$UBOL_DIR" \
  about:blank >"$base/chrome.log" 2>&1 &

for _ in $(seq 60); do
  if curl -fsS "http://127.0.0.1:$port/json/version" >/dev/null 2>&1; then
    echo "filters browser up on :$port; its log so far:"
    sleep 2
    tail -n 20 "$base/chrome.log"
    exit 0
  fi
  sleep 1
done
echo "filters browser did not start; its log:" >&2
cat "$base/chrome.log" >&2
exit 1
