#!/usr/bin/env node
// TTS Pipeline — Stage 3 (CacheChecker)
//
// Reads the canonical manifest from Stage 2 and decides which entries actually
// need to be (re-)rendered by Stage 4. The cache key is a sha-256 of:
//   voiceProfile + voiceSettings + expandedText
// For each entry we check whether `{outputFile}.hash` exists and matches. If
// yes → skip (already rendered). If no → enqueue for render.
//
// Output: a render-plan manifest that Stage 4 consumes.
//
// See specs/shared/voice-pipeline.md.
//
// Usage:
//   node check-cache.mjs [--input PATH] [--out PATH] [--assets-root PATH] \
//                       [--voice-profiles PATH] [-v]

import { readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT_DEFAULT = path.resolve(__dirname, '..', '..');

// ---------- CLI ----------

function parseArgs(argv) {
  const args = {
    input: path.resolve(__dirname, 'canonical-manifest.json'),
    out: path.resolve(__dirname, 'render-plan.json'),
    assetsRoot: REPO_ROOT_DEFAULT,
    voiceProfiles: path.resolve(__dirname, 'voice-profiles.json'),
    verbose: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--input') args.input = path.resolve(argv[++i]);
    else if (a === '--out') args.out = path.resolve(argv[++i]);
    else if (a === '--assets-root') args.assetsRoot = path.resolve(argv[++i]);
    else if (a === '--voice-profiles') args.voiceProfiles = path.resolve(argv[++i]);
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

function entryHashInput(entry, voiceProfileSettings) {
  // The hash captures everything that would change the audio output.
  // - voice profile id
  // - voice settings (stability / similarity / style)
  // - the literal text that will be sent to TTS (including SSML breaks)
  // - the locale (different locales produce different audio for the same text)
  const settings = voiceProfileSettings || {};
  return [
    entry.voiceProfile,
    entry.locale,
    JSON.stringify(settings),
    entry.expandedText,
  ].join('\n--\n');
}

async function readHashSidecarFor(outputFilePath) {
  const hashPath = outputFilePath + '.hash';
  if (!existsSync(hashPath)) return null;
  try {
    const raw = await readFile(hashPath, 'utf8');
    return raw.trim();
  } catch (e) {
    return null;
  }
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node check-cache.mjs [--input PATH] [--out PATH] [--assets-root PATH] [--voice-profiles PATH] [-v]');
    process.exit(0);
  }

  // Load canonical manifest from Stage 2.
  const canonical = JSON.parse(await readFile(args.input, 'utf8'));

  // Load voice profiles (so we can include voice settings in the hash). If the
  // file doesn't exist yet, use an empty config — initial generation still
  // works; once profiles are locked, subsequent runs will re-render entries
  // whose voice settings changed.
  let voiceProfiles = { profiles: {} };
  if (existsSync(args.voiceProfiles)) {
    try {
      voiceProfiles = JSON.parse(await readFile(args.voiceProfiles, 'utf8'));
    } catch (e) {
      console.warn(`Warning: voice-profiles.json could not be parsed (${e.message}); proceeding with empty settings.`);
    }
  }

  const toRender = [];
  const skipped = [];
  const checks = [];

  // Renderable entries: cues with full-render, digit-stitched-template, or
  // digit-stitched+runtime-template strategy. Plus the digit library.
  const renderableCues = canonical.cues.filter(
    (c) =>
      c.renderStrategy === 'full-render' ||
      c.renderStrategy === 'digit-stitched-template' ||
      c.renderStrategy === 'digit-stitched+runtime-template',
  );

  for (const cue of renderableCues) {
    const profileSettings = voiceProfiles.profiles?.[cue.voiceProfile]?.settings;
    const hashInput = entryHashInput(cue, profileSettings);
    const expectedHash = sha256(hashInput);

    const absPath = path.join(args.assetsRoot, cue.outputFile);
    const existingHash = await readHashSidecarFor(absPath);
    const audioExists = existsSync(absPath);

    const entry = {
      cueId: cue.expandedCueId,
      voiceProfile: cue.voiceProfile,
      narratorCharacter: cue.narratorCharacter,
      locale: cue.locale,
      text: cue.expandedText,
      outputFile: cue.outputFile,
      renderStrategy: cue.renderStrategy,
      slotBindings: cue.slotBindings,
      ...(cue.stitchedSlots ? { stitchedSlots: cue.stitchedSlots } : {}),
      ...(cue.runtimeOnlySlots ? { runtimeOnlySlots: cue.runtimeOnlySlots } : {}),
      expectedHash,
    };

    if (audioExists && existingHash === expectedHash) {
      skipped.push(entry);
      if (args.verbose) console.log(`SKIP  ${cue.outputFile}`);
    } else {
      toRender.push(entry);
      if (args.verbose) {
        if (!audioExists) console.log(`NEW   ${cue.outputFile}`);
        else console.log(`STALE ${cue.outputFile}  (existing hash ${existingHash?.slice(0, 8)} != expected ${expectedHash.slice(0, 8)})`);
      }
    }

    checks.push({
      outputFile: cue.outputFile,
      audioExists,
      hashMatches: audioExists && existingHash === expectedHash,
    });
  }

  // Digit library — same hash logic.
  const digitLibToRender = [];
  const digitLibSkipped = [];
  for (const entry of canonical.digitLibrary || []) {
    const profileSettings = voiceProfiles.profiles?.[entry.voiceProfile]?.settings;
    const hashInput = entryHashInput(entry, profileSettings);
    const expectedHash = sha256(hashInput);

    const absPath = path.join(args.assetsRoot, entry.outputFile);
    const existingHash = await readHashSidecarFor(absPath);
    const audioExists = existsSync(absPath);

    const planEntry = {
      cueId: `digit:${entry.voiceProfile}:${entry.digit}`,
      voiceProfile: entry.voiceProfile,
      locale: entry.locale,
      text: entry.text,
      outputFile: entry.outputFile,
      renderStrategy: 'full-render',
      isDigitLibrary: true,
      digit: entry.digit,
      expectedHash,
    };

    if (audioExists && existingHash === expectedHash) {
      digitLibSkipped.push(planEntry);
    } else {
      digitLibToRender.push(planEntry);
    }
  }

  const totalToRender = toRender.length + digitLibToRender.length;
  const totalSkipped = skipped.length + digitLibSkipped.length;
  const totalRenderableChars =
    toRender.reduce((s, e) => s + e.text.length, 0) +
    digitLibToRender.reduce((s, e) => s + e.text.length, 0);

  const plan = {
    generatedAt: new Date().toISOString(),
    sourceManifest: path.relative(__dirname, args.input),
    sourceManifestHash: canonical.sourceManifestHash,
    canonicalGeneratedAt: canonical.generatedAt,
    locale: canonical.locale,
    totalChecked: renderableCues.length + (canonical.digitLibrary?.length || 0),
    totalToRender,
    totalSkipped,
    cuesToRender: toRender.length,
    cuesSkipped: skipped.length,
    digitLibraryToRender: digitLibToRender.length,
    digitLibrarySkipped: digitLibSkipped.length,
    totalRenderableChars,
    estimatedCost: estimateCost(totalRenderableChars),
    entries: [...toRender, ...digitLibToRender],
  };

  await writeFile(args.out, JSON.stringify(plan, null, 2));

  // Console summary.
  console.log('');
  console.log('Cache check complete.');
  console.log(`  Checked:          ${plan.totalChecked} entries`);
  console.log(`    Cues:           ${renderableCues.length}`);
  console.log(`    Digit library:  ${canonical.digitLibrary?.length || 0}`);
  console.log('');
  console.log(`  Skipped:          ${totalSkipped} (already rendered + hash matches)`);
  console.log(`    Cues:           ${skipped.length}`);
  console.log(`    Digit library:  ${digitLibSkipped.length}`);
  console.log('');
  console.log(`  To render:        ${totalToRender}`);
  console.log(`    Cues:           ${toRender.length}`);
  console.log(`    Digit library:  ${digitLibToRender.length}`);
  console.log(`    Total chars:    ${totalRenderableChars.toLocaleString()}`);
  console.log('');
  console.log(`  ElevenLabs cost projection: ${plan.estimatedCost.summary}`);
  console.log('');
  console.log(`Render plan written to: ${args.out}`);

  process.exit(0);
}

function estimateCost(totalChars) {
  // Rough projection vs. ElevenLabs published tiers.
  const tiers = [
    { name: 'creator', monthlyChars: 100_000, monthlyUsd: 22 },
    { name: 'pro', monthlyChars: 500_000, monthlyUsd: 99 },
    { name: 'scale', monthlyChars: 2_000_000, monthlyUsd: 330 },
  ];
  const fit = tiers.find((t) => totalChars <= t.monthlyChars) || tiers[tiers.length - 1];
  return {
    chars: totalChars,
    suggestedTier: fit.name,
    tierMonthlyChars: fit.monthlyChars,
    tierMonthlyUsd: fit.monthlyUsd,
    summary: `${totalChars.toLocaleString()} chars — fits ${fit.name} tier ($${fit.monthlyUsd}/mo / ${fit.monthlyChars.toLocaleString()} chars)`,
  };
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
