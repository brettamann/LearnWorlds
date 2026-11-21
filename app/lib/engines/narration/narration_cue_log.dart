// NarrationCueLog — every distinct line the app has actually spoken.
//
// This exists to make recording possible at all, and it is keyed by the words
// rather than by the cueId for the same reason `narrationClipKey` is: a cueId
// names a *slot*, and the same slot says different words in different
// sessions. Keyed by text, the log collapses on its own — the 25 cueIds that
// are all some number word become the seven sentences you actually have to
// read.
//
// It persists. `narration_script.dart` enumerates every line the game can
// compose from a finite catalog, but a handful are assembled from lesson JSON
// and only appear when that lesson is played. Accumulating across sessions
// means those get picked up as they're encountered instead of demanding one
// heroic playthrough that touches everything.
//
// A development affordance, not save state: it lives under its own
// SharedPreferences key so it can be cleared without touching a save, and
// nothing in the game reads it.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../platform/narration_audio.dart';
import 'narration_line.dart';

const String _kLogKey = 'critmath.narration.observed.v1';

/// One line the app spoke, as the recording script needs it.
class ObservedCue {
  const ObservedCue({required this.text, required this.cueId});

  final String text;

  /// The first cueId this text was seen under, kept only so the export can
  /// group lines by activity. Never used for lookup.
  final String? cueId;

  String get clipKey => narrationClipKey(text);
}

class NarrationCueLog extends Notifier<Map<String, ObservedCue>> {
  bool _hydrated = false;

  @override
  Map<String, ObservedCue> build() {
    unawaited(_hydrate());
    return const <String, ObservedCue>{};
  }

  /// Record [line]. Keyed by normalised text, so a line spoken from twelve
  /// different cueIds is one entry and one recording.
  ///
  /// Unlike the cueId scheme this replaced, a line with no cueId is recorded
  /// too — there is nothing special about it, the words are the key.
  void record(NarrationLine line) {
    final text = narrationTextNormalize(line.text);
    if (text.isEmpty) return;
    if (state.containsKey(text)) return;
    state = <String, ObservedCue>{
      ...state,
      text: ObservedCue(text: text, cueId: line.cueId),
    };
    unawaited(_persist());
  }

  void clear() {
    state = const <String, ObservedCue>{};
    unawaited(_persist());
  }

  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLogKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final restored = <String, ObservedCue>{};
      for (final entry in decoded) {
        final map = entry as Map<String, dynamic>;
        final text = narrationTextNormalize(map['text'] as String? ?? '');
        if (text.isEmpty) continue;
        restored[text] = ObservedCue(
          text: text,
          cueId: map['cueId'] as String?,
        );
      }
      // Anything spoken while we were still reading wins — it is newer.
      state = <String, ObservedCue>{...restored, ...state};
    } catch (_) {
      // A corrupt or absent log is not worth failing a launch over. The worst
      // case is re-observing lines by playing.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kLogKey,
        jsonEncode(<Map<String, String?>>[
          for (final cue in state.values)
            <String, String?>{'text': cue.text, 'cueId': cue.cueId},
        ]),
      );
    } catch (_) {
      // Persistence is a convenience; the in-memory log still exports.
    }
  }
}

final narrationCueLogProvider =
    NotifierProvider<NarrationCueLog, Map<String, ObservedCue>>(
      NarrationCueLog.new,
    );
