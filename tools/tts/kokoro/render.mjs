// Render the narration script to voice clips with Kokoro, locally and free.
//
//   node tools/tts/kokoro/render.mjs status
//   node tools/tts/kokoro/render.mjs audition "Seven."
//   node tools/tts/kokoro/render.mjs render [--only <batch>] [--matching <re>] [--limit N] [--force]
//   node tools/tts/kokoro/phonemes.mjs "toucan" "toucann"
//   node tools/tts/kokoro/render.mjs orphans [--delete]
//
// Kokoro-82M is Apache-licensed and runs on the CPU here in about two seconds
// a line, so the whole 253-line script is roughly nine minutes and costs
// nothing. That changes what the narration layer is: `specs/shared/
// text-and-tts-deferral.md` deferred the paid render pipeline and left every
// line in the OS synth voice, and the diagnosis in the engagement plan is
// blunt about the cost — "one flat synth voice at one pitch for the keeper,
// the narrator, and the numbers alike", for a pre-reader whose only two
// channels are sight and sound.
//
// NOTHING IN THE APP CHANGES. NarrationPlayer already prefers a bundled clip
// and falls back to system TTS when there is none, and NarrationAudio
// discovers clips straight off Flutter's AssetManifest at boot. A rendered
// clip is picked up because it is in the folder under the right name; there is
// no manifest to build and no code to wire.
//
// A human recording always wins. `render` never overwrites a file that already
// exists, so a line the owner records by hand simply stays, and the machine
// fills in everything around it.
//
// One thing is renderer-only: `lexicon.mjs` respells the handful of words
// eSpeak reads wrong (gryphon, toucan) before they reach the synthesiser. The
// clip key is still the hash of the real sentence, so nothing in the app or
// the script learns the misspelling. Because that means the text can stay put
// while what gets *said* changes, the manifest records the words each clip was
// actually spoken from and `render` re-renders anything the lexicon has moved
// since — the reuse rule is "the words I would say now are the words I said",
// not "a file exists".

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { finishClip, encodeMp3 } from './wav.mjs';
import { spokenText } from './lexicon.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..', '..');
const SCRIPT = path.join(HERE, 'script.json');
const OUT_DIR = path.join(ROOT, 'app', 'assets', 'audio', 'narration');
const MANIFEST = path.join(HERE, 'rendered.json');

// q8 is the quantised ONNX build: ~86MB instead of ~330MB, and the difference
// is not audible on speech this short. Raise to 'fp32' if it ever is.
const MODEL = 'onnx-community/Kokoro-82M-v1.0-ONNX';
const DTYPE = 'q8';

// MP3 at 64 kbps mono, not WAV.
//
// Measured on the longest line in the script: 10.3s of 24 kHz 16-bit mono is
// 483 KB as WAV and 81 KB as MP3, and the whole 253-line script is ~16 minutes
// of speech - 46 MB against roughly 8 MB. 46 MB of narration in a Flutter web
// bundle is a bad first load, and `parade-intro` alone accounts for 31 MB of
// it. MP3 is also the one format every target decodes without argument, which
// is why the SFX ship as it.
//
// Pass --wav for lossless output; NarrationAudio keys on the filename stem and
// ignores the extension, so both work.
const BITRATE_KBPS = 64;

// Voice per batch. Everything is one narrator today — the plan's fiction has
// Keeper Haddock narrating and framing tasks, and Buddy never speaks — but the
// diagnosis specifically complained that the keeper, the narrator and the
// numbers all shared one timbre, so the seam is here to use.
//
// af_heart is the only grade-A voice in the pack; af_bella is A-. Which one
// suits a five-year-old is a judgement to make by ear, not from a grade table:
// run `audition` and listen.
const DEFAULT_VOICE = 'af_heart';
const VOICE_BY_BATCH = {
  // counts: 'af_bella',
};

const argv = process.argv.slice(2);
const command = argv[0] || 'status';
const flag = (name) => argv.includes(`--${name}`);
const value = (name, fallback) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && argv[i + 1] ? argv[i + 1] : fallback;
};

function loadScript() {
  if (!fs.existsSync(SCRIPT)) {
    console.error(`${path.relative(ROOT, SCRIPT)} is missing. Regenerate it with:`);
    console.error('  cd app && dart run tool/dump_narration_script.dart > ../tools/tts/kokoro/script.json');
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(SCRIPT, 'utf8'));
}

function allLines(script) {
  return script.batches.flatMap((b) =>
    b.lines.map((l) => ({ ...l, batch: b.id, voice: VOICE_BY_BATCH[b.id] || DEFAULT_VOICE })),
  );
}

const clipExt = () => (flag('wav') ? 'wav' : 'mp3');
const clipPath = (clipKey, ext = clipExt()) => path.join(OUT_DIR, `${clipKey}.${ext}`);

