// Minimal PNG codec plus the image ops the art pipeline needs.
//
// Dependency-free on purpose. `sharp` and `jimp` both mean a native build or a
// multi-megabyte install in a repo whose only other tooling dependency is ajv,
// and everything here is a handful of loops over an RGBA byte array. Node's
// zlib does the compression, which is the only genuinely hard part of PNG.
//
// Scope: 8-bit non-interlaced PNG, colour types 0/2/4/6, decoded to RGBA and
// always re-encoded as RGBA. That covers every asset in app/assets (all six
// sampled are RGBA8) and everything an image model returns. Anything else
// throws by name rather than producing quietly wrong pixels.

import zlib from 'node:zlib';

const SIG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

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
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

/** An image: width, height, and `data` as RGBA8, row-major, length w*h*4. */
export class Img {
  constructor(width, height, data) {
    this.width = width;
    this.height = height;
    this.data = data ?? Buffer.alloc(width * height * 4);
  }

  static blank(width, height, [r, g, b, a] = [0, 0, 0, 0]) {
    const img = new Img(width, height);
    for (let i = 0; i < img.data.length; i += 4) {
      img.data[i] = r;
      img.data[i + 1] = g;
      img.data[i + 2] = b;
      img.data[i + 3] = a;
    }
    return img;
  }
}

// ---------------------------------------------------------------- decode

export function decodePng(buf) {
  if (!buf.subarray(0, 8).equals(SIG)) throw new Error('not a PNG (bad signature)');

  let pos = 8;
  let ihdr = null;
  let palette = null;
  let trns = null;
  const idat = [];

  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const body = buf.subarray(pos + 8, pos + 8 + len);
    pos += 12 + len; // length + type + data + crc

    if (type === 'IHDR') {
      ihdr = {
        width: body.readUInt32BE(0),
        height: body.readUInt32BE(4),
        bitDepth: body[8],
        colorType: body[9],
        interlace: body[12],
      };
    } else if (type === 'PLTE') palette = Buffer.from(body);
    else if (type === 'tRNS') trns = Buffer.from(body);
    else if (type === 'IDAT') idat.push(body);
    else if (type === 'IEND') break;
  }

  if (!ihdr) throw new Error('PNG has no IHDR');
  const { width, height, bitDepth, colorType, interlace } = ihdr;
  if (interlace !== 0) throw new Error('interlaced PNG not supported');
  if (bitDepth !== 8) throw new Error(`unsupported bit depth ${bitDepth} (need 8)`);

  const channels = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[colorType];
  if (channels === undefined) throw new Error(`unsupported colour type ${colorType}`);
  if (colorType === 3 && !palette) throw new Error('palette PNG with no PLTE');

  const raw = zlib.inflateSync(Buffer.concat(idat));
  const bpp = channels; // bitDepth is 8, so bytes per pixel === channels
  const stride = width * bpp;
  const out = Buffer.alloc(height * stride);

  // Undo the per-scanline filter. Each row is prefixed with one filter byte.
  let ip = 0;
  for (let y = 0; y < height; y++) {
    const filter = raw[ip++];
    const row = out.subarray(y * stride, (y + 1) * stride);
    const prev = y > 0 ? out.subarray((y - 1) * stride, y * stride) : null;
    for (let x = 0; x < stride; x++) {
      const rawByte = raw[ip++];
      const a = x >= bpp ? row[x - bpp] : 0;
      const b = prev ? prev[x] : 0;
      const c = prev && x >= bpp ? prev[x - bpp] : 0;
      let v;
      switch (filter) {
        case 0: v = rawByte; break;
        case 1: v = rawByte + a; break;
        case 2: v = rawByte + b; break;
        case 3: v = rawByte + ((a + b) >> 1); break;
        case 4: {
          const p = a + b - c;
          const pa = Math.abs(p - a);
          const pb = Math.abs(p - b);
          const pc = Math.abs(p - c);
          v = rawByte + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c);
          break;
        }
        default: throw new Error(`unknown PNG filter ${filter} on row ${y}`);
      }
      row[x] = v & 0xff;
    }
  }

  // Expand whatever we decoded into RGBA.
  const rgba = Buffer.alloc(width * height * 4);
  for (let i = 0, n = width * height; i < n; i++) {
    const s = i * bpp;
    const d = i * 4;
    if (colorType === 6) {
      out.copy(rgba, d, s, s + 4);
    } else if (colorType === 2) {
      rgba[d] = out[s]; rgba[d + 1] = out[s + 1]; rgba[d + 2] = out[s + 2]; rgba[d + 3] = 255;
    } else if (colorType === 0) {
      rgba[d] = rgba[d + 1] = rgba[d + 2] = out[s]; rgba[d + 3] = 255;
    } else if (colorType === 4) {
      rgba[d] = rgba[d + 1] = rgba[d + 2] = out[s]; rgba[d + 3] = out[s + 1];
    } else {
      const pi = out[s] * 3;
      rgba[d] = palette[pi]; rgba[d + 1] = palette[pi + 1]; rgba[d + 2] = palette[pi + 2];
      rgba[d + 3] = trns && out[s] < trns.length ? trns[out[s]] : 255;
    }
  }

  return new Img(width, height, rgba);
}

