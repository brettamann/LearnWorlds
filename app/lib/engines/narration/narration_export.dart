// The recording script, as JSON the harness in tools/tts/record/ can load.
//
// Two sources, merged:
//
//   1. `narration_script.dart` — everything enumerable from the catalogs. This
//      is the bulk of it and it needs no playthrough at all.
//   2. `NarrationCueLog` — anything the app was actually heard to say that the
//      enumerator doesn't cover, which is mostly lines assembled from lesson
//      JSON. The log persists, so this half fills in as the game gets played.
//
// It also reports coverage honestly, because the two failure modes of a
// recording session are both invisible otherwise: recording lines the game
// will never ask for, and holding onto clips whose text has since been
// reworded. `orphans` is the second one — a clip in the bundle that matches no
// line anything can now speak.

import 'dart:convert';

import '../../data/narration_script.dart';
import '../../platform/narration_audio.dart';
import 'narration_cue_log.dart';

/// How the whole job stands, for the Settings subtitle and the harness header.
class NarrationCoverage {
  const NarrationCoverage({
    required this.scripted,
    required this.recorded,
    required this.orphaned,
  });

  /// Distinct lines in the script (enumerated + observed).
  final int scripted;

  /// How many of those already have a clip in the bundle.
  final int recorded;

  /// Clips in the bundle matching no line in the script. Almost always a line
  /// that was reworded after it was recorded.
  final int orphaned;

  int get remaining => scripted - recorded;

  double get fraction => scripted == 0 ? 0 : recorded / scripted;
}

/// Build the export.
///
/// [observed] is the cue log; [clipKeys] is what NarrationAudio found in the
/// bundle. Both are passed in rather than read from providers so this is a
/// pure function and testable without a container.
Map<String, dynamic> buildNarrationExport({
  required Iterable<ObservedCue> observed,
  required Set<String> clipKeys,
}) {
  final batches = buildNarrationScript();
  final scripted = narrationScriptTexts();

  // Anything heard that the enumerator missed. Sorted by cueId so lines from
  // the same activity land together in the reading order.
  final extras = <String, ObservedCue>{};
  for (final cue in observed) {
    if (scripted.contains(cue.text)) continue;
    extras[cue.text] = cue;
  }
  final extraCues = extras.values.toList()
    ..sort((a, b) => (a.cueId ?? '~').compareTo(b.cueId ?? '~'));

  final allTexts = <String>{...scripted, ...extras.keys};
  final allKeys = allTexts.map(narrationClipKey).toSet();
  final coverage = NarrationCoverage(
    scripted: allTexts.length,
    recorded: allKeys.intersection(clipKeys).length,
    orphaned: clipKeys.difference(allKeys).length,
  );

  Map<String, dynamic> lineOf(String text) {
    final key = narrationClipKey(text);
    return <String, dynamic>{
      'text': narrationTextNormalize(text),
      'file': key,
      'recorded': clipKeys.contains(key),
    };
  }

  return <String, dynamic>{
    'version': 2,
    // Stated so a future harness can refuse a script it doesn't understand
    // rather than writing hundreds of misnamed files.
    'keyScheme': 'slug48 + "__" + fnv1a32(utf8(collapseWhitespace(text)))',
    'clipDir': kNarrationClipDir,
    'coverage': <String, int>{
      'lines': coverage.scripted,
      'recorded': coverage.recorded,
      'remaining': coverage.remaining,
      'orphaned': coverage.orphaned,
    },
    'orphans': (clipKeys.difference(allKeys).toList()..sort()),
    'batches': <Map<String, dynamic>>[
      for (final batch in batches)
        <String, dynamic>{
          'id': batch.id,
          'title': batch.title,
          'note': batch.note,
          'complete': batch.isComplete,
          'variants': batch.variants,
          'lines': <Map<String, dynamic>>[
            for (final line in batch.lines) lineOf(line),
          ],
        },
      if (extraCues.isNotEmpty)
        <String, dynamic>{
          'id': 'observed',
          'title': 'Heard while playing, not in the catalogs',
          'note': 'Lines assembled from lesson JSON rather than from a Dart '
              'catalog, so they only appear here once the lesson that owns '
              'them has been played. Expect this batch to grow.',
          'complete': true,
          'variants': extraCues.length,
          'lines': <Map<String, dynamic>>[
            for (final cue in extraCues) lineOf(cue.text),
          ],
        },
    ],
  };
}

/// Coverage alone, for the Settings subtitle.
NarrationCoverage narrationCoverage({
  required Iterable<ObservedCue> observed,
  required Set<String> clipKeys,
}) {
  final texts = <String>{
    ...narrationScriptTexts(),
    for (final cue in observed) cue.text,
  };
  final keys = texts.map(narrationClipKey).toSet();
  return NarrationCoverage(
    scripted: texts.length,
    recorded: keys.intersection(clipKeys).length,
    orphaned: clipKeys.difference(keys).length,
  );
}

String narrationExportJson({
  required Iterable<ObservedCue> observed,
  required Set<String> clipKeys,
}) =>
    const JsonEncoder.withIndent('  ').convert(
      buildNarrationExport(observed: observed, clipKeys: clipKeys),
    );
