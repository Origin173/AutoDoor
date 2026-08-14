// AutoDoor asset processor: turns raw AI-generated item renders into
// game-ready PZ icons. Pure Node + zlib, no external dependencies.
//
// Pipeline per image:
//   1. decode PNG (RGBA/RGB/gray, 8-bit)
//   2. background removal: BFS flood fill from all border pixels, with a
//      per-pixel background colour field so smooth gradients are followed;
//      soft alpha ramp + un-bleed (defringe) against the local bg colour
//   3. crop to content bounding box
//   4. area-average (premultiplied) resize to fit 128x128, centered
//   5. encode PNG, write next to the original (original backed up to
//      tools/ai_originals/ first)
//
// Works for dark AND light backgrounds (the bg colour is learned from the
// borders, not assumed). Run: node tools/process_ai_images.js
"use strict";
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const root = path.join(__dirname, "..");
const texDir = path.join(root, "42", "media", "textures");
const backupDir = path.join(__dirname, "ai_originals");

// TARGET = 128x128 canvas, content fitted to FIT px (like vanilla icons).
const TARGET = 128;
const FIT = 112;

// ---------- PNG decode ----------
function decodePNG(file) {
  const b = fs.readFileSync(file);
  if (b.readUInt32BE(0) !== 0x89504e47) throw new Error(file + " is not a PNG");
  let off = 8, w = 0, h = 0, bit = 0, color = 0, interlace = 0;
  const idat = [];
  while (off < b.length) {
    const len = b.readUInt32BE(off);
    const type = b.toString("ascii", off + 4, off + 8);
    if (type === "IHDR") {
      w = b.readUInt32BE(off + 8); h = b.readUInt32BE(off + 12);
      bit = b[off + 16]; color = b[off + 17]; interlace = b[off + 20];
    } else if (type === "IDAT") idat.push(b.slice(off + 8, off + 8 + len));
    off += 12 + len;
  }
  if (bit !== 8 || interlace !== 0) throw new Error(file + ": only 8-bit non-interlaced PNG supported");
  const ch = color === 6 ? 4 : color === 2 ? 3 : color === 0 ? 1 : color === 4 ? 2 : 0;
  if (!ch) throw new Error(file + ": unsupported colour type " + color);
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * ch + 1;
  const out = Buffer.alloc(w * h * ch);
  for (let y = 0; y < h; y++) {
    const f = raw[y * stride];
    for (let x = 0; x < w * ch; x++) {
      const i = y * stride + 1 + x, idx = y * w * ch + x;
      const a = x >= ch ? out[idx - ch] : 0;
      const u = y > 0 ? out[idx - w * ch] : 0;
      const ul = x >= ch && y > 0 ? out[idx - w * ch - ch] : 0;
      let v = raw[i];
      if (f === 1) v = (v + a) & 255;
      else if (f === 2) v = (v + u) & 255;
      else if (f === 3) v = (v + ((a + u) >> 1)) & 255;
      else if (f === 4) {
        const p = a + u - ul, pa = Math.abs(p - a), pb = Math.abs(p - u), pc = Math.abs(p - ul);
        v = (v + (pa <= pb && pa <= pc ? a : pb <= pc ? u : ul)) & 255;
      }
      out[idx] = v;
    }
  }
  // normalize to RGBA
  if (ch === 4) return { w, h, data: out };
  const rgba = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    const s = i * ch, d = i * 4;
    if (ch === 3) { rgba[d] = out[s]; rgba[d + 1] = out[s + 1]; rgba[d + 2] = out[s + 2]; rgba[d + 3] = 255; }
    else if (ch === 1) { rgba[d] = rgba[d + 1] = rgba[d + 2] = out[s]; rgba[d + 3] = 255; }
    else { rgba[d] = rgba[d + 1] = rgba[d + 2] = out[s]; rgba[d + 3] = out[s + 1]; }
  }
  return { w, h, data: rgba };
}

// ---------- PNG encode (RGBA) ----------
const CRC_TABLE = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c; }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const t = Buffer.from(type, "ascii");
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t, data])));
  return Buffer.concat([len, t, data, crc]);
}
function encodePNG(w, h, rgba) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6;
  const stride = w * 4 + 1;
  const raw = Buffer.alloc(stride * h);
  for (let y = 0; y < h; y++) {
    raw[y * stride] = 0;
    rgba.copy(raw, y * stride + 1, y * w * 4, (y + 1) * w * 4);
  }
  return Buffer.concat([sig, chunk("IHDR", ihdr), chunk("IDAT", zlib.deflateSync(raw, { level: 9 })), chunk("IEND", Buffer.alloc(0))]);
}

