#!/usr/bin/env bash
# usage: filter-diff.sh <url-substring> '<css selector>' <outdir>
# Previews a candidate cosmetic filter in the first matching tab, without
# touching uBO Lite or reloading: scrolls the first match into view, captures
# the viewport, hides every match with an injected <style id="uf-proto">,
# captures again, then removes the style. Writes off.png, on.png and diff.png
# (off | on | changed pixels in red) and prints the match and pixel counts.
# Plain CSS only; procedural filters (:has-text() etc.) go through `just test`.
# Needs ImageMagick (`magick`).
set -euo pipefail

MATCH="$1"
SELECTOR="$2"
OUT="$3"
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUT"

page() { node "$HERE/eval.mjs" "$MATCH" "$1"; }
SEL=$(node -p 'JSON.stringify(process.argv[1])' "$SELECTOR")
# Resolves after two animation frames, i.e. once layout and paint have caught up.
FRAMES='new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)))'

count=$(page "(async () => {
  document.getElementById('uf-proto')?.remove();
  const all = document.querySelectorAll($SEL);
  all[0]?.scrollIntoView({ block: 'start' });
  scrollBy(0, -80); // keep sticky site headers from covering the target
  await $FRAMES;
  return all.length + ' matched, ' + [...all].filter(e => e.checkVisibility()).length + ' visible';
})()")
echo "$SELECTOR: ${count//\"/}"
node "$HERE/screenshot.mjs" "$MATCH" "$OUT/off.png" >/dev/null

page "(async () => {
  const s = document.createElement('style');
  s.id = 'uf-proto';
  s.textContent = $SEL + ' { display: none !important; }';
  document.head.appendChild(s);
  await $FRAMES;
})()" >/dev/null
node "$HERE/screenshot.mjs" "$MATCH" "$OUT/on.png" >/dev/null
page "document.getElementById('uf-proto').remove()" >/dev/null

ae=$(magick compare -metric AE -fuzz 2% "$OUT/off.png" "$OUT/on.png" "$OUT/delta.png" 2>&1 >/dev/null || true)
magick "$OUT/off.png" "$OUT/on.png" "$OUT/delta.png" +append -resize 50% "$OUT/diff.png"
echo "$ae pixels differ -> $OUT/diff.png"
