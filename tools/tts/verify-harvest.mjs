#!/usr/bin/env node
// One-off Node.js verification script. Mirrors the Dart Harvester logic so we
// can run the pipeline NOW (before Dart SDK is installed) and inspect the
// manifest. The canonical implementation is in lib/harvester.dart.
//
// Usage:
//   node verify-harvest.mjs [--repo-root PATH] [--out PATH] [--locale CODE] [-v]
//
// Defaults match the Dart CLI.

import { readFile, readdir, writeFile, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------- CLI parsing ----------

function parseArgs(argv) {
  const args = {
    repoRoot: path.resolve(__dirname, '..', '..'),
    out: path.resolve(__dirname, 'harvest-manifest.json'),
    locale: 'en-US',
    verbose: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--repo-root') args.repoRoot = path.resolve(argv[++i]);
    else if (a === '--out') args.out = path.resolve(argv[++i]);
    else if (a === '--locale') args.locale = argv[++i];
    else if (a === '-v' || a === '--verbose') args.verbose = true;
    else if (a === '-h' || a === '--help') args.help = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(2);
    }
  }
  return args;
}

// ---------- Harvester logic ----------

function stableKey(at, _index) {
  const tsRe = /^[0-9]+(\.[0-9]+)?s$/;
  if (tsRe.test(at)) {
    return 't' + at.replace(/\./g, '_').replace(/s$/, '') + 's';
  }
  return at.replace(/[^A-Za-z0-9_-]/g, '_');
}

function extractSlots(text) {
  const re = /\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
  const set = new Set();
  let m;
  while ((m = re.exec(text)) !== null) set.add(m[1]);
  return [...set].sort();
}

function harvestLessonRuntime(lesson, source, locale, warnings, errors) {
  const cues = [];

  const lessonId = lesson.id;
  if (typeof lessonId !== 'string') {
    errors.push(`${source}: missing required field "id"`);
    return cues;
  }

  const voiceProfile = lesson.narratorVoice;
  if (typeof voiceProfile !== 'string') {
    errors.push(`${source}: missing required field "narratorVoice"`);
    return cues;
  }

  const narratorCharacter =
    typeof lesson.narratorCharacter === 'string' ? lesson.narratorCharacter : null;

  const phases = lesson.phases;
  if (!phases || typeof phases !== 'object') {
    errors.push(`${source}: missing or invalid "phases" object`);
    return cues;
  }

  for (const phaseName of ['iShow', 'weTry', 'youDo']) {
    const phase = phases[phaseName];
    if (!phase || typeof phase !== 'object') continue;
    const script = phase.narrationScript;
    if (script == null) continue;
    if (!Array.isArray(script)) {
      warnings.push(`${source}: phase ${phaseName} has non-array narrationScript`);
      continue;
    }

    const seenKeys = new Set();
    for (let i = 0; i < script.length; i++) {
      const entry = script[i];
      if (!entry || typeof entry !== 'object') {
        warnings.push(`${source}: ${phaseName} narrationScript[${i}] is not an object`);
        continue;
      }
      const at = entry.at;
      const text = entry.text;
      if (typeof at !== 'string') {
        warnings.push(`${source}: ${phaseName} narrationScript[${i}] missing/invalid "at"`);
        continue;
      }
      if (typeof text !== 'string') {
        warnings.push(`${source}: ${phaseName} narrationScript[${i}] missing/invalid "text"`);
        continue;
      }
      if (!text.trim()) {
        warnings.push(`${source}: ${phaseName} narrationScript[${i}] has empty text`);
        continue;
      }

      let cueKey = stableKey(at, i);
      if (seenKeys.has(cueKey)) {
        const original = cueKey;
        let n = 2;
        while (seenKeys.has(`${original}_${n}`)) n++;
        cueKey = `${original}_${n}`;
        warnings.push(
          `${source}: ${phaseName} had duplicate cue key "${original}" — disambiguated as "${cueKey}"`
        );
      }
      seenKeys.add(cueKey);

      const cue = {
        cueId: `lesson:${lessonId}:${phaseName}:${cueKey}`,
        voiceProfile,
        locale,
        text,
        source,
      };
      if (narratorCharacter) cue.narratorCharacter = narratorCharacter;
      const slots = extractSlots(text);
      if (slots.length) cue.slotPlaceholders = slots;
      cues.push(cue);
    }
  }

  return cues;
}