// ---------- background removal ----------
// BFS from every border pixel. Each accepted pixel stores its own colour as
// the local bg estimate, so the fill follows smooth gradients. A pixel is
// background when its distance to the neighbour's bg estimate is < TOL
// (distance = sum of absolute RGB differences, 0..765).
const TOL = 70;     // BFS acceptance
const R0 = 45;      // alpha ramp: 0 below R0
const R1 = 110;     // alpha ramp: 1 above R1
const DIST = (a, b) => Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[2] - b[2]);

function removeBackground(w, h, data) {
  const n = w * h;
  // bgField: local bg colour per pixel (-1 = not reached by fill)
  const bg = new Float32Array(n * 3).fill(-1);
  const fillD = new Float32Array(n);   // distance at fill time
  const queue = new Int32Array(n);
  let head = 0, tail = 0;
  const seed = (x, y) => {
    const i = y * w + x, j = i * 3;
    if (bg[j] >= 0) return;
    bg[j] = data[j]; bg[j + 1] = data[j + 1]; bg[j + 2] = data[j + 2];
    fillD[i] = 0;
    queue[tail++] = i;
  };
  for (let x = 0; x < w; x++) { seed(x, 0); seed(x, h - 1); }
  for (let y = 0; y < h; y++) { seed(0, y); seed(w - 1, y); }
  const nb = (i) => { const x = i % w, y = (i / w) | 0; const r = []; if (x > 0) r.push(i - 1); if (x < w - 1) r.push(i + 1); if (y > 0) r.push(i - w); if (y < h - 1) r.push(i + w); return r; };
  while (head < tail) {
    const i = queue[head++];
    const j = i * 3;
    const bgr = bg[j], bgg = bg[j + 1], bgb = bg[j + 2];
    for (const k of nb(i)) {
      if (bg[k * 3] >= 0) continue;
      const kk = k * 3;
      const d = Math.abs(data[kk] - bgr) + Math.abs(data[kk + 1] - bgg) + Math.abs(data[kk + 2] - bgb);
      if (d < TOL) {
        bg[kk] = data[kk]; bg[kk + 1] = data[kk + 1]; bg[kk + 2] = data[kk + 2];
        fillD[k] = d;
        queue[tail++] = k;
      }
    }
  }
  const filled = tail;
  // build alpha + un-bleed
  const alpha = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    if (bg[i * 3] < 0) { alpha[i] = 1; continue; }   // object interior
    let a = (fillD[i] - R0) / (R1 - R0);
    if (a <= 0) { alpha[i] = 0; continue; }
    if (a > 1) a = 1;
    alpha[i] = a;
    // un-bleed: recover fg colour from the blend with the local bg colour
    const j = i * 3, d = i * 4;
    const inv = 1 - a;
    const fg = (c, b) => Math.max(0, Math.min(255, Math.round((c - inv * b) / a)));
    data[d] = fg(data[d], bg[j]);
    data[d + 1] = fg(data[d + 1], bg[j + 1]);
    data[d + 2] = fg(data[d + 2], bg[j + 2]);
  }
  // speckle cleanup: drop tiny isolated alpha blobs (bg noise)
  const mask = new Uint8Array(n);
  for (let i = 0; i < n; i++) mask[i] = alpha[i] > 0.15 ? 1 : 0;
  const seen = new Uint8Array(n);
  const comp = new Int32Array(n);
  for (let i = 0; i < n; i++) {
    if (!mask[i] || seen[i]) continue;
    let cs = 0;
    comp[cs++] = i; seen[i] = 1;
    for (let p = 0; p < cs; p++) {
      const c = comp[p];
      for (const k of nb(c)) if (mask[k] && !seen[k]) { seen[k] = 1; comp[cs++] = k; }
    }
    if (cs < 5) for (let p = 0; p < cs; p++) alpha[comp[p]] = 0;
  }
  return { alpha, filled, total: n };
}

// ---------- crop ----------
function cropToContent(w, h, data, alpha, pad) {
  let x0 = w, y0 = h, x1 = -1, y1 = -1;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (alpha[y * w + x] > 0.05) {
      if (x < x0) x0 = x; if (x > x1) x1 = x;
      if (y < y0) y0 = y; if (y > y1) y1 = y;
    }
  }
  x0 = Math.max(0, x0 - pad); y0 = Math.max(0, y0 - pad);
  x1 = Math.min(w - 1, x1 + pad); y1 = Math.min(h - 1, y1 + pad);
  const cw = x1 - x0 + 1, chh = y1 - y0 + 1;
  const out = Buffer.alloc(cw * chh * 4);
  const outA = new Float32Array(cw * chh);
  for (let y = 0; y < chh; y++) for (let x = 0; x < cw; x++) {
    const s = ((y0 + y) * w + (x0 + x)) * 4, d = (y * cw + x) * 4;
    out[d] = data[s]; out[d + 1] = data[s + 1]; out[d + 2] = data[s + 2]; out[d + 3] = data[s + 3];
    outA[y * cw + x] = alpha[(y0 + y) * w + (x0 + x)];
  }
  return { w: cw, h: chh, data: out, alpha: outA };
}

