// NarrationPlayer — owns the "what caption is on screen right now" state and
// dispatches the same line to a voice.
//
// Two voices, in order of preference:
//
//   1. A recorded clip, if one is bundled for this line's *text*. See
//      NarrationAudio — the owner records these himself, in batches.
//   2. The OS text-to-speech engine, for every cue with no recording yet.
//
// The fallback is the whole design. It means recording is incremental and
// never blocks: a build with zero clips behaves exactly as this player always
// has, and each clip that lands quietly upgrades one line from synth to human.
// This does not un-defer the ElevenLabs pipeline
// (specs/shared/text-and-tts-deferral.md); it drops a human voice into the
// same slot that pipeline would have filled.
//
// API is intentionally tiny:
//   .speak(line)    — replace the current caption (+ speak via TTS if enabled)
//   .enqueue(line)  — say this AFTER the current line finishes
//   .clear()        — remove the caption and stop any in-flight TTS
//   .state          — the current line, or null
//
// LessonRunner / ActivityRunner drive .speak. CaptionOverlay watches .state.
//
// ---------------------------------------------------------------------------
// Why there is a queue now
//
// There wasn't one, and its absence was a design constraint the whole game was
// bent around: `speak` cancels whatever is in flight, so two lines in one beat
// meant the first got cut off mid-word. Every runner carries a comment about
// it, and the Counting Parade's between-round line had to absorb the
// cardinality ("Five fawns!") because a separate line for it would have been
// clipped.
//
// That was fine until a beat genuinely had two things to say — the keeper
// finishing the round, and then a card being handed over. Deferring one of
// them in each runner would have been the same rule written eleven times, so
// the ordering lives here instead.
//
// `speak` still interrupts. That is the right default and nothing that calls
// it changed. `enqueue` is the opt-in: use it for a line that must be *heard*
// but can wait, and never for a line that is answering a tap.
//
// Knowing when a line has finished:
//
//   - A recorded clip is exact. `NarrationAudio.play` awaits just_audio's
//     `play()`, which completes at the end of the clip.
//   - System TTS is estimated from the length of the text, because
//     `flutter_tts`'s completion handler is not dependable on the web, which
//     is the platform this actually ships on. It is a fallback path for lines
//     with no recording, and every line in the script has one.
//
// Both are backstopped by a timeout, because the failure mode of a queue that
// waits forever is a child sitting in silence.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/narration_audio.dart';
import '../../platform/system_tts.dart';
import '../../providers/tts_settings_provider.dart';
import 'narration_cue_log.dart';
import 'narration_line.dart';

/// A line waiting its turn, and whether it should take the caption when it
/// starts.
class _Queued {
  const _Queued(this.line, {required this.caption});
  final NarrationLine line;
  final bool caption;
}

/// Added to the estimate when the in-flight line is a recorded clip, so the
/// fallback wait lands a little after the clip rather than over its tail.
const Duration _kClipWaitSlack = Duration(milliseconds: 1200);

/// At most this many lines wait. A beat with three things to say is a design
/// problem, not a scheduling one, and a deep queue means a child hears an
/// answer to something she did half a minute ago.
const int _kMaxQueued = 2;

/// Roughly how long [text] takes to say, for the synth path only.
///
/// SystemTts runs at speech rate 0.45, which lands near two and a half words a
/// second. Deliberately a little generous: overrunning costs a short pause
/// before the next line, while undershooting cuts one off, which is the exact
/// bug the queue exists to stop.
Duration narrationSpokenEstimate(String text) {
  final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final seconds = 0.45 + words.length * 0.42;
  return Duration(milliseconds: (seconds.clamp(0.8, 12.0) * 1000).round());
}

class NarrationPlayer extends Notifier<NarrationLine?> {
  @override
  NarrationLine? build() {
    ref.onDispose(() {
      _alive = false;
      _synthWait?.cancel();
      _synthWait = null;
    });
    return null;
  }

  bool _alive = true;

  /// Bumped by every speak/clear. An in-flight `_voice` that no longer matches
  /// has been superseded and must not drain the queue behind its replacement.
  int _generation = 0;

  final List<_Queued> _queue = <_Queued>[];

  /// True while a line is (as far as we can tell) still being said.
  bool _speaking = false;

  /// Counts down the estimated length of a synth line, so the queue behind it
  /// knows when to start.
  ///
  /// Started by [enqueue], not by [_voice]. That distinction is the whole
  /// reason this is not simpler: a timer armed on every spoken line leaves one
  /// pending after every line, and `flutter_test` fails any test whose tree is
  /// torn down while a timer is outstanding — nine tests with nothing to do
  /// with narration went red. Arming it only when something is actually
  /// waiting means a game that never queues never creates one.
  Timer? _synthWait;

  /// How long the in-flight line is expected to take. Used by [enqueue] to
  /// size its wait, and never armed unless something is actually queued.
  Duration _waitEstimate = Duration.zero;

  /// Whether a line is in flight. Exposed for tests and for callers that want
  /// to decide between speaking and waiting.
  bool get isSpeaking => _speaking;

