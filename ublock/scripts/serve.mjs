// Serves the working copy of filters.txt to uBO Lite in the filters browser, so
// tests run the same import-by-URL path the real devices use (they subscribe to
// the raw GitHub URL instead). Run directly for manual use: node scripts/serve.mjs
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

export const PORT = Number(process.env.FILTERS_PORT || 47811);
export const LIST_URL = `http://127.0.0.1:${PORT}/filters.txt`;
const FILE = fileURLToPath(new URL("../filters.txt", import.meta.url));

// Resolves with the server once it is listening; server.close() stops it.
export function serve() {
  const server = createServer(async (req, res) => {
    if (new URL(req.url, LIST_URL).pathname !== "/filters.txt") {
      res.writeHead(404).end();
      return;
    }
    // Read on every request so an edit is picked up by the next re-import.
    res.writeHead(200, {
      "content-type": "text/plain; charset=utf-8",
      "cache-control": "no-store",
    });
    res.end(await readFile(FILE));
  });
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(PORT, "127.0.0.1", () => resolve(server));
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  await serve();
  console.log(`serving ${FILE} at ${LIST_URL}`);
}
