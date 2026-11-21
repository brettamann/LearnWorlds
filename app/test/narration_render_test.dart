// Every line the game can say has a voice.
//
// This is the gate that was missing. Nothing anywhere reported "this line has
// no recording" — a line with no clip does not fail, does not warn, and is not
// silent. It quietly comes out in the OS synth voice, which is a change of
// narrator mid-session and, for a pre-reader, the difference between an adult
// reading to her and a robot. It took someone playing the game and noticing.
//
// Two failure modes, and this catches both:
//
//   1. **A line nothing enumerates.** 'Mystic Sanctuary' was never in the
//      script at all, so the renderer could not have rendered it. Caught by
//      keeping the catalogs and the script the single source, and by
//      `map_labels_test.dart` for the labels specifically.
//   2. **A line reworded after it was recorded.** Clips are keyed by the words
//      spoken, so changing a sentence orphans its clip and the new wording
//      falls straight through to the synth. That is what this test is for, and
//      it fires the moment the wording changes rather than months later.
//
// Only `narration_script.dart`'s own batches are checked. Lesson JSON and the
// literal sweep are rendered too, but they are assembled by
// `tool/dump_narration_script.dart` and are not reachable from a Flutter test;
// `node tools/tts/kokoro/render.mjs status` owns those.
//
// Re-render after any wording change:
//
//   cd app && dart run tool/dump_narration_script.dart \
//       > ../tools/tts/kokoro/script.json
//   node tools/tts/kokoro/render.mjs render

import 'dart:io';

import 'package:critmath/data/narration_script.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// Clip keys present in `assets/audio/narration/`, whatever the extension.
///
/// Read once. A per-line directory listing over a thousand lines turned a
/// two-second test into a minute.
Set<String> _renderedKeys() {
  final dir = Directory('assets/audio/narration');
  if (!dir.existsSync()) return const <String>{};
  return <String>{
    for (final file in dir.listSync().whereType<File>())
      if (file.uri.pathSegments.last.contains('.'))
        file.uri.pathSegments.last.split('.').first,
  };
}

void main() {
  final rendered = _renderedKeys();

  test('the clip folder is not empty', () {
    // Guards the three tests below from passing vacuously if the assets ever
    // move: an empty set would make every "is it rendered" check trivially
    // wrong rather than trivially right, but the failure should say so once
    // and clearly rather than 1,071 times.
    expect(
      rendered,
      isNotEmpty,
      reason: 'no clips found under assets/audio/narration/',
    );
  });

  test('every line in every batch has a rendered clip', () {
    final missing = <String, List<String>>{};
    for (final batch in buildNarrationScript()) {
      for (final line in batch.lines) {
        if (!rendered.contains(narrationClipKey(line))) {
          (missing[batch.id] ??= <String>[]).add(line);
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'these lines would speak in the browser synth voice:\n'
          '${missing.entries.map((e) => '  ${e.key}: ${e.value.join("\n    ")}').join("\n")}\n'
          'Re-render — see the header of this file.',
    );
  });

  test('no batch is empty', () {
    // An empty batch is how a catalog rename fails quietly: the loop that
    // builds it iterates nothing, the script shrinks, and every line it used
    // to carry reverts to the synth voice without a word about it.
    for (final batch in buildNarrationScript()) {
      expect(batch.lines, isNotEmpty, reason: batch.id);
    }
  });

  test('no line is duplicated within a batch', () {
    // Two identical lines in one batch means an enumeration is crossing a
    // dimension the wording does not actually use — harmless for playback,
    // but it inflates the "lines to record" count a human reads.
    for (final batch in buildNarrationScript()) {
      final texts = batch.lines.map(narrationTextNormalize).toList();
      expect(texts.toSet(), hasLength(texts.length), reason: batch.id);
    }
  });
}