  int get queuedCount => _queue.length;

  void speak(NarrationLine line) {
    _queue.clear();
    state = line;
    unawaited(_voice(line));
  }

  /// Speak the line via system TTS but DO NOT push it to the caption overlay.
  /// Use this when the text is already on-screen via a speech bubble (keeper
  /// intros, interstitials, reward beats) — otherwise the same line would
  /// show twice, once in the bubble and once in the bottom caption bar.
  void speakWithoutCaption(NarrationLine line) {
    _queue.clear();
    // Clear any prior caption so a previous "Three." doesn't linger under the
    // bubble. The bubble is the visible text channel during this beat.
    state = null;
    unawaited(_voice(line));
  }

  /// Say [line] once the current one has finished, instead of cutting it off.
  ///
  /// Speaks immediately when nothing is in flight, so a caller does not have
  /// to know which case it is in. Silently drops the line if the queue is
  /// already full — see [_kMaxQueued].
  void enqueue(NarrationLine line, {bool caption = true}) {
    if (!_speaking) {
      caption ? speak(line) : speakWithoutCaption(line);
      return;
    }
    if (_queue.length >= _kMaxQueued) return;
    _queue.add(_Queued(line, caption: caption));
    if (_synthWait != null) return;
    // Measured from now rather than from when the line started, which runs a
    // fraction long. Callers enqueue in the same beat they speak, so the
    // difference is a few frames of extra pause and never an overlap - and an
    // overlap is the bug this exists to prevent.
    final generation = _generation;
    _synthWait = Timer(_waitEstimate, () => _finished(generation));
  }

  void clear() {
    _queue.clear();
    _synthWait?.cancel();
    _synthWait = null;
    _generation++;
    _speaking = false;
    state = null;
    unawaited(ref.read(systemTtsProvider).stop());
    unawaited(ref.read(narrationAudioProvider).stop());
  }

  /// Recorded clip first, system TTS otherwise. Both paths are gated on the
  /// same read-aloud setting — a recorded line is still narration, so turning
  /// narration off has to silence it too.
  Future<void> _voice(NarrationLine line) async {
    final generation = ++_generation;
    _synthWait?.cancel();
    _synthWait = null;

    // Logged whether or not it is spoken: the log is what the recording
    // harness reads, and a muted session is still a session that named its
    // cues.
    ref.read(narrationCueLogProvider.notifier).record(line);
    if (!ref.read(ttsEnabledProvider)) {
      // Muted. The queue still drains, so a caller that split a beat into two
      // enqueued lines gets the same *state* transitions either way.
      _speaking = false;
      _drain(generation);
      return;
    }

    _speaking = true;

    // Matched on the words, not the cueId. cueIds encode position, and the
    // same cueId says different words in different sessions — see
    // narrationClipKey. Lines with no cueId at all are recordable too, which
    // the cueId scheme could never do.
    final recorded = ref.read(narrationAudioProvider);
    try {
      if (recorded.has(line.text)) {
        // Silence the synth voice before the human one starts, or a line that
        // was mid-utterance would talk over its own replacement.
        unawaited(ref.read(systemTtsProvider).stop());
        // Completes at the end of the clip, which is what makes the queue
        // exact rather than estimated on this path.
        //
        // Deliberately not `.timeout(...)`: Future.timeout arms a timer for
        // every line whether or not anything is waiting on it, and a platform
        // where `play` never completes - a widget test, an unimplemented
        // plugin - then leaves one pending for twenty seconds. The bound lives
        // in enqueue instead, which only arms a wait when there is something
        // to wait for.
        _waitEstimate = narrationSpokenEstimate(line.text) + _kClipWaitSlack;
        await recorded.play(line.text);
      } else {
        // Fire-and-forget. SystemTts swallows errors so a failed utterance
        // can't take down the caption layer.
        unawaited(recorded.stop());
        unawaited(ref.read(systemTtsProvider).speak(line.text));
        // No timer here on purpose. Nothing is waiting on this line yet, and
        // most lines never will be; enqueue arms the wait if one arrives.
        _waitEstimate = narrationSpokenEstimate(line.text);
        return;
      }
    } catch (_) {
      // A missing plugin, a stalled clip, a timeout. Treat it as finished:
      // the follow-up line is more use than a queue that never drains.
    }
    _finished(generation);
  }

  /// The line for [generation] is over, as far as we can tell.
  void _finished(int generation) {
    _synthWait?.cancel();
    _synthWait = null;
    if (!_alive || _generation != generation) return;
    _speaking = false;
    _drain(generation);
  }

  void _drain(int generation) {
    if (!_alive || _generation != generation || _queue.isEmpty) return;
    final next = _queue.removeAt(0);
    // Straight to _voice rather than through speak(), which would clear the
    // queue it is draining.
    if (next.caption) {
      state = next.line;
    } else {
      state = null;
    }
    unawaited(_voice(next.line));
  }
}

final narrationPlayerProvider =
    NotifierProvider<NarrationPlayer, NarrationLine?>(NarrationPlayer.new);
