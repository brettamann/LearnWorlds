#!/usr/bin/env node
// TTS Pipeline — Stage 4 (TTSGenerator)
//
// Consumes the render plan from Stage 3 and produces audio files via the
// ElevenLabs API. Writes a `.hash` sidecar next to each audio file so Stage 3
// can skip already-rendered entries on subsequent runs.
//
// Output format:
//   Default = MP3 (no ffmpeg required; Flutter just_audio handles it natively).
//   With --aac and ffmpeg available, converts to AAC .m4a per asset-paths.md.
//
// Safety:
//   --dry-run is the DEFAULT. To actually call the ElevenLabs API and incur
//   billable usage, pass --live.
//
// Authentication:
//   Set ELEVENLABS_API_KEY in the environment. The script will not start a
//   live run without it.
//
// See specs/shared/voice-pipeline.md.
//
// Usage:
//   node generate.mjs [--input PATH] [--voice-profiles PATH] [--assets-root PATH]
//                     [--live] [--aac] [--max N] [--start-from N] [--throttle-ms N]
//                     [--retry N] [-v]

import { readFile, writeFile, mkdir, stat } from 'node:fs/promises';
import { existsSync, createWriteStream } from 'node:fs';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { pipeline } from 'node:stream/promises';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT_DEFAULT = path.resolve(__dirname, '..', '..');
const ELEVENLABS_TTS_ENDPOINT = 'https://api.elevenlabs.io/v1/text-to-speech';

// ---------- CLI ----------

function parseArgs(argv) {
  const args = {
    input: path.resolve(__dirname, 'render-plan.json'),
    voiceProfiles: path.resolve(__dirname, 'voice-profiles.json'),
    assetsRoot: REPO_ROOT_DEFAULT,
    live: false,
    aac: false,
    max: Infinity,
    startFrom: 0,
    throttleMs: 250,
    retry: 3,
    verbose: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--input') args.input = path.resolve(argv[++i]);
    else if (a === '--voice-profiles') args.voiceProfiles = path.resolve(argv[++i]);
    else if (a === '--assets-root') args.assetsRoot = path.resolve(argv[++i]);
    else if (a === '--live') args.live = true;
    else if (a === '--aac') args.aac = true;
    else if (a === '--max') args.max = Number(argv[++i]);
    else if (a === '--start-from') args.startFrom = Number(argv[++i]);
    else if (a === '--throttle-ms') args.throttleMs = Number(argv[++i]);
    else if (a === '--retry') args.retry = Number(argv[++i]);
    else if (a === '-v' || a === '--verbose') args.verbose = true;
    else if (a === '-h' || a === '--help') args.help = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(2);
    }
  }
  return args;
}

// ---------- Helpers ----------

function sha256(s) {
  return createHash('sha256').update(s).digest('hex');
}

function sleep(ms) {
  return new Promise((res) => setTimeout(res, ms));
}

function entryHashInput(entry, voiceProfileSettings) {
  return [
    entry.voiceProfile,
    entry.locale,
    JSON.stringify(voiceProfileSettings || {}),
    entry.text,
  ].join('\n--\n');
}

async function ensureDir(filePath) {
  await mkdir(path.dirname(filePath), { recursive: true });
}

function isProfileReady(profile) {
  if (!profile) return false;
  if (!profile.voiceId) return false;
  if (profile.voiceId.startsWith('REPLACE_')) return false;
  return true;
}

// ---------- ffmpeg check ----------

async function ffmpegAvailable() {
  return new Promise((resolve) => {
    const proc = spawn('ffmpeg', ['-version'], { stdio: ['ignore', 'ignore', 'ignore'] });
    proc.on('error', () => resolve(false));
    proc.on('exit', (code) => resolve(code === 0));
  });
}

async function convertMp3ToM4a(mp3Path, m4aPath) {
  await ensureDir(m4aPath);
  return new Promise((resolve, reject) => {
    // -y overwrite, -i input, -c:a aac, -b:a 64k mono
    const proc = spawn('ffmpeg', [
      '-y',
      '-i', mp3Path,
      '-c:a', 'aac',
      '-b:a', '64k',
      '-ac', '1',
      m4aPath,
    ], { stdio: ['ignore', 'ignore', 'pipe'] });

    let stderr = '';
    proc.stderr.on('data', (d) => { stderr += d.toString(); });
    proc.on('error', reject);
    proc.on('exit', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`ffmpeg exited ${code}: ${stderr.slice(0, 300)}`));
    });
  });
}