function harvestActivityNarration(doc, source, defaultLocale, warnings, errors) {
  const cues = [];

  const activityId = doc.activity;
  if (typeof activityId !== 'string') {
    errors.push(`${source}: missing required field "activity"`);
    return cues;
  }
  const defaultVoiceProfile = doc.voiceProfile;
  if (typeof defaultVoiceProfile !== 'string') {
    errors.push(`${source}: missing required field "voiceProfile"`);
    return cues;
  }
  const docLocale = typeof doc.locale === 'string' ? doc.locale : defaultLocale;
  const narratorCharacter =
    typeof doc.narratorCharacter === 'string' ? doc.narratorCharacter : null;

  if (!Array.isArray(doc.cues)) {
    errors.push(`${source}: missing or invalid "cues" array`);
    return cues;
  }

  const seenIds = new Set();

  for (let i = 0; i < doc.cues.length; i++) {
    const entry = doc.cues[i];
    if (!entry || typeof entry !== 'object') {
      warnings.push(`${source}: cues[${i}] is not an object`);
      continue;
    }
    const { id, event, text } = entry;
    if (typeof id !== 'string') {
      warnings.push(`${source}: cues[${i}] missing "id"`);
      continue;
    }
    if (typeof event !== 'string') {
      warnings.push(`${source}: cue "${id}" missing "event"`);
      continue;
    }
    if (typeof text !== 'string' || !text.trim()) {
      warnings.push(`${source}: cue "${id}" missing or empty "text"`);
      continue;
    }
    if (seenIds.has(id)) {
      warnings.push(`${source}: duplicate cue id "${id}"`);
      continue;
    }
    seenIds.add(id);

    const voiceProfile =
      typeof entry.voiceProfile === 'string' ? entry.voiceProfile : defaultVoiceProfile;
    const cueId = `activity:${activityId}:${id}`;

    const cue = {
      cueId,
      voiceProfile,
      locale: docLocale,
      text,
      source,
    };
    if (narratorCharacter) cue.narratorCharacter = narratorCharacter;

    const slots = extractSlots(text);
    if (slots.length) cue.slotPlaceholders = slots;

    // Verify slot map covers all placeholders.
    if (entry.slotSource && typeof entry.slotSource === 'object') {
      for (const slotName of slots) {
        if (!Object.prototype.hasOwnProperty.call(entry.slotSource, slotName)) {
          warnings.push(
            `${source}: cue "${id}" text uses {${slotName}} but slotSource has no entry for it`
          );
        }
      }
    }

    cues.push(cue);
  }

  return cues;
}

async function walkActivityNarration(repoRoot, locale, verbose, warnings, errors) {
  const dir = path.join(repoRoot, 'content', 'strings', locale, 'activities');
  if (!existsSync(dir)) {
    warnings.push(`Activity narration directory not found: ${dir} (skipping)`);
    return [];
  }
  const cues = [];
  const entries = (await readdir(dir))
    .filter((e) => e.endsWith('.json') && !e.startsWith('.'))
    .sort();

  for (const name of entries) {
    if (verbose) console.log(`Walking: content/strings/${locale}/activities/${name}`);
    try {
      const raw = await readFile(path.join(dir, name), 'utf8');
      const json = JSON.parse(raw);
      if (typeof json !== 'object' || json == null || Array.isArray(json)) {
        errors.push(`content/strings/${locale}/activities/${name}: root is not an object`);
        continue;
      }
      cues.push(
        ...harvestActivityNarration(json, `activity-narration/${name}`, locale, warnings, errors)
      );
    } catch (e) {
      errors.push(`content/strings/${locale}/activities/${name}: parse failed: ${e.message}`);
    }
  }
  return cues;
}

async function walkLessonRuntimes(repoRoot, locale, verbose, warnings, errors) {
  const dir = path.join(repoRoot, 'data', 'lesson-runtime');
  if (!existsSync(dir)) {
    errors.push(`Lesson runtime directory not found: ${dir}`);
    return [];
  }
  const cues = [];
  const entries = (await readdir(dir))
    .filter((e) => e.endsWith('.json') && !e.startsWith('.'))
    .sort();

  for (const name of entries) {
    if (verbose) console.log(`Walking: data/lesson-runtime/${name}`);
    try {
      const raw = await readFile(path.join(dir, name), 'utf8');
      const json = JSON.parse(raw);
      if (typeof json !== 'object' || json == null || Array.isArray(json)) {
        errors.push(`data/lesson-runtime/${name}: root is not an object`);
        continue;
      }
      cues.push(
        ...harvestLessonRuntime(json, `lesson-runtime/${name}`, locale, warnings, errors)
      );
    } catch (e) {
      errors.push(`data/lesson-runtime/${name}: parse failed: ${e.message}`);
    }
  }
  return cues;
}

