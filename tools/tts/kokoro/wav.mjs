// Float samples in, 16-bit PCM WAV out, with the trim and normalise the
// recording harness already applies to human takes.
//
// Kokoro hands back a Float32Array and kokoro-js's own `save()` writes 32-bit
// float WAV (format tag 3). That is a poor shipping format here for two
// reasons: browser support for float WAV is uneven — Safari and iOS are the
// ones that matter, since the iPad is the eventual target — and it is twice
// the bytes for audio that will sit in the app bundle. tools/tts/record/
// already writes 16-bit PCM for exactly these reasons, so machine-rendered and
// human-recorded clips end up in the same format and the app cannot tell them
// apart.

/** Peak amplitude, or 0 for silence. */
function peak(samples) {
  let max = 0;
  for (let i = 0; i < samples.length; i++) {
    const v = Math.abs(samples[i]);
    if (v > max) max = v;
  }
  return max;
}

/**
 * Drop leading and trailing silence, keeping [padMs] of air at each end.
 *
 * Kokoro pads generously — a one-word line like "Seven." comes back at 1.4s,
 * most of which is nothing. That matters more than the bytes: the counting
 * ladder plays one of these per tap, and dead air at the head of each clip
 * reads as lag between the child's finger and the sound.
 *
 * The threshold is relative to the clip's own peak so a quiet line is not
 * trimmed to nothing.
 */
export function trimSilence(samples, sampleRate, { padMs = 30, floor = 0.02 } = {}) {
  const p = peak(samples);
  if (p === 0) return samples;
  const threshold = p * floor;

  let start = 0;
  while (start < samples.length && Math.abs(samples[start]) < threshold) start++;
  let end = samples.length - 1;
  while (end > start && Math.abs(samples[end]) < threshold) end--;
  if (end <= start) return samples;

  const pad = Math.round((padMs / 1000) * sampleRate);
  return samples.subarray(
    Math.max(0, start - pad),
    Math.min(samples.length, end + 1 + pad),
  );
}

/**
 * Scale so the loudest sample sits at [targetDb] dBFS.
 *
 * Kokoro's output level varies noticeably line to line. Left alone, one clip
 * in the counting ladder is audibly louder than its neighbours, which is very
 * obvious when they play in sequence.
 */
export function normalize(samples, targetDb = -1) {
  const p = peak(samples);
  if (p === 0) return samples;
  const gain = Math.pow(10, targetDb / 20) / p;
  const out = new Float32Array(samples.length);
  for (let i = 0; i < samples.length; i++) out[i] = samples[i] * gain;
  return out;
}

/** Mono 16-bit PCM WAV. */
export function encodeWav(samples, sampleRate) {
  const dataBytes = samples.length * 2;
  const buf = Buffer.alloc(44 + dataBytes);

  buf.write('RIFF', 0, 'ascii');
  buf.writeUInt32LE(36 + dataBytes, 4);
  buf.write('WAVE', 8, 'ascii');

  buf.write('fmt ', 12, 'ascii');
  buf.writeUInt32LE(16, 16); // PCM header size
  buf.writeUInt16LE(1, 20); // format 1 = PCM integer, not 3 = IEEE float
  buf.writeUInt16LE(1, 22); // mono
  buf.writeUInt32LE(sampleRate, 24);
  buf.writeUInt32LE(sampleRate * 2, 28); // byte rate
  buf.writeUInt16LE(2, 32); // block align
  buf.writeUInt16LE(16, 34); // bits per sample

  buf.write('data', 36, 'ascii');
  buf.writeUInt32LE(dataBytes, 40);

  for (let i = 0; i < samples.length; i++) {
    // Clamp before scaling: normalise targets -1 dBFS but a rounding step can
    // still land a sample outside [-1, 1], and wrapping that would be an
    // audible click.
    const v = Math.max(-1, Math.min(1, samples[i]));
    buf.writeInt16LE(Math.round(v * 32767), 44 + i * 2);
  }
  return buf;
}

/** trim -> normalise -> encode, the whole tail of the pipeline. */
export function finishClip(samples, sampleRate, options = {}) {
  return encodeWav(normalize(trimSilence(samples, sampleRate, options), options.targetDb), sampleRate);
}

/**
 * Re-encode a 16-bit PCM WAV as mono MP3.
 *
 * lamejs rather than ffmpeg: ffmpeg is not on PATH here and adding a system
 * binary to the build steps for one conversion is a poor trade against a pure
 * JS encoder that installs with the rest of the tooling.
 *
 * Takes the finished WAV rather than raw floats so trimming and normalising
 * happen once, identically, whichever format is being written.
 */
export async function encodeMp3(wavBuffer, bitrateKbps = 64) {
  const mod = await import('@breezystack/lamejs');
  const lame = mod.default ?? mod;

  const fmt = wavBuffer.indexOf('fmt ');
  const sampleRate = wavBuffer.readUInt32LE(fmt + 12);
  const dataIdx = wavBuffer.indexOf('data', fmt);
  const dataLen = wavBuffer.readUInt32LE(dataIdx + 4);

  const samples = new Int16Array(dataLen / 2);
  for (let i = 0; i < samples.length; i++) {
    samples[i] = wavBuffer.readInt16LE(dataIdx + 8 + i * 2);
  }

  const encoder = new lame.Mp3Encoder(1, sampleRate, bitrateKbps);
  const chunks = [];
  // 1152 samples is one MPEG-1 Layer III granule pair; lamejs expects to be
  // fed in those units.
  const BLOCK = 1152;
  for (let i = 0; i < samples.length; i += BLOCK) {
    const encoded = encoder.encodeBuffer(samples.subarray(i, i + BLOCK));
    if (encoded.length) chunks.push(Buffer.from(encoded));
  }
  const tail = encoder.flush();
  if (tail.length) chunks.push(Buffer.from(tail));
  return Buffer.concat(chunks);
}