// ---------- ElevenLabs API ----------

async function elevenlabsRender({ text, voiceId, model, settings, apiKey }) {
  const body = {
    text,
    model_id: model,
    voice_settings: {
      stability: settings.stability,
      similarity_boost: settings.similarityBoost,
      style: settings.style,
      use_speaker_boost: settings.useSpeakerBoost,
    },
  };

  const url = `${ELEVENLABS_TTS_ENDPOINT}/${voiceId}?output_format=mp3_44100_64`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      'xi-api-key': apiKey,
      'Content-Type': 'application/json',
      'Accept': 'audio/mpeg',
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    const errText = await resp.text().catch(() => '');
    const err = new Error(`ElevenLabs ${resp.status}: ${errText.slice(0, 300)}`);
    err.status = resp.status;
    err.retryable = resp.status === 429 || resp.status >= 500;
    throw err;
  }

  if (!resp.body) throw new Error('ElevenLabs response had no body');
  return resp.body; // ReadableStream of MP3 bytes
}

async function writeStreamToFile(stream, filePath) {
  await ensureDir(filePath);
  // Convert WHATWG ReadableStream to Node Readable for pipeline().
  const { Readable } = await import('node:stream');
  const nodeStream = Readable.fromWeb(stream);
  await pipeline(nodeStream, createWriteStream(filePath));
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node generate.mjs [--input PATH] [--voice-profiles PATH] [--assets-root PATH] [--live] [--aac] [--max N] [--start-from N] [--throttle-ms N] [--retry N] [-v]');
    console.log('');
    console.log('Defaults to DRY-RUN. Pass --live to actually call the ElevenLabs API.');
    process.exit(0);
  }

  const plan = JSON.parse(await readFile(args.input, 'utf8'));
  const voiceProfiles = JSON.parse(await readFile(args.voiceProfiles, 'utf8'));

  const entries = plan.entries.slice(args.startFrom, args.startFrom + args.max);

  console.log('TTS Generator');
  console.log(`  Mode:            ${args.live ? 'LIVE (will call ElevenLabs API)' : 'DRY-RUN (no API calls)'}`);
  console.log(`  Output format:   ${args.aac ? 'AAC (.m4a via ffmpeg)' : 'MP3 (.mp3 direct from API)'}`);
  console.log(`  Render plan:     ${path.relative(REPO_ROOT_DEFAULT, args.input).replace(/\\/g, '/')}`);
  console.log(`  Entries in plan: ${plan.entries.length}`);
  console.log(`  Window:          [${args.startFrom}, ${args.startFrom + entries.length})`);
  console.log(`  Throttle:        ${args.throttleMs}ms between calls`);
  console.log('');

  // Pre-flight checks.
  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (args.live) {
    if (!apiKey) {
      console.error('ERROR: --live mode requires ELEVENLABS_API_KEY environment variable.');
      console.error('  Set it temporarily: $env:ELEVENLABS_API_KEY = "sk_..."  (PowerShell)');
      console.error('  Or:                 export ELEVENLABS_API_KEY=sk_...     (bash)');
      process.exit(2);
    }
    // Check voice profile readiness for every distinct voiceProfile in the window.
    const requestedProfiles = new Set(entries.map((e) => e.voiceProfile));
    const unready = [];
    for (const profileName of requestedProfiles) {
      if (!isProfileReady(voiceProfiles.profiles?.[profileName])) {
        unready.push(profileName);
      }
    }
    if (unready.length > 0) {
      console.error('ERROR: voice profile(s) not ready:');
      for (const p of unready) console.error(`  - ${p} (voiceId is missing or still REPLACE_...)`);
      console.error('Edit tools/tts/voice-profiles.json with locked ElevenLabs voice IDs first.');
      process.exit(2);
    }
  }

  let useFfmpeg = false;
  if (args.aac) {
    useFfmpeg = await ffmpegAvailable();
    if (!useFfmpeg) {
      console.error('ERROR: --aac requested but ffmpeg is not on PATH.');
      console.error('  Install: choco install ffmpeg (Windows) | brew install ffmpeg (macOS) | apt install ffmpeg (Linux)');
      process.exit(2);
    }
  }

  // Stats.
  let rendered = 0;
  let skippedAlreadyRendered = 0;
  let failed = 0;
  let totalCharsSent = 0;
  const failures = [];

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];
    const idx = args.startFrom + i + 1;

    // Decide output path. Plan has .m4a path; rewrite to .mp3 if not using ffmpeg.
    const m4aRelPath = entry.outputFile;
    const mp3RelPath = m4aRelPath.replace(/\.m4a$/i, '.mp3');
    const finalRelPath = args.aac && useFfmpeg ? m4aRelPath : mp3RelPath;
    const finalAbsPath = path.join(args.assetsRoot, finalRelPath);
    const tmpMp3AbsPath = path.join(args.assetsRoot, mp3RelPath);
    const hashAbsPath = finalAbsPath + '.hash';

    const profile = voiceProfiles.profiles?.[entry.voiceProfile];
    const settings = profile?.settings || {};
    const hashInput = entryHashInput(entry, settings);
    const expectedHash = sha256(hashInput);

    // Quick re-check: maybe Stage 3 ran with stale assumptions; if the audio exists
    // AND the sidecar matches, skip even in live mode.
    if (existsSync(finalAbsPath) && existsSync(hashAbsPath)) {
      const existing = (await readFile(hashAbsPath, 'utf8')).trim();
      if (existing === expectedHash) {
        skippedAlreadyRendered++;
        if (args.verbose) console.log(`[${idx}/${plan.entries.length}] SKIP  ${finalRelPath}`);
        continue;
      }
    }

    const previewText = entry.text.length > 60 ? entry.text.slice(0, 57) + '...' : entry.text;
    const prefix = `[${idx}/${plan.entries.length}]`;

    if (!args.live) {
      console.log(`${prefix} DRY   ${finalRelPath}  "${previewText}"`);
      rendered++;
      totalCharsSent += entry.text.length;
      continue;
    }

    // Live render with retry.
    let attempt = 0;
    let lastErr = null;
    while (attempt <= args.retry) {
      try {
        const stream = await elevenlabsRender({
          text: entry.text,
          voiceId: profile.voiceId,
          model: profile.model || 'eleven_multilingual_v2',
          settings,
          apiKey,
        });
        await writeStreamToFile(stream, tmpMp3AbsPath);

        if (args.aac && useFfmpeg) {
          await convertMp3ToM4a(tmpMp3AbsPath, finalAbsPath);
          // Delete the tmp mp3 if we're targeting .m4a and the paths differ.
          if (tmpMp3AbsPath !== finalAbsPath) {
            try { await (await import('node:fs/promises')).unlink(tmpMp3AbsPath); } catch {}
          }
        }
        // Write hash sidecar.
        await writeFile(hashAbsPath, expectedHash + '\n');

        rendered++;
        totalCharsSent += entry.text.length;
        console.log(`${prefix} OK    ${finalRelPath}  "${previewText}"`);
        break;
      } catch (e) {
        lastErr = e;
        if (!e.retryable || attempt === args.retry) {
          failed++;
          failures.push({ cueId: entry.cueId, outputFile: finalRelPath, error: e.message });
          console.log(`${prefix} FAIL  ${finalRelPath}  ${e.message}`);
          break;
        }
        const backoffMs = Math.min(60_000, 1000 * Math.pow(2, attempt));
        console.log(`${prefix} retry in ${backoffMs}ms (${e.message})`);
        await sleep(backoffMs);
        attempt++;
      }
    }

    if (args.throttleMs > 0) await sleep(args.throttleMs);
  }

  console.log('');
  console.log('Generator complete.');
  console.log(`  Entries in window: ${entries.length}`);
  console.log(`  Rendered:          ${rendered}`);
  console.log(`  Skipped (cached):  ${skippedAlreadyRendered}`);
  console.log(`  Failed:            ${failed}`);
  console.log(`  Chars sent:        ${totalCharsSent.toLocaleString()}`);
  if (!args.live) {
    console.log('');
    console.log('THIS WAS A DRY RUN. Re-run with --live to actually call ElevenLabs.');
  }
  if (failures.length > 0) {
    console.log('');
    console.log('Failures:');
    for (const f of failures.slice(0, 10)) {
      console.log(`  ${f.cueId}: ${f.error}`);
    }
    if (failures.length > 10) console.log(`  ... and ${failures.length - 10} more`);
  }

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
