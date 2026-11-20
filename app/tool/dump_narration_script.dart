// Dumps the narration script as JSON, for the Kokoro renderer to speak.
//
//   dart run tool/dump_narration_script.dart > ../tools/tts/kokoro/script.json
//
// The renderer is a Node script and the script itself is Dart, built by walking
// the same catalogs and calling the same line-building functions the runners
// call. Reimplementing any of that in JavaScript would create exactly the drift
// `narration_script.dart` exists to prevent — a reworded line would keep its
// old recording and nothing would report it. So Dart stays the single source of
// truth and hands the words over as data.
//
// Emits the clip key alongside every line. That key is the filename the app
// looks up at runtime (`narrationClipKey` in platform/narration_audio.dart), so
// computing it here rather than in the renderer keeps the hashing in one
// language and one implementation.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/data/narration_script.dart';
import 'package:critmath/platform/narration_clip_key.dart';

import 'narration_sources.dart';

/// Every line the lesson runtime speaks, read from the authored JSON.
///
/// `narration_script.dart` enumerates what the Dart runners compose, which is
/// the counting words, the warm miss/hint lines and Counting Parade's keeper
/// script - 253 lines. It cannot see the I-Show and We-Try narration, because
/// that is authored in `data/lesson-runtime/*.json` and only reaches the app
/// through `LessonRuntime`. Leaving it out meant every lesson still opened in
/// the browser synth voice, which is the first thing anyone hears.
///
/// Read from `assets/data/lesson-runtime/` rather than the repo-root `data/`
/// on purpose: the mirror is what the app actually loads, so if the two have
/// drifted this renders what will really be spoken.
///
/// Every `text` field in those files sits under a `narrationScript` array -
/// checked across all 22 lessons, 301 occurrences, no exceptions - so the walk
/// can take them all without guessing which strings are spoken.
List<String> lessonNarrationLines() {
  final dir = Directory('assets/data/lesson-runtime');
  if (!dir.existsSync()) return const <String>[];

  final seen = <String, String>{};

  void collect(Object? node, {required bool inNarrationScript}) {
    if (node is List) {
      for (final item in node) {
        collect(item, inNarrationScript: inNarrationScript);
      }
      return;
    }
    if (node is! Map) return;
    for (final entry in node.entries) {
      if (inNarrationScript && entry.key == 'text' && entry.value is String) {
        final text = narrationTextNormalize(entry.value as String);
        if (text.isNotEmpty) seen[text] = text;
        continue;
      }
      collect(
        entry.value,
        inNarrationScript: inNarrationScript || entry.key == 'narrationScript',
      );
    }
  }

  final files = dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.json'),
      );
  for (final file in files) {
    collect(
      jsonDecode(file.readAsStringSync()),
      inNarrationScript: false,
    );
  }

  // Sorted so the dump is stable across filesystem ordering and the diff is
  // readable when a lesson gains a line.
  return seen.values.toList()..sort();
}

/// The activity names on the Sanctuary map, read from the registry.
///
/// Every lesson node's banner is wrapped in `ReadAloudGate` and says its own
/// label, and that label is `activity.displayName` straight out of
/// `data/activity-registry/*.json`. It is the one piece of text on that screen
/// a pre-reader has no other way to get at, and neither of the other sources
/// can see it: `narration_script.dart` is Flutter-free and cannot load an
/// asset, and the literal sweep only reads `lib/`.
///
/// Only top-level activities. Sub-modes and challenge variants have display
/// names too, but nothing speaks them - the picker sheet is silent - and
/// rendering a clip nothing can play is pure download weight.
///
/// Read from the `assets/` mirror for the same reason the lesson lines are:
/// it is what the app actually loads, so a stale mirror renders what will
/// really be spoken rather than what was meant to be.
List<String> activityDisplayNames() {
  final dir = Directory('assets/data/activity-registry');
  if (!dir.existsSync()) return const <String>[];

  final seen = <String>{};
  final files = dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.json'),
      );
  for (final file in files) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) continue;
    final activities = decoded['activities'];
    if (activities is! List) continue;
    for (final activity in activities) {
      if (activity is! Map) continue;
      final name = activity['displayName'];
      if (name is String) {
        final text = narrationTextNormalize(name);
        if (text.isNotEmpty) seen.add(text);
      }
    }
  }

  return seen.toList()..sort();
}

void main() {
  final batches = buildNarrationScript();
  final lessonLines = lessonNarrationLines();
  final activityNames = activityDisplayNames();

  // Lines that are plain string literals in Dart - Haddock's opening
  // monologue, every const round's keeperLine, the mystery-egg dialog. Neither
  // of the two sources above can see them, and they were the last thing still
  // speaking in the browser voice.
  final known = <String>{
    ...batches.expand((b) => b.lines).map(narrationTextNormalize),
    ...lessonLines,
    ...activityNames,
  };
  final literalLines = dartNarrationLiterals('lib')
      .map(narrationTextNormalize)
      .where((t) => t.isNotEmpty && !known.contains(t))
      .toSet()
      .toList()
    ..sort();

  final payload = <String, dynamic>{
    'version': 1,
    // Named so a renderer built against a different key scheme fails loudly
    // instead of writing files the app will never open.
    'keyScheme': 'slug48__fnv1a32(utf8(collapseWhitespace(text)))',
    'batches': <Map<String, dynamic>>[
      for (final batch in batches)
        <String, dynamic>{
          'id': batch.id,
          'title': batch.title,
          'note': batch.note,
          'variants': batch.variants,
          'complete': batch.isComplete,
          'lines': <Map<String, String>>[
            for (final text in batch.lines)
              <String, String>{
                'text': text,
                'clipKey': narrationClipKey(text),
              },
          ],
        },
      if (literalLines.isNotEmpty)
        <String, dynamic>{
          'id': 'dart-literals',
          'title': 'Lines written directly in Dart',
          'note': 'Swept out of lib/ by tool/narration_sources.dart: the '
              'sanctuary prologue, const round keeperLines, reward dialog. '
              'Interpolated templates are excluded - their variants have to '
              'come from the catalog that fills the slot.',
          'variants': literalLines.length,
          'complete': true,
          'lines': <Map<String, String>>[
            for (final text in literalLines)
              <String, String>{
                'text': text,
                'clipKey': narrationClipKey(text),
              },
          ],
        },
      if (activityNames.isNotEmpty)
        <String, dynamic>{
          'id': 'activity-names',
          'title': 'The Sanctuary map - the name of a lesson, on tap',
          'note': 'Authored in data/activity-registry/*.json and spoken by '
              'the banner beside each lesson node. Same direction as the '
              'map-labels batch: naming a place, not announcing it.',
          'variants': activityNames.length,
          'complete': true,
          'lines': <Map<String, String>>[
            for (final text in activityNames)
              <String, String>{
                'text': text,
                'clipKey': narrationClipKey(text),
              },
          ],
        },
      if (lessonLines.isNotEmpty)
        <String, dynamic>{
          'id': 'lesson-json',
          'title': 'Lesson narration (I Show / We Try)',
          'note': 'Authored in data/lesson-runtime/*.json and spoken by '
              'LessonRuntime. Not enumerable from narration_script.dart, '
              'which only sees what the Dart runners compose.',
          'variants': lessonLines.length,
          'complete': true,
          'lines': <Map<String, String>>[
            for (final text in lessonLines)
              <String, String>{
                'text': text,
                'clipKey': narrationClipKey(text),
              },
          ],
        },
    ],
  };

  // Pretty-printed: this file is committed and read by humans deciding what to
  // re-render, so a readable diff is worth the bytes.
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(payload));
}
