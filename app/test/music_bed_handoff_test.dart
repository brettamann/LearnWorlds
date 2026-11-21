// The music has to survive a route change, in the order route changes really
// happen.
//
// music_bed_continuity_test.dart pins the engine's claim/release behaviour, and
// it did so against a sequence written from an assumption: old screen releases,
// new screen claims. Navigation does not work that way. Flutter mounts the
// incoming route and only disposes the outgoing one as the transition finishes,
// so what the engine actually sees is
//
//     claim(new) ... release(old)
//
// With an unconditional deferred stop in release, that schedules the music to
// die a few seconds into a screen that is actively asking for it, and there is
// no later claim to cancel it — the new screen already claimed, before the
// release was scheduled. The child hears the music start with the lesson and
// stop once the round begins, which is exactly the report that started this.
//
// So these drive a real GoRouter and a real SfxEngine, and assert on sound
// rather than on call order. Reasoning about the ordering by hand is what got
// it wrong the first time.

import 'dart:async';

import 'package:critmath/data/sfx_catalog.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:critmath/ui/scopes/music_bed_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

/// The music player, reduced to the two questions these tests ask: is it making
/// a sound, and did it have to reload the file to do it.
class _FakePlayer implements AudioPlayer {
  final List<String> log = <String>[];
  bool _playing = false;
  double _volume = 1;

  int get assetLoads =>
      log.where((String e) => e.startsWith('setAsset')).length;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
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
  Future<void> setLoopMode(LoopMode mode) async => log.add('loop');

  /// Never completes — the real contract, and under LoopMode.one a looping bed's
  /// play() genuinely never does.
  @override
  Future<void> play() {
    _playing = true;
    return Completer<void>().future;
  }

  @override
  Future<void> pause() async => _playing = false;

  @override
  Future<void> stop() async => _playing = false;

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A screen that wants music — anything wrapped in a MusicBedScope.
class _Scored extends StatelessWidget {
  const _Scored({required this.name, this.bed = kDefaultMusicBed});

  final String name;
  final String bed;

  @override
  Widget build(BuildContext context) => MusicBedScope(
        bed: bed,
        child: Scaffold(body: Center(child: Text(name))),
      );
}

/// An app under test: the engine, the one player carrying the music, and
/// whatever navigation the test needs.
class _Rig {
  _Rig(this.engine, this.container);

  final SfxEngine engine;
  final ProviderContainer container;
  final List<_FakePlayer> players = <_FakePlayer>[];

  /// The engine is the only thing that puts a player in a loop mode, which is
  /// a truer handle on the bed than "the last one built".
  _FakePlayer get music => players.firstWhere((p) => p.log.contains('loop'));

  Widget wrap(Widget child) =>
      UncontrolledProviderScope(container: container, child: child);

  /// Unmount, then dispose the engine — in that order, so the release the
  /// unmount schedules is cancelled rather than left pending past the end of
  /// the test.
  Future<void> shutDown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    engine.dispose();
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_Rig> buildRig() async {
    late final _Rig rig;
    final engine = SfxEngine(
      playerFactory: () {
        final player = _FakePlayer();
        rig.players.add(player);
        return player;
      },
    );
    rig = _Rig(
      engine,
      ProviderContainer(
        overrides: [sfxEngineProvider.overrideWithValue(engine)],
      ),
    );
    await engine.warmUp();
    return rig;
  }

