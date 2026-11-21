// Client for the ImageGeneration service (Weetermachine/ImageGeneration).
//
// Contract per the integration brief:
//
//   POST /api/uploads          multipart, field "image"  -> { upload_id }
//   POST /api/generate         json                      -> { generation_id, status }
//   GET  /api/generations/:id  poll until succeeded/failed
//   GET  /api/files/:id        the bytes
//
// Two things here are deliberately loose. The brief documents request shapes
// precisely but response *field names* only loosely ("-> { generation_id }"),
// and it describes `source_upload_id` as work still to be done rather than
// shipped. So responses are read through `pick()` across plausible aliases and
// `probe()` reports what the live service actually answers, instead of this
// file asserting a shape it has never seen. Tighten both once a real response
// is in hand.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

// ---------------------------------------------------------------- config

/**
 * Read KEY=VALUE lines. Deliberately tiny: no export/quote/interpolation
 * handling, because anything cleverer invites a key that silently parses wrong.
 */
function parseEnv(text) {
  const out = {};
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    out[trimmed.slice(0, eq).trim()] = value;
  }
  return out;
}

export function loadEnv(repoRoot) {
  const candidates = [
    path.join(repoRoot, '.env'),
    path.join(repoRoot, 'app', '.env'),
    path.join(repoRoot, 'tools', 'artgen', '.env'),
  ];
  const found = [];
  let env = {};
  for (const file of candidates) {
    if (!fs.existsSync(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    const parsed = parseEnv(text);
    found.push({ file, keys: Object.keys(parsed), bytes: text.length });
    env = { ...env, ...parsed };
  }
  return { env: { ...env, ...process.env }, found, candidates };
}

// The names the app/.env template already uses. Aliases accepted so a copy of
// the AI-DM block works unchanged either way.
const URL_KEYS = ['IMAGEGEN_URL', 'IMAGEGEN_BASE_URL'];
const TOKEN_KEYS = ['IMAGEGEN_TOKEN', 'IMAGEGEN_API_KEY'];

function firstOf(env, keys) {
  for (const k of keys) if (env[k]) return env[k];
  return undefined;
}

export function configFromEnv(env) {
  const baseUrl = firstOf(env, URL_KEYS);
  const apiKey = firstOf(env, TOKEN_KEYS);
  const missing = [];
  if (!baseUrl) missing.push(URL_KEYS.join(' or '));
  if (!apiKey) missing.push(TOKEN_KEYS.join(' or '));
  if (missing.length) {
    const err = new Error(`missing config: ${missing.join(', ')}`);
    err.missing = missing;
    throw err;
  }
  return {
    baseUrl: baseUrl.replace(/\/+$/, ''),
    apiKey,
    // ImageGen issues per-app tokens (scripts/issueAppToken.js). The header it
    // expects is not documented in the brief, so it stays configurable and
    // `probe()` reports which scheme the live service accepts.
    authHeader: env.IMAGEGEN_AUTH_HEADER || 'Authorization',
    authScheme: env.IMAGEGEN_AUTH_SCHEME ?? 'Bearer',
    // /api/models reports default_provider=gemini with configured:false on
    // this deployment, so an omitted provider routes to a provider that has no
    // credentials. Always send one explicitly.
    provider: env.IMAGEGEN_PROVIDER || 'openai',
    // The service picks the model from the effort tier (draft ->
    // gpt-image-1-mini, standard/premium -> gpt-image-2). Only set this to pin
    // a specific model against that mapping.
    model: env.IMAGEGEN_MODEL || undefined,
    userRef: env.IMAGEGEN_USER_REF || 'critmath',
  };
}

/** First present key from a response object, tried in order. */
function pick(obj, ...names) {
  for (const n of names) {
    if (obj && obj[n] !== undefined && obj[n] !== null) return obj[n];
  }
  return undefined;
}

export class ImageGenError extends Error {
  constructor(message, { status, body } = {}) {
    super(message);
    this.name = 'ImageGenError';
    this.status = status;
    this.body = body;
  }
}

export class ImageGenClient {
  constructor(config, { log = () => {} } = {}) {
    this.config = config;
    this.log = log;
  }

  get authHeaders() {
    const { authHeader, authScheme, apiKey } = this.config;
    return { [authHeader]: authScheme ? `${authScheme} ${apiKey}` : apiKey };
  }

  async request(method, route, { json, form, accept = 'application/json', timeoutMs = 120000 } = {}) {
    const url = `${this.config.baseUrl}${route}`;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(url, {
        method,
        headers: {
          ...this.authHeaders,
          ...(json ? { 'Content-Type': 'application/json' } : {}),
          Accept: accept,
        },
        body: json ? JSON.stringify(json) : form,
        signal: controller.signal,
      });

      const type = res.headers.get('content-type') || '';
      if (!res.ok) {
        const body = type.includes('json') ? await res.json().catch(() => null) : await res.text().catch(() => '');
        throw new ImageGenError(`${method} ${route} -> ${res.status}`, { status: res.status, body });
      }
      if (accept !== 'application/json') return Buffer.from(await res.arrayBuffer());
      return type.includes('json') ? res.json() : res.text();
    } finally {
      clearTimeout(timer);
    }
  }

  /**
   * Ask the service what it is, without generating anything.
   *
   * Used before spending money: confirms the base URL resolves, the key is
   * accepted, and reports whether the edits path exists yet.
   */
  async probe() {
    const results = {};
    // No listing route here: /api/generations?limit=1 was removed from the
    // service and returns 404 whatever you send, which made probe() look like
    // an auth failure. Per-generation reads (/api/generations/:id) still work
    // and are what the poll loop uses.
    for (const route of ['/api/health', '/api/models', '/api/presets']) {
      try {
        results[route] = { ok: true, body: await this.request('GET', route, { timeoutMs: 15000 }) };
      } catch (err) {
        results[route] = { ok: false, status: err.status, error: err.message, body: err.body };
      }
    }
    return results;
  }

  async upload(filePath) {
    const form = new FormData();
    form.append(
      'image',
      new Blob([fs.readFileSync(filePath)], { type: 'image/png' }),
      path.basename(filePath),
    );
    const res = await this.request('POST', '/api/uploads', { form });
    const id = pick(res, 'upload_id', 'id', 'uploadId');
    if (!id) throw new ImageGenError('upload returned no id', { body: res });
    return { id, raw: res };
  }

  /**
   * Queue one generation. Returns the generation id.
   *
   * [sourceUploadId] drives the edit path. The brief lists that as unbuilt at
   * commit 2dc5bf1, so a service that has not shipped it may 400 — or, worse,
   * ignore it and bill for a text-to-image result. `runOne` verifies rather
   * than trusting.
   */
  /**
   * Queue one generation. Returns the generation id.
   *
   * Vocabulary is the live service's, confirmed against GET /api/models:
   * effort is draft|standard|premium (NOT "quality"), aspect is
   * square|portrait|landscape, resolution is 0.5k|1k|2k|4k and is ignored by
   * the openai provider.
   *
   * [sourceUploadId] drives the edit path. openai advertises
   * max_input_images: 4, so this deployment may well support it, but the brief
   * describes it as unbuilt - probe.mjs checks whether a bogus id is rejected
   * (good) or silently ignored (bills for the wrong picture).
   */
  async generate({
    prompt,
    effort = 'draft',
    aspect = 'square',
    resolution,
    idempotencyKey,
    sourceUploadId,
    seed,
    presetKey,
    enhance,
  }) {
    const body = {
      prompt,
      provider: this.config.provider,
      effort,
      aspect,
      user_ref: this.config.userRef,
    };
    if (this.config.model) body.model = this.config.model;
    if (resolution) body.resolution = resolution;
    if (idempotencyKey) body.idempotency_key = idempotencyKey;
    if (sourceUploadId) body.source_upload_id = sourceUploadId;
    if (seed !== undefined) body.seed = seed;
    if (presetKey) body.preset_key = presetKey;
    if (enhance !== undefined) body.enhance = enhance;

    const res = await this.request('POST', '/api/generate', { json: body });
    const id = pick(res, 'generation_id', 'id', 'generationId');
    if (!id) throw new ImageGenError('generate returned no generation id', { body: res });
    return { id, raw: res };
  }

  async status(generationId) {
    return this.request('GET', `/api/generations/${encodeURIComponent(generationId)}`);
  }

  async poll(generationId, { timeoutMs = 300000, intervalMs = 2500 } = {}) {
    const deadline = Date.now() + timeoutMs;
    let last = null;
    for (;;) {
      last = await this.status(generationId);
      const state = String(pick(last, 'status', 'state') || '').toLowerCase();
      if (['succeeded', 'success', 'completed', 'done'].includes(state)) return last;
      if (['failed', 'error', 'cancelled', 'canceled', 'refused'].includes(state)) {
        throw new ImageGenError(`generation ${generationId} ${state}`, { body: last });
      }
      if (Date.now() > deadline) {
        throw new ImageGenError(`generation ${generationId} still ${state || 'unknown'} after ${timeoutMs}ms`, { body: last });
      }
      this.log(`  ${generationId} ${state || 'pending'}...`);
      await new Promise((r) => setTimeout(r, intervalMs));
    }
  }

  /**
   * Bytes for a finished generation.
   *
   * The service returns `url` as a site-relative path ("/api/files/<id>"), so
   * it has to be resolved against the base URL - handing it to fetch() as-is
   * throws "Failed to parse URL". Relative and absolute are both handled here
   * because only one of them is documented.
   */
  async download(generation) {
    const direct = pick(generation, 'url', 'output_url', 'file_url');
    if (typeof direct === 'string' && direct.startsWith('/')) {
      return this.request('GET', direct, { accept: 'image/png' });
    }
    if (typeof direct === 'string') {
      const res = await fetch(direct, { headers: this.authHeaders });
      if (!res.ok) throw new ImageGenError(`GET ${direct} -> ${res.status}`);
      return Buffer.from(await res.arrayBuffer());
    }

    const fileId =
      pick(generation, 'file_id', 'fileId', 'output_file_id') ??
      pick(pick(generation, 'file', 'output', 'result') || {}, 'id', 'file_id') ??
      pick(generation, 'generation_id', 'id');
    if (fileId) {
      return this.request('GET', `/api/files/${encodeURIComponent(fileId)}`, { accept: 'image/png' });
    }
    throw new ImageGenError('cannot locate output file on generation record', { body: generation });
  }

  /** generate -> poll -> download, as one call. */
  async runOne(spec) {
    const { id } = await this.generate(spec);
    this.log(`  queued ${id}`);
    const finished = await this.poll(id);
    const bytes = await this.download(finished);
    return { id, bytes, record: finished };
  }
}

/**
 * Idempotency key for one asset request.
 *
 * Includes the source image hash when there is one. The brief calls this out
 * explicitly: keyed on the prompt alone, a second edit of a *different* image
 * with the same style prompt returns the first image.
 */
export function idempotencyKey({ prompt, effort, aspect, provider, sourceBytes, salt = '' }) {
  const h = crypto.createHash('sha256');
  h.update(JSON.stringify({ prompt, effort, aspect, provider, salt }));
  if (sourceBytes) h.update(crypto.createHash('sha256').update(sourceBytes).digest());
  return `critmath-${h.digest('hex').slice(0, 32)}`;
}
