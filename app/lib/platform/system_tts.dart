// SystemTts — thin adapter over `flutter_tts`. Used as the deferral-period
// audio path (see specs/shared/text-and-tts-deferral.md). On web this dispatches
// to the browser's SpeechSynthesis API; on iOS/Android it uses the native TTS
// engine. Errors are swallowed so the caption layer always still works.
//
// Lifecycle:
//   - Constructed lazily by `systemTtsProvider`. Construction is cheap;
//     `_init()` runs once and silently no-ops if the platform plugin
//     isn't available (e.g. unit tests).
//   - `speak(text)` cancels any in-flight utterance and queues the new one.
//   - `stop()` clears anything in flight (used when captions clear).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SystemTts {
  SystemTts() {
    _initFuture = _init();
  }

  FlutterTts? _tts;
  bool _ready = false;
  Future<void>? _initFuture;

  // Tracks whether an utterance is currently in flight so we only pay the
  // cancel→speak delay when we're actually interrupting.
  bool _speaking = false;

  // Monotonic generation: every speak/stop bumps it. A scheduled speak() that
  // started before another call only finishes if the gen still matches — so
  // a fawn-tap fired during the breathing-room delay isn't lost behind a
  // stale earlier utterance.
  int _gen = 0;

  // Chrome / Edge SpeechSynthesis drops `speak()` calls that follow `cancel()`
  // too quickly. ~150ms is enough breathing room to avoid the race without
  // feeling like a noticeable pause between rapid count cues.
  static const Duration _cancelSpeakGap = Duration(milliseconds: 150);

  Future<void> _init() async {
    try {
      // `new FlutterTts()` registers a MethodChannel handler. In environments
      // where the binary messenger isn't initialized (e.g. unit tests that
      // don't call TestWidgetsFlutterBinding.ensureInitialized), this throws.
      // Catch sync + async failures uniformly so the caption path keeps
      // working without any extra ceremony.
      final tts = FlutterTts();
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.45);
      await tts.setPitch(1.05);
      await tts.setVolume(1.0);
      tts.setCompletionHandler(() => _speaking = false);
      tts.setCancelHandler(() => _speaking = false);
      tts.setErrorHandler((_) => _speaking = false);
      _tts = tts;
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> speak(String text) async {
    await _initFuture;
    final tts = _tts;
    if (!_ready || tts == null) return;
    final myGen = ++_gen;
    try {
      if (_speaking) {
        await tts.stop();
        await Future<void>.delayed(_cancelSpeakGap);
        // A newer speak/stop call superseded us during the delay — bail so we
        // don't talk over the latest one.
        if (_gen != myGen) return;
      }
      _speaking = true;
      await tts.speak(text);
    } catch (_) {
      if (_gen == myGen) _speaking = false;
    }
  }

  Future<void> stop() async {
    _gen++;
    final tts = _tts;
    if (!_ready || tts == null) return;
    try {
      await tts.stop();
    } catch (_) {}
    _speaking = false;
  }
}

final systemTtsProvider = Provider<SystemTts>((ref) => SystemTts());