  /// Builds a router over [screens] and pumps it.
  Future<(_Rig, GoRouter)> pumpApp(
    WidgetTester tester,
    Map<String, WidgetBuilder> screens,
  ) async {
    final rig = await buildRig();
    final router = GoRouter(
      routes: [
        for (final entry in screens.entries)
          GoRoute(
            path: entry.key,
            builder: (context, _) => entry.value(context),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(rig.wrap(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    return (rig, router);
  }

  /// Long enough that any release the navigation scheduled would have fired.
  Future<void> waitOutTheGrace(WidgetTester tester) =>
      tester.pump(kMusicBedReleaseGrace + const Duration(seconds: 3));

  testWidgets('the music keeps playing after walking to the next screen',
      (tester) async {
    final (rig, router) = await pumpApp(tester, {
      '/': (_) => const _Scored(name: 'map'),
      '/next': (_) => const _Scored(name: 'lesson'),
    });
    expect(rig.music.playing, isTrue);

    router.go('/next');
    await tester.pumpAndSettle();
    await waitOutTheGrace(tester);

    expect(
      rig.music.playing,
      isTrue,
      reason: 'the outgoing screen released after the incoming one claimed, '
          'and that release stopped music somebody was still asking for',
    );
    expect(
      rig.music.assetLoads,
      1,
      reason: 'and it is the same continuous take, not a restart',
    );
    await rig.shutDown(tester);
  });

  testWidgets('three screens deep, the music is still the same take',
      (tester) async {
    // Map -> lesson -> round is the shape of an ordinary visit, and it was the
    // second hop where the child heard it stop.
    final (rig, router) = await pumpApp(tester, {
      '/': (_) => const _Scored(name: 'map'),
      '/lesson': (_) => const _Scored(name: 'lesson'),
      '/round': (_) => const _Scored(name: 'round'),
    });

    for (final path in ['/lesson', '/round']) {
      router.go(path);
      await tester.pumpAndSettle();
      await waitOutTheGrace(tester);
      expect(
        rig.music.playing,
        isTrue,
        reason: 'went silent on the way to $path',
      );
    }
    expect(rig.music.assetLoads, 1);
    await rig.shutDown(tester);
  });

  testWidgets('leaving for a screen that wants no music does stop it',
      (tester) async {
    // The other half. If a release can no longer stop the bed then the bed
    // never stops, so this is the test that keeps the fix honest.
    final (rig, router) = await pumpApp(tester, {
      '/': (_) => const _Scored(name: 'map'),
      '/quiet': (_) => const Scaffold(body: Text('quiet')),
    });
    expect(rig.music.playing, isTrue);

    router.go('/quiet');
    await tester.pumpAndSettle();
    expect(
      rig.music.playing,
      isTrue,
      reason: 'inside the grace window, in case the next screen wants it',
    );

    await waitOutTheGrace(tester);
    expect(rig.music.playing, isFalse);
    await rig.shutDown(tester);
  });

  testWidgets('a screen that asks for a different bed gets it', (tester) async {
    // Opting into a challenge is one of the few places where a change in the
    // music is the point, and the claim count must not swallow it.
    final (rig, router) = await pumpApp(tester, {
      '/': (_) => const _Scored(name: 'map'),
      '/challenge': (_) =>
          const _Scored(name: 'challenge', bed: kChallengeMusicBed),
    });

    router.go('/challenge');
    await tester.pumpAndSettle();
    await waitOutTheGrace(tester);

    expect(rig.music.playing, isTrue);
    expect(rig.music.assetLoads, 2, reason: 'a real change of track');
    expect(rig.music.log.last, 'setAsset:${kMusicBeds[kChallengeMusicBed]}');
    await rig.shutDown(tester);
  });

  testWidgets('claims and releases balance over a round trip', (tester) async {
    // The count is only correct if it comes back to zero. A screen that claims
    // twice, or releases without claiming, would drift — and drift is invisible
    // until the day the music stops for good.
    final (rig, router) = await pumpApp(tester, {
      '/': (_) => const _Scored(name: 'map'),
      '/deep': (_) => const _Scored(name: 'deep'),
      '/quiet': (_) => const Scaffold(body: Text('quiet')),
    });
    expect(rig.engine.musicBedClaims, 1);

    router.go('/deep');
    await tester.pumpAndSettle();
    expect(
      rig.engine.musicBedClaims,
      1,
      reason: 'two screens overlapped, but only one is left standing',
    );

    router.go('/quiet');
    await tester.pumpAndSettle();
    expect(rig.engine.musicBedClaims, 0);

    router.go('/');
    await tester.pumpAndSettle();
    expect(rig.engine.musicBedClaims, 1);
    await rig.shutDown(tester);
  });

  testWidgets('a scope that changes its bed does not leak a claim',
      (tester) async {
    // MusicBedScope.didUpdateWidget re-points its claim rather than taking a
    // second one. A second claim would leave the count permanently high and the
    // music would outlive every screen.
    final rig = await buildRig();

    Widget app(String bed) => rig.wrap(
          MaterialApp(
            home: MusicBedScope(
              bed: bed,
              child: const Scaffold(body: Text('here')),
            ),
          ),
        );

    await tester.pumpWidget(app(kDefaultMusicBed));
    await tester.pumpAndSettle();
    expect(rig.engine.musicBedClaims, 1);

    await tester.pumpWidget(app(kChallengeMusicBed));
    await tester.pumpAndSettle();
    expect(rig.engine.musicBedClaims, 1);
    expect(rig.music.log.last, 'setAsset:${kMusicBeds[kChallengeMusicBed]}');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(rig.engine.musicBedClaims, 0);
    await rig.shutDown(tester);
  });
}