// ---------------------------------------------------------------- encode

function chunk(type, body) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(body.length);
  const typed = Buffer.concat([Buffer.from(type, 'ascii'), body]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(typed));
  return Buffer.concat([len, typed, crc]);
}

export function encodePng(img) {
  const { width, height, data } = img;
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // RGBA
  ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0; // deflate / adaptive / no interlace

  // Filter type 0 (None) on every row. Costs some size against an adaptive
  // filter, but these are small sprites and the simplicity is worth more.
  const stride = width * 4;
  const raw = Buffer.alloc(height * (stride + 1));
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0;
    data.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }

  return Buffer.concat([
    SIG,
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// ---------------------------------------------------------------- ops

/**
 * Bounding box of pixels with alpha above [threshold], as {x, y, w, h}.
 * Returns null for a fully transparent image.
 */
export function alphaBounds(img, threshold = 8) {
  const { width, height, data } = img;
  let minX = width, minY = height, maxX = -1, maxY = -1;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (data[(y * width + x) * 4 + 3] > threshold) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < 0) return null;
  return { x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1 };
}

/**
 * Bounding box of the actual subject, ignoring isolated specks.
 *
 * `alphaBounds` is literal: one stray semi-opaque pixel in a corner drags the
 * box out to meet it. Models leave those behind constantly - a faint mark, a
 * ghost of a removed background - and the consequence is not cosmetic. The box
 * feeds `reframeTo`, so a speck 200px from the subject halves the size the
 * sprite renders at, which is exactly how a small-o mouth ended up a dot.
 *
 * Rows and columns holding less than [minCoverage] of the busiest row/column's
 * opaque pixels are treated as empty. That removes specks without any
 * connected-component machinery, and it cannot eat the subject, whose rows are
 * dense by construction.
 */
export function contentBounds(img, { threshold = 8, minCoverage = 0.02 } = {}) {
  const { width, height, data } = img;
  const rows = new Int32Array(height);
  const cols = new Int32Array(width);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (data[(y * width + x) * 4 + 3] > threshold) {
        rows[y]++;
        cols[x]++;
      }
    }
  }

  const rowFloor = Math.max(1, Math.max(...rows) * minCoverage);
  const colFloor = Math.max(1, Math.max(...cols) * minCoverage);

  let top = 0; while (top < height && rows[top] < rowFloor) top++;
  let bottom = height - 1; while (bottom > top && rows[bottom] < rowFloor) bottom--;
  let left = 0; while (left < width && cols[left] < colFloor) left++;
  let right = width - 1; while (right > left && cols[right] < colFloor) right--;

  if (bottom < top || right < left) return null;
  return { x: left, y: top, w: right - left + 1, h: bottom - top + 1 };
}

/**
 * Bilinear resample to [w]x[h].
 *
 * Alpha is premultiplied before sampling and divided back out after. Without
 * that, a transparent pixel's RGB (which is arbitrary — often black) bleeds
 * into its opaque neighbours and every sprite picks up a dark fringe.
 */
