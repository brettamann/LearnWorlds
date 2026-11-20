// Art pipeline CLI.
//
//   node tools/artgen/artgen.mjs status              what exists, what is cached, what it cost
//   node tools/artgen/artgen.mjs gen [id...]         generate only what is missing (--force to redo)
//   node tools/artgen/artgen.mjs process [id...]     re-run local post-processing from cache, free
//   node tools/artgen/artgen.mjs sheet [id...]       contact sheet for review
//   node tools/artgen/artgen.mjs preview             mouths composited on Buddy, as the app renders them
//   node tools/artgen/artgen.mjs install [id...]     copy processed art into app/assets
//
// `gen` never regenerates a cached request, so re-running it is free and safe.
// Only `--force` spends money on something already in hand.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { loadEnv, configFromEnv, ImageGenClient } from './client.mjs';
import { Cache } from './cache.mjs';
import { ASSETS, assetById, resolveIds } from './catalog.mjs';
import {
  decodePng, encodePng, alphaBounds, reframeTo, hardenAlpha,
  knockOutBackground, softenBlacks, contactSheet, compose, resize, mirrorX, Img,
} from './png.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..');
const CACHE_DIR = path.join(HERE, 'cache');
const WORK_DIR = path.join(HERE, 'out');

const argv = process.argv.slice(2);
const command = argv[0] || 'status';
const flags = new Set(argv.filter((a) => a.startsWith('--')));
const ids = argv.slice(1).filter((a) => !a.startsWith('--'));

const cache = new Cache(CACHE_DIR);
fs.mkdirSync(WORK_DIR, { recursive: true });

const abs = (p) => path.join(ROOT, p);
const rel = (p) => path.relative(ROOT, p).replace(/\\/g, '/');

function refBytes(asset) {
  return asset.reference ? fs.readFileSync(abs(asset.reference)) : undefined;
}

function keyFor(asset, config) {
  return Cache.key({
    prompt: asset.prompt,
    provider: config.provider,
    effort: asset.effort ?? 'draft',
    aspect: asset.aspect ?? 'square',
    resolution: asset.resolution,
    referenceBytes: refBytes(asset),
    variant: asset.variant ?? 0,
  });
}

/**
 * Local, free, deterministic half of the pipeline.
 *
 * Kept separate from generation so prompts and framing can be tuned against
 * bytes already paid for. Order matters: knock out any background the model
 * left behind, kill the shadow it added, warm the linework, and only then
 * reframe — reframing measures the alpha bounding box, so it has to run after
 * everything that changes alpha.
 */
function process1(asset, sourceBytes) {
  let img = decodePng(sourceBytes);
  // `cutout: false` for the one kind of asset that is meant to be opaque edge
  // to edge - a background. The chain below exists to turn a drawn-on card
  // into a sprite: knockOutBackground floods inward from the border, which on
  // a painted sky eats the sky, and softenBlacks pulls linework that a
  // background does not have. Everything else in the catalog is a cutout, so
  // it stays the default.
  if (asset.cutout !== false) {
    img = knockOutBackground(img);
    img = hardenAlpha(img, asset.alphaCutoff ?? 56);
    if (asset.softenBlacks !== false) img = softenBlacks(img);
  }
  if (asset.reframe && asset.reference) {
    img = reframeTo(img, decodePng(fs.readFileSync(abs(asset.reference))), asset.reframe);
  }
  // Last, because everything above measures or edits pixels and is cheaper to
  // reason about at the generated size. The model always returns 1024x1024,
  // which is enormous for a sprite drawn at a fraction of a map: the eight
  // decor items shipped 14MB into a web build to be rendered around 150px.
  // maxSize is the on-disk cap; BoxFit.contain does the rest.
  if (asset.maxSize && Math.max(img.width, img.height) > asset.maxSize) {
    const scale = asset.maxSize / Math.max(img.width, img.height);
    img = resize(img, Math.round(img.width * scale), Math.round(img.height * scale));
  }
  return img;
}

function processedPath(asset) {
  return path.join(WORK_DIR, `${asset.id}.png`);
}

// ------------------------------------------------------------------ status

function status() {
  let config = null;
  try {
    config = configFromEnv(loadEnv(ROOT).env);
  } catch {
    /* status still works offline; keys just show as unknown */
  }

  console.log('asset                  installed  cached  processed');
  console.log('-'.repeat(58));
  for (const a of ASSETS) {
    const installed = fs.existsSync(abs(a.out));
    const cached = config ? Boolean(cache.get(keyFor(a, config))) : null;
    const processed = fs.existsSync(processedPath(a));
    console.log(
      `${a.id.padEnd(22)} ${(installed ? 'yes' : 'no').padEnd(10)} ` +
      `${(cached === null ? '?' : cached ? 'yes' : 'no').padEnd(7)} ${processed ? 'yes' : 'no'}`,
    );
  }
  console.log('-'.repeat(58));
  console.log(`cache: ${cache.count} image(s), ${cache.totalSpentCents.toFixed(1)}c spent to date`);
  if (config) {
    const live = ASSETS.map((a) => keyFor(a, config));
    const orphans = cache.orphans(live);
    if (orphans.length) {
      console.log(`${orphans.length} cached image(s) no longer match any catalog prompt (edited since).`);
    }
  }
}

