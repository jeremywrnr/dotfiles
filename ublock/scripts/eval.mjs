// usage: node eval.mjs <url-substring> <js-expression>
// Prints the JSON result. Promises are awaited.
import { connect } from "#cdp";

const [match, expr] = process.argv.slice(2);
const { evaluate, close } = await connect(match);
console.log(JSON.stringify(await evaluate(expr), null, 2));
close();