/**
 * Any file already claiming this clip key, whatever its extension.
 *
 * NarrationAudio maps a clip by filename stem, so `key.wav` and `key.mp3` in
 * the same folder are two entries fighting over one key and which one wins is
 * whatever order the asset manifest happens to list. More importantly a human
 * recording arrives as .wav, and re-rendering over it would replace a real
 * voice with a synthetic one.
 */
function existingClip(clipKey) {
  if (!fs.existsSync(OUT_DIR)) return null;
  const hit = fs
    .readdirSync(OUT_DIR)
    .find((f) => f.startsWith(`${clipKey}.`) && !f.startsWith('.'));
  return hit ? path.join(OUT_DIR, hit) : null;
}

function loadManifest() {
  return fs.existsSync(MANIFEST)
    ? JSON.parse(fs.readFileSync(MANIFEST, 'utf8'))
    : { version: 1, model: MODEL, dtype: DTYPE, clips: {} };
}

function saveManifest(m) {
  fs.writeFileSync(MANIFEST, `${JSON.stringify(m, null, 2)}\n`);
}

let _tts = null;
async function tts() {
  if (_tts) return _tts;
  const { KokoroTTS } = await import('kokoro-js');
  process.stderr.write('loading Kokoro (first run downloads ~86MB)...\n');
  _tts = await KokoroTTS.from_pretrained(MODEL, { dtype: DTYPE, device: 'cpu' });
  return _tts;
}

/**
 * Synthesise one line and write it.
 *
 * Returns null when a clip is already there. That is the whole reuse rule: a
 * clip key is a hash of the words, so a file only goes missing when the words
 * changed, and only changed lines are ever re-rendered.
 */
async function renderLine(line, { force = false } = {}) {
  const existing = existingClip(line.clipKey);
  if (existing && !force) return null;

  const engine = await tts();
  const spoken = spokenText(line.text);
  const audio = await engine.generate(spoken, { voice: line.voice });
  const wav = finishClip(audio.audio, audio.sampling_rate);
  const seconds = +((wav.length - 44) / 2 / audio.sampling_rate).toFixed(2);

  const wantWav = flag('wav');
  const bytes = wantWav ? wav : await encodeMp3(wav, BITRATE_KBPS);

  fs.mkdirSync(OUT_DIR, { recursive: true });
  // Replacing a clip in the other format would otherwise leave both behind,
  // fighting over the same key.
  if (existing && existing !== clipPath(line.clipKey)) fs.unlinkSync(existing);
  fs.writeFileSync(clipPath(line.clipKey), bytes);
  // `spoken` only when it differs, so the manifest stays readable and an
  // entry without one plainly means "said exactly what it says".
  return {
    bytes: bytes.length,
    seconds,
    format: wantWav ? 'wav' : 'mp3',
    ...(spoken === line.text ? {} : { spoken }),
  };
}

/**
 * True when the clip on disk was rendered from different words than we would
 * speak now — i.e. the lexicon changed under a line whose text did not.
 *
 * An entry with no `spoken` was rendered straight from its text, which is what
 * every clip predating the lexicon was, so the backfill is exact rather than a
 * guess and no existing clip is re-rendered for nothing.
 */
function isStale(line, manifest) {
  const entry = manifest.clips[line.clipKey];
  if (!entry) return false;
  return (entry.spoken ?? entry.text ?? line.text) !== spokenText(line.text);
}

// ------------------------------------------------------------------ status

function status() {
  const script = loadScript();
  const lines = allLines(script);
  const manifest = loadManifest();

  console.log('batch                lines  rendered  missing');
  console.log('-'.repeat(50));
  for (const batch of script.batches) {
    const done = batch.lines.filter((l) => existingClip(l.clipKey)).length;
    console.log(
      `${batch.id.padEnd(20)} ${String(batch.lines.length).padStart(5)} ` +
      `${String(done).padStart(9)} ${String(batch.lines.length - done).padStart(8)}`,
    );
  }
  console.log('-'.repeat(50));

  const done = lines.filter((l) => existingClip(l.clipKey));
  const bytes = done.reduce((n, l) => n + fs.statSync(existingClip(l.clipKey)).size, 0);
  const seconds = Object.values(manifest.clips).reduce((n, c) => n + (c.seconds || 0), 0);
  console.log(`${done.length} of ${lines.length} rendered, ${(bytes / 1048576).toFixed(1)} MB, ~${Math.round(seconds)}s of speech`);

  // Files present that the script no longer asks for: a line was reworded, so
  // its key changed and the old clip is now unreachable. Reported rather than
  // deleted, because a hand-recorded take is not something to bin silently.
  const orphans = findOrphans(lines);
  if (orphans.length) {
    console.log(`${orphans.length} clip(s) no longer referenced by the script (see \`orphans\`)`);
  }

  const stale = lines.filter((l) => isStale(l, manifest));
  if (stale.length) {
    console.log(`${stale.length} clip(s) predate the current pronunciation lexicon — run \`render\``);
  }
}

