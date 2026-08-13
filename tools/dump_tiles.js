// Dump vanilla tile definitions matching sprite name prefixes from
// newtiledefinitions.tiles.txt. Usage:
//   node tools/dump_tiles.js <path-to-tiles.txt> [prefix1 prefix2 ...]
// Prints: sprite name :: prop=value; prop=value
"use strict";
const fs = require("fs");

const file = process.argv[2];
const prefixes = process.argv.slice(3);
if (!file || prefixes.length === 0) {
  console.error("usage: node dump_tiles.js <tiles.txt> <prefix> [prefix...]");
  process.exit(1);
}

const src = fs.readFileSync(file, "utf8");
const lines = src.split(/\r?\n/);

let curName = null;
let curProps = null;
const out = [];

for (const raw of lines) {
  const l = raw.trim();
  const m = l.match(/^\/\/\s*(\S+)$/);
  if (m) {
    if (curName && curProps && prefixes.some((p) => curName.startsWith(p))) {
      out.push(curName + " :: " + curProps.join("; "));
    }
    curName = m[1];
    curProps = [];
    continue;
  }
  if (l === "{") {
    if (!curProps) curProps = [];
    continue;
  }
  if (l === "}") {
    if (curName && curProps && prefixes.some((p) => curName.startsWith(p))) {
      out.push(curName + " :: " + curProps.join("; "));
    }
    curName = null;
    curProps = null;
    continue;
  }
  if (curProps && l && !l.startsWith("//")) {
    const pm = l.match(/^([\w.]+)\s*=\s*(.*)$/);
    if (pm) curProps.push(pm[1] + "=" + pm[2]);
  }
}

console.log(out.join("\n"));
console.error("total matched: " + out.length);
