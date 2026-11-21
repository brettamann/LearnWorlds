// node tools/tts/record/check.mjs
//
// Guards the two parts of the recording harness that fail silently.
//
//   1. The clip key. If this drifts from narrationClipKey() in
//      app/lib/platform/narration_audio.dart, every take is written under a
//      filename the app never looks up. Nothing errors — the game just keeps
//      using the synth voice. The same vectors are pinned in
//      app/test/narration_script_test.dart, so a change to either side breaks
//      one of the two.
//
//   2. The silence splitter. A continuous take that segments wrongly produces
//      clips shifted by one, which means a child hears "Four." when the game
//      meant "Three." The harness compares the segment count against the batch
//      length before it will save, but that check is only as good as the
//      splitter under realistic room noise.
//
// Both functions are pulled out of the page rather than duplicated, so this
// tests the code that actually runs.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(here, 'index.html'), 'utf8');

function extract(from, to) {
  const a = html.indexOf(from);
  const b = html.indexOf(to);
  if (a < 0 || b < 0 || b <= a) {
    throw new Error(`could not find ${from} .. ${to} in index.html`);
  }
  return html.slice(a, b);
}

const scope = {};
// eslint-disable-next-line no-new-func
new Function(
  extract('const normalize =', '// Shared vectors') +
    extract('function splitOnSilence', 'function resplit()') +
    'Object.assign(this, { clipKey, splitOnSilence });',
).call(scope);

let failures = 0;
const check = (ok, label, detail = '') => {
  if (!ok) failures++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${label}${detail ? '  ' + detail : ''}`);
};

// --- 1. clip key -----------------------------------------------------------
const VECTORS = [
  ['One.', 'one__ccbaa073'],
  ['Not that one. Look again.', 'not-that-one-look-again__c6dc8490'],
  // The em dash has to hash as UTF-8 bytes or Dart and JS disagree about
  // nearly every prompt in the game.
  [
    'Touch each fawn — and count out loud with me!',
    'touch-each-fawn-and-count-out-loud-with-me__4a5087aa',
  ],
];
for (const [text, want] of VECTORS) {
  const got = scope.clipKey(text);
  check(got === want, `clipKey(${JSON.stringify(text.slice(0, 34))})`,
    got === want ? '' : `wanted ${want}, got ${got}`);
}

// --- 2. splitter -----------------------------------------------------------
const RATE = 48000;

/// A synthetic take: `n` bursts of voiced-ish signal separated by `gapMs` of
/// room tone at `floor` amplitude.
function synthesize(n, speechMs, gapMs, floor) {
  const total = Math.round((RATE * ((speechMs + gapMs) * n + 500)) / 1000);
  const data = new Float32Array(total);
  // Deterministic pseudo-noise: a fixed LCG, so a flaky run means a real
  // regression rather than an unlucky Math.random().
  let seed = 12345;
  const rnd = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff) * 2 - 1;
  for (let i = 0; i < total; i++) data[i] = rnd() * floor;
  let t = Math.round(RATE * 0.25);
  for (let k = 0; k < n; k++) {
    const len = Math.round((RATE * speechMs) / 1000);
    for (let i = 0; i < len; i++) {
      data[t + i] += Math.sin(i / 12) * 0.5 * (Math.abs(rnd()) * 0.6 + 0.4);
    }
    t += len + Math.round((RATE * gapMs) / 1000);
  }
  return { data, rate: RATE };
}

const OPTS = { thresholdDb: -42, minGapMs: 350 };
const CASES = [
  ['10 lines, 1.0s gaps, quiet room', 10, 700, 1000, 0.0008],
  ['10 lines, 0.6s gaps', 10, 700, 600, 0.0008],
  ['25 lines, 1.0s gaps, noisy room', 25, 600, 1000, 0.004],
  ['5 lines, 1.5s gaps', 5, 900, 1500, 0.001],
  ['100 lines, 0.8s gaps (the counts batch)', 100, 500, 800, 0.001],
];
for (const [label, n, speech, gap, floor] of CASES) {
  const segs = scope.splitOnSilence(synthesize(n, speech, gap, floor), OPTS);
  check(segs.length === n, label, `expected ${n}, got ${segs.length}`);
}

// Silence alone must yield nothing rather than one giant segment.
check(
  scope.splitOnSilence(synthesize(0, 0, 0, 0.0008), OPTS).length === 0,
  'an empty room splits into no segments',
);

console.log(failures ? `\n${failures} failure(s)` : '\nAll checks passed.');
process.exit(failures ? 1 : 0);
