// usage: node click.mjs <url-substring> <css-selector | text:Exact text>
// Real mouse click at the element's center (many sites ignore synthetic .click() calls).
import { connect } from "#cdp";

const [match, target] = process.argv.slice(2);
const page = await connect(match);
console.log("clicked", await page.click(target));
page.close();
