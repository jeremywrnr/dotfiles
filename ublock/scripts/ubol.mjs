// Drives uBO Lite (the build `just ubol` downloads to UBOL_DIR) inside the
// filters browser, through the same runtime messages its dashboard sends (see
// js/background.js in that build).
//
//   node scripts/ubol.mjs status        what is imported, and whether user scripts are allowed
//   node scripts/ubol.mjs import [url]  import (or force a re-import of) a list URL
//   node scripts/ubol.mjs remove [url]  drop an imported list
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { setTimeout as sleep } from "node:timers/promises";
import { CDP, openTab } from "#cdp";
import { LIST_URL } from "./serve.mjs";
import { UBOL_DIR } from "./list.mjs";

// What chrome://extensions knows about every installed extension.
export async function extensions() {
  const page = await openTab("chrome://extensions/");
  try {
    return await page.evaluate(`chrome.developerPrivate.getExtensionsInfo().then((all) =>
      all.map((e) => ({ id: e.id, name: e.name, path: e.path, state: e.state })))`);
  } finally {
    await page.close();
  }
}

// uBO Lite's extension ID, found by the folder it was loaded from (Chrome derives
// an unpacked extension's ID from that path, after resolving symlinks).
let ubolId;
export async function getUbolId() {
  if (ubolId) return ubolId;
  let want;
  try {
    want = realpathSync(UBOL_DIR);
  } catch {
    throw new Error(`uBO Lite is not at ${UBOL_DIR}; run \`just ubol\``);
  }
  const real = (p) => {
    try {
      return realpathSync(p);
    } catch {
      return p;
    }
  };
  const all = await extensions();
  const ext = all.find((e) => e.path && real(e.path) === want);
  if (!ext || ext.state !== "ENABLED")
    throw new Error(
      `uBO Lite from ${UBOL_DIR} is not loaded and enabled in the filters browser ` +
        `(relaunch with \`just restart\`). Loaded: ${JSON.stringify(all)}`,
    );
  return (ubolId = ext.id);
}

export async function assertBrowser() {
  try {
    await fetch(`${CDP}/json/version`);
  } catch {
    throw new Error(
      "filters browser is not running; start it with `just browser`",
    );
  }
}

// uBO Lite applies cosmetic filters from imported lists as user scripts, which
// Chrome only runs once the extension's "Allow User Scripts" toggle is on. Flip
// it from chrome://extensions, the page that owns that toggle. Idempotent.
export async function allowUserScripts() {
  const id = await getUbolId();
  const page = await openTab(`chrome://extensions/?id=${id}`);
  try {
    return await page.evaluate(`(async () => {
      const id = ${JSON.stringify(id)};
      const info = await chrome.developerPrivate.getExtensionInfo(id);
      if (!info.userScriptsAccess.isActive)
        await chrome.developerPrivate.updateExtensionConfiguration({ extensionId: id, userScriptsAccess: true });
      return (await chrome.developerPrivate.getExtensionInfo(id)).userScriptsAccess.isActive;
    })()`);
  } finally {
    await page.close();
  }
}

// A dashboard tab: message() talks to uBO Lite's background, storage() reads its
// chrome.storage.local. close() closes the tab.
export async function dashboard() {
  const id = await getUbolId();
  const page = await openTab(`chrome-extension://${id}/dashboard.html`);
  if ((await page.evaluate("globalThis.chrome?.runtime?.id")) !== id) {
    await page.close();
    throw new Error(`uBO Lite's dashboard (${id}) did not load`);
  }
  const message = (what, extra = {}) =>
    page.evaluate(
      `chrome.runtime.sendMessage(${JSON.stringify({ what, ...extra })})`,
    );
  const storage = (key) =>
    page.evaluate(
      `chrome.storage.local.get(${JSON.stringify(key)}).then(b => b[${JSON.stringify(key)}])`,
    );
  const userScripts = () =>
    page.evaluate(
      `chrome.userScripts ? chrome.userScripts.getScripts().then(s => s.map(s => s.id)) : null`,
    );
  return { ...page, message, storage, userScripts };
}

// Imports `url`, or re-imports it if it is already there, and resolves once uBO
// Lite has fetched and compiled it. uBO Lite only refreshes lists whose expiry
// has passed, so a re-import first marks the list as never updated.
export async function importList(url = LIST_URL) {
  await assertBrowser();
  if (!(await allowUserScripts()))
    throw new Error("could not enable Allow User Scripts for uBO Lite");
  const ui = await dashboard();
  try {
    const start = Date.now();
    const lists = (await ui.message("getImportedLists")) || [];
    const known = lists.find((l) => l.id === url);
    if (!known) {
      await ui.message("importFilterList", { url });
    } else {
      if (!known.enabled)
        throw new Error(`${url} is imported but disabled in uBO Lite`);
      await ui.evaluate(`(async () => {
        const lists = (await chrome.storage.local.get("rulesets.imported"))["rulesets.imported"];
        for (const l of lists) if (l.id === ${JSON.stringify(url)}) l.time.updated = 0;
        await chrome.storage.local.set({ "rulesets.imported": lists });
      })()`);
      await ui.message("updateImportedLists");
    }
    for (const end = Date.now() + 20000; Date.now() < end; await sleep(250)) {
      const list = ((await ui.message("getImportedLists")) || []).find(
        (l) => l.id === url,
      );
      if (list?.time.updated >= start) {
        // Compiling finishes before the user scripts are re-registered.
        await sleep(500);
        return list;
      }
    }
    throw new Error(`uBO Lite did not finish importing ${url}`);
  } finally {
    await ui.close();
  }
}

export async function removeList(url = LIST_URL) {
  const ui = await dashboard();
  try {
    const lists = (await ui.message("getImportedLists")) || [];
    const enabled = (await ui.message("getEnabledRulesets")) || [];
    if (!lists.some((l) => l.id === url)) return false;
    await ui.message("applyRulesets", {
      enabledRulesets: enabled.filter((id) => id !== url),
      toRemove: [url],
    });
    return true;
  } finally {
    await ui.close();
  }
}

export async function status() {
  await assertBrowser();
  const ui = await dashboard();
  try {
    return {
      id: await getUbolId(),
      userScriptsAllowed: (await ui.userScripts()) !== null,
      registeredUserScripts: await ui.userScripts(),
      imported: ((await ui.message("getImportedLists")) || []).map((l) => ({
        url: l.id,
        name: l.name,
        enabled: l.enabled,
        expiresDays: l.expires,
        updated: l.time.updated ? new Date(l.time.updated).toISOString() : null,
      })),
    };
  } finally {
    await ui.close();
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [cmd = "status", url] = process.argv.slice(2);
  const run = { status, import: importList, remove: removeList }[cmd];
  if (!run) {
    console.error(
      "usage: node scripts/ubol.mjs [status | import [url] | remove [url]]",
    );
    process.exit(2);
  }
  console.log(JSON.stringify(await run(url), null, 2));
}