export function resize(img, w, h) {
  const out = new Img(w, h);
  const { width: sw, height: sh, data: sd } = img;
  const sx = sw / w;
  const sy = sh / h;

  for (let y = 0; y < h; y++) {
    const fy = Math.min(sh - 1, Math.max(0, (y + 0.5) * sy - 0.5));
    const y0 = Math.floor(fy);
    const y1 = Math.min(sh - 1, y0 + 1);
    const wy = fy - y0;

    for (let x = 0; x < w; x++) {
      const fx = Math.min(sw - 1, Math.max(0, (x + 0.5) * sx - 0.5));
      const x0 = Math.floor(fx);
      const x1 = Math.min(sw - 1, x0 + 1);
      const wx = fx - x0;

      let r = 0, g = 0, b = 0, a = 0;
      for (const [px, py, weight] of [
        [x0, y0, (1 - wx) * (1 - wy)],
        [x1, y0, wx * (1 - wy)],
        [x0, y1, (1 - wx) * wy],
        [x1, y1, wx * wy],
      ]) {
        const s = (py * sw + px) * 4;
        const sa = sd[s + 3] / 255;
        r += sd[s] * sa * weight;
        g += sd[s + 1] * sa * weight;
        b += sd[s + 2] * sa * weight;
        a += sa * weight;
      }

      const d = (y * w + x) * 4;
      if (a > 0.0001) {
        out.data[d] = Math.round(Math.min(255, r / a));
        out.data[d + 1] = Math.round(Math.min(255, g / a));
        out.data[d + 2] = Math.round(Math.min(255, b / a));
      }
      out.data[d + 3] = Math.round(Math.min(255, a * 255));
    }
  }
  return out;
}

/** Source-over composite of [src] onto [dst] at (dx, dy). Mutates dst. */
export function compose(dst, src, dx, dy) {
  for (let y = 0; y < src.height; y++) {
    const ty = dy + y;
    if (ty < 0 || ty >= dst.height) continue;
    for (let x = 0; x < src.width; x++) {
      const tx = dx + x;
      if (tx < 0 || tx >= dst.width) continue;
      const s = (y * src.width + x) * 4;
      const d = (ty * dst.width + tx) * 4;
      const sa = src.data[s + 3] / 255;
      if (sa <= 0) continue;
      const da = dst.data[d + 3] / 255;
      const oa = sa + da * (1 - sa);
      for (let c = 0; c < 3; c++) {
        dst.data[d + c] = Math.round(
          (src.data[s + c] * sa + dst.data[d + c] * da * (1 - sa)) / oa,
        );
      }
      dst.data[d + 3] = Math.round(oa * 255);
    }
  }
  return dst;
}

/**
 * Horizontal mirror.
 *
 * For paired sprites - Buddy's arms and legs - where the left is the right
 * seen from the other side. Generating the two separately produced two limbs
 * that disagreed about how many fingers Buddy has, which is worse than any
 * saving it buys; flipping is exact and free.
 */
export function mirrorX(img) {
  const out = new Img(img.width, img.height);
  for (let y = 0; y < img.height; y++) {
    for (let x = 0; x < img.width; x++) {
      const src = (y * img.width + x) * 4;
      const dst = (y * img.width + (img.width - 1 - x)) * 4;
      out.data[dst] = img.data[src];
      out.data[dst + 1] = img.data[src + 1];
      out.data[dst + 2] = img.data[src + 2];
      out.data[dst + 3] = img.data[src + 3];
    }
  }
  return out;
}

export function crop(img, { x, y, w, h }) {
  const out = new Img(w, h);
  for (let row = 0; row < h; row++) {
    const s = ((y + row) * img.width + x) * 4;
    img.data.copy(out.data, row * w * 4, s, s + w * 4);
  }
  return out;
}

/**
 * Knock a near-white background out to transparency.
 *
 * A safety net, not the primary path — gpt-image-1 can return real alpha when
 * asked for a transparent background. But a model that ignores the instruction
 * returns a white card, and a white card composited over the meadow is a
 * visible rectangle. Flood-fills inward from the border so white *inside* the
 * subject (teeth, eyes, highlights) survives.
 */
export function knockOutBackground(img, tolerance = 18) {
  const { width, height, data } = img;
  const seen = new Uint8Array(width * height);
  const stack = [];

  const isBg = (i) => {
    const p = i * 4;
    return (
      data[p + 3] > 8 &&
      data[p] >= 255 - tolerance &&
      data[p + 1] >= 255 - tolerance &&
      data[p + 2] >= 255 - tolerance
    );
  };

  for (let x = 0; x < width; x++) {
    stack.push(x, (height - 1) * width + x);
  }
  for (let y = 0; y < height; y++) {
    stack.push(y * width, y * width + width - 1);
  }

  while (stack.length) {
    const i = stack.pop();
    if (seen[i] || !isBg(i)) continue;
    seen[i] = 1;
    data[i * 4 + 3] = 0;
    const x = i % width;
    const y = (i / width) | 0;
    if (x > 0) stack.push(i - 1);
    if (x < width - 1) stack.push(i + 1);
    if (y > 0) stack.push(i - width);
    if (y < height - 1) stack.push(i + width);
  }
  return img;
}

