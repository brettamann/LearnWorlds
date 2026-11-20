// Checks for the Kokoro render path. Run after touching wav.mjs or render.mjs.
//
//   node tools/tts/kokoro/check.mjs
//
// Same shape as tools/tts/record/check.mjs. The properties worth pinning are
// the ones that fail silently: a WAV header that says the wrong thing produces
// a file the browser refuses without telling anyone which line broke, and a
// clip written under a stem the app does not look up is simply never heard.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { trimSilence, normalize, encodeWav, finishClip } from './wav.mjs';
import { SAY_AS, spokenText } from './lexicon.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..', '..');
const OUT_DIR = path.join(ROOT, 'app', 'assets', 'audio', 'narration');

let failures = 0;
function check(name, fn) {
  try {
    fn();
    console.log(`  ok   ${name}`);
  } catch (err) {
    failures++;
    console.log(`  FAIL ${name}\n       ${err.message}`);
  }
}
function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}
function near(a, b, tol, msg) {
  assert(Math.abs(a - b) <= tol, `${msg} (got ${a}, want ${b} +/- ${tol})`);
}

/** A tone with `lead` and `tail` seconds of silence around it. */
function tone({ rate = 24000, lead = 0.5, body = 1.0, tail = 0.5, amp = 0.25 }) {
  const n = Math.round((lead + body + tail) * rate);
  const out = new Float32Array(n);
  const start = Math.round(lead * rate);
  const end = start + Math.round(body * rate);
  for (let i = start; i < end; i++) out[i] = Math.sin((2 * Math.PI * 220 * i) / rate) * amp;
  return { samples: out, rate, start, end };
}

console.log('wav encoding');

check('header declares 16-bit PCM mono, not float', () => {
  // kokoro-js writes format tag 3 (IEEE float). Browsers - Safari especially -
  // are unreliable on that, which is the whole reason this encoder exists.
  const buf = encodeWav(new Float32Array(1000), 24000);
  assert(buf.toString('ascii', 0, 4) === 'RIFF', 'missing RIFF');
  assert(buf.toString('ascii', 8, 12) === 'WAVE', 'missing WAVE');
  const fmt = buf.indexOf('fmt ');
  assert(buf.readUInt16LE(fmt + 8) === 1, 'format tag must be 1 (PCM), not 3 (float)');
  assert(buf.readUInt16LE(fmt + 10) === 1, 'must be mono');
  assert(buf.readUInt16LE(fmt + 22) === 16, 'must be 16-bit');
  assert(buf.readUInt32LE(fmt + 12) === 24000, 'sample rate lost');
});

check('declared data length matches the bytes actually written', () => {
  // A wrong length here plays as truncated audio or a burst of noise, with no
  // error anywhere.
  const buf = encodeWav(new Float32Array(5000), 24000);
  const dataIdx = buf.indexOf('data');
  assert(buf.readUInt32LE(dataIdx + 4) === 5000 * 2, 'data chunk length wrong');
  assert(buf.length === 44 + 5000 * 2, 'buffer size wrong');
  assert(buf.readUInt32LE(4) === 36 + 5000 * 2, 'RIFF size wrong');
});

check('samples survive the float -> int16 round trip', () => {
  const src = new Float32Array([0, 0.5, -0.5, 0.999, -0.999]);
  const buf = encodeWav(src, 24000);
  const dataIdx = buf.indexOf('data') + 8;
  for (let i = 0; i < src.length; i++) {
    near(buf.readInt16LE(dataIdx + i * 2) / 32767, src[i], 0.001, `sample ${i}`);
  }
});

check('out-of-range samples clamp instead of wrapping', () => {
  // Normalising to -1 dBFS can still leave a sample marginally over 1.0 after
  // rounding. Wrapping that would be an audible click on a child's headphones.
  const buf = encodeWav(new Float32Array([2.0, -2.0]), 24000);
  const dataIdx = buf.indexOf('data') + 8;
  assert(buf.readInt16LE(dataIdx) === 32767, 'positive overflow did not clamp');
  assert(buf.readInt16LE(dataIdx + 2) === -32767, 'negative overflow did not clamp');
});

console.log('trim and normalise');

check('leading and trailing silence go, with padding kept', () => {
  const { samples, rate, start, end } = tone({ lead: 0.5, body: 1.0, tail: 0.5 });
  const padMs = 30;
  const trimmed = trimSilence(samples, rate, { padMs });
  const pad = (padMs / 1000) * rate;
  near(trimmed.length, end - start + 2 * pad, rate * 0.02, 'trimmed length');
  assert(trimmed.length < samples.length, 'nothing was trimmed');
});

check('a fully silent clip is returned untouched rather than emptied', () => {
  const silent = new Float32Array(1000);
  assert(trimSilence(silent, 24000).length === 1000, 'silence should pass through');
});

check('normalise reaches -1 dBFS from quiet and from loud', () => {
  const target = Math.pow(10, -1 / 20);
  for (const amp of [0.02, 0.9]) {
    const src = new Float32Array(100).fill(amp);
    const out = normalize(src);
    near(Math.max(...out), target, 0.001, `peak for amp ${amp}`);
  }
});

