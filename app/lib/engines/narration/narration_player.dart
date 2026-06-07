// NarrationPlayer — owns the "what caption is on screen right now" state and
// optionally dispatches the same line to the system TTS engine. During the
// voice-deferral window (specs/shared/text-and-tts-deferral.md) the system
// TTS path is the only audio; once pre-rendered ElevenLabs files exist, this
// player will also dispatch to an AudioProvider and pick TTS only as a
// fallback for un-rendered cueIds.
//
// API is intentionally tiny:
//   .speak(line)  — replace the current caption (+ speak via TTS if enabled)
//   .clear()      — remove the caption and stop any in-flight TTS
//   .state        — the current line, or null
//
// LessonRunner / ActivityRunner drive .speak. CaptionOverlay watches .state.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/system_tts.dart';
import '../../providers/tts_settings_provider.dart';
import 'narration_line.dart';

class NarrationPlayer extends Notifier<NarrationLine?> {
  @override
  NarrationLine? build() => null;

  void speak(NarrationLine line) {
    state = line;
    if (ref.read(ttsEnabledProvider)) {
      // Fire-and-forget. SystemTts swallows errors so a failed utterance
      // can't take down the caption layer.
      unawaited(ref.read(systemTtsProvider).speak(line.text));
    }
  }

  /// Speak the line via system TTS but DO NOT push it to the caption overlay.
  /// Use this when the text is already on-screen via a speech bubble (keeper
  /// intros, interstitials, reward beats) — otherwise the same line would
  /// show twice, once in the bubble and once in the bottom caption bar.
  void speakWithoutCaption(NarrationLine line) {
    // Clear any prior caption so a previous "Three." doesn't linger under the
    // bubble. The bubble is the visible text channel during this beat.
    state = null;
    if (ref.read(ttsEnabledProvider)) {
      unawaited(ref.read(systemTtsProvider).speak(line.text));
    }
  }

  void clear() {
    state = null;
    unawaited(ref.read(systemTtsProvider).stop());
  }
}

final narrationPlayerProvider =
    NotifierProvider<NarrationPlayer, NarrationLine?>(NarrationPlayer.new);
