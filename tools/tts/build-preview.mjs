#!/usr/bin/env node
// TTS Pipeline — Stage 6 (PreviewBundle)
//
// Generates a self-contained HTML bundle for QA reviewing every narration cue.
// Each cue shows its cueId, text, and an audio player. Filterable by source
// (lesson/activity/digit), voice profile, render strategy, and free-text search.
//
// The bundle works whether 0 or all audio files are rendered — if a file is
// missing, the player just shows the standard "no source" state.
//
// See specs/shared/voice-pipeline.md.
//
// Usage:
//   node build-preview.mjs [--canonical PATH] [--assets-root PATH] [--out PATH]

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT_DEFAULT = path.resolve(__dirname, '..', '..');

// ---------- CLI ----------

function parseArgs(argv) {
  const args = {
    canonical: path.resolve(__dirname, 'canonical-manifest.json'),
    assetsRoot: REPO_ROOT_DEFAULT,
    out: path.resolve(__dirname, 'preview-bundle'),
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--canonical') args.canonical = path.resolve(argv[++i]);
    else if (a === '--assets-root') args.assetsRoot = path.resolve(argv[++i]);
    else if (a === '--out') args.out = path.resolve(argv[++i]);
    else if (a === '-h' || a === '--help') args.help = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(2);
    }
  }
  return args;
}

// ---------- Helpers ----------

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

function categorizeCueId(cueId) {
  // cueId namespaces:
  //   lesson:{lessonId}:{phase}:{key}[:{slug}]
  //   activity:{activityId}:{event-id}[:{slug}]
  //   digit:{voice}:{n}
  const parts = cueId.split(':');
  if (parts[0] === 'lesson') {
    return { source: 'lesson', sourceId: parts[1], group: parts[1] };
  }
  if (parts[0] === 'activity') {
    return { source: 'activity', sourceId: parts[1], group: parts[1] };
  }
  if (parts[0] === 'digit') {
    return { source: 'digit-library', sourceId: parts[1], group: parts[1] };
  }
  return { source: parts[0] || 'unknown', sourceId: 'unknown', group: 'unknown' };
}

function fileExistsRelative(assetsRoot, relPath) {
  if (!relPath) return false;
  try {
    return statSync(path.join(assetsRoot, relPath)).isFile();
  } catch {
    return false;
  }
}

// ---------- HTML / CSS / JS templates ----------

const CSS = `
* { box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  margin: 0;
  background: #fbf6e9;
  color: #2a1f26;
}
header {
  background: #5a8f44;
  color: #fbf6e9;
  padding: 16px 24px;
  position: sticky;
  top: 0;
  z-index: 10;
  border-bottom: 2px solid #3d2b2e;
}
header h1 { margin: 0 0 4px; font-size: 18px; }
header .sub { font-size: 13px; opacity: 0.85; }
.filters {
  padding: 12px 24px;
  background: #fff8dc;
  border-bottom: 1px solid #e0d8b8;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
  position: sticky;
  top: 70px;
  z-index: 9;
}
.filters label { font-size: 13px; }
.filters select, .filters input[type="text"] {
  padding: 6px 10px;
  border: 1px solid #c8a877;
  border-radius: 4px;
  background: white;
  font-family: inherit;
  font-size: 13px;
}
.filters input[type="text"] { min-width: 240px; }
.filters .stats { margin-left: auto; font-size: 12px; color: #5c4d47; }
main { padding: 16px 24px 80px; max-width: 1200px; margin: 0 auto; }
.group { margin: 24px 0; }
.group-header {
  font-size: 15px;
  font-weight: 600;
  border-bottom: 1px solid #c8a877;
  padding-bottom: 4px;
  margin: 0 0 12px;
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}
.group-count { font-size: 12px; color: #999; font-weight: normal; }
.cue {
  background: white;
  border: 1px solid #e0d8b8;
  border-radius: 6px;
  padding: 10px 14px;
  margin: 6px 0;
  display: grid;
  grid-template-columns: 1fr auto;
  grid-template-rows: auto auto;
  gap: 6px 16px;
  align-items: center;
}
.cue .text {
  font-size: 14px;
  line-height: 1.4;
}
.cue .text .ssml { color: #c97a5f; font-style: italic; font-size: 12px; }
.cue .cueId {
  font-family: ui-monospace, Menlo, monospace;
  font-size: 11px;
  color: #888;
  grid-column: 1 / -1;
  word-break: break-all;
}
.cue audio {
  height: 30px;
  width: 240px;
}
.cue.missing audio { display: none; }
.cue.missing .audio-placeholder {
  font-size: 11px;
  color: #b54a4a;
  background: #fde0e0;
  border-radius: 4px;
  padding: 6px 10px;
  white-space: nowrap;
}
.badge {
  display: inline-block;
  padding: 1px 6px;
  border-radius: 3px;
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-right: 4px;
  vertical-align: middle;
}
.badge-voice { background: #6da659; color: white; }
.badge-strategy { background: #8a9099; color: white; }
.badge-locale { background: #c8a877; color: white; }
.no-results { padding: 40px; text-align: center; color: #888; }
`;

