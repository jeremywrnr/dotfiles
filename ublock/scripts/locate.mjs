// usage: node scripts/locate.mjs <url-substring> '<css selector>' [max]
// Describes every element matching the selector in the first matching tab: what
// it is, whether it is visible, its size, the custom elements and links inside
// it, and its ancestors. Use it to find the stable handle for a filter and to
// count matches across page types. Prints JSON.
import { connect } from "#cdp";

const [match, selector, max = "20"] = process.argv.slice(2);
if (!selector) {
  console.error(
    "usage: node scripts/locate.mjs <url-substring> '<css selector>' [max]",
  );
  process.exit(2);
}

const describe = (selector, max) => {
  const label = (e) =>
    e.tagName.toLowerCase() +
    (e.id ? `#${e.id}` : "") +
    [...e.attributes]
      .filter((a) => !["class", "id", "style"].includes(a.name))
      .slice(0, 4)
      .map(
        (a) =>
          `[${a.name}${a.value && a.value.length < 40 ? `="${a.value}"` : ""}]`,
      )
      .join("");
  const all = [...document.querySelectorAll(selector)];
  return {
    url: location.href,
    count: all.length,
    visible: all.filter((e) => e.checkVisibility()).length,
    matches: all.slice(0, max).map((e) => {
      const r = e.getBoundingClientRect();
      const ancestors = [];
      for (
        let p = e.parentElement;
        p && p !== document.body;
        p = p.parentElement
      )
        ancestors.push(label(p));
      const inner = [...e.querySelectorAll("*")];
      return {
        element: label(e),
        classes: [...e.classList],
        visible: e.checkVisibility(),
        box: [r.x, r.y, r.width, r.height].map(Math.round),
        heading: (
          e.querySelector("h1, h2, h3, [role=heading]")?.textContent || ""
        )
          .trim()
          .replace(/\s+/g, " ")
          .slice(0, 80),
        text: (e.innerText || "").trim().replace(/\s+/g, " ").slice(0, 120),
        // Custom elements and data-/aria- attributes are the usual stable handles.
        customElements: [
          ...new Set(
            inner
              .map((x) => x.tagName.toLowerCase())
              .filter((t) => t.includes("-")),
          ),
        ].slice(0, 20),
        handles: [
          ...new Set(
            inner.flatMap((x) =>
              [...x.attributes]
                .filter((a) => /^(data-|aria-label|role$|is-)/.test(a.name))
                .map((a) => `${a.name}=${a.value.slice(0, 40)}`),
            ),
          ),
        ].slice(0, 20),
        links: [
          ...new Set(
            inner
              .filter((x) => x.tagName === "A" && x.getAttribute("href"))
              .map((x) =>
                x
                  .getAttribute("href")
                  .replace(/[?#].*/, "")
                  .replace(/\/[\w-]{8,}$/, "/…"),
              ),
          ),
        ].slice(0, 10),
        ancestors: ancestors.slice(0, 8),
      };
    }),
  };
};

const page = await connect(match);
console.log(
  JSON.stringify(
    await page.evaluate(
      `(${describe})(${JSON.stringify(selector)}, ${Number(max)})`,
    ),
    null,
    2,
  ),
);
page.close();