function findOrphans(lines) {
  if (!fs.existsSync(OUT_DIR)) return [];
  const wanted = new Set(lines.map((l) => l.clipKey));
  return fs
    .readdirSync(OUT_DIR)
    .filter((f) => /\.(wav|mp3)$/.test(f))
    .filter((f) => !wanted.has(f.replace(/\.(wav|mp3)$/, '')));
}

// ---------------------------------------------------------------- audition

/**
 * Speak one line in several voices, into a scratch folder, to be compared by
 * ear. Nothing here can judge a voice; this exists so a person can.
 */
async function audition() {
  const text = argv.slice(1).filter((a) => !a.startsWith('--'))[0]
    || 'Oh, thank goodness you are here. I lose track of the fawns every time I blink.';
  const voices = (value('voices', 'af_heart,af_bella,af_nicole,bf_emma')).split(',');
  const dir = path.join(HERE, 'audition');
  fs.mkdirSync(dir, { recursive: true });

  const engine = await tts();
  for (const voice of voices) {
    // Through the lexicon, so an audition is a preview of what ships.
    const audio = await engine.generate(spokenText(text), { voice });
    const wav = finishClip(audio.audio, audio.sampling_rate);
    fs.writeFileSync(path.join(dir, `${voice}.wav`), wav);
    console.log(`${voice.padEnd(12)} ${(wav.length / 1024).toFixed(0)} KB`);
  }
  console.log(`\n${path.relative(ROOT, dir)} - listen, then set DEFAULT_VOICE in this file.`);
}

// ------------------------------------------------------------------ render

async function render() {
  const script = loadScript();
  if (script.keyScheme && !script.keyScheme.startsWith('slug48__fnv1a32')) {
    console.error(`script.json uses key scheme "${script.keyScheme}", which this renderer does not know.`);
    process.exit(1);
  }

  let lines = allLines(script);
  const only = value('only');
  if (only) lines = lines.filter((l) => l.batch === only);
  const matching = value('matching');
  if (matching) {
    const re = new RegExp(matching, 'i');
    lines = lines.filter((l) => re.test(l.text));
  }
  const limit = Number(value('limit', 0));
  if (limit > 0) lines = lines.slice(0, limit);

  const force = flag('force');
  const manifest = loadManifest();
  const stale = new Set(
    lines.filter((l) => isStale(l, manifest)).map((l) => l.clipKey),
  );
  if (stale.size) {
    console.log(`${stale.size} clip(s) speak different words now — re-rendering`);
  }
  const started = Date.now();
  let made = 0;
  let skipped = 0;

  for (const [i, line] of lines.entries()) {
    const result = await renderLine(line, {
      force: force || stale.has(line.clipKey),
    });
    if (!result) {
      skipped++;
      continue;
    }
    made++;
    manifest.clips[line.clipKey] = {
      text: line.text,
      batch: line.batch,
      voice: line.voice,
      ...result,
    };
    if (made % 10 === 0 || i === lines.length - 1) {
      const rate = (Date.now() - started) / 1000 / made;
      const left = Math.round(rate * (lines.length - i - 1));
      process.stdout.write(`  ${made} rendered, ${skipped} already present, ~${left}s left\n`);
      saveManifest(manifest);
    }
  }

  manifest.model = MODEL;
  manifest.dtype = DTYPE;
  saveManifest(manifest);
  console.log(`\n${made} rendered, ${skipped} reused, ${((Date.now() - started) / 1000).toFixed(0)}s total.`);
  if (made) console.log('No app changes needed - clips are discovered from the asset manifest at boot.');
}

// ----------------------------------------------------------------- orphans

function orphans() {
  const list = findOrphans(allLines(loadScript()));
  if (!list.length) {
    console.log('no orphans; every clip matches a line in the script');
    return;
  }
  const manifest = loadManifest();
  console.log(`${list.length} clip(s) the script no longer asks for:\n`);
  for (const f of list) {
    const key = f.replace(/\.(wav|mp3)$/, '');
    const known = manifest.clips[key];
    console.log(`  ${f}${known ? `  "${known.text.slice(0, 60)}"` : '  (not machine-rendered - a hand recording?)'}`);
  }
  if (flag('delete')) {
    // Only ever delete clips this tool rendered. Anything else in that folder
    // arrived another way and is not ours to bin.
    let removed = 0;
    for (const f of list) {
      const k = f.replace(/\.(wav|mp3)$/, '');
      if (!manifest.clips[k]) continue;
      fs.unlinkSync(path.join(OUT_DIR, f));
      delete manifest.clips[k];
      removed++;
    }
    saveManifest(manifest);
    console.log(`\ndeleted ${removed} machine-rendered orphan(s); left anything unrecognised in place`);
  } else {
    console.log('\n--delete removes the machine-rendered ones (never a clip this tool did not write)');
  }
}

const COMMANDS = { status, audition, render, orphans };
if (!COMMANDS[command]) {
  console.log(`unknown command "${command}". try: ${Object.keys(COMMANDS).join(', ')}`);
  process.exit(1);
}
await COMMANDS[command]();