function buildHtml(payload) {
  return `<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>CritMath Narration Preview</title>
<style>${CSS}</style>
<header>
  <h1>CritMath Narration Preview</h1>
  <div class="sub">${payload.totalCues} cues across ${payload.groups.length} groups · generated ${escapeHtml(payload.generatedAt)}</div>
</header>
<div class="filters">
  <label>Source: <select id="filter-source">
    <option value="">All sources</option>
    ${payload.sources.map(s => `<option value="${escapeHtml(s)}">${escapeHtml(s)}</option>`).join('')}
  </select></label>
  <label>Group: <select id="filter-group">
    <option value="">All groups</option>
    ${payload.groups.map(g => `<option value="${escapeHtml(g.id)}">${escapeHtml(g.label)}</option>`).join('')}
  </select></label>
  <label>Voice: <select id="filter-voice">
    <option value="">All voices</option>
    ${payload.voices.map(v => `<option value="${escapeHtml(v)}">${escapeHtml(v)}</option>`).join('')}
  </select></label>
  <label>Strategy: <select id="filter-strategy">
    <option value="">All strategies</option>
    ${payload.strategies.map(s => `<option value="${escapeHtml(s)}">${escapeHtml(s)}</option>`).join('')}
  </select></label>
  <label>Status: <select id="filter-status">
    <option value="">All</option>
    <option value="ready">Audio present</option>
    <option value="missing">Audio missing</option>
  </select></label>
  <input type="text" id="filter-text" placeholder="Search text…">
  <div class="stats" id="stats"></div>
</div>
<main id="main"></main>
<script>
const data = ${JSON.stringify(payload)};
function applyFilters() {
  const src = document.getElementById('filter-source').value;
  const grp = document.getElementById('filter-group').value;
  const voice = document.getElementById('filter-voice').value;
  const strat = document.getElementById('filter-strategy').value;
  const status = document.getElementById('filter-status').value;
  const q = document.getElementById('filter-text').value.toLowerCase();
  let shown = 0;
  const main = document.getElementById('main');
  const groups = {};
  for (const cue of data.cues) {
    if (src && cue.source !== src) continue;
    if (grp && cue.group !== grp) continue;
    if (voice && cue.voiceProfile !== voice) continue;
    if (strat && cue.renderStrategy !== strat) continue;
    if (status === 'ready' && !cue.audioReady) continue;
    if (status === 'missing' && cue.audioReady) continue;
    if (q && !cue.text.toLowerCase().includes(q) && !cue.cueId.toLowerCase().includes(q)) continue;
    if (!groups[cue.group]) groups[cue.group] = [];
    groups[cue.group].push(cue);
    shown++;
  }
  document.getElementById('stats').textContent = shown + ' shown';
  if (shown === 0) {
    main.innerHTML = '<div class="no-results">No cues match the current filters.</div>';
    return;
  }
  const html = [];
  for (const groupId of Object.keys(groups).sort()) {
    const cues = groups[groupId];
    const groupLabel = (data.groups.find(g => g.id === groupId) || {}).label || groupId;
    html.push('<section class="group">');
    html.push('<h2 class="group-header"><span>' + escapeAttr(groupLabel) + '</span><span class="group-count">' + cues.length + ' cue' + (cues.length === 1 ? '' : 's') + '</span></h2>');
    for (const cue of cues) {
      html.push(renderCue(cue));
    }
    html.push('</section>');
  }
  main.innerHTML = html.join('');
}
function escapeAttr(s) {
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
function renderCue(cue) {
  // Highlight SSML break markers visually.
  const textHtml = escapeAttr(cue.text).replace(/&lt;break time=&quot;\\d+ms&quot;\\/&gt;/g, m => '<span class="ssml">' + m + '</span>');
  const ready = cue.audioReady;
  return ['<div class="cue' + (ready ? '' : ' missing') + '">',
    '<div class="text">',
      '<span class="badge badge-voice">' + escapeAttr(cue.voiceProfile.split('-')[0]) + '</span>',
      '<span class="badge badge-strategy">' + escapeAttr(cue.renderStrategy) + '</span>',
      '<span class="badge badge-locale">' + escapeAttr(cue.locale) + '</span>',
      textHtml,
    '</div>',
    ready
      ? '<audio controls preload="none" src="' + escapeAttr(cue.audioSrc) + '"></audio>'
      : '<div class="audio-placeholder">not rendered yet</div>',
    '<div class="cueId">' + escapeAttr(cue.cueId) + '</div>',
  '</div>'].join('');
}
for (const id of ['filter-source','filter-group','filter-voice','filter-strategy','filter-status']) {
  document.getElementById(id).addEventListener('change', applyFilters);
}
document.getElementById('filter-text').addEventListener('input', applyFilters);
applyFilters();
</script>
</html>`;
}

