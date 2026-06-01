// Harvester: Stage 1 of the TTS pipeline.
//
// Walks the CritMath repo and extracts every narration cue that needs to be
// rendered to audio. The output manifest is the input to the next stage
// (ScriptCanonicalizer → CacheChecker → TTSGenerator).
//
// See specs/shared/voice-pipeline.md for the full pipeline.

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

/// A single line of narration that needs TTS rendering.
class Cue {
  /// Stable identifier: `lesson:{lessonId}:{phase}:{key}` or similar namespace.
  final String cueId;

  /// Voice profile id from `voice-profiles.json` (e.g., `sanctuary-warm-naturalist`).
  final String voiceProfile;

  /// Visible scene character if the narrator is embodied (e.g., `storyteller-turtle`).
  /// Null for unseen narrators.
  final String? narratorCharacter;

  /// BCP 47 locale code (e.g., `en-US`).
  final String locale;

  /// The text to be spoken. May contain `{slot}` placeholders.
  final String text;

  /// Source file path (relative to repo root) for traceability.
  final String source;

  /// Slot placeholders detected in the text. Empty if no slots.
  final List<String> slotPlaceholders;

  Cue({
    required this.cueId,
    required this.voiceProfile,
    required this.narratorCharacter,
    required this.locale,
    required this.text,
    required this.source,
    required this.slotPlaceholders,
  });

  Map<String, dynamic> toJson() => {
        'cueId': cueId,
        'voiceProfile': voiceProfile,
        if (narratorCharacter != null) 'narratorCharacter': narratorCharacter,
        'locale': locale,
        'text': text,
        'source': source,
        if (slotPlaceholders.isNotEmpty) 'slotPlaceholders': slotPlaceholders,
      };
}

/// The output of a harvest run.
class HarvestResult {
  final List<Cue> cues;
  final List<String> warnings;
  final List<String> errors;
  final DateTime generatedAt;

  HarvestResult({
    required this.cues,
    required this.warnings,
    required this.errors,
    required this.generatedAt,
  });

  int get totalCues => cues.length;

  /// Count of cues per voice profile.
  Map<String, int> get byVoice {
    final map = <String, int>{};
    for (final c in cues) {
      map[c.voiceProfile] = (map[c.voiceProfile] ?? 0) + 1;
    }
    return _sortedByValueDesc(map);
  }

  /// Count of cues per source category.
  Map<String, int> get bySource {
    final map = <String, int>{};
    for (final c in cues) {
      final category = c.source.split('/').first;
      map[category] = (map[category] ?? 0) + 1;
    }
    return _sortedByValueDesc(map);
  }

  /// Count of cues per lesson.
  Map<String, int> get byLesson {
    final map = <String, int>{};
    for (final c in cues) {
      final parts = c.cueId.split(':');
      if (parts.length >= 2 && parts[0] == 'lesson') {
        map[parts[1]] = (map[parts[1]] ?? 0) + 1;
      }
    }
    return _sortedByValueDesc(map);
  }

  /// Count of cues with slot placeholders (needing slot-fill expansion later).
  int get cuesWithSlots => cues.where((c) => c.slotPlaceholders.isNotEmpty).length;

  /// Detect cueId collisions. Returns map of cueId → count where count > 1.
  Map<String, int> get duplicateCueIds {
    final counts = <String, int>{};
    for (final c in cues) {
      counts[c.cueId] = (counts[c.cueId] ?? 0) + 1;
    }
    return Map.fromEntries(counts.entries.where((e) => e.value > 1));
  }

  /// Per-voice character estimate (for cost estimation).
  Map<String, int> get charsByVoice {
    final map = <String, int>{};
    for (final c in cues) {
      map[c.voiceProfile] = (map[c.voiceProfile] ?? 0) + c.text.length;
    }
    return _sortedByValueDesc(map);
  }

  int get totalChars => cues.fold(0, (sum, c) => sum + c.text.length);

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'totalCues': totalCues,
        'totalChars': totalChars,
        'cuesWithSlots': cuesWithSlots,
        'byVoice': byVoice,
        'charsByVoice': charsByVoice,
        'bySource': bySource,
        'byLesson': byLesson,
        'duplicateCueIds': duplicateCueIds,
        'warnings': warnings,
        'errors': errors,
        'cues': cues.map((c) => c.toJson()).toList(),
      };
}

