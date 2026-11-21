// Does each tap target on the island map actually cover its badge?
//
// The island map is a painting with four medallions drawn into it: a flat cyan
// disc, a heavy black ring, a picture in the middle. To a child who navigates
// entirely by picture, the medallion *is* the button - it is the only thing on
// the screen shaped like one.
//
// The tap regions were authored against the scenery instead. Foundry got the
// upper-left mountains, Portals got the peaks, and every one of the four
// targets ended up sitting above its own badge:
//
//   portals     0% of the medallion inside its tap region
//   foundry     a sliver at the very top
//   sanctuary   the top quarter
//   home        about half
//
// So on the first screen of the game she pressed the middle of a big round
// button with a house on it and nothing happened, three times in four. It is
// invisible from the code - the rectangles look like perfectly reasonable
// numbers - and invisible from a screenshot unless you draw the hit boxes over
// it, which is how it was actually found.
//
// The rectangles are measured out of the PNG now. This re-measures and checks
// them, so replacing the placeholder art (which is the plan) fails loudly here
// rather than quietly on the first screen a child sees.
//
//   node tools/scripts/check-map-regions.mjs
//
// It reads the rects straight out of home_map_screen.dart with a regex, which
// is a real coupling and worth stating: keep the `id:` and `rect:` lines of a
// MapRegion adjacent and in that order, or this stops seeing them.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { decodePng } from '../artgen/png.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const SCREEN = join(ROOT, 'app', 'lib', 'ui', 'screens', 'home_map_screen.dart');
const ART = join(ROOT, 'app', 'assets', 'maps', 'home_screen_map.png');

/** The medallion disc fill: a flat vector cyan, uniform to within a few LSBs. */
const FILL = [41, 189, 206];
const FILL_TOL = 7;

/** Smallest disc we will believe, in pixels. */
const MIN_AREA = 1500;
const MIN_SIDE = 60;

function medallions() {
  const img = decodePng(readFileSync(ART));
  const { width: W, height: H, data } = img;
  // The painted ocean behind the badges is a close cyan - close enough that a
  // loose match floods straight out of the disc and swallows half the sea.
  // The discs are flat fills and the ocean never is, so match tightly.
  const hit = (i) =>
    data[i + 3] > 200 &&
    Math.abs(data[i] - FILL[0]) < FILL_TOL &&
    Math.abs(data[i + 1] - FILL[1]) < FILL_TOL &&
    Math.abs(data[i + 2] - FILL[2]) < FILL_TOL;

  const seen = new Uint8Array(W * H);
  const found = [];
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const p = y * W + x;
      if (seen[p] || !hit(p * 4)) continue;
      let minX = x;
      let maxX = x;
      let minY = y;
      let maxY = y;
      let n = 0;
      const stack = [p];
      seen[p] = 1;
      while (stack.length) {
        const q = stack.pop();
        const qx = q % W;
        const qy = (q / W) | 0;
        n++;
        if (qx < minX) minX = qx;
        if (qx > maxX) maxX = qx;
        if (qy < minY) minY = qy;
        if (qy > maxY) maxY = qy;
        for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          const nx = qx + dx;
          const ny = qy + dy;
          if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue;
          const r = ny * W + nx;
          if (seen[r] || !hit(r * 4)) continue;
          seen[r] = 1;
          stack.push(r);
        }
      }
      const w = maxX - minX + 1;
      const h = maxY - minY + 1;
      // Round and big. The ratio test drops slivers of matching colour that
      // happen to appear in the painting.
      if (
        n > MIN_AREA &&
        w > MIN_SIDE &&
        h > MIN_SIDE &&
        Math.abs(w - h) < Math.max(w, h) * 0.45
      ) {
        found.push({
          cx: (minX + maxX) / 2 / W,
          cy: (minY + maxY) / 2 / H,
          // Width is the honest diameter: a badge's icon can eat into the
          // fill vertically (the factory does) but never horizontally.
          d: w / W,
        });
      }
    }
  }
  return found;
}

function declaredRegions() {
  const src = readFileSync(SCREEN, 'utf8');
  const out = [];
  const re =
    /id:\s*'([a-z-]+)',[\s\S]{0,400}?Rect\.fromLTWH\(\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),?\s*\)/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    out.push({
      id: m[1],
      l: Number(m[2]),
      t: Number(m[3]),
      w: Number(m[4]),
      h: Number(m[5]),
    });
  }
  return out;
}

const discs = medallions();
const regions = declaredRegions();
const problems = [];

if (discs.length !== regions.length) {
  problems.push(
    `the art has ${discs.length} medallions and the screen declares ` +
      `${regions.length} regions`
  );
}

for (const r of regions) {
  const rcx = r.l + r.w / 2;
  const rcy = r.t + r.h / 2;
  // Nearest badge, then check it is genuinely covered rather than merely
  // nearest - "nearest" is true even when the region is nowhere near it.
  let best = null;
  let bestDist = Infinity;
  for (const d of discs) {
    const dist = Math.hypot(d.cx - rcx, d.cy - rcy);
    if (dist < bestDist) {
      bestDist = dist;
      best = d;
    }
  }
  if (!best) {
    problems.push(`${r.id}: no medallion in the art at all`);
    continue;
  }
  // The badge must sit inside the tap region, with its ring.
  const half = best.d / 2;
  const inside =
    best.cx - half >= r.l - 1e-6 &&
    best.cx + half <= r.l + r.w + 1e-6 &&
    best.cy - half * (r.w / r.h) >= r.t - 1e-6 &&
    best.cy + half * (r.w / r.h) <= r.t + r.h + 1e-6;
  if (!inside) {
    problems.push(
      `${r.id}: the badge at (${best.cx.toFixed(3)}, ${best.cy.toFixed(3)}) ` +
        `d=${best.d.toFixed(3)} is not inside ` +
        `Rect.fromLTWH(${r.l}, ${r.t}, ${r.w}, ${r.h})`
    );
    continue;
  }
  // And the region must not be so much larger than the badge that it is
  // really a rectangle of scenery with a badge somewhere in it.
  if (r.w > best.d * 2.0 || r.h > best.d * 2.6) {
    problems.push(
      `${r.id}: tap region ${r.w.toFixed(3)}x${r.h.toFixed(3)} dwarfs its ` +
        `${best.d.toFixed(3)}-wide badge - it is scenery, not a button`
    );
  }
}

for (const r of regions) {
  const rcx = (r.l + r.w / 2).toFixed(3);
  const rcy = (r.t + r.h / 2).toFixed(3);
  console.log(`  ${r.id.padEnd(18)} centre ${rcx}, ${rcy}`);
}
console.log('');

if (problems.length) {
  console.error('Map tap targets do not match the art:\n');
  for (const p of problems) console.error(`  - ${p}`);
  console.error(
    '\nRe-measure: the medallion centres and diameters printed by this ' +
      'script are normalized to the image, so a region is\n' +
      '  Rect.fromLTWH(cx - d/2 - m, cy - d*(W/H)/2 - m, d + 2m, d*(W/H) + 2m)\n' +
      'for a small margin m.\n'
  );
  process.exit(1);
}

console.log(
  `All ${regions.length} island tap targets cover their medallion. ✓`
);
