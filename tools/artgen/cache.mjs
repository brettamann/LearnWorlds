// Local cache for generated images and for uploads.
//
// Every generation costs money and ~18 seconds, and the failure mode without a
// cache is a folder of thirty near-identical mouths nobody can tell apart. So
// a request is keyed by its *content* — prompt, provider, effort, aspect,
// resolution, and the bytes of any reference image — and a key that is already
// on disk is never sent again.
//
// This is the same principle as the narration clip key: address the artefact
// by what it is, not by where it sits in a list. There it stopped one sentence
// being recorded five times; here it stops one sprite being generated five
// times. Rewording a prompt deliberately produces a new key, which is the
// point — the old image stays cached so a regression is one edit away, and
// `artgen prune` is the only thing that ever deletes.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const MANIFEST = 'manifest.json';

function sha256(buf) {
  return crypto.createHash('sha256').update(buf).digest('hex');
}

export class Cache {
  constructor(dir) {
    this.dir = dir;
    this.file = path.join(dir, MANIFEST);
    fs.mkdirSync(dir, { recursive: true });
    this.data = fs.existsSync(this.file)
      ? JSON.parse(fs.readFileSync(this.file, 'utf8'))
      : { version: 1, generations: {}, uploads: {} };
  }

  save() {
    fs.writeFileSync(this.file, `${JSON.stringify(this.data, null, 2)}\n`);
  }

  /**
   * Content key for one generation request.
   *
   * [referenceBytes] participates so that editing against a different source
   * image is a different request. Leaving it out would return the first
   * result for every subsequent reference — the exact trap the integration
   * brief flags about idempotency keys.
   */
  static key({ prompt, provider, effort, aspect, resolution, referenceBytes, variant = 0 }) {
    const h = crypto.createHash('sha256');
    h.update(JSON.stringify({ prompt, provider, effort, aspect, resolution: resolution ?? null, variant }));
    if (referenceBytes) h.update(sha256(referenceBytes));
    return h.digest('hex').slice(0, 24);
  }

  pathFor(key) {
    return path.join(this.dir, `${key}.png`);
  }

  /** The cached entry for [key], or null. Verifies the file still exists. */
  get(key) {
    const entry = this.data.generations[key];
    if (!entry) return null;
    const file = this.pathFor(key);
    if (!fs.existsSync(file)) return null;
    return { ...entry, file };
  }

  put(key, bytes, record) {
    const file = this.pathFor(key);
    fs.writeFileSync(file, bytes);
    this.data.generations[key] = {
      generation_id: record.generation_id ?? record.id ?? null,
      provider: record.provider ?? null,
      model: record.model ?? null,
      cost_cents: record.cost_cents ?? null,
      width: record.width ?? null,
      height: record.height ?? null,
      prompt: record.prompt_raw ?? record.prompt ?? null,
      created_at: record.created_at ?? null,
      bytes: bytes.length,
    };
    this.save();
    return { ...this.data.generations[key], file };
  }

  /**
   * Upload id for a local file, uploading only if its bytes are new.
   *
   * Style references are reused across a whole batch — every Buddy mouth edits
   * against the same v1.png — so without this the same 89 KB file is uploaded
   * once per asset.
   */
  async uploadOnce(client, filePath) {
    const bytes = fs.readFileSync(filePath);
    const hash = sha256(bytes);
    const hit = this.data.uploads[hash];
    if (hit) return { id: hit.upload_id, bytes, cached: true };

    const { id } = await client.upload(filePath);
    this.data.uploads[hash] = {
      upload_id: id,
      source: path.basename(filePath),
      uploaded_at: new Date().toISOString(),
    };
    this.save();
    return { id, bytes, cached: false };
  }

  get totalSpentCents() {
    return Object.values(this.data.generations).reduce((n, g) => n + (g.cost_cents || 0), 0);
  }

  get count() {
    return Object.keys(this.data.generations).length;
  }

  /** Cached entries whose key is not in [liveKeys] — orphans from edited prompts. */
  orphans(liveKeys) {
    const live = new Set(liveKeys);
    return Object.keys(this.data.generations).filter((k) => !live.has(k));
  }
}
