// Two properties of the whole game that only show up by playing it.
//
// 1. **Everything she hears has a voice.** A line spoken by the game but
//    missing from the recording script plays in the browser's synth voice -
//    a change of narrator mid-round, which reads as broken rather than
//    missing. The script enumerates what the catalogs can produce; this
//    checks what the game actually said, by playing each Sanctuary activity
//    with a pretend child who taps things and sits still. Written after the
//    same mistake was made three times in one day: a hint that sliced the
//    advice off the end of a miss line at runtime, producing a sentence no
//    catalog contained.
//
// 2. **A child who does nothing never has the round finished for her.** The
//    first real play session reported the game completing her taps for her,
//    and a hint ladder that restarts itself from its own top rung does the
//    same thing slowly - one demonstration every fifteen seconds until the
//    round is done. So each playfield sits untouched for ninety seconds and
//    no round may resolve. (Where's Buddy is exempt: its spec demonstrates
//    and resolves the round, and says so.)

import 'dart:math' as math;

import 'package:critmath/data/narration_script.dart';
import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/providers/wallet_provider.dart';
import 'package:critmath/ui/widgets/caption_overlay.dart';
import 'package:critmath/ui/widgets/sanctuary_round_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'playfield_caption_band_test.dart' show playfields;
import 'support/harness.dart';

const Size _size = Size(1180, 820);

/// Keys the new playfields put on things a child taps.
const List<String> _tapPrefixes = <String>[
  'pond-frog',
  'pond-pad',
  'pantry-item',
  'pantry-crate',
  'number-card',
  'bench-choice',
  'picnic-treat',
  'picnic-diner',
  'picnic-same',
  'story-critter',
  'story-check',
  'scribe-fly',
  'garden-r',
];

Future<ProviderContainer> _mount(WidgetTester tester, String key) async {
  useViewSize(tester, _size);
  final container = ProviderContainer(
    overrides: [sessionIdProvider.overrideWithValue('play-through')],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  return container;
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

bool _isShellPlayfield(WidgetTester tester) =>
    find.byType(SanctuaryRoundShell).evaluate().isNotEmpty;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final scriptKeys = <String>{
    for (final line in narrationScriptTexts()) narrationClipKey(line),
  };

  group('everything she hears has a voice', () {
    for (final key in playfields().keys) {
      testWidgets(key, (tester) async {
        final container = await _mount(tester, key);
        await tester.pump();
        if (!_isShellPlayfield(tester)) {
          // The older activities have lines deliberately left to the synth
          // voice (see paradeTransitionLine); narration_render_test covers
          // them through the script instead.
          await _drain(tester);
          return;
        }
        final heard = <String>{};
        container.listen<NarrationLine?>(narrationPlayerProvider, (_, l) {
          if (l != null) heard.add(l.text);
        });
        // A pretend child: taps whatever there is to tap, in a shuffled
        // order, with pauses long enough for the hint ladder to speak.
        final rng = math.Random(key.hashCode);
        for (var step = 0; step < 90; step++) {
          final targets = find
              .byWidgetPredicate((w) {
                final k = w.key;
                return k is ValueKey<String> &&
                    _tapPrefixes.any(k.value.startsWith);
              })
              .evaluate()
              .toList();
          if (targets.isNotEmpty && step % 6 != 5) {
            final t = targets[rng.nextInt(targets.length)];
            final box = t.renderObject;
            if (box is RenderBox && box.hasSize && box.attached) {
              final c = box.localToGlobal(box.size.center(Offset.zero));
              if (c.dx >= 0 &&
                  c.dy >= 0 &&
                  c.dx < _size.width &&
                  c.dy < _size.height) {
                await tester.tapAt(c);
              }
            }
            await tester.pump(const Duration(milliseconds: 700));
          } else {
            // Sit still for a while, so the hints get their turn.
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(seconds: 1));
            }
          }
        }
        final unvoiced = heard
            .where((line) => !scriptKeys.contains(narrationClipKey(line)))
            .toList();
        expect(heard, isNotEmpty);
        expect(
          unvoiced,
          isEmpty,
          reason: 'said by the game and missing from the recording script, so '
              'spoken in the synth voice. Build the line in the activity\'s '
              '_words.dart and list it there - never cut a sentence up at '
              'runtime.',
        );
        await _drain(tester);
      });
    }
  });

  group('a child who does nothing', () {
    for (final key in playfields().keys) {
      if (key == 'wheres-buddy') continue;
      testWidgets('never has the round in $key finished for her',
          (tester) async {
        final container = await _mount(tester, key);
        for (var i = 0; i < 90; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(
          container.read(walletProvider),
          0,
          reason: 'a round resolved with nobody touching anything - the hint '
              'ladder did her turn for her',
        );
        await _drain(tester);
      });
    }
  });
}
