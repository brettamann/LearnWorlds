// Print the IPA Kokoro will actually say for a word or line.
//
//   node tools/tts/kokoro/phonemes.mjs toucan too-can toukan "TOO can"
//
// Kokoro phonemises with eSpeak-NG and then synthesises from the phonemes, so
// a mispronunciation is decided before the model ever runs — which means it is
// *readable* rather than something you can only judge by ear. That is what
// this is for: pick a respelling for lexicon.mjs by comparing IPA against the
// pronunciation you want, instead of rendering candidates and guessing.
//
// The engine has no phoneme input, so `stream()` is the seam: it yields the
// phoneme string alongside the audio for each sentence it processes.

import { KokoroTTS, TextSplitterStream } from 'kokoro-js';

const MODEL = 'onnx-community/Kokoro-82M-v1.0-ONNX';
const VOICE = 'af_heart';

const words = process.argv.slice(2);
if (words.length === 0) {
  console.error('usage: node phonemes.mjs <text> [<text> ...]');
  process.exit(1);
}

process.stderr.write('loading Kokoro...\n');
const tts = await KokoroTTS.from_pretrained(MODEL, {
  dtype: 'q8',
  device: 'cpu',
});

for (const word of words) {
  // Fed through an explicitly closed splitter. Passing a plain string to
  // stream() builds one internally and never closes it, so the iterator waits
  // forever for a sentence that is not coming and node exits on an unsettled
  // await having printed nothing.
  const splitter = new TextSplitterStream();
  splitter.push(word);
  splitter.close();
  const parts = [];
  for await (const { phonemes } of tts.stream(splitter, { voice: VOICE })) {
    parts.push(phonemes);
  }
  console.log(`${word.padEnd(34)} ${parts.join(' | ')}`);
}
