// AutoDoor mod asset generator.
// Generates item icons and the poster.png without any external dependency
// (pure Node + zlib). Run: node tools/gen_icons.js
"use strict";
const zlib = require("zlib");
const fs = require("fs");
const path = require("path");

// ---------- minimal PNG encoder (RGBA) ----------
const CRC_TABLE = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const t = Buffer.from(type, "ascii");
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, data])));
  return Buffer.concat([len, t, data, crc]);
}

function encodePNG(w, h, rgba) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  const stride = w * 4 + 1;
  const raw = Buffer.alloc(stride * h);
  for (let y = 0; y < h; y++) {
    raw[y * stride] = 0; // filter: none
    rgba.copy(raw, y * stride + 1, y * w * 4, (y + 1) * w * 4);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([sig, chunk("IHDR", ihdr), chunk("IDAT", idat), chunk("IEND", Buffer.alloc(0))]);
}

// ---------- tiny raster helpers ----------
function canvas(w, h) {
  return { w, h, data: Buffer.alloc(w * h * 4) };
}
function setPx(c, x, y, r, g, b, a = 255) {
  if (x < 0 || y < 0 || x >= c.w || y >= c.h) return;
  const i = (y * c.w + x) * 4;
  c.data[i] = r;
  c.data[i + 1] = g;
  c.data[i + 2] = b;
  c.data[i + 3] = a;
}
function blendPx(c, x, y, r, g, b, a) {
  if (x < 0 || y < 0 || x >= c.w || y >= c.h || a <= 0) return;
  const i = (y * c.w + x) * 4;
  if (a >= 255 || c.data[i + 3] === 0) {
    c.data[i] = r; c.data[i + 1] = g; c.data[i + 2] = b; c.data[i + 3] = a;
    return;
  }
  const da = c.data[i + 3] / 255;
  const sa = a / 255;
  const oa = sa + da * (1 - sa);
  c.data[i] = Math.round((r * sa + c.data[i] * da * (1 - sa)) / oa);
  c.data[i + 1] = Math.round((g * sa + c.data[i + 1] * da * (1 - sa)) / oa);
  c.data[i + 2] = Math.round((b * sa + c.data[i + 2] * da * (1 - sa)) / oa);
  c.data[i + 3] = Math.round(oa * 255);
}
function fillRect(c, x0, y0, x1, y1, col) {
  for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) blendPx(c, x, y, col[0], col[1], col[2], col[3]);
}
function fillCircle(c, cx, cy, rad, col) {
  const r2 = rad * rad;
  for (let y = cy - rad; y <= cy + rad; y++)
    for (let x = cx - rad; x <= cx + rad; x++) {
      const dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r2) blendPx(c, x, y, col[0], col[1], col[2], col[3]);
    }
}
function fillRoundRect(c, x0, y0, x1, y1, rad, col) {
  fillRect(c, x0 + rad, y0, x1 - rad, y1, col);
  fillRect(c, x0, y0 + rad, x1, y1 - rad, col);
  fillCircle(c, x0 + rad, y0 + rad, rad, col);
  fillCircle(c, x1 - rad, y0 + rad, rad, col);
  fillCircle(c, x0 + rad, y1 - rad, rad, col);
  fillCircle(c, x1 - rad, y1 - rad, rad, col);
}
function ring(c, cx, cy, outR, inR, col) {
  for (let y = cy - outR; y <= cy + outR; y++)
    for (let x = cx - outR; x <= cx + outR; x++) {
      const d2 = (x - cx) * (x - cx) + (y - cy) * (y - cy);
      if (d2 <= outR * outR && d2 >= inR * inR) blendPx(c, x, y, col[0], col[1], col[2], col[3]);
    }
}
function writePNG(c, file) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, encodePNG(c.w, c.h, c.data));
  console.log("wrote", file, c.w + "x" + c.h);
}

// ---------- palette ----------
const BODY = [56, 58, 62, 255];       // dark grey remote body
const BODY_LIGHT = [84, 88, 94, 255];
const BODY_DARK = [28, 30, 34, 255];
const RED = [208, 52, 44, 255];
const BLUE = [44, 111, 208, 255];
const YELLOW = [208, 160, 44, 255];
const GREEN = [44, 208, 111, 255];
const SCREEN = [16, 18, 22, 255];
const GOLD = [208, 160, 44, 255];
const GOLD_LIGHT = [240, 200, 110, 255];
const GOLD_DARK = [120, 92, 24, 255];
const BG = [28, 31, 36, 255];
const PANEL = [196, 198, 202, 255];
const PANEL_DARK = [120, 124, 132, 255];

// ---------- remote control icon (128x128) ----------
function drawRemote(c, ox, oy, s) {
  const w = Math.round(72 * s), h = Math.round(88 * s);
  const x0 = ox - w / 2, y0 = oy - h / 2, x1 = x0 + w, y1 = y0 + h;
  const r = Math.round(10 * s);
  // body
  fillRoundRect(c, x0, y0, x1, y1, r, BODY);
  // top highlight
  fillRoundRect(c, x0 + Math.round(3 * s), y0 + Math.round(2 * s), x1 - Math.round(3 * s), y0 + Math.round(14 * s), Math.round(5 * s), BODY_LIGHT);
  // screen
  fillRoundRect(c, x0 + Math.round(10 * s), y0 + Math.round(10 * s), x1 - Math.round(10 * s), y0 + Math.round(22 * s), Math.round(3 * s), SCREEN);
  // buttons
  fillCircle(c, x0 + Math.round(20 * s), y0 + Math.round(38 * s), Math.round(7 * s), RED);
  fillCircle(c, x1 - Math.round(20 * s), y0 + Math.round(38 * s), Math.round(7 * s), BLUE);
  fillCircle(c, x0 + w / 2, y0 + Math.round(56 * s), Math.round(9 * s), YELLOW);
  // led
  fillCircle(c, x0 + w / 2, y0 + Math.round(76 * s), Math.round(3.5 * s), GREEN);
}

