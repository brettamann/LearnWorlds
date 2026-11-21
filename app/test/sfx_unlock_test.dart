// Unlocking the audio, and the reason the counting tones went missing.
//
// A browser will not play audio until the user has interacted with the page,
// and for the HTML5 elements just_audio_web wraps that permission is granted
// **per element**. Unlocking means starting and immediately pausing every
// player once, inside a real gesture.
//
// The trap, which this file exists to keep shut: `AudioPlayer.play()` returns
// a Future that completes when playback **ends**, not when it starts. The
// first version of `unlock` awaited it, once per player, in a loop — so
// blessing 42 players waited out 18 seconds of audio, and the last of them was
// the music bed, whose `play()` under `LoopMode.one` never completes at all.
//
// What that sounded like from the sofa: the rising counting tone was missing
// for the first taps of a session and then turned up partway through,
// apparently at random. Nothing logged, nothing threw.
//
// The fake below reproduces the real contract exactly — `play()` completes
// only on pause or stop — so a regression here hangs the test rather than
// quietly passing.

import 'dart:async';

import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class _FakePlayer implements AudioPlayer {
  _FakePlayer(this.log);

  final List<String> log;
  Completer<void>? _playing;

  @override
  bool get playing => _playing != null;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    log.add('asset:$assetPath');
    return Duration.zero;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  /// Completes on pause/stop, never on its own — which is what the real one
  /// does, and the whole point of this fake.
  @override
  Future<void> play() {
    log.add('play');
    return (_playing = Completer<void>()).future;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> pause() async {
    log.add('pause');
    _playing?.complete();
    _playing = null;
  }

  @override
  Future<void> stop() async {
    _playing?.complete();
    _playing = null;
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('warm-up decodes the counting ladder before anything else', () {
    // The ladder is the only sound tied to a tap the child makes in her first
    // few seconds, so it should be ready first rather than whenever the
    // catalog happens to reach it.
    final log = <String>[];
    final engine = SfxEngine(playerFactory: () => _FakePlayer(log));
    addTearDown(engine.dispose);

    return engine.warmUp().then((_) {
      final assets = log.where((e) => e.startsWith('asset:')).toList();
      expect(assets, isNotEmpty);
      for (var i = 0; i < kCountLadder.length; i++) {
        expect(
          assets[i],
          'asset:${kCountLadder[i]}',
          reason: 'ladder note ${i + 1} should be decoded before the pools',
        );
      }
    });
  });

  test('unlock finishes, and blesses every player', () async {
    final log = <String>[];
    final engine = SfxEngine(playerFactory: () => _FakePlayer(log));
    addTearDown(engine.dispose);

    // The assertion is partly that this returns at all. Awaiting play() here
    // would deadlock against the fake, exactly as it stalled against a looping
    // music bed in the browser.
    final ok = await engine.unlock().timeout(
      const Duration(seconds: 5),
      onTimeout: () => fail('unlock never completed — is play() awaited?'),
    );

    expect(ok, isTrue);
    expect(engine.isUnlocked, isTrue);

    final plays = log.where((e) => e == 'play').length;
    final pauses = log.where((e) => e == 'pause').length;
    expect(plays, greaterThan(kCountLadder.length));
    expect(
      pauses,
      plays,
      reason:
          'every player that was started has to be paused again, or the '
          'unlock pass is audible',
    );
  });

  test('unlock is idempotent and does not re-bless', () async {
    final log = <String>[];
    final engine = SfxEngine(playerFactory: () => _FakePlayer(log));
    addTearDown(engine.dispose);
    await engine.unlock();
    final after = log.length;
    await engine.unlock();
    expect(log.length, after);
  });

  test('two gestures at once run one pass', () async {
    // AudioUnlockScope offers every pointer-down until the engine reports
    // success, so overlapping calls are expected rather than exceptional.
    final log = <String>[];
    final engine = SfxEngine(playerFactory: () => _FakePlayer(log));
    addTearDown(engine.dispose);
    final results = await Future.wait(<Future<bool>>[
      engine.unlock(),
      engine.unlock(),
    ]);
    expect(results, everyElement(isTrue));
    final players = log.where((e) => e.startsWith('asset:')).length;
    expect(
      log.where((e) => e == 'play').length,
      lessThanOrEqualTo(players + 1),
      reason: 'the music player has no asset, so it is players + 1 at most',
    );
  });

  test('the ladder climbs, and clamps rather than throwing', () async {
    final log = <String>[];
    final engine = SfxEngine(playerFactory: () => _FakePlayer(log));
    addTearDown(engine.dispose);
    await engine.warmUp();
    log.clear();
    engine
      ..playCountStep(1)
      ..playCountStep(kCountLadder.length + 40)
      // Below the bottom of the scale is not a note, it is a bug upstream.
      ..playCountStep(0);
    // _fire is fire-and-forget by design — a tap sound must never make a
    // caller await — so the plays land a few microtasks later.
    await pumpEventQueue();
    // Two of the three fired; nothing threw.
    expect(log.where((e) => e == 'play').length, 2);
  });
}