// ---------- Aggregations ----------

function sortDesc(map) {
  return Object.fromEntries(
    [...Object.entries(map)].sort((a, b) => b[1] - a[1])
  );
}

function buildResult(cues, warnings, errors) {
  const byVoice = {};
  const charsByVoice = {};
  const bySource = {};
  const byLesson = {};
  const cueIdCount = {};
  let totalChars = 0;
  let cuesWithSlots = 0;

  for (const c of cues) {
    byVoice[c.voiceProfile] = (byVoice[c.voiceProfile] || 0) + 1;
    charsByVoice[c.voiceProfile] = (charsByVoice[c.voiceProfile] || 0) + c.text.length;
    const cat = c.source.split('/')[0];
    bySource[cat] = (bySource[cat] || 0) + 1;
    const parts = c.cueId.split(':');
    if (parts[0] === 'lesson' && parts[1]) {
      byLesson[parts[1]] = (byLesson[parts[1]] || 0) + 1;
    }
    cueIdCount[c.cueId] = (cueIdCount[c.cueId] || 0) + 1;
    totalChars += c.text.length;
    if (c.slotPlaceholders) cuesWithSlots++;
  }

  const duplicateCueIds = Object.fromEntries(
    Object.entries(cueIdCount).filter(([, count]) => count > 1)
  );

  return {
    generatedAt: new Date().toISOString(),
    totalCues: cues.length,
    totalChars,
    cuesWithSlots,
    byVoice: sortDesc(byVoice),
    charsByVoice: sortDesc(charsByVoice),
    bySource: sortDesc(bySource),
    byLesson: sortDesc(byLesson),
    duplicateCueIds,
    warnings,
    errors,
    cues,
  };
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node verify-harvest.mjs [--repo-root PATH] [--out PATH] [--locale CODE] [-v]');
    process.exit(0);
  }

  const warnings = [];
  const errors = [];

  const cues = [];
  cues.push(
    ...(await walkLessonRuntimes(args.repoRoot, args.locale, args.verbose, warnings, errors))
  );
  cues.push(
    ...(await walkActivityNarration(args.repoRoot, args.locale, args.verbose, warnings, errors))
  );

  const result = buildResult(cues, warnings, errors);

  await writeFile(args.out, JSON.stringify(result, null, 2));

  // Console summary
  console.log('');
  console.log('Harvest complete.');
  console.log(`  Locale:       ${args.locale}`);
  console.log(`  Total cues:   ${result.totalCues}`);
  console.log(`  Total chars:  ${result.totalChars}`);
  console.log(`  With slots:   ${result.cuesWithSlots} (need slot-fill expansion)`);
  console.log('');
  console.log('By voice profile:');
  for (const [voice, count] of Object.entries(result.byVoice)) {
    const chars = result.charsByVoice[voice] || 0;
    console.log(`  ${voice}: ${count} cues, ${chars} chars`);
  }
  console.log('');
  console.log('By source category:');
  for (const [source, count] of Object.entries(result.bySource)) {
    console.log(`  ${source}: ${count} cues`);
  }
  console.log('');
  console.log('Per-lesson cue counts (top 10):');
  const entries = Object.entries(result.byLesson).slice(0, 10);
  for (const [lesson, count] of entries) {
    console.log(`  ${lesson}: ${count}`);
  }
  if (Object.keys(result.byLesson).length > 10) {
    console.log(`  ... and ${Object.keys(result.byLesson).length - 10} more lessons.`);
  }
  console.log('');

  if (Object.keys(result.duplicateCueIds).length) {
    console.log('⚠ Duplicate cue IDs:');
    for (const [cueId, n] of Object.entries(result.duplicateCueIds)) {
      console.log(`  ${cueId} × ${n}`);
    }
    console.log('');
  }

  if (warnings.length) {
    console.log(`Warnings (${warnings.length}):`);
    for (const w of warnings) console.log(`  - ${w}`);
    console.log('');
  }

  if (errors.length) {
    console.error(`Errors (${errors.length}):`);
    for (const e of errors) console.error(`  - ${e}`);
    console.error('');
  }

  console.log(`Manifest written to: ${args.out}`);
  process.exit(errors.length ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