/**
 * Pull pure-black linework toward the warm near-black the art direction
 * mandates (`specs/shared/art-direction.md`: "Never pure black — darkest line
 * colour is #2A1F26"). Only touches pixels already darker than [ceiling], so
 * it recolours outlines without tinting shadows.
 */
export function softenBlacks(img, ceiling = 40, target = [0x2a, 0x1f, 0x26]) {
  const { data } = img;
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] === 0) continue;
    const lum = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    if (lum >= ceiling) continue;
    // Fully black goes all the way to target; near-ceiling barely moves.
    const t = 1 - lum / ceiling;
    for (let c = 0; c < 3; c++) {
      data[i + c] = Math.round(data[i + c] * (1 - t) + target[c] * t);
    }
  }
  return img;
}

/**
 * Kill a soft drop shadow or outer glow without destroying edge antialiasing.
 *
 * Image models like to add a shadow even when told not to, and it arrives as a
 * wide band of low-alpha dark pixels. Composited over Buddy that reads as
 * grime around the mouth. Antialiasing is a 1-2px band, a glow is tens of
 * pixels, so a straight alpha cutoff removes the glow and costs only a sliver
 * of edge softness. Remaining alpha is rescaled so the edge does not gain a
 * hard step where the cutoff bit.
 */
export function hardenAlpha(img, cutoff = 56) {
  const { data } = img;
  for (let i = 3; i < data.length; i += 4) {
    const a = data[i];
    if (a === 0 || a === 255) continue;
    data[i] = a <= cutoff ? 0 : Math.round(((a - cutoff) / (255 - cutoff)) * 255);
  }
  return img;
}

/**
 * Re-frame [img] so its opaque content sits where a reference asset's content
 * sits.
 *
 * This is the whole reason the pipeline exists. Every Buddy layer renders with
 * `BoxFit.contain` inside a fixed fractional box (see `_frac` in
 * buddy_widget.dart), which means the *transparent margins* of the PNG decide
 * where the art lands and how big it looks. Two mouths drawn at different
 * scales inside their canvases render at different sizes on the same face.
 *
 * So: match the reference canvas exactly, put the content's centre where the
 * reference's centre is, and scale content width to [widthScale] of the
 * reference's content width. `widthScale` is per-asset because a small-o mouth
 * genuinely is narrower than a wide-open smile — the registration is enforced,
 * the proportion stays an art decision.
 */
export function reframeTo(img, reference, { widthScale = 1, threshold = 8, minCoverage = 0.02 } = {}) {
  const refBox = contentBounds(reference, { threshold, minCoverage });
  const srcBox = contentBounds(img, { threshold, minCoverage });
  if (!refBox) throw new Error('reference image is fully transparent');
  if (!srcBox) throw new Error('source image is fully transparent');

  const targetW = Math.max(1, Math.round(refBox.w * widthScale));
  const scale = targetW / srcBox.w;
  const targetH = Math.max(1, Math.round(srcBox.h * scale));

  const content = resize(crop(img, srcBox), targetW, targetH);
  const out = Img.blank(reference.width, reference.height);
  compose(
    out,
    content,
    Math.round(refBox.x + refBox.w / 2 - targetW / 2),
    Math.round(refBox.y + refBox.h / 2 - targetH / 2),
  );
  return out;
}

/**
 * Grid of images on a flat background, for eyeballing a batch together.
 *
 * Judging generated art one file at a time is the wrong unit — the failure
 * that matters is a set that doesn't cohere, and that is only visible side by
 * side. No labels: text rendering would mean a font dependency, so the caller
 * prints the reading order instead.
 */
export function contactSheet(images, { columns = 4, cell = 256, pad = 16, background = [0xfb, 0xf6, 0xe9, 0xff] } = {}) {
  const rows = Math.ceil(images.length / columns);
  const sheet = Img.blank(
    columns * cell + (columns + 1) * pad,
    rows * cell + (rows + 1) * pad,
    background,
  );

  images.forEach((img, i) => {
    const col = i % columns;
    const row = (i / columns) | 0;
    const scale = Math.min(cell / img.width, cell / img.height);
    const w = Math.max(1, Math.round(img.width * scale));
    const h = Math.max(1, Math.round(img.height * scale));
    compose(
      sheet,
      resize(img, w, h),
      pad + col * (cell + pad) + ((cell - w) >> 1),
      pad + row * (cell + pad) + ((cell - h) >> 1),
    );
  });

  return sheet;
}