// --------------------------------------------------------------------- gen

async function gen() {
  const config = configFromEnv(loadEnv(ROOT).env);
  const client = new ImageGenClient(config, { log: (m) => console.log(m) });
  const targets = resolveIds(ids).map(assetById);

  let spent = 0;
  let reused = 0;
  for (const asset of targets) {
    const key = keyFor(asset, config);
    const hit = cache.get(key);
    if (hit && !flags.has('--force')) {
      console.log(`= ${asset.id} cached (${hit.model || 'unknown'}, ${hit.cost_cents ?? '?'}c) - not regenerating`);
      reused++;
      fs.writeFileSync(processedPath(asset), encodePng(process1(asset, fs.readFileSync(hit.file))));
      continue;
    }

    let sourceUploadId;
    if (asset.reference) {
      const up = await cache.uploadOnce(client, abs(asset.reference));
      sourceUploadId = up.id;
      console.log(`+ ${asset.id} reference ${rel(abs(asset.reference))} ${up.cached ? '(upload reused)' : '(uploaded)'}`);
    }

    console.log(`+ ${asset.id} generating (${asset.effort ?? 'draft'})...`);
    const { bytes, record } = await client.runOne({
      prompt: asset.prompt,
      effort: asset.effort ?? 'draft',
      aspect: asset.aspect ?? 'square',
      resolution: asset.resolution,
      sourceUploadId,
      // The cache key already encodes prompt + reference, so it doubles as a
      // correct idempotency key: same content, same server-side job.
      idempotencyKey: `critmath-${key}`,
    });

    // Trust nothing: a service that ignored source_upload_id would still
    // return 200 and bill us for the wrong picture.
    if (sourceUploadId && !(record.input_upload_ids || []).includes(sourceUploadId)) {
      console.log(`  WARNING: ${asset.id} was generated WITHOUT the reference image.`);
      console.log('  The style will not match. Check image-input support before trusting this.');
    }

    const entry = cache.put(key, bytes, record);
    spent += entry.cost_cents || 0;
    console.log(`  ${record.model} ${record.width}x${record.height} ${entry.cost_cents}c ${record.latency_ms}ms`);
    fs.writeFileSync(processedPath(asset), encodePng(process1(asset, bytes)));
  }

  console.log(`\n${reused} reused, ${targets.length - reused} generated, ${spent.toFixed(1)}c this run.`);
}

// ----------------------------------------------------------------- process

function processOnly() {
  const config = configFromEnv(loadEnv(ROOT).env);
  for (const asset of resolveIds(ids).map(assetById)) {
    const hit = cache.get(keyFor(asset, config));
    if (!hit) {
      console.log(`- ${asset.id} not cached; run gen first`);
      continue;
    }
    const img = process1(asset, fs.readFileSync(hit.file));
    fs.writeFileSync(processedPath(asset), encodePng(img));
    const box = alphaBounds(img);
    console.log(`= ${asset.id} -> ${img.width}x${img.height}, content ${box.w}x${box.h} at ${box.x},${box.y}`);
  }
}

// ------------------------------------------------------------------- sheet

function sheet() {
  const targets = resolveIds(ids).map(assetById);
  const panels = [];
  const legend = [];

  for (const asset of targets) {
    // Reference first, then the result, so drift is visible as a pair.
    if (asset.reference) {
      panels.push(decodePng(fs.readFileSync(abs(asset.reference))));
      legend.push(`${asset.id}: reference (${path.basename(asset.reference)})`);
    }
    const p = processedPath(asset);
    if (fs.existsSync(p)) {
      panels.push(decodePng(fs.readFileSync(p)));
      legend.push(`${asset.id}: generated + processed`);
    }
  }

  if (!panels.length) {
    console.log('nothing to show; run gen first');
    return;
  }

  const out = path.join(WORK_DIR, 'contact-sheet.png');
  fs.writeFileSync(out, encodePng(contactSheet(panels, { columns: 2, cell: 300 })));
  console.log(`${rel(out)} (${panels.length} panels, 2 per row)`);
  legend.forEach((l, i) => console.log(`  ${i + 1}. ${l}`));
}

// ----------------------------------------------------------------- preview

