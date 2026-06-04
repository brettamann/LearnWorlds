#!/usr/bin/env node
// Voice sampler — helper for picking ElevenLabs voice IDs.
//
// Given a list of candidate voice IDs, renders the same set of representative
// lines through each so you can listen and pick. Output goes to a dedicated
// `voice-samples/` directory so it doesn't mix with production audio.
//
// Usage:
//   node sample-voices.mjs --voices VOICE_ID1,VOICE_ID2,VOICE_ID3 \
//                           [--profile sanctuary-warm-naturalist] \
//                           [--lines PATH] [--out PATH]
//
// Requires ELEVENLABS_API_KEY in env.

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync, createWriteStream } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pipeline } from 'node:stream/promises';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ELEVENLABS_TTS_ENDPOINT = 'https://api.elevenlabs.io/v1/text-to-speech';

// Default representative lines spanning lesson + activity + emotional registers.
// These are the lines you'll judge each candidate voice on.
const DEFAULT_LINES = [
  // Calm explanatory (K.CC.4a I-Show opening)
  "Let's count these fawns together. Watch how each one gets one touch.",
  // Counting cadence
  "One. Two. Three.",
  // Cardinality punchline (K.CC.4b)
  "The last number you say tells you how many. Every time.",
  // Warm correction (K.OA.5 incorrect-answer)
  "Three take away one is two. Try the next one.",
  // Celebratory (Counting Parade round-pass)
  "Six! There are six fawns.",
  // Conceptual insight (K.OA.3 closing)
  "Numbers can be split lots of different ways. Three and two. Four and one. They're all five.",
  // Storyteller turtle (warm story-tone)
  "Listen to this story. Four ducks are in the pond.",
  // Wonder beat (K.G.6 fawn enters habitat)
  "Look at that. You built a home.",
];

function parseArgs(argv) {
  const args = {
    voices: [],
    profile: 'sanctuary-warm-naturalist',
    profilesPath: path.resolve(__dirname, 'voice-profiles.json'),
    lines: null,
    out: path.resolve(__dirname, 'voice-samples'),
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--voices') args.voices = argv[++i].split(',').map((s) => s.trim()).filter(Boolean);
    else if (a === '--profile') args.profile = argv[++i];
    else if (a === '--profiles') args.profilesPath = path.resolve(argv[++i]);
    else if (a === '--lines') args.lines = path.resolve(argv[++i]);
    else if (a === '--out') args.out = path.resolve(argv[++i]);
    else if (a === '-h' || a === '--help') args.help = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(2);
    }
  }
  return args;
}

async function fetchVoice({ text, voiceId, apiKey, settings }) {
  const url = `${ELEVENLABS_TTS_ENDPOINT}/${voiceId}?output_format=mp3_44100_64`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      'xi-api-key': apiKey,
      'Content-Type': 'application/json',
      'Accept': 'audio/mpeg',
    },
    body: JSON.stringify({
      text,
      model_id: 'eleven_multilingual_v2',
      voice_settings: {
        stability: settings.stability,
        similarity_boost: settings.similarityBoost,
        style: settings.style,
        use_speaker_boost: settings.useSpeakerBoost,
      },
    }),
  });
  if (!resp.ok) {
    const errText = await resp.text().catch(() => '');
    throw new Error(`ElevenLabs ${resp.status}: ${errText.slice(0, 300)}`);
  }
  return resp.body;
}

