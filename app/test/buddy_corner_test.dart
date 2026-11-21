// Nothing she has to touch may sit underneath Buddy.
//
// Buddy stands in the bottom-left corner of every playfield, drawn over the
// top of the round, and he answers a poke - which is lovely, and which means
// he takes the touch. So a frog or a card that slides under him is not
// partly hidden, it is untouchable: her finger lands on Buddy, Buddy giggles,
// and the thing she was aiming at never hears about it.
//
// Found by rendering Ten-Frame Pond's two-colour bank, where the fourth green
// frog sat squarely under him. The caption-band and tap-size checks could not
// have seen it: the frog was above the band and a perfectly good size.

import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/characters/buddy_companion.dart';
import 'package:critmath/ui/common/caption_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'playfield_caption_band_test.dart' show playfields;
import 'support/harness.dart';

const Size _size = Size(1180, 820);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final key in playfields().keys) {
    testWidgets('$key keeps its targets out from under Buddy', (tester) async {
      useViewSize(tester, _size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionIdProvider.overrideWithValue('buddy-guard')],
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: playfields()[key]!),
                  const CaptionOverlay(),
                ],
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final buddyTouch = find.descendant(
        of: find.byType(BuddyCompanion),
        matching: find.byType(GestureDetector),
      );
      if (buddyTouch.evaluate().isNotEmpty) {
        final buddyBox = buddyTouch.evaluate().first.renderObject! as RenderBox;
        final buddy = buddyBox.localToGlobal(Offset.zero) & buddyBox.size;
        final buddyElements = buddyTouch.evaluate().toSet();

        final offenders = <String>[];
        final screen = _size.width * _size.height;
        for (final type in <Type>[
          GestureDetector,
          Draggable<Object>,
          DragTarget<Object>,
          InkWell,
        ]) {
          for (final e in find.byType(type).evaluate()) {
            if (buddyElements.contains(e)) continue;
            // Skip anything inside Buddy himself.
            var inBuddy = false;
            e.visitAncestorElements((a) {
              if (a.widget is BuddyCompanion) inBuddy = true;
              return !inBuddy;
            });
            if (inBuddy) continue;
            final box = e.renderObject;
            if (box is! RenderBox || !box.hasSize) continue;
            final r = box.localToGlobal(Offset.zero) & box.size;
            // Full-bleed surfaces - the clearing's tap-anywhere, a pond you
            // can tap anywhere on - are not targets.
            if (r.width * r.height > screen * 0.35) continue;
            final overlap = r.intersect(buddy);
            if (overlap.width <= 0 || overlap.height <= 0) continue;
            final share = overlap.width * overlap.height / (r.width * r.height);
            if (share > 0.2) {
              offenders.add(
                '$type ${r.width.toStringAsFixed(0)}x'
                '${r.height.toStringAsFixed(0)} at '
                '(${r.left.toStringAsFixed(0)}, ${r.top.toStringAsFixed(0)}) '
                '- ${(share * 100).toStringAsFixed(0)}% under Buddy',
              );
            }
          }
        }
        expect(
          offenders,
          isEmpty,
          reason: 'Buddy takes the touch, so these cannot be tapped where '
              'they overlap him',
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
  }
}
