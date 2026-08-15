const lp = require("luaparse");
const fs = require("fs");
const path = require("path");
let fail = 0;
function walk(d) {
  for (const f of fs.readdirSync(d)) {
    const p = path.join(d, f);
    const s = fs.statSync(p);
    if (s.isDirectory()) walk(p);
    else if (f.endsWith(".lua")) check(p);
  }
}
function check(p) {
  try {
    lp.parse(fs.readFileSync(p, "utf8"), { luaVersion: "5.1" });
    console.log("OK  " + p);
  } catch (e) {
    fail++;
    console.log("FAIL " + p + " :: " + e.message);
  }
}
walk(process.argv[2]);
process.exit(fail ? 1 : 0);