function fileSafe(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 40).replace(/^-+|-+$/g, '');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || args.voices.length === 0) {
    console.log('Voice sampler');
    console.log('');
    console.log('Usage: node sample-voices.mjs --voices ID1,ID2,ID3 [--profile NAME] [--lines PATH] [--out PATH]');
    console.log('');
    console.log('Requires ELEVENLABS_API_KEY in environment.');
    console.log('');
    console.log('Outputs:');
    console.log('  voice-samples/<voice-id>/01_line-text.mp3, 02_...');
    console.log('  voice-samples/index.html  (browser preview page with audio players)');
    process.exit(args.help ? 0 : 2);
  }

  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    console.error('ELEVENLABS_API_KEY environment variable is required.');
    process.exit(2);
  }

  const profiles = JSON.parse(await readFile(args.profilesPath, 'utf8'));
  const profile = profiles.profiles?.[args.profile];
  if (!profile) {
    console.error(`Voice profile "${args.profile}" not found in ${args.profilesPath}`);
    process.exit(2);
  }
  const settings = profile.settings || {};

  let lines = DEFAULT_LINES;
  if (args.lines) {
    const raw = await readFile(args.lines, 'utf8');
    lines = raw.split('\n').map((s) => s.trim()).filter(Boolean);
  }

  await mkdir(args.out, { recursive: true });

  console.log(`Sampling ${args.voices.length} voice candidate(s) against ${lines.length} line(s)...`);
  console.log(`Profile settings: stability=${settings.stability}, similarity=${settings.similarityBoost}, style=${settings.style}`);
  console.log('');

  const indexEntries = [];

  for (const voiceId of args.voices) {
    console.log(`Voice ${voiceId}:`);
    const voiceDir = path.join(args.out, voiceId);
    await mkdir(voiceDir, { recursive: true });

    const lineEntries = [];
    for (let i = 0; i < lines.length; i++) {
      const text = lines[i];
      const slug = `${String(i + 1).padStart(2, '0')}_${fileSafe(text)}.mp3`;
      const outAbs = path.join(voiceDir, slug);
      const outRel = path.relative(args.out, outAbs).replace(/\\/g, '/');

      try {
        const stream = await fetchVoice({ text, voiceId, apiKey, settings });
        const { Readable } = await import('node:stream');
        await pipeline(Readable.fromWeb(stream), createWriteStream(outAbs));
        console.log(`  ${slug}  "${text.slice(0, 60)}${text.length > 60 ? '...' : ''}"`);
        lineEntries.push({ text, file: outRel });
      } catch (e) {
        console.error(`  FAIL ${slug}: ${e.message}`);
      }

      // Small throttle between requests.
      await new Promise((r) => setTimeout(r, 200));
    }
    indexEntries.push({ voiceId, lines: lineEntries });
  }

  // Write a simple HTML preview.
  const html = renderHtml(indexEntries, args.profile);
  await writeFile(path.join(args.out, 'index.html'), html);

  console.log('');
  console.log(`Done. Open ${path.join(args.out, 'index.html')} in a browser to compare side-by-side.`);
}

function renderHtml(indexEntries, profileName) {
  const rows = indexEntries
    .map((v) => {
      const audios = v.lines
        .map(
          (l, i) =>
            `<tr><td>${i + 1}</td><td>${escapeHtml(l.text)}</td><td><audio controls src="${escapeHtml(l.file)}"></audio></td></tr>`,
        )
        .join('\n');
      return `<h2>Voice ID: <code>${escapeHtml(v.voiceId)}</code></h2><table>${audios}</table>`;
    })
    .join('\n');
  return `<!doctype html><meta charset="utf-8"><title>Voice samples — ${escapeHtml(profileName)}</title>
<style>body{font-family:sans-serif;max-width:900px;margin:24px auto;padding:0 16px}table{width:100%;border-collapse:collapse;margin-bottom:32px}td{border-bottom:1px solid #eee;padding:8px;vertical-align:middle}td:first-child{width:32px;color:#999}td:nth-child(2){font-style:italic}audio{width:280px}h2{margin-top:32px}</style>
<h1>Voice samples — profile <code>${escapeHtml(profileName)}</code></h1>
<p>Listen to each candidate. The one that best matches the profile's tone notes wins. Lock the voice ID into <code>voice-profiles.json</code> when chosen.</p>
${rows}`;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

main().catch((e) => { console.error(e); process.exit(1); });