check('normalise leaves silence alone instead of dividing by zero', () => {
  const out = normalize(new Float32Array(100));
  assert(out.every((v) => v === 0 && Number.isFinite(v)), 'silence became non-finite');
});

check('finishClip trims, normalises and encodes in one pass', () => {
  const { samples, rate } = tone({ lead: 0.5, body: 1.0, tail: 0.5, amp: 0.05 });
  const buf = finishClip(samples, rate);
  const fmt = buf.indexOf('fmt ');
  assert(buf.readUInt16LE(fmt + 8) === 1, 'not PCM');
  const dataIdx = buf.indexOf('data');
  const seconds = buf.readUInt32LE(dataIdx + 4) / 2 / rate;
  near(seconds, 1.06, 0.1, 'duration after trim');

  let peak = 0;
  for (let i = dataIdx + 8; i < buf.length; i += 2) {
    peak = Math.max(peak, Math.abs(buf.readInt16LE(i)) / 32767);
  }
  near(peak, Math.pow(10, -1 / 20), 0.01, 'peak after normalise');
});

console.log('clips on disk');

check('every rendered clip matches a line the script still asks for', () => {
  const scriptFile = path.join(HERE, 'script.json');
  if (!fs.existsSync(scriptFile) || !fs.existsSync(OUT_DIR)) return;
  const script = JSON.parse(fs.readFileSync(scriptFile, 'utf8'));
  const wanted = new Set(script.batches.flatMap((b) => b.lines.map((l) => l.clipKey)));

  const manifest = fs.existsSync(path.join(HERE, 'rendered.json'))
    ? JSON.parse(fs.readFileSync(path.join(HERE, 'rendered.json'), 'utf8'))
    : { clips: {} };

  const stray = fs
    .readdirSync(OUT_DIR)
    .filter((f) => /\.(wav|mp3)$/.test(f))
    .map((f) => f.replace(/\.(wav|mp3)$/, ''))
    // Only machine-rendered clips are ours to judge; a hand recording of a
    // line assembled from lesson JSON is legitimately not in the script.
    .filter((k) => manifest.clips[k] && !wanted.has(k));

  assert(stray.length === 0, `${stray.length} rendered clip(s) orphaned by a reworded line: ${stray.slice(0, 3).join(', ')} - run \`render.mjs orphans\``);
});

check('no clip key is claimed by two files at once', () => {
  if (!fs.existsSync(OUT_DIR)) return;
  const byKey = new Map();
  for (const f of fs.readdirSync(OUT_DIR).filter((x) => /\.(wav|mp3)$/.test(x))) {
    const key = f.replace(/\.(wav|mp3)$/, '');
    byKey.set(key, [...(byKey.get(key) || []), f]);
  }
  const dupes = [...byKey.entries()].filter(([, files]) => files.length > 1);
  assert(dupes.length === 0, `${dupes.length} key(s) have both a .wav and .mp3; which one plays is undefined: ${dupes.slice(0, 2).map(([k]) => k).join(', ')}`);
});

// ------------------------------------------------------------- lexicon

check('every pronunciation rule still has a word to fix', () => {
  const scriptPath = path.join(HERE, 'script.json');
  if (!fs.existsSync(scriptPath)) return;
  const script = JSON.parse(fs.readFileSync(scriptPath, 'utf8'));
  const all = script.batches.flatMap((b) => b.lines.map((l) => l.text)).join(' ');

  for (const entry of SAY_AS) {
    // A rule for a word nobody says any more is dead weight that still forces
    // a re-render every time someone touches the file.
    const used = new RegExp(`\\b${entry.word}s?\\b`, 'i').test(all);
    assert(used, `nothing in the script says "${entry.word}" any more - drop the rule`);
    assert(entry.say !== entry.word, `"${entry.word}" respells to itself`);
    assert(entry.heard !== entry.want, `"${entry.word}" records the same IPA for both`);
  }
});

check('respelling survives capitalisation and plurals', () => {
  for (const { word, say } of SAY_AS) {
    const Word = word[0].toUpperCase() + word.slice(1);
    const Say = say[0].toUpperCase() + say.slice(1);
    assert(spokenText(word) === say, `${word} -> ${spokenText(word)}`);
    assert(spokenText(`${word}s`) === `${say}s`, `${word}s -> ${spokenText(`${word}s`)}`);
    // Sentence-initial: "Gryphons!" must not come back as "griffins!".
    assert(spokenText(`${Word}s are here.`) === `${Say}s are here.`, `${Word}s -> ${spokenText(`${Word}s are here.`)}`);
    // And a word that merely contains it is left alone.
    assert(spokenText(`un${word}ish`) === `un${word}ish`, `matched inside a longer word`);
  }
});

check('a line with no rule in it is untouched', () => {
  const line = 'Touch each fawn, one at a time.';
  assert(spokenText(line) === line, 'the lexicon rewrote a line it has no rule for');
});

console.log(failures === 0 ? '\nAll checks passed.' : `\n${failures} check(s) failed.`);
process.exit(failures === 0 ? 0 : 1);
