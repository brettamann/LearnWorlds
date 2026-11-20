// The Mystic Sanctuary has to sound like one place.
//
// It didn't. Every runner started the music bed in initState and stopped it in
// dispose, so a single visit — lesson, round, keeper's gift, next round — was
// four separate screens each owning the music for as long as it happened to be
// mounted. Walking from one sub-mode to the next tore the bed down and built it
// back from the top, and the lesson in between had no music at all. Three
// sections of one continuous place, and you could hear the joins.
//
// So the engine owns the bed now. A screen *claims* it and *releases* it, a
// claim is idempotent by asset, and a release is a deferred stop. What these
// tests pin is the pair of moments that behaviour turns on: a route change
// that re-claims the same file must be inaudible, and actually leaving must
// still stop the music.

import 'dart:async';

import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class _FakePlayer implements AudioPlayer {
  final List<String> log = <String>[];
  String? asset;
  LoopMode? loopModeSet;
  bool _playing = false;
  double _volume = 1;

  int get assetLoads =>
      log.where((String e) => e.startsWith('setAsset')).length;
  int get stops => log.where((String e) => e == 'stop').length;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    asset = assetPath;
    log.add('setAsset:$assetPath');
    return Duration.zero;
  }

  @override
  bool get playing => _playing;

  @override
  double get volume => _volume;

  @override
  Future<void> setVolume(double volume) async => _volume = volume;

  @override
  Future<void> setLoopMode(LoopMode mode) async => loopModeSet = mode;

  /// Completes on pause/stop and never on its own — the real contract, and
  /// under LoopMode.one it means a looping bed's `play()` never completes at
  /// all. See sfx_unlock_test.dart, where the same fake keeps that shut.
  @override
  Future<void> play() {
    _playing = true;
    log.add('play');
    return Completer<void>().future;
  }

  @override
  Future<void> pause() async => _playing = false;

  @override
  Future<void> stop() async {
    _playing = false;
    log.add('stop');
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A warmed-up engine plus the one player that carries the music.
class _Rig {
  _Rig(this.engine, this.music);

  final SfxEngine engine;
  final _FakePlayer music;
}

_Rig _warmRig(FakeAsync async) {
  final players = <_FakePlayer>[];
  final engine = SfxEngine(
    playerFactory: () {
      final player = _FakePlayer();
      players.add(player);
      return player;
    },
  );
  unawaited(engine.warmUp());
  async.flushMicrotasks();
  // The music player is the only one the engine puts in a loop mode, which is
  // a truer handle on it than "the last one created".
  final music = players.firstWhere((_FakePlayer p) => p.loopModeSet != null);
  return _Rig(engine, music);
}

void main() {
  test('claiming a bed that is already playing does not restart it', () {
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();
      expect(rig.music.asset, kSanctuaryMusicBed);
      expect(rig.music.playing, isTrue);
      expect(rig.music.assetLoads, 1);

      // A lesson asking for the picnic bed resolves to the same file. Two
      // names for one place must not sound like a cut.
      unawaited(rig.engine.startMusicBed('sanctuary-picnic'));
      async.flushMicrotasks();
      expect(
        rig.music.assetLoads,
        1,
        reason: 'reloading the asset restarts the track from zero',
      );
      expect(rig.music.stops, 0);
      expect(rig.music.playing, isTrue);
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('the music survives a screen handing off to the next', () {
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();

      // The exact shape of a sub-mode change: the old runner disposes, and a
      // couple of frames later the next screen mounts and claims the bed.
      rig.engine.releaseMusicBed();
      async.elapse(const Duration(milliseconds: 200));
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.elapse(const Duration(seconds: 5));

      expect(rig.music.playing, isTrue);
      expect(
        rig.music.stops,
        0,
        reason: 'the pending release should have been cancelled by the claim',
      );
      expect(rig.music.assetLoads, 1);
      expect(rig.music.volume, closeTo(kDefaultMusicVolume, 0.001));
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('a release nobody answers does stop the music', () {
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();

      rig.engine.releaseMusicBed();
      async.elapse(kMusicBedReleaseGrace ~/ 2);
      expect(
        rig.music.playing,
        isTrue,
        reason: 'still inside the grace window — this is the frame a route '
            'change lives in',
      );

      async.elapse(kMusicBedReleaseGrace + const Duration(seconds: 2));
      expect(rig.music.playing, isFalse);
      expect(rig.engine.musicBedAsset, isNull);
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('a different bed does replace the current one', () {
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();
      unawaited(rig.engine.startMusicBed(kChallengeMusicBed));
      async.flushMicrotasks();

      // Opting into a challenge is one of the few places a change in the
      // music is the point.
      expect(rig.music.assetLoads, 2);
      expect(rig.music.asset, kMusicBeds[kChallengeMusicBed]);
      expect(rig.music.playing, isTrue);
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('a fade already in flight cannot stop the bed that replaced it', () {
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();

      // Release, let the grace window expire so the 600ms fade-out is running,
      // then claim a different bed mid-fade. Without the generation guard the
      // tail of that fade reaches its `stop()` a moment later and kills the
      // music that just started.
      rig.engine.releaseMusicBed();
      async.elapse(kMusicBedReleaseGrace + const Duration(milliseconds: 200));
      unawaited(rig.engine.startMusicBed(kChallengeMusicBed));
      async.elapse(const Duration(seconds: 5));

      expect(rig.music.playing, isTrue);
      expect(rig.music.asset, kMusicBeds[kChallengeMusicBed]);
      expect(rig.music.volume, closeTo(kDefaultMusicVolume, 0.001));
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('unlocking audio does not stop the bed it finds playing', () {
    // AudioUnlockScope offers every pointer-down to the engine until one
    // succeeds, so the unlock pass can run well after the music has started —
    // and blessing a player means pausing and rewinding it. Nothing in the
    // browser needs a grant for an element that is audibly already playing.
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();
      expect(rig.music.playing, isTrue);

      unawaited(rig.engine.unlock());
      async.elapse(const Duration(seconds: 2));

      expect(
        rig.music.playing,
        isTrue,
        reason: 'the unlock pass paused the music it was meant to leave alone',
      );
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('turning music back on resumes the bed a screen still wants', () {
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      unawaited(rig.engine.startMusicBed('sanctuary-low'));
      async.flushMicrotasks();

      rig.engine.setMusicEnabled(false);
      async.elapse(const Duration(seconds: 2));
      expect(rig.music.playing, isFalse);

      // A mute is not the screen letting go, so the claim outlives it.
      rig.engine.setMusicEnabled(true);
      async.elapse(const Duration(seconds: 2));
      expect(rig.music.playing, isTrue);
      expect(rig.engine.musicBedAsset, kSanctuaryMusicBed);
      rig.engine.dispose();
      async.flushTimers();
    });
  });

  test('releasing a bed that was never claimed leaves no timer behind', () {
    // Runners release in dispose unconditionally, and most of them are torn
    // down in tests where the audio plugin does not exist. An unconditional
    // Timer here would fail every one of those on a pending-timer check.
    fakeAsync((FakeAsync async) {
      final rig = _warmRig(async);
      rig.engine.releaseMusicBed();
      expect(async.pendingTimers, isEmpty);
      rig.engine.dispose();
      async.flushTimers();
    });
  });
}