/**
 * Composite Buddy the way the app does, once per mouth.
 *
 * A mouth judged on its own is judged wrong. It renders at 0.14 of Buddy's
 * height through BoxFit.contain, so what matters is whether it reads as an
 * expression at that size on that face - not whether it is a nice drawing at
 * 1024px. The `_frac` boxes below are copied from buddy_widget.dart and must
 * stay in step with it.
 */
function preview() {
  const S = 400;
  const load = (p) => decodePng(fs.readFileSync(p));

  // BoxFit.contain: scale the whole image into the box, preserve aspect, centre.
  const place = (canvas, img, { left, top, width, height }) => {
    const bw = width * S;
    const bh = height * S;
    const k = Math.min(bw / img.width, bh / img.height);
    const w = Math.max(1, Math.round(img.width * k));
    const h = Math.max(1, Math.round(img.height * k));
    compose(canvas, resize(img, w, h), Math.round(left * S + (bw - w) / 2), Math.round(top * S + (bh - h) / 2));
  };

  const parts = {
    body: load(abs('app/assets/buddy/body/teal.png')),
    eyes: load(abs('app/assets/buddy/eyes/v1.png')),
    armL: load(abs('app/assets/buddy/arms/arm-1-l.png')),
    armR: load(abs('app/assets/buddy/arms/arm-1-r.png')),
    legL: load(abs('app/assets/buddy/legs/leg-1-l.png')),
    legR: load(abs('app/assets/buddy/legs/leg-1-r.png')),
  };

  const mouths = [['v1 (installed, idle)', abs('app/assets/buddy/mouths/v1.png')]];
  for (const a of ASSETS.filter((x) => x.id.startsWith('mouth-'))) {
    const p = processedPath(a);
    if (fs.existsSync(p)) mouths.push([a.title, p]);
  }

  const panels = mouths.map(([, file]) => {
    const c = Img.blank(S, S, [0xfb, 0xf6, 0xe9, 0xff]);
    place(c, parts.legL, { left: 0.18, top: 0.62, width: 0.30, height: 0.35 });
    place(c, parts.legR, { left: 0.52, top: 0.62, width: 0.30, height: 0.35 });
    place(c, parts.armL, { left: 0.02, top: 0.30, width: 0.30, height: 0.42 });
    place(c, parts.armR, { left: 0.68, top: 0.30, width: 0.30, height: 0.42 });
    place(c, parts.body, { left: 0.15, top: 0.15, width: 0.70, height: 0.70 });
    place(c, parts.eyes, { left: 0.28, top: 0.32, width: 0.44, height: 0.22 });
    place(c, load(file), { left: 0.36, top: 0.54, width: 0.28, height: 0.14 });
    return c;
  });

  const out = path.join(WORK_DIR, 'buddy-preview.png');
  fs.writeFileSync(out, encodePng(contactSheet(panels, { columns: 4, cell: 300, pad: 12 })));
  console.log(rel(out));
  mouths.forEach(([label], i) => console.log(`  ${i + 1}. ${label}`));
}

// ----------------------------------------------------------------- install

function install() {
  for (const asset of resolveIds(ids).map(assetById)) {
    const src = processedPath(asset);
    if (!fs.existsSync(src)) {
      console.log(`- ${asset.id} not processed; run gen first`);
      continue;
    }
    const dest = abs(asset.out);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
    console.log(`> ${asset.id} -> ${asset.out}`);
    // `mirror` writes the other half of a paired sprite. See png.mjs mirrorX.
    if (asset.mirror) {
      const flipped = abs(asset.mirror);
      fs.mkdirSync(path.dirname(flipped), { recursive: true });
      fs.writeFileSync(flipped, encodePng(mirrorX(decodePng(fs.readFileSync(src)))));
      console.log(`> ${asset.id} -> ${asset.mirror} (mirrored)`);
    }
  }
  console.log('\nRemember: new Buddy parts also need a kBuddyMouths entry in');
  console.log('app/lib/data/buddy_parts_catalog.dart, or buddyMouthAsset() falls back to v1.');
}

const COMMANDS = { status, gen, process: processOnly, sheet, preview, install };

if (!COMMANDS[command]) {
  console.log(`unknown command "${command}". try: ${Object.keys(COMMANDS).join(', ')}`);
  process.exit(1);
}

try {
  await COMMANDS[command]();
} catch (err) {
  console.error(`\n${err.name === 'ImageGenError' ? 'service error' : 'error'}: ${err.message}`);
  if (err.body) console.error(JSON.stringify(err.body, null, 2).slice(0, 800));
  if (err.missing) {
    console.error('\nSet these in app/.env:');
    for (const m of err.missing) console.error(`  ${m}`);
  }
  process.exit(1);
}
