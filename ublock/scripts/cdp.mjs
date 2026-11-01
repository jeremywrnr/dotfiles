// DevTools-protocol helpers for the filters browser (`just browser`: a chrome-dev
// instance on :9223 with uBO Lite loaded). Copied from better-email's
// test/integration/cdp.mjs; only the default port differs. Imported as "#cdp".
export const CDP = `http://127.0.0.1:${process.env.CHROME_DEV_PORT || 9223}`;

// Attach to the first page tab whose URL contains `match`.
export async function connect(match) {
  const targets = await (await fetch(`${CDP}/json/list`)).json();
  const t = targets.find((t) => t.type === "page" && t.url.includes(match));
  if (!t) throw new Error(`no page matching ${match}`);
  return attach(t);
}

// Open `url` in a new tab and resolve once it has loaded; close() closes the tab.
export async function openTab(url) {
  const t = await (
    await fetch(`${CDP}/json/new?about:blank`, { method: "PUT" })
  ).json();
  const page = await attach(t);
  // Clipboard APIs need a focused document; a tab driven from here usually isn't.
  await page.send("Emulation.setFocusEmulationEnabled", { enabled: true });
  // Opaque origins (about:blank, data:) can't hold permissions.
  if (/^https?:/.test(url))
    await page.send("Browser.grantPermissions", {
      origin: new URL(url).origin,
      permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"],
    });
  await page.send("Page.enable");
  const loaded = page.once("Page.loadEventFired");
  await page.send("Page.navigate", { url });
  await loaded;
  return { ...page, close: () => fetch(`${CDP}/json/close/${t.id}`) };
}

// JS expression for the element `target` names: a CSS selector, or
// "text:Exact label" for the deepest element with that text.
function finder(target) {
  if (!target.startsWith("text:"))
    return `document.querySelector(${JSON.stringify(target)})`;
  // Walks text nodes rather than reading innerText on every element (which forces layout).
  return `(() => { const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); let n, hit;
    while ((n = w.nextNode())) if (n.nodeValue.trim() === ${JSON.stringify(target.slice(5))}) hit = n.parentElement;
    return hit; })()`;
}

async function attach(t) {
  const ws = new WebSocket(t.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener("open", r));
  let id = 0;
  const pending = new Set();
  // A navigation or tab close drops the socket; fail in-flight calls instead of hanging.
  ws.addEventListener("close", () =>
    pending.forEach((fail) => fail(new Error("CDP connection closed"))),
  );
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const i = ++id;
      pending.add(reject);
      const onMessage = (m) => {
        const d = JSON.parse(m.data);
        if (d.id !== i) return;
        ws.removeEventListener("message", onMessage);
        pending.delete(reject);
        d.error ? reject(new Error(d.error.message)) : resolve(d.result);
      };
      ws.addEventListener("message", onMessage);
      ws.send(JSON.stringify({ id: i, method, params }));
    });
  // Resolves with the params of the next `method` event.
  const once = (method) =>
    new Promise((resolve) => {
      const onMessage = (m) => {
        const d = JSON.parse(m.data);
        if (d.method !== method) return;
        ws.removeEventListener("message", onMessage);
        resolve(d.params);
      };
      ws.addEventListener("message", onMessage);
    });
  const evaluate = async (expression) => {
    const { result, exceptionDetails } = await send("Runtime.evaluate", {
      expression,
      returnByValue: true,
      awaitPromise: true,
    });
    if (exceptionDetails)
      throw new Error(
        exceptionDetails.exception?.description || exceptionDetails.text,
      );
    return result.value;
  };
  // Scrolls `target` into view; returns its center and box.
  const center = async (target) => {
    const box = await evaluate(`(() => {
      const e = ${finder(target)};
      if (!e) return null;
      e.scrollIntoView({ block: "center" });
      const r = e.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2, top: r.top, tag: e.tagName };
    })()`);
    if (!box) throw new Error(`no element for ${target}`);
    return box;
  };
  const mouse = (type, { x, y }) =>
    send("Input.dispatchMouseEvent", {
      type,
      x,
      y,
      button: "left",
      clickCount: 1,
    });
  // Real mouse events; many sites ignore synthetic .click()s and :hover needs a pointer.
  const hover = async (target) => {
    const box = await center(target);
    await mouse("mouseMoved", { x: box.x, y: box.y + 80 }); // enter from outside
    await mouse("mouseMoved", box);
    return box;
  };
  const click = async (target) => {
    const box = await hover(target);
    await mouse("mousePressed", box);
    await mouse("mouseReleased", box);
    return box;
  };
  return {
    send,
    once,
    evaluate,
    center,
    hover,
    click,
    close: () => ws.close(),
  };
}