// ---------- Main ----------

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node build-preview.mjs [--canonical PATH] [--assets-root PATH] [--out PATH]');
    process.exit(0);
  }

  if (!existsSync(args.canonical)) {
    console.error(`Canonical manifest not found: ${args.canonical}`);
    console.error('Run Stage 2 (canonicalize.mjs) first.');
    process.exit(2);
  }
  const canonical = JSON.parse(await readFile(args.canonical, 'utf8'));

  // Build flat cue list from canonical + digit library.
  const allCues = [];
  for (const c of canonical.cues) {
    const m4a = c.outputFile;
    const mp3 = m4a.replace(/\.m4a$/i, '.mp3');
    // Prefer .mp3 if it exists (default render format), otherwise .m4a.
    const mp3Exists = fileExistsRelative(args.assetsRoot, mp3);
    const m4aExists = fileExistsRelative(args.assetsRoot, m4a);
    const audioReady = mp3Exists || m4aExists;
    const audioFile = mp3Exists ? mp3 : (m4aExists ? m4a : mp3); // for display
    const cat = categorizeCueId(c.expandedCueId);
    allCues.push({
      cueId: c.expandedCueId,
      text: c.expandedText,
      voiceProfile: c.voiceProfile,
      locale: c.locale,
      renderStrategy: c.renderStrategy,
      source: cat.source,
      group: cat.group,
      audioSrc: '../../' + audioFile, // relative from preview-bundle/index.html to assets/...
      audioReady,
    });
  }
  for (const d of canonical.digitLibrary || []) {
    const m4a = d.outputFile;
    const mp3 = m4a.replace(/\.m4a$/i, '.mp3');
    const mp3Exists = fileExistsRelative(args.assetsRoot, mp3);
    const m4aExists = fileExistsRelative(args.assetsRoot, m4a);
    const audioReady = mp3Exists || m4aExists;
    const audioFile = mp3Exists ? mp3 : (m4aExists ? m4a : mp3);
    allCues.push({
      cueId: `digit:${d.voiceProfile}:${d.digit}`,
      text: d.text,
      voiceProfile: d.voiceProfile,
      locale: d.locale,
      renderStrategy: 'full-render',
      source: 'digit-library',
      group: d.voiceProfile,
      audioSrc: '../../' + audioFile,
      audioReady,
    });
  }

  // Sort by cueId.
  allCues.sort((a, b) => a.cueId.localeCompare(b.cueId));

  // Collect filter options.
  const sources = Array.from(new Set(allCues.map((c) => c.source))).sort();
  const voices = Array.from(new Set(allCues.map((c) => c.voiceProfile))).sort();
  const strategies = Array.from(new Set(allCues.map((c) => c.renderStrategy))).sort();
  const groupSet = new Set(allCues.map((c) => c.group));
  const groups = Array.from(groupSet).sort().map((id) => ({ id, label: id }));

  const audioReadyCount = allCues.filter((c) => c.audioReady).length;

  const payload = {
    generatedAt: new Date().toISOString(),
    totalCues: allCues.length,
    audioReadyCount,
    sources,
    voices,
    strategies,
    groups,
    cues: allCues,
  };

  const html = buildHtml(payload);

  await mkdir(args.out, { recursive: true });
  const outFile = path.join(args.out, 'index.html');
  await writeFile(outFile, html);

  console.log('');
  console.log('Preview bundle built.');
  console.log(`  Total cues:        ${allCues.length}`);
  console.log(`  Audio ready:       ${audioReadyCount}`);
  console.log(`  Awaiting render:   ${allCues.length - audioReadyCount}`);
  console.log(`  Sources:           ${sources.join(', ')}`);
  console.log(`  Voices:            ${voices.join(', ')}`);
  console.log(`  Render strategies: ${strategies.join(', ')}`);
  console.log(`  Groups:            ${groups.length}`);
  console.log('');
  console.log(`Open: ${outFile}`);
  console.log(`(Audio players use relative paths to ../../assets/... so the bundle must stay in tools/tts/preview-bundle/)`);

  process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(1); });
