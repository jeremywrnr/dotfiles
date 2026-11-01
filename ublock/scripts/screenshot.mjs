// usage: node screenshot.mjs <url-substring> <out.png> [height]
// Captures the full viewport, or only its top `height` CSS px (e.g. 120 for a site header).
import { writeFileSync } from "fs";
import { connect } from "#cdp";

const [match, out, h = "0"] = process.argv.slice(2);
const { send, evaluate, close } = await connect(match);
const params = { format: "png" };
if (Number(h) > 0) {
  params.clip = {
    x: 0,
    y: 0,
    width: await evaluate("innerWidth"),
    height: Number(h),
    scale: 1,
  };
}
const { data } = await send("Page.captureScreenshot", params);
writeFileSync(out, Buffer.from(data, "base64"));
console.log(out);
close();