// ---------- poster (512x256) ----------
function drawPoster() {
  const c = canvas(512, 256);
  fillRect(c, 0, 0, 511, 255, BG);
  // ground
  fillRect(c, 0, 200, 511, 255, [20, 22, 26, 255]);
  // garage door silhouette behind (left)
  fillRoundRect(c, 40, 40, 170, 200, 6, [46, 50, 56, 255]);
  for (let i = 0; i < 4; i++) {
    const y0 = 52 + i * 34;
    fillRect(c, 48, y0, 162, y0 + 18, [36, 40, 46, 255]);
  }
  // fence gate silhouette behind (right)
  fillRect(c, 330, 52, 336, 200, [46, 50, 56, 255]);
  fillRect(c, 480, 52, 486, 200, [46, 50, 56, 255]);
  fillRect(c, 336, 70, 480, 76, [46, 50, 56, 255]);
  fillRect(c, 336, 120, 480, 126, [46, 50, 56, 255]);
  for (let y = 76; y < 120; y += 6)
    for (let x = 342; x < 474; x += 8) setPx(c, x, y, 46, 50, 56, 255);
  // big remote in the middle
  drawRemote(c, 256, 130, 2.4);
  // signal waves
  const waveCol = [120, 124, 132, 200];
  for (const [cx, cy, r] of [[256, 84, 12], [256, 84, 22], [256, 84, 32]]) {
    for (let a = -60; a <= 60; a++) {
      const rad = (a * Math.PI) / 180;
      const x = Math.round(cx + r * Math.cos(rad));
      const y = Math.round(cy - r * Math.sin(rad));
      setPx(c, x, y, waveCol[0], waveCol[1], waveCol[2], 200);
    }
  }
  return c;
}

// ---------- auto door motor icon (128x128): receiver+motor box with
// an antenna and a battery slot ----------
function drawMotor(c) {
  // body (dark electronics box)
  fillRoundRect(c, 20, 28, 108, 104, 6, BODY_DARK);
  fillRoundRect(c, 26, 34, 102, 98, 4, BODY);
  // antenna
  fillRect(c, 78, 6, 82, 30, PANEL_DARK);
  fillCircle(c, 80, 10, 5, RED);
  // receiver window / status screen
  fillRoundRect(c, 34, 42, 94, 58, 3, SCREEN);
  // battery slot (bottom)
  fillRoundRect(c, 40, 70, 88, 88, 3, BODY_LIGHT);
  fillRect(c, 46, 76, 82, 82, SCREEN);
  fillRect(c, 46, 76, 52, 82, GREEN);
  fillRect(c, 76, 76, 82, 82, GREEN);
  // motor hint: small gear (simple circle + spokes)
  fillCircle(c, 64, 96, 5, PANEL_DARK);
  fillRect(c, 60, 90, 62, 102, PANEL_DARK);
  fillRect(c, 66, 90, 68, 102, PANEL_DARK);
}

// ---------- auto door magazine icon (128x128): a magazine/book with a
// small remote drawing on the cover ----------
function drawMagazine(c) {
  // cover
  fillRoundRect(c, 24, 16, 104, 112, 4, [40, 44, 52, 255]);
  // spine highlight
  fillRect(c, 28, 20, 32, 108, [64, 70, 80, 255]);
  // title bar
  fillRect(c, 40, 26, 96, 36, PANEL_DARK);
  // title text hint (3 dashes)
  fillRect(c, 44, 30, 92, 32, BODY_DARK);
  // small remote drawing on the cover
  drawRemote(c, 64, 74, 0.55);
  // signal waves
  const waveCol = [120, 124, 132, 255];
  for (const [cx, cy, r] of [[64, 60, 6], [64, 60, 10]]) {
    for (let a = -50; a <= 50; a++) {
      const rad = (a * Math.PI) / 180;
      setPx(c, Math.round(cx + r * Math.cos(rad)), Math.round(cy - r * Math.sin(rad)), waveCol[0], waveCol[1], waveCol[2], 255);
    }
  }
}

// ---------- main ----------
const root = path.join(__dirname, "..");
const texDir = path.join(root, "42", "media", "textures");

const remoteIcon = canvas(128, 128);
drawRemote(remoteIcon, 64, 64, 1);
writePNG(remoteIcon, path.join(texDir, "Item_RemoteDoorOpener.png"));

const motorIcon = canvas(128, 128);
drawMotor(motorIcon);
writePNG(motorIcon, path.join(texDir, "Item_AutoDoorMotor.png"));

const magazineIcon = canvas(128, 128);
drawMagazine(magazineIcon);
writePNG(magazineIcon, path.join(texDir, "Item_AutoDoorMagazine.png"));

writePNG(drawPoster(), path.join(root, "poster.png"));
