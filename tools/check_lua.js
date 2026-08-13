// Lua structural sanity check: bracket balance, ignoring strings/comments.
const fs = require("fs");
const path = require("path");

function walk(dir, out = []) {
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    if (fs.statSync(p).isDirectory()) walk(p, out);
    else if (f.endsWith(".lua") || f.endsWith(".json") || (f.endsWith(".txt") && p.includes("Translate"))) out.push(p);
  }
  return out;
}

let fail = 0;
for (const file of walk(path.join(__dirname, "..", "42", "media", "lua"))) {
  let src = fs.readFileSync(file, "utf8");
  src = src.replace(/--\[\[[\s\S]*?\]\]/g, " ").replace(/--[^\n]*/g, " ");
  src = src.replace(/"(?:[^"\\]|\\.)*"/g, '""').replace(/'(?:[^'\\]|\\.)*'/g, "''");
  let depth = 0;
  let line = 1;
  let bad = null;
  for (let i = 0; i < src.length; i++) {
    if (src[i] === "\n") line++;
    if (src[i] === "{" || src[i] === "(") depth++;
    else if (src[i] === "}" || src[i] === ")") {
      depth--;
      if (depth < 0) {
        bad = "negative depth at line " + line;
        break;
      }
    }
  }
  if (bad || depth !== 0) {
    console.log("FAIL", file, bad || "depth=" + depth);
    fail++;
  } else {
    console.log("OK  ", file);
  }
}
// also verify json files parse
for (const file of walk(path.join(__dirname, "..", "42", "media", "lua"))) {
  if (file.endsWith(".json")) {
    try {
      JSON.parse(fs.readFileSync(file, "utf8"));
      console.log("OK  ", file);
    } catch (e) {
      console.log("FAIL", file, e.message);
      fail++;
    }
  }
}
process.exit(fail ? 1 : 0);
