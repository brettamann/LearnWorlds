#!/usr/bin/env node
// TTS Pipeline — Stage 5 (ManifestUpdater)
//
// Walks the rendered audio files under assets/, cross-references each against
// the canonical manifest (Stage 2) to recover cueId + voice profile + text,
// and produces:
//   1. Per-folder manifests at assets/{category}/{thing}/narration/{locale}/manifest.json
//   2. A global runtime manifest at assets/narration-manifest.json
//
// The runtime's AssetPathResolver loads the global manifest at boot and uses it
// to map cueIds to audio file paths.
//
// See specs/shared/voice-pipeline.md and specs/shared/asset-paths.md.
//
// Usage:
//   node build-manifests.mjs [--canonical PATH] [--assets-root PATH] [-v]

import { readFile, writeFile, readdir, stat, mkdir } from 'node:fs/promises';
import { existsSync, createReadStream } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT_DEFAULT = path.resolve(__dirname, '..', '..');

// ---------- CLI ----------

function parseArgs(argv) {
  const args = {
    canonical: path.resolve(__dirname, 'canonical-manifest.json'),
    assetsRoot: REPO_ROOT_DEFAULT,
    verbose: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--canonical') args.canonical = path.resolve(argv[++i]);
    else if (a === '--assets-root') args.assetsRoot = path.resolve(argv[++i]);
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

async function sha256File(filePath) {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256');
    const stream = createReadStream(filePath);
    stream.on('data', (chunk) => hash.update(chunk));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

function toForward(p) {
  return p.replace(/\\/g, '/');
}

// Walk a directory tree for files matching a predicate.
async function walkFiles(rootDir, predicate) {
  const out = [];
  async function recurse(dir) {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const e of entries) {
      if (e.name.startsWith('.')) continue;
      const full = path.join(dir, e.name);
      if (e.isDirectory()) await recurse(full);
      else if (e.isFile() && predicate(full)) out.push(full);
    }
  }
  await recurse(rootDir);
  return out;
}

function audioExtRe(p) {
  return /\.(mp3|m4a)$/i.test(p);
}

// Parse a narration audio path back into { category, asset, locale, fileBase }.
// Patterns we handle:
//   assets/lessons/{id}/narration/{locale}/{base}.{ext}
//   assets/activities/{id}/narration/{locale}/{base}.{ext}
//   assets/shared/region-narrators/{locale}/{voice}/{base}.{ext}
//   assets/shared/region-narrators/{locale}/{voice}/numerals/{base}.{ext}
function classifyNarrationPath(absPath, assetsRoot) {
  const rel = toForward(path.relative(assetsRoot, absPath));
  const parts = rel.split('/');
  if (parts[0] !== 'assets') return null;
  if (parts[1] === 'lessons' && parts[3] === 'narration') {
    return {
      category: 'lessons',
      asset: parts[2],
      narrationDir: `assets/lessons/${parts[2]}/narration/${parts[4]}`,
      locale: parts[4],
      fileBase: parts.slice(5).join('/'),
    };
  }
  if (parts[1] === 'activities' && parts[3] === 'narration') {
    return {
      category: 'activities',
      asset: parts[2],
      narrationDir: `assets/activities/${parts[2]}/narration/${parts[4]}`,
      locale: parts[4],
      fileBase: parts.slice(5).join('/'),
    };
  }
  if (parts[1] === 'shared' && parts[2] === 'region-narrators') {
    // assets/shared/region-narrators/{locale}/{voice}/[numerals/]?{base}
    const locale = parts[3];
    const voice = parts[4];
    const tail = parts.slice(5).join('/');
    return {
      category: 'region-narrators',
      asset: voice,
      narrationDir: `assets/shared/region-narrators/${locale}/${voice}`,
      locale,
      fileBase: tail,
    };
  }
  return null;
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node build-manifests.mjs [--canonical PATH] [--assets-root PATH] [-v]');
    process.exit(0);
  }

  // Load the canonical manifest so we can map output-paths back to cueIds + text + voice.
  if (!existsSync(args.canonical)) {
    console.error(`Canonical manifest not found: ${args.canonical}`);
    console.error('Run Stage 2 (canonicalize.mjs) first.');
    process.exit(2);
  }
  const canonical = JSON.parse(await readFile(args.canonical, 'utf8'));

  // Index canonical entries by both their .m4a and .mp3 output paths so we
  // recognize either rendered format.
  const cueByPath = new Map();
  for (const c of canonical.cues) {
    const m4a = toForward(c.outputFile);
    const mp3 = m4a.replace(/\.m4a$/i, '.mp3');
    cueByPath.set(m4a, { source: 'cue', entry: c });
    cueByPath.set(mp3, { source: 'cue', entry: c });
  }
  for (const d of canonical.digitLibrary || []) {
    const m4a = toForward(d.outputFile);
    const mp3 = m4a.replace(/\.m4a$/i, '.mp3');
    cueByPath.set(m4a, { source: 'digit', entry: d });
    cueByPath.set(mp3, { source: 'digit', entry: d });
  }

  // Walk all narration directories under assets/.
  const audioFiles = await walkFiles(path.join(args.assetsRoot, 'assets'), audioExtRe);
  if (args.verbose) console.log(`Found ${audioFiles.length} audio file(s) under assets/`);

  // Build per-folder + global manifest data.
  const perFolderEntries = new Map(); // narrationDir -> entries array
  const globalEntries = {}; // cueId -> entry
  const orphans = []; // audio files we couldn't tie back to a canonical entry
  let totalBytes = 0;

  for (const absPath of audioFiles) {
    const rel = toForward(path.relative(args.assetsRoot, absPath));
    const classification = classifyNarrationPath(absPath, args.assetsRoot);
    if (!classification) {
      // Not under a recognized narration path.
      continue;
    }

    const lookup = cueByPath.get(rel);
    if (!lookup) {
      orphans.push(rel);
      continue;
    }
    const { source, entry } = lookup;

    const st = await stat(absPath);
    const sha = await sha256File(absPath);

    let cueId, text, voiceProfile, locale;
    if (source === 'cue') {
      cueId = entry.expandedCueId;
      text = entry.expandedText;
      voiceProfile = entry.voiceProfile;
      locale = entry.locale;
    } else {
      // digit library entry
      cueId = `digit:${entry.voiceProfile}:${entry.digit}`;
      text = entry.text;
      voiceProfile = entry.voiceProfile;
      locale = entry.locale;
    }

    const perFolderEntry = {
      cueId,
      file: path.basename(rel),
      text,
      voiceProfile,
      locale,
      size: st.size,
      sha256: sha,
    };

    const dir = classification.narrationDir;
    if (!perFolderEntries.has(dir)) perFolderEntries.set(dir, []);
    perFolderEntries.get(dir).push(perFolderEntry);

    // Global manifest is tight: only what runtime needs to play the audio.
    globalEntries[cueId] = {
      file: rel,
      size: st.size,
      sha256: sha,
      voiceProfile,
      locale,
    };

    totalBytes += st.size;
  }

  // Sort per-folder entries by cueId for deterministic output.
  for (const arr of perFolderEntries.values()) {
    arr.sort((a, b) => a.cueId.localeCompare(b.cueId));
  }

  // Write per-folder manifests.
  let foldersWritten = 0;
  for (const [narrationDir, entries] of perFolderEntries.entries()) {
    const manifestPath = path.join(args.assetsRoot, narrationDir, 'manifest.json');
    const sample = entries[0];
    const manifest = {
      $schema: '../../../../schemas/narration-folder-manifest.schema.json',
      narrationDir,
      locale: sample.locale,
      voiceProfile: sample.voiceProfile,
      version: 1,
      generatedAt: new Date().toISOString(),
      entryCount: entries.length,
      totalBytes: entries.reduce((s, e) => s + e.size, 0),
      entries,
    };
    await mkdir(path.dirname(manifestPath), { recursive: true });
    await writeFile(manifestPath, JSON.stringify(manifest, null, 2));
    foldersWritten++;
    if (args.verbose) console.log(`Wrote ${narrationDir}/manifest.json (${entries.length} entries)`);
  }

  // Roll up locale/voice stats for the global manifest.
  const byLocale = {};
  const byVoice = {};
  for (const e of Object.values(globalEntries)) {
    byLocale[e.locale] = (byLocale[e.locale] || 0) + 1;
    byVoice[e.voiceProfile] = (byVoice[e.voiceProfile] || 0) + 1;
  }

  // Write global runtime manifest.
  const globalManifestPath = path.join(args.assetsRoot, 'assets', 'narration-manifest.json');
  const globalManifest = {
    version: 1,
    generatedAt: new Date().toISOString(),
    sourceCanonicalHash: canonical.sourceManifestHash,
    totalEntries: Object.keys(globalEntries).length,
    totalAudioBytes: totalBytes,
    byLocale,
    byVoice,
    entries: globalEntries,
  };
  await mkdir(path.dirname(globalManifestPath), { recursive: true });
  await writeFile(globalManifestPath, JSON.stringify(globalManifest, null, 2));

  // Console summary.
  console.log('');
  console.log('Manifest build complete.');
  console.log(`  Audio files found:      ${audioFiles.length}`);
  console.log(`  Cataloged in manifest:  ${Object.keys(globalEntries).length}`);
  console.log(`  Orphans (no canonical): ${orphans.length}`);
  console.log(`  Per-folder manifests:   ${foldersWritten}`);
  console.log(`  Total audio bytes:      ${totalBytes.toLocaleString()}`);
  console.log('');
  if (Object.keys(byLocale).length > 0) {
    console.log('By locale:');
    for (const [loc, n] of Object.entries(byLocale)) console.log(`  ${loc}: ${n}`);
    console.log('');
  }
  if (Object.keys(byVoice).length > 0) {
    console.log('By voice profile:');
    for (const [v, n] of Object.entries(byVoice)) console.log(`  ${v}: ${n}`);
    console.log('');
  }
  if (orphans.length > 0) {
    console.log(`⚠ ${orphans.length} orphan file(s) — present on disk but no canonical entry (showing first 10):`);
    for (const o of orphans.slice(0, 10)) console.log(`  ${o}`);
    if (orphans.length > 10) console.log(`  ... and ${orphans.length - 10} more`);
    console.log('');
    console.log('Orphans usually mean Stage 1/2 narration changed but old .mp3 files weren\'t cleaned up.');
    console.log('');
  }
  console.log(`Global manifest:  ${toForward(path.relative(args.assetsRoot, globalManifestPath))}`);
  console.log(`Per-folder:       ${foldersWritten} written`);

  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
