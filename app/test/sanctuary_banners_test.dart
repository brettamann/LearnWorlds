// Every place's name banner has room of its own.
//
// Each node on the Sanctuary map has a parchment banner with its name, and a
// tap on the banner says the name out loud - it is how a child who cannot read
// the map finds out where a path goes. So two banners on top of each other are
// not just untidy: a tap meant for one says the other's name, or opens the
// other place.
//
// This could not happen while seven of the eleven places were asleep, because
// the map revealed them one at a time and most were never on screen together.
// Waking them all on 2026-09-24 put all eleven names on the map at once, and
// three pairs overlapped.

import 'package:critmath/data/sanctuary_sequence.dart';
import 'package:critmath/platform/sfx_engine.dart';
import 'package:critmath/providers/app_providers.dart';
import 'package:critmath/providers/exploration_provider.dart';
import 'package:critmath/providers/map_anchors_provider.dart';
import 'package:critmath/ui/screens/sanctuary_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/harness.dart';

class _Quiet extends SfxEngine {
  @override
  Future<void> startMusicBed(String variantKey) async {}
  @override
  void releaseMusicBed({Duration grace = kMusicBedReleaseGrace}) {}
}

const List<Size> _windows = <Size>[Size(1180, 820), Size(1366, 1024)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final window in _windows) {
    testWidgets('with every place explored, no two banners overlap at '
        '${window.width.toInt()}x${window.height.toInt()}', (tester) async {
      useViewSize(tester, window);
      final container = ProviderContainer(
        overrides: [sfxEngineProvider.overrideWithValue(_Quiet())],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(activityRegistryProvider.future);
        await container.read(conceptRegistryProvider.future);
        await container.read(sanctuaryAnchorsProvider.future);
      });
      container
          .read(explorationProvider.notifier)
          .replaceAll(kSanctuarySequence.toSet());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const SanctuaryMapScreen(),
                ),
                GoRoute(path: '/:x', builder: (_, __) => const SizedBox()),
              ],
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final banners = <String, Rect>{};
      for (final e in find.byType(Image).evaluate()) {
        final img = e.widget as Image;
        final provider = img.image;
        if (provider is! AssetImage ||
            !provider.assetName.contains('banner_parchment')) {
          continue;
        }
        String? owner;
        e.visitAncestorElements((a) {
          final k = a.widget.key;
          if (k is ValueKey<String> && k.value.startsWith('node-')) {
            owner = k.value.substring(5);
            return false;
          }
          return true;
        });
        final box = e.renderObject! as RenderBox;
        banners[owner ?? 'banner-${banners.length}'] =
            box.localToGlobal(Offset.zero) & box.size;
      }
      expect(banners.length, greaterThanOrEqualTo(11));

      final overlaps = <String>[];
      final names = banners.keys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          // A few pixels of parchment edge touching is fine; the ends are
          // decorative curls. A shared body is not.
          final a = banners[names[i]]!.deflate(6);
          final b = banners[names[j]]!.deflate(6);
          if (a.overlaps(b)) overlaps.add('${names[i]} / ${names[j]}');
        }
      }
      final offScreen = <String>[
        for (final n in names)
          if (banners[n]!.left < 0 || banners[n]!.right > window.width) n,
      ];
      expect(overlaps, isEmpty, reason: 'these banners cover each other');
      expect(offScreen, isEmpty, reason: 'these run off the screen');

      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
  }
}
