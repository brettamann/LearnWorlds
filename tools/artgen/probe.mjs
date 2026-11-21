// Diagnostic: what does the live ImageGen instance actually answer?
//
// Run before any generation. It costs nothing, and it settles the three things
// the integration brief leaves open: which auth header the per-app token wants,
// what the response records are really shaped like, and whether the edits
// (image-input) path exists on this deployment yet.
//
//   node tools/artgen/probe.mjs
//
// Never prints the token. Every line that could carry it is masked.

import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadEnv, configFromEnv } from './client.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

const { env, found, candidates } = loadEnv(ROOT);

console.log('=== env ===');
if (!found.length) {
  console.log('no .env found. looked in:');
  for (const c of candidates) console.log('  ', path.relative(ROOT, c));
  process.exit(1);
}
for (const f of found) {
  console.log(`  ${path.relative(ROOT, f.file)} (${f.bytes} bytes): ${f.keys.join(', ') || '(no keys parsed)'}`);
}

let config;
try {
  config = configFromEnv(env);
} catch (err) {
  console.log('\n' + err.message);
  process.exit(1);
}

const masked = `${config.apiKey.slice(0, 3)}...${config.apiKey.slice(-3)} (${config.apiKey.length} chars)`;
console.log(`\n  base url: ${config.baseUrl}`);
console.log(`  token:    ${masked}`);

// The .env comment warns that ImageGen serves files through nginx via
// X-Accel-Redirect, so pointing at the Express container yields an empty 200
// on /api/files/:id. That failure is silent and looks like a broken image, so
// name the risk up front rather than debugging it later.
const port = (config.baseUrl.match(/:(\d+)/) || [])[1];
if (port && port !== '8094') {
  console.log(`  note:     port ${port} is not the default nginx web port (8094).`);
  console.log('            If /api/files returns 0 bytes, this is why.');
}

const SCHEMES = [
  ['Authorization', 'Bearer'],
  ['Authorization', ''],
  ['X-App-Token', ''],
  ['X-Api-Key', ''],
];

const ROUTES = [
  ['GET', '/api/health'],
  ['GET', '/api/models'],
  ['GET', '/api/presets'],
  ['GET', '/api/generations?limit=1'],
  ['GET', '/api/uploads?limit=1'],
];

function summarize(body, limit = 400) {
  if (body === undefined || body === null) return '(empty)';
  const text = typeof body === 'string' ? body : JSON.stringify(body);
  return text.length > limit ? `${text.slice(0, limit)}... (${text.length} chars)` : text;
}

async function tryRequest(header, scheme, method, route) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15000);
  try {
    const res = await fetch(`${config.baseUrl}${route}`, {
      method,
      headers: {
        [header]: scheme ? `${scheme} ${config.apiKey}` : config.apiKey,
        Accept: 'application/json',
      },
      signal: controller.signal,
    });
    const type = res.headers.get('content-type') || '';
    const body = type.includes('json') ? await res.json().catch(() => null) : await res.text().catch(() => '');
    return { status: res.status, type, body };
  } catch (err) {
    return { error: err.name === 'AbortError' ? 'timeout after 15s' : err.message };
  } finally {
    clearTimeout(timer);
  }
}

console.log('\n=== reachability + auth scheme ===');
let working = null;
for (const [header, scheme] of SCHEMES) {
  const label = scheme ? `${header}: ${scheme} <token>` : `${header}: <token>`;
  // /api/models, not a listing route: it is authenticated (401 without a
  // token, 200 with one), which is exactly what makes it a discriminator.
  // /api/health answers 200 to anybody and would call a dead token good.
  //
  // This used to probe `/api/generations?limit=1`, which the service has since
  // removed. It 404s for everyone, so the probe reported "no auth scheme
  // accepted" about a live service and a valid token - a false negative that
  // looks exactly like a rotated key.
  const r = await tryRequest(header, scheme, 'GET', '/api/models');
  if (r.error) {
    console.log(`  ${label.padEnd(34)} -> ${r.error}`);
    continue;
  }
  console.log(`  ${label.padEnd(34)} -> ${r.status}`);
  if (r.status >= 200 && r.status < 300 && !working) working = { header, scheme };
}

if (!working) {
  console.log('\nNo auth scheme accepted. Either the token is for a different');
  console.log('instance, it has been rotated, or the URL is not the API root.');
  process.exit(1);
}

console.log(`\n  accepted: ${working.header}${working.scheme ? ` / ${working.scheme}` : ''}`);
if (working.header !== 'Authorization' || working.scheme !== 'Bearer') {
  console.log('  -> add to app/.env:');
  console.log(`     IMAGEGEN_AUTH_HEADER=${working.header}`);
  console.log(`     IMAGEGEN_AUTH_SCHEME=${working.scheme}`);
}

console.log('\n=== routes ===');
for (const [method, route] of ROUTES) {
  const r = await tryRequest(working.header, working.scheme, method, route);
  if (r.error) {
    console.log(`  ${method} ${route.padEnd(28)} -> ${r.error}`);
    continue;
  }
  console.log(`  ${method} ${route.padEnd(28)} -> ${r.status}  ${summarize(r.body, 300)}`);
}

// Does this deployment have image-input yet? The brief describes it as unbuilt
// at commit 2dc5bf1. A 400 naming the field means built-and-validating; a 200
// means built; silence about the field is the dangerous case, because it bills
// for a text-to-image result that ignores the reference image.
console.log('\n=== image-input (edit mode) support ===');
const controller = new AbortController();
const timer = setTimeout(() => controller.abort(), 20000);
try {
  const res = await fetch(`${config.baseUrl}/api/generate`, {
    method: 'POST',
    headers: {
      [working.header]: working.scheme ? `${working.scheme} ${config.apiKey}` : config.apiKey,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    // A deliberately bogus upload id. If the field is understood we expect a
    // 403/404 about ownership; if it is unknown we expect it to be ignored,
    // which is exactly what must not happen silently.
    body: JSON.stringify({
      prompt: 'connectivity probe, do not render',
      source_upload_id: '00000000-0000-0000-0000-000000000000',
      user_ref: 'critmath-probe',
      idempotency_key: 'critmath-probe-source-upload-support',
    }),
    signal: controller.signal,
  });
  const type = res.headers.get('content-type') || '';
  const body = type.includes('json') ? await res.json().catch(() => null) : await res.text().catch(() => '');
  console.log(`  POST /api/generate (bogus source_upload_id) -> ${res.status}`);
  console.log(`  ${summarize(body, 500)}`);
  if (res.status >= 200 && res.status < 300) {
    console.log('\n  WARNING: accepted an upload id that cannot exist.');
    console.log('  The field is being ignored -> edit mode is NOT live, and');
    console.log('  requests sent with a reference image would silently bill as');
    console.log('  plain text-to-image. Use text-to-image explicitly until the');
    console.log('  brief’s section 1 ships.');
  }
} catch (err) {
  console.log(`  ${err.name === 'AbortError' ? 'timeout after 20s' : err.message}`);
} finally {
  clearTimeout(timer);
}
