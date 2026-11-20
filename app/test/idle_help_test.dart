// What happens when she does nothing?
//
// A wrong tap that produces no reaction is indistinguishable from a frozen
// app - that was the diagnosis this whole engagement pass started from, and
// every runner now answers a wrong tap. Nobody asked the other half of the
// question. A five-year-old who does not know which shape has four sides does
// not tap the wrong one; she sits there. Standing still is the most likely
// thing a stuck child does, and it is the one input the game cannot see.
//
// `HintLadder` was written for exactly this and went into six runners. It was
// missing from four, and they were the four hardest ones:
//
//   * shape-garden-sort  - "Sort by number of sides." The one round that asks
//     about a property of a shape rather than about the shape.
//   * two-attribute-hunt - two attributes at once, the hardest thing the
//     Shape Garden ever asks.
//   * build-a-habitat    - a three-sentence instruction, spoken once, to a
//     child who cannot read the replay button.
//   * wheres-buddy       - one preposition. Its spec-mandated demonstration
//     fires "after 3 wrong taps", which only ever happens if she guesses.
//
// Measured, not guessed: mount each playfield, touch nothing for twenty
// seconds, and see whether anything is said. Four of ten said nothing at all.
//
// The second guard here is the one that made the first six worth having. The
// top rung of the ladder explains and then does the thing it just explained,
// and the doing speaks too - and `speak` cuts off whatever is in flight. So
// the explanation, which is the entire content of a demonstration, was cut
// off a few milliseconds after it started, in every activity that had a
// ladder, every time. Nothing looked wrong; the lines were all there in the
// log, back to back. See HintLadder for the rule that fixes it.

import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/widgets/caption_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'playfield_caption_band_test.dart' show playfields;
import 'support/harness.dart';

/// The reference window, as `README.md` and the rest of the suite use.
const Size _size = Size(1180, 820);

/// How long she is allowed to be left with nothing.
///
/// The ladder's own top rung is fifteen seconds and one activity's authored
/// thresholds run a little longer, so this is that plus room, not a target.
const Duration _kPatience = Duration(seconds: 20);

/// The shortest a spoken line can take, per `narrationSpokenEstimate`, which
/// clamps at 0.8s. Two lines closer together than that means the first one was
/// cut off - there was not time to say it.
const int _kShortestLineMs = 800;

/// One thing the game said, and when.
typedef _Said = ({int atMs, String text});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Mounts [key]'s playfield, lets it settle, then leaves it strictly alone
  /// for [_kPatience] and returns everything it said in that time.
  Future<List<_Said>> idleFor(WidgetTester tester, String key) async {
    useViewSize(tester, _size);

    final container = ProviderContainer(
      // Pinned so the seeded scatter is the same every run.
      overrides: [sessionIdProvider.overrideWithValue('idle-guard')],
    );
    addTearDown(container.dispose);

    var clock = 0;
    final said = <_Said>[];
    container.listen<NarrationLine?>(narrationPlayerProvider, (_, next) {
      if (next != null) said.add((atMs: clock, text: next.text));
    });

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

    // Settle: the prompt the round opens with, which is not help - it is what
    // she has already heard and not acted on.
    //
    // Explicit frames rather than pumpAndSettle: BuddyWidget breathes on a
    // repeating controller, so a playfield never settles.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    said.clear();

    // Now she does nothing at all. Fifty-millisecond steps so the timestamps
    // are fine enough to tell a cut-off line from a queued one.
    const step = Duration(milliseconds: 50);
    for (var i = 0; i * step.inMilliseconds < _kPatience.inMilliseconds; i++) {
      clock += step.inMilliseconds;
      await tester.pump(step);
    }
    return said;
  }

  /// Runs the timers the runners leave behind, so teardown is clean.
  ///
  /// Unmount first. Where's Buddy demonstrates, resolves the round and starts
  /// the next one, which stalls and gets demonstrated at in turn - so a
  /// mounted playfield creates new timers exactly as fast as pumping drains
  /// them, and the loop never converges.
  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  group('a child who is doing nothing', () {
    for (final key in playfields().keys) {
      testWidgets('is offered help in $key', (tester) async {
        final said = await idleFor(tester, key);
        expect(
          said,
          isNotEmpty,
          reason: '$key left her with nothing for '
              '${_kPatience.inSeconds}s. Every playfield needs a HintLadder, '
              'or standing still is indistinguishable from the app being '
              'frozen.',
        );
        await drain(tester);
      });
    }
  });

  group('the game never talks over itself', () {
    for (final key in playfields().keys) {
      testWidgets('while she is idle in $key', (tester) async {
        final said = await idleFor(tester, key);
        for (var i = 1; i < said.length; i++) {
          final gap = said[i].atMs - said[i - 1].atMs;
          expect(
            gap,
            greaterThanOrEqualTo(_kShortestLineMs),
            reason: '$key cut off "${said[i - 1].text}" after ${gap}ms with '
                '"${said[i].text}". Nothing she did caused this, so the '
                'second line has to wait: enqueue it rather than speaking it.',
          );
        }
        await drain(tester);
      });
    }
  });
}