// ---------- premultiplied area-average resize ----------
function scaleToFit(src, sw, sh, fit) {
  const s = Math.min(fit / sw, fit / sh);
  const dw = Math.max(1, Math.round(sw * s)), dh = Math.max(1, Math.round(sh * s));
  const sx = sw / dw, sy = sh / dh;
  const out = Buffer.alloc(dw * dh * 4);
  for (let oy = 0; oy < dh; oy++) {
    const y0 = oy * sy, y1 = Math.min(sh, (oy + 1) * sy);
    const iy0 = Math.floor(y0), iy1 = Math.ceil(y1);
    for (let ox = 0; ox < dw; ox++) {
      const x0 = ox * sx, x1 = Math.min(sw, (ox + 1) * sx);
      const ix0 = Math.floor(x0), ix1 = Math.ceil(x1);
      let rs = 0, gs = 0, bs = 0, as = 0;
      for (let y = iy0; y < iy1; y++) {
        const wy = Math.max(0, Math.min(y + 1, y1) - Math.max(y, y0));
        for (let x = ix0; x < ix1; x++) {
          const wx = Math.max(0, Math.min(x + 1, x1) - Math.max(x, x0));
          const i = (y * sw + x) * 4;
          const a = src[i + 3] / 255;
          const wgt = wx * wy;
          rs += src[i] * a * wgt; gs += src[i + 1] * a * wgt; bs += src[i + 2] * a * wgt; as += a * wgt;
        }
      }
      const o = (oy * dw + ox) * 4;
      if (as > 0) {
        out[o] = Math.round(rs / as); out[o + 1] = Math.round(gs / as); out[o + 2] = Math.round(bs / as);
      }
      out[o + 3] = Math.round((as / (sx * sy)) * 255);
    }
  }
  return { w: dw, h: dh, data: out };
}

// ---------- main ----------
function processFile(name) {
  const src = path.join(texDir, name + ".png");
  if (!fs.existsSync(src)) { console.log("skip (missing):", name); return; }
  fs.mkdirSync(backupDir, { recursive: true });
  const bak = path.join(backupDir, name + ".png");
  if (!fs.existsSync(bak)) { fs.copyFileSync(src, bak); console.log("backup ->", path.relative(root, bak)); }

  const img = decodePNG(src);
  console.log("== " + name + ": " + img.w + "x" + img.h);

  const { alpha, filled, total } = removeBackground(img.w, img.h, img.data);
  console.log("   bg fill: " + Math.round((filled / total) * 100) + "% of frame");

  const crop = cropToContent(img.w, img.h, img.data, alpha, 8);
  const scaled = scaleToFit(crop.data, crop.w, crop.h, FIT);

  // center on the target canvas
  const canvas = Buffer.alloc(TARGET * TARGET * 4);
  const ox = Math.floor((TARGET - scaled.w) / 2), oy = Math.floor((TARGET - scaled.h) / 2);
  for (let y = 0; y < scaled.h; y++) scaled.data.copy(canvas, ((oy + y) * TARGET + ox) * 4, y * scaled.w * 4, (y + 1) * scaled.w * 4);

  fs.writeFileSync(src, encodePNG(TARGET, TARGET, canvas));
  console.log("   wrote " + path.relative(root, src) + " (" + crop.w + "x" + crop.h + " content -> " + scaled.w + "x" + scaled.h + ")");

  // verify
  const chk = decodePNG(src);
  const corners = [0, (chk.w - 1) * 4, (chk.h - 1) * chk.w * 4, (chk.w * chk.h - 1) * 4];
  const cornerAlpha = corners.map((i) => chk.data[i + 3]);
  let op = 0, top = 0;
  for (let i = 3; i < chk.data.length; i += 4) { if (chk.data[i] > 10) op++; }
  for (let i = 3; i < chk.w * 4; i += 4) if (chk.data[i] > 10) top++;
  console.log("   verify: " + chk.w + "x" + chk.h + " RGBA, opaque " + Math.round((op / (chk.w * chk.h)) * 100) + "%, corner alpha " + cornerAlpha.join(","));
}

const targets = process.argv.slice(2);
const files = targets.length
  ? targets
  : ["Item_RemoteDoorOpener", "Item_AutoDoorMotor", "Item_AutoDoorMagazine"];
for (const f of files) processFile(f);
console.log("done.");
