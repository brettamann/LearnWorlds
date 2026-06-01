#!/usr/bin/env node
// TTS Pipeline — Stage 2 (Canonicalizer)
//
// Reads the harvest manifest from Stage 1, expands every {slot} placeholder
// per the slot-vocabulary expansion strategy, and produces a canonical manifest
// where every concrete TTS render job is enumerated.
//
// Output is what Stage 3 (CacheChecker) and Stage 4 (TTSGenerator) consume.
//
// See specs/shared/voice-pipeline.md and specs/shared/slot-vocabulary.md.
//
// Usage:
//   node canonicalize.mjs [--input PATH] [--vocab PATH] [--out PATH] [--locale CODE] [--max-expansions-per-cue N] [-v]

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ---------- CLI ----------

function parseArgs(argv) {
  const args = {
    input: path.resolve(__dirname, 'harvest-manifest.json'),
    vocab: path.resolve(__dirname, '..', '..', 'data', 'slot-vocabulary'),
    out: path.resolve(__dirname, 'canonical-manifest.json'),
    locale: 'en-US',
    maxExpansionsPerCue: 200,
    verbose: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--input') args.input = path.resolve(argv[++i]);
    else if (a === '--vocab') args.vocab = path.resolve(argv[++i]);
    else if (a === '--out') args.out = path.resolve(argv[++i]);
    else if (a === '--locale') args.locale = argv[++i];
    else if (a === '--max-expansions-per-cue') args.maxExpansionsPerCue = Number(argv[++i]);
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

function fileSafeSlug(value) {
  // Convert a slot value into a file-safe slug.
  // "apple slices" → "apple-slices", "5" → "5", "in front of" → "in-front-of"
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function extractSlotsInOrder(text) {
  // Returns ordered list of slot names appearing in the text (preserves repeats).
  const re = /\{([A-Za-z_][A-Za-z0-9_]*)\}/g;
  const out = [];
  let m;
  while ((m = re.exec(text)) !== null) out.push(m[1]);
  return out;
}

function uniqueSlots(text) {
  return Array.from(new Set(extractSlotsInOrder(text))).sort();
}

function substituteSlot(text, slotName, value) {
  return text.replace(new RegExp(`\\{${slotName}\\}`, 'g'), String(value));
}

// Cartesian product of N arrays.
function cartesian(arrays) {
  return arrays.reduce(
    (acc, curr) => acc.flatMap((a) => curr.map((c) => [...a, c])),
    [[]],
  );
}

// ---------- Vocabulary resolution ----------

class VocabularyResolver {
  constructor(vocabFile) {
    this.locale = vocabFile.locale;
    this.aliases = vocabFile.aliases || {};
    this.vocabularies = vocabFile.vocabularies || {};
  }

  // Resolve a slot name (potentially an alias) to its canonical id.
  toCanonical(slotName) {
    return this.aliases[slotName] || slotName;
  }

  // Resolve to canonical AND look up its vocabulary entry.
  // Returns null if not found.
  entry(slotName) {
    const id = this.toCanonical(slotName);
    return this.vocabularies[id] || null;
  }

  // Get all expansion values for a slot, paired with their file-safe slugs.
  // Returns array of { value: string, slug: string, audioValue: string }.
  // audioValue = what the TTS renders (e.g., "five" for spokenAs: numeral-as-word).
  expansionValues(slotName) {
    const entry = this.entry(slotName);
    if (!entry) return [];

    const strategy = entry.ttsExpansionStrategy || 'expand-per-value';
    if (strategy === 'runtime-only') return []; // not expanded offline

    // Enumerated string/enum values.
    if (Array.isArray(entry.values)) {
      return entry.values.map((v) => ({
        value: v,
        slug: fileSafeSlug(v),
        audioValue: v,
      }));
    }

    // Derived slot — values is a map from source value to this slot's value.
    if (entry.derivedFrom && typeof entry.values === 'object') {
      return Object.entries(entry.values).map(([sourceValue, derivedValue]) => ({
        value: derivedValue,
        slug: fileSafeSlug(derivedValue),
        audioValue: derivedValue,
        derivedFromValue: sourceValue,
      }));
    }

    // Integer range with optional practicalRange.
    if (entry.type === 'integer' && entry.range) {
      const min = entry.practicalRange?.min ?? entry.range.min;
      const max = entry.practicalRange?.max ?? entry.range.max;
      const numeralWord = entry.spokenAs === 'numeral-as-word';
      const out = [];
      for (let n = min; n <= max; n++) {
        out.push({
          value: String(n),
          slug: String(n),
          audioValue: numeralWord ? numeralToWord(n) : String(n),
        });
      }
      return out;
    }

    return [];
  }

  // For derived slots (e.g., creatureSpeciesPlural derived from creatureSpecies),
  // return the source slot's canonical id. Null if not derived.
  derivedFrom(slotName) {
    const entry = this.entry(slotName);
    return entry?.derivedFrom || null;
  }
}

// Numeral → English word (0–100). For other locales, this is per-locale.
function numeralToWord(n) {
  if (n < 0 || n > 100 || !Number.isInteger(n)) return String(n);
  const ones = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
    'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
  const tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
  if (n < 20) return ones[n];
  if (n === 100) return 'one hundred';
  const t = Math.floor(n / 10);
  const o = n % 10;
  return o === 0 ? tens[t] : `${tens[t]}-${ones[o]}`;
}

// ---------- Canonicalization ----------

function groupDerivedSlots(slotNames, resolver) {
  // Slots that derive from a common source must expand together (e.g., creatureSpecies and creatureSpeciesPlural
  // both expand from the same source value, not independently). We group them into "expansion groups".
  //
  // Returns array of groups. Each group is { sourceSlotId, slots: [slotNameUsedInText, ...] }.
  // Slots that don't derive from anything become their own one-element group.

  const groups = new Map();
  const standalone = [];

  for (const slotName of slotNames) {
    const canonical = resolver.toCanonical(slotName);
    const entry = resolver.entry(slotName);
    if (!entry) {
      // Unknown slot; treat as standalone, will warn later.
      standalone.push({ sourceSlotId: canonical, slots: [slotName] });
      continue;
    }
    const derivedFrom = entry.derivedFrom;
    if (derivedFrom) {
      if (!groups.has(derivedFrom)) groups.set(derivedFrom, { sourceSlotId: derivedFrom, slots: [] });
      groups.get(derivedFrom).slots.push(slotName);
    } else {
      // This slot IS its own source. Check if any other slot derives from it.
      if (!groups.has(canonical)) groups.set(canonical, { sourceSlotId: canonical, slots: [] });
      groups.get(canonical).slots.push(slotName);
    }
  }

  // Standalone slots that aren't part of any group already.
  for (const s of standalone) {
    if (!groups.has(s.sourceSlotId)) {
      groups.set(s.sourceSlotId, s);
    }
  }

  return Array.from(groups.values());
}

function expansionsForGroup(group, resolver, warnings, cueIdForWarning) {
  // Produce list of { bindings: {slotName: {value, slug, audioValue}}, sourceValue }.
  // For grouped slots, sourceValue drives the binding for all slots in the group.
  const sourceId = group.sourceSlotId;
  const sourceEntry = resolver.vocabularies[sourceId];

  // If the source slot doesn't exist in vocabularies but the slot itself does (e.g., the slot in the text IS the source),
  // fall back to the first slot in the group.
  let sourceValues;
  if (sourceEntry) {
    sourceValues = resolver.expansionValues(sourceId);
  } else {
    // Try the first slot in the group as the source.
    sourceValues = resolver.expansionValues(group.slots[0]);
  }

  if (sourceValues.length === 0) {
    // Either runtime-only (skip) or unknown slot (warn).
    if (!sourceEntry && group.slots.length > 0) {
      const slotName = group.slots[0];
      const canonical = resolver.toCanonical(slotName);
      if (canonical === slotName) {
        warnings.push(`${cueIdForWarning}: unknown slot {${slotName}} (no vocabulary entry; not in aliases)`);
      } else {
        warnings.push(`${cueIdForWarning}: slot {${slotName}} aliases to "${canonical}" but no vocabulary entry exists`);
      }
    }
    return [];
  }

  // For each source value, build bindings for every slot in the group.
  return sourceValues.map((sourceVal) => {
    const bindings = {};
    for (const slotName of group.slots) {
      const slotEntry = resolver.entry(slotName);
      if (slotEntry?.derivedFrom) {
        // Look up the derived value via the source.
        const derivedValues = resolver.expansionValues(slotName);
        // Match sourceVal.value to derivedFromValue.
        const match = derivedValues.find((dv) => dv.derivedFromValue === sourceVal.value);
        bindings[slotName] = match || { value: sourceVal.value, slug: sourceVal.slug, audioValue: sourceVal.value };
      } else {
        bindings[slotName] = sourceVal;
      }
    }
    return { bindings, sourceValue: sourceVal.value };
  });
}

// Strategy classification per slot. Returns one of:
//   'expand-per-value' — cartesian-expand over this slot's values
//   'digit-stitched'   — replace with <break/>; runtime concatenates from digit library
//   'runtime-only'     — leave placeholder intact; runtime substitutes at speak time
//   'unknown'          — slot not in vocabulary; warn and leave intact
function strategyForSlot(slotName, resolver) {
  const entry = resolver.entry(slotName);
  if (!entry) return 'unknown';
  return entry.ttsExpansionStrategy || 'expand-per-value';
}

// SSML pause marker for stitched-numeral slots. The TTS engine produces a brief
// silence at this position; the runtime overlays the corresponding numeral.m4a.
const STITCH_BREAK = '<break time="500ms"/>';

function canonicalizeCue(cue, resolver, maxExpansionsPerCue, warnings) {
  const slotNamesInOrder = extractSlotsInOrder(cue.text);
  const uniq = Array.from(new Set(slotNamesInOrder));

  if (uniq.length === 0) {
    return [{
      originalCueId: cue.cueId,
      expandedCueId: cue.cueId,
      voiceProfile: cue.voiceProfile,
      narratorCharacter: cue.narratorCharacter,
      locale: cue.locale,
      expandedText: cue.text,
      source: cue.source,
      slotBindings: {},
      renderStrategy: 'full-render',
    }];
  }

  // Classify each slot by strategy.
  const strategies = {};
  for (const s of uniq) strategies[s] = strategyForSlot(s, resolver);

  // Buckets.
  const expandSlots = uniq.filter((s) => strategies[s] === 'expand-per-value');
  const stitchSlots = uniq.filter((s) => strategies[s] === 'digit-stitched');
  const runtimeOnly = uniq.filter((s) => strategies[s] === 'runtime-only');
  const unknown = uniq.filter((s) => strategies[s] === 'unknown');

  for (const s of unknown) {
    const canonical = resolver.toCanonical(s);
    if (canonical === s) {
      warnings.push(`${cue.cueId}: unknown slot {${s}} (no vocabulary entry; not in aliases)`);
    } else {
      warnings.push(`${cue.cueId}: slot {${s}} aliases to "${canonical}" but no vocabulary entry exists`);
    }
  }

  // If the cue has no expand-per-value slots, it's a single template variant.
  if (expandSlots.length === 0) {
    let expandedText = cue.text;
    const stitchBindings = {};
    for (const s of stitchSlots) {
      expandedText = substituteSlot(expandedText, s, STITCH_BREAK);
      stitchBindings[s] = { strategy: 'digit-stitched', canonical: resolver.toCanonical(s) };
    }
    // Runtime-only slots stay as placeholders.

    const stitched = stitchSlots.length > 0;
    const runtimeTemplating = runtimeOnly.length > 0;

    let renderStrategy = 'full-render';
    if (stitched && runtimeTemplating) renderStrategy = 'digit-stitched+runtime-template';
    else if (stitched) renderStrategy = 'digit-stitched-template';
    else if (runtimeTemplating) renderStrategy = 'runtime-template';

    return [{
      originalCueId: cue.cueId,
      expandedCueId: cue.cueId,
      voiceProfile: cue.voiceProfile,
      narratorCharacter: cue.narratorCharacter,
      locale: cue.locale,
      expandedText,
      source: cue.source,
      slotBindings: {},
      renderStrategy,
      ...(stitched ? { stitchedSlots: stitchSlots.map((s) => resolver.toCanonical(s)) } : {}),
      ...(runtimeTemplating ? { runtimeOnlySlots: runtimeOnly } : {}),
    }];
  }

  // Group derived expand-per-value slots together so they expand jointly.
  const groups = groupDerivedSlots(expandSlots, resolver);

  const groupExpansions = [];
  for (const group of groups) {
    const exps = expansionsForGroup(group, resolver, warnings, cue.cueId);
    if (exps.length === 0) {
      groupExpansions.push([{ bindings: Object.fromEntries(group.slots.map((s) => [s, null])), sourceValue: null }]);
    } else {
      groupExpansions.push(exps);
    }
  }

  const products = cartesian(groupExpansions);

  if (products.length > maxExpansionsPerCue) {
    warnings.push(
      `${cue.cueId}: ${products.length} expand-per-value combinations exceeds cap of ${maxExpansionsPerCue}; consider whether so many expand-per-value slots really belong in one cue`,
    );
  }

  return products.map((combo) => {
    const allBindings = {};
    for (const groupBindings of combo) {
      Object.assign(allBindings, groupBindings.bindings);
    }

    let expandedText = cue.text;
    // Substitute expand-per-value slots.
    for (const s of expandSlots) {
      const binding = allBindings[s];
      if (binding) expandedText = substituteSlot(expandedText, s, binding.audioValue);
    }
    // Replace digit-stitched slots with break markers.
    for (const s of stitchSlots) {
      expandedText = substituteSlot(expandedText, s, STITCH_BREAK);
    }
    // Runtime-only slots stay as placeholders.

    const slugs = [];
    for (const s of expandSlots) {
      const b = allBindings[s];
      if (b && b.slug) slugs.push(b.slug);
    }
    const expandedCueId = slugs.length > 0 ? `${cue.cueId}:${slugs.join('+')}` : cue.cueId;

    const stitched = stitchSlots.length > 0;
    const runtimeTemplating = runtimeOnly.length > 0;
    let renderStrategy = 'full-render';
    if (stitched && runtimeTemplating) renderStrategy = 'digit-stitched+runtime-template';
    else if (stitched) renderStrategy = 'digit-stitched-template';
    else if (runtimeTemplating) renderStrategy = 'runtime-template';

    return {
      originalCueId: cue.cueId,
      expandedCueId,
      voiceProfile: cue.voiceProfile,
      narratorCharacter: cue.narratorCharacter,
      locale: cue.locale,
      expandedText,
      source: cue.source,
      slotBindings: Object.fromEntries(
        Object.entries(allBindings)
          .filter(([_, v]) => v != null)
          .map(([k, v]) => [k, v.value]),
      ),
      renderStrategy,
      ...(stitched ? { stitchedSlots: stitchSlots.map((s) => resolver.toCanonical(s)) } : {}),
      ...(runtimeTemplating ? { runtimeOnlySlots: runtimeOnly } : {}),
    };
  });
}

// Build a digit library entry list — one per voice profile, covering integer values 0–N.
// At runtime these audio files fill the <break/> gaps from digit-stitched cues.
function buildDigitLibrary(voiceProfiles, maxNumeral, locale) {
  const entries = [];
  for (const voice of voiceProfiles) {
    for (let n = 0; n <= maxNumeral; n++) {
      entries.push({
        digit: n,
        voiceProfile: voice,
        locale,
        text: numeralToWord(n),
        outputFile: `assets/shared/region-narrators/${locale}/${voice}/numerals/${n}.m4a`,
        renderStrategy: 'full-render',
      });
    }
  }
  return entries;
}

// ---------- Output file path resolution ----------

function outputFilePath(expandedCue) {
  // Build the asset path per specs/shared/asset-paths.md
  // Format: assets/{category}/{slug}/narration/{locale}/{cueSlug}.m4a
  // where {cueSlug} is a file-safe form of the cue's expandedCueId tail.
  //
  // cueId format:
  //   lesson:lesson-k-cc-4a-one-to-one:iShow:t1s:fawns (after expansion)
  //   activity:counting-parade:count-the-parade.round-start:fawns
  //   shared:region-narrator:sanctuary:round-pass

  const parts = expandedCue.expandedCueId.split(':');
  const ns = parts[0];

  if (ns === 'lesson') {
    const lessonId = parts[1];
    const phase = parts[2];
    const tail = parts.slice(3).join('-');
    return `assets/lessons/${lessonId.replace(/^lesson-/, '')}/narration/${expandedCue.locale}/${phase}_${fileSafeSlug(tail)}.m4a`;
  } else if (ns === 'activity') {
    const activityId = parts[1];
    const tail = parts.slice(2).join('-');
    return `assets/activities/${activityId}/narration/${expandedCue.locale}/${fileSafeSlug(tail)}.m4a`;
  } else if (ns === 'shared') {
    const tail = parts.slice(1).join('-');
    return `assets/shared/region-narrators/${expandedCue.locale}/${fileSafeSlug(tail)}.m4a`;
  }
  // Unknown namespace; put it in shared.
  return `assets/shared/${fileSafeSlug(expandedCue.expandedCueId)}_${expandedCue.locale}.m4a`;
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node canonicalize.mjs [--input PATH] [--vocab PATH] [--out PATH] [--locale CODE] [--max-expansions-per-cue N] [-v]');
    process.exit(0);
  }

  // Load harvest manifest.
  const harvestRaw = await readFile(args.input, 'utf8');
  const harvest = JSON.parse(harvestRaw);
  const harvestHash = createHash('sha256').update(harvestRaw).digest('hex').slice(0, 16);

  // Load vocabulary.
  const vocabPath = path.join(args.vocab, `${args.locale}.json`);
  const vocabRaw = await readFile(vocabPath, 'utf8');
  const vocab = JSON.parse(vocabRaw);
  const resolver = new VocabularyResolver(vocab);

  // Canonicalize each cue.
  const warnings = [];
  const expandedCues = [];

  for (const cue of harvest.cues) {
    const expansions = canonicalizeCue(cue, resolver, args.maxExpansionsPerCue, warnings);
    for (const exp of expansions) {
      exp.outputFile = outputFilePath(exp);
    }
    expandedCues.push(...expansions);
  }

  // Build digit library — separate from cues, but rendered through the same TTS pipeline.
  // K range: 0–20 covers most use cases; we use 0–100 to cover any cue with wider digit-stitched range.
  const allVoices = Array.from(new Set(expandedCues.map((c) => c.voiceProfile)));
  const digitLibrary = buildDigitLibrary(allVoices, 100, args.locale);

  // Detect duplicate expandedCueIds.
  const expandedIdCounts = {};
  for (const e of expandedCues) {
    expandedIdCounts[e.expandedCueId] = (expandedIdCounts[e.expandedCueId] || 0) + 1;
  }
  const duplicates = Object.fromEntries(
    Object.entries(expandedIdCounts).filter(([, n]) => n > 1),
  );

  // Detect duplicate outputFile paths.
  const fileCounts = {};
  for (const e of expandedCues) {
    fileCounts[e.outputFile] = (fileCounts[e.outputFile] || 0) + 1;
  }
  const dupFiles = Object.fromEntries(
    Object.entries(fileCounts).filter(([, n]) => n > 1),
  );

  // Aggregations.
  let totalChars = 0;
  const byVoice = {};
  const byRenderStrategy = {};
  const charsByVoice = {};
  for (const e of expandedCues) {
    totalChars += e.expandedText.length;
    byVoice[e.voiceProfile] = (byVoice[e.voiceProfile] || 0) + 1;
    charsByVoice[e.voiceProfile] = (charsByVoice[e.voiceProfile] || 0) + e.expandedText.length;
    byRenderStrategy[e.renderStrategy] = (byRenderStrategy[e.renderStrategy] || 0) + 1;
  }

  const sortDesc = (m) => Object.fromEntries([...Object.entries(m)].sort((a, b) => b[1] - a[1]));

  // Renderable = anything that needs TTS output (full-render OR digit-stitched-template — the latter has actual audio with gaps).
  // Runtime-template-only (no digit stitch, no expand) is skipped entirely — runtime substitutes.
  const renderable = expandedCues.filter(
    (e) => e.renderStrategy === 'full-render' || e.renderStrategy === 'digit-stitched-template' || e.renderStrategy === 'digit-stitched+runtime-template',
  );
  const renderableChars = renderable.reduce((s, c) => s + c.expandedText.length, 0);
  const digitLibraryChars = digitLibrary.reduce((s, e) => s + e.text.length, 0);

  const output = {
    generatedAt: new Date().toISOString(),
    sourceManifest: path.relative(__dirname, args.input),
    sourceManifestHash: harvestHash,
    sourceManifestCueCount: harvest.totalCues,
    locale: args.locale,
    maxExpansionsPerCue: args.maxExpansionsPerCue,
    totalExpandedCues: expandedCues.length,
    renderableCues: renderable.length,
    runtimeTemplateCues: expandedCues.length - renderable.length,
    digitLibraryEntries: digitLibrary.length,
    totalChars,
    renderableChars,
    digitLibraryChars,
    grandTotalRenderableChars: renderableChars + digitLibraryChars,
    byVoice: sortDesc(byVoice),
    charsByVoice: sortDesc(charsByVoice),
    byRenderStrategy: sortDesc(byRenderStrategy),
    duplicateExpandedCueIds: duplicates,
    duplicateOutputFiles: dupFiles,
    warnings,
    cues: expandedCues,
    digitLibrary,
  };

  await writeFile(args.out, JSON.stringify(output, null, 2));

  // Console summary.
  console.log('');
  console.log('Canonicalize complete.');
  console.log(`  Locale:               ${args.locale}`);
  console.log(`  Source cues:          ${harvest.totalCues}`);
  console.log(`  Expanded cues:        ${expandedCues.length}`);
  console.log(`  Renderable cues:      ${renderable.length} (full-render — TTS will produce one .m4a each)`);
  console.log(`  Runtime template:     ${expandedCues.length - renderable.length} (skip TTS; runtime substitutes at speak time)`);
  console.log(`  Total expanded chars: ${totalChars}`);
  console.log(`  Renderable chars:     ${output.renderableChars}`);
  console.log('');
  console.log('By render strategy:');
  for (const [s, c] of Object.entries(output.byRenderStrategy)) {
    console.log(`  ${s}: ${c}`);
  }
  console.log('');
  console.log('By voice profile:');
  for (const [v, c] of Object.entries(output.byVoice)) {
    console.log(`  ${v}: ${c} cues, ${output.charsByVoice[v]} chars`);
  }
  console.log('');

  if (Object.keys(duplicates).length) {
    console.log(`⚠ Duplicate expandedCueId entries: ${Object.keys(duplicates).length}`);
    for (const [id, n] of Object.entries(duplicates).slice(0, 5)) {
      console.log(`  ${id} × ${n}`);
    }
    if (Object.keys(duplicates).length > 5) {
      console.log(`  ... and ${Object.keys(duplicates).length - 5} more.`);
    }
    console.log('');
  }

  if (Object.keys(dupFiles).length) {
    console.log(`⚠ Duplicate output file paths: ${Object.keys(dupFiles).length}`);
    for (const [f, n] of Object.entries(dupFiles).slice(0, 5)) {
      console.log(`  ${f} × ${n}`);
    }
    console.log('');
  }

  if (warnings.length) {
    console.log(`Warnings (${warnings.length}):`);
    for (const w of warnings.slice(0, 20)) console.log(`  - ${w}`);
    if (warnings.length > 20) console.log(`  ... and ${warnings.length - 20} more.`);
    console.log('');
  }

  // ElevenLabs cost projection (Creator tier = 100k chars/mo for $22).
  const tierCharLimits = { creator: 100000, pro: 500000, scale: 2000000 };
  const totalRenderableChars = output.grandTotalRenderableChars;
  let suggestedTier = 'creator';
  if (totalRenderableChars > tierCharLimits.creator) suggestedTier = 'pro';
  if (totalRenderableChars > tierCharLimits.pro) suggestedTier = 'scale';
  console.log(`Digit library (separate render pass):`);
  console.log(`  Entries:           ${digitLibrary.length} (${output.digitLibraryChars} chars)`);
  console.log('');
  console.log(`ElevenLabs cost projection (renderable cues + digit library):`);
  console.log(`  Renderable chars:      ${output.renderableChars.toLocaleString()}`);
  console.log(`  + Digit library chars: ${output.digitLibraryChars.toLocaleString()}`);
  console.log(`  = Grand total:         ${totalRenderableChars.toLocaleString()}`);
  console.log(`  Suggested tier:        ${suggestedTier}`);
  console.log(`    creator: 100k chars/mo @ ~$22`);
  console.log(`    pro:     500k chars/mo @ ~$99`);
  console.log(`    scale:   2M chars/mo @ ~$330`);
  console.log('');

  console.log(`Manifest written to: ${args.out}`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