Map<String, int> _sortedByValueDesc(Map<String, int> input) {
  final entries = input.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// The harvester. Constructed with config, run via `run()`.
class Harvester {
  /// Absolute or relative path to the CritMath repo root.
  final String repoRoot;

  /// The locale being harvested for. Defaults to `en-US`.
  final String locale;

  /// Print walked files to stdout.
  final bool verbose;

  final List<String> _warnings = [];
  final List<String> _errors = [];

  Harvester({
    required this.repoRoot,
    this.locale = 'en-US',
    this.verbose = false,
  });

  Future<HarvestResult> run() async {
    final cues = <Cue>[];

    cues.addAll(await _walkLessonRuntimes());
    cues.addAll(await _walkActivityNarration());

    // Future walkers: shared narrator-cues, onboarding strings, dashboard strings.

    return HarvestResult(
      cues: cues,
      warnings: List.unmodifiable(_warnings),
      errors: List.unmodifiable(_errors),
      generatedAt: DateTime.now(),
    );
  }

  Future<List<Cue>> _walkLessonRuntimes() async {
    final dirPath = p.join(repoRoot, 'data', 'lesson-runtime');
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      _errors.add('Lesson runtime directory not found: $dirPath');
      return [];
    }

    final cues = <Cue>[];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .toList();

    // Sort for deterministic output (helps with diffing across runs).
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      if (file is! File) continue;
      final name = p.basename(file.path);
      if (name.startsWith('.')) continue;

      if (verbose) {
        stdout.writeln('Walking: data/lesson-runtime/$name');
      }

      try {
        final raw = await file.readAsString();
        final json = jsonDecode(raw);
        if (json is! Map<String, dynamic>) {
          _errors.add('data/lesson-runtime/$name: root is not an object');
          continue;
        }
        cues.addAll(_harvestLessonRuntime(json, 'lesson-runtime/$name'));
      } catch (e) {
        _errors.add('data/lesson-runtime/$name: parse failed: $e');
      }
    }

    return cues;
  }

  List<Cue> _harvestLessonRuntime(Map<String, dynamic> lesson, String source) {
    final cues = <Cue>[];

    final lessonId = lesson['id'] as String?;
    if (lessonId == null) {
      _errors.add('$source: missing required field "id"');
      return cues;
    }

    final voiceProfile = lesson['narratorVoice'] as String?;
    if (voiceProfile == null) {
      _errors.add('$source: missing required field "narratorVoice"');
      return cues;
    }

    final narratorCharacter = lesson['narratorCharacter'] as String?;

    final phases = lesson['phases'];
    if (phases is! Map<String, dynamic>) {
      _errors.add('$source: missing or invalid "phases" object');
      return cues;
    }

    // Walk each phase that has a narrationScript.
    for (final phaseName in const ['iShow', 'weTry', 'youDo']) {
      final phase = phases[phaseName];
      if (phase is! Map<String, dynamic>) {
        // youDo typically has no narrationScript (it hands off to the activity);
        // this is fine — just skip silently.
        continue;
      }

      final script = phase['narrationScript'];
      if (script == null) continue;
      if (script is! List) {
        _warnings.add('$source: phase $phaseName has non-array narrationScript');
        continue;
      }

      final seenCueKeys = <String>{};

      for (var i = 0; i < script.length; i++) {
        final entry = script[i];
        if (entry is! Map<String, dynamic>) {
          _warnings.add('$source: $phaseName narrationScript[$i] is not an object');
          continue;
        }

        final at = entry['at'];
        final text = entry['text'];

        if (at is! String) {
          _warnings.add('$source: $phaseName narrationScript[$i] missing or invalid "at"');
          continue;
        }
        if (text is! String) {
          _warnings.add('$source: $phaseName narrationScript[$i] missing or invalid "text"');
          continue;
        }
        if (text.trim().isEmpty) {
          _warnings.add('$source: $phaseName narrationScript[$i] has empty text');
          continue;
        }

        var cueKey = _stableKey(at, i);

        // Defensively disambiguate if two entries collide on the same key.
        if (!seenCueKeys.add(cueKey)) {
          final original = cueKey;
          var disambig = 2;
          while (!seenCueKeys.add('${original}_$disambig')) {
            disambig++;
          }
          cueKey = '${original}_$disambig';
          _warnings.add(
              '$source: $phaseName had duplicate cue key "$original" — disambiguated as "$cueKey"');
        }

        final cueId = 'lesson:$lessonId:$phaseName:$cueKey';

        cues.add(Cue(
          cueId: cueId,
          voiceProfile: voiceProfile,
          narratorCharacter: narratorCharacter,
          locale: locale,
          text: text,
          source: source,
          slotPlaceholders: _extractSlots(text),
        ));
      }
    }

    return cues;
  }

  Future<List<Cue>> _walkActivityNarration() async {
    final dirPath = p.join(repoRoot, 'content', 'strings', locale, 'activities');
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      // Not an error — activity narration may not yet be authored for this locale.
      _warnings.add('Activity narration directory not found: $dirPath (skipping)');
      return [];
    }

    final cues = <Cue>[];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      if (file is! File) continue;
      final name = p.basename(file.path);
      if (name.startsWith('.')) continue;

      if (verbose) {
        stdout.writeln('Walking: content/strings/$locale/activities/$name');
      }

      try {
        final raw = await file.readAsString();
        final json = jsonDecode(raw);
        if (json is! Map<String, dynamic>) {
          _errors.add('content/strings/$locale/activities/$name: root is not an object');
          continue;
        }
        cues.addAll(_harvestActivityNarration(
            json, 'activity-narration/$name'));
      } catch (e) {
        _errors.add('content/strings/$locale/activities/$name: parse failed: $e');
      }
    }

    return cues;
  }

  List<Cue> _harvestActivityNarration(
      Map<String, dynamic> doc, String source) {
    final cues = <Cue>[];

    final activityId = doc['activity'] as String?;
    if (activityId == null) {
      _errors.add('$source: missing required field "activity"');
      return cues;
    }

    final defaultVoiceProfile = doc['voiceProfile'] as String?;
    if (defaultVoiceProfile == null) {
      _errors.add('$source: missing required field "voiceProfile"');
      return cues;
    }

    final docLocale = doc['locale'] as String? ?? locale;
    final narratorCharacter = doc['narratorCharacter'] as String?;

    final cueList = doc['cues'];
    if (cueList is! List) {
      _errors.add('$source: missing or invalid "cues" array');
      return cues;
    }

    final seenIds = <String>{};

    for (var i = 0; i < cueList.length; i++) {
      final entry = cueList[i];
      if (entry is! Map<String, dynamic>) {
        _warnings.add('$source: cues[$i] is not an object');
        continue;
      }

      final id = entry['id'] as String?;
      final event = entry['event'] as String?;
      final text = entry['text'] as String?;

      if (id == null) {
        _warnings.add('$source: cues[$i] missing "id"');
        continue;
      }
      if (event == null) {
        _warnings.add('$source: cue "$id" missing "event"');
        continue;
      }
      if (text == null || text.trim().isEmpty) {
        _warnings.add('$source: cue "$id" missing or empty "text"');
        continue;
      }

      if (!seenIds.add(id)) {
        _warnings.add('$source: duplicate cue id "$id"');
        continue;
      }

      final voiceProfile = (entry['voiceProfile'] as String?) ?? defaultVoiceProfile;
      final cueId = 'activity:$activityId:$id';

      final slotMap = entry['slotSource'];
      final slots = _extractSlots(text);

      cues.add(Cue(
        cueId: cueId,
        voiceProfile: voiceProfile,
        narratorCharacter: narratorCharacter,
        locale: docLocale,
        text: text,
        source: source,
        slotPlaceholders: slots,
      ));

      // Verify slot map covers all placeholders if both are present.
      if (slotMap is Map<String, dynamic>) {
        for (final slotName in slots) {
          if (!slotMap.containsKey(slotName)) {
            _warnings.add(
                '$source: cue "$id" text uses {$slotName} but slotSource has no entry for it');
          }
        }
      }
    }

    return cues;
  }

  /// Convert a narration `at` value into a stable, file-safe cue key.
  ///
  /// Timestamps like `"2s"`, `"0.5s"`, `"11s"` become `"t2s"`, `"t0_5s"`, `"t11s"`.
  /// Symbolic cue ids like `"we-try-start"` are normalized (replace any chars
  /// outside `[A-Za-z0-9_-]` with `_`).
  String _stableKey(String at, int index) {
    final timestamp = RegExp(r'^[0-9]+(\.[0-9]+)?s$');
    if (timestamp.hasMatch(at)) {
      return 't${at.replaceAll('.', '_').replaceAll('s', '')}s';
    }
    return at.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  /// Extract `{slotName}` placeholders from text. Returns deduplicated slot names.
  List<String> _extractSlots(String text) {
    final matches = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}').allMatches(text);
    final set = <String>{};
    for (final m in matches) {
      set.add(m.group(1)!);
    }
    return set.toList()..sort();
  }
}
