// NarrationPlayer unit tests — proves the state transitions independent of UI.

import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
import 'package:critmath/platform/narration_audio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NarrationPlayer', () {
    test('starts with no active line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(narrationPlayerProvider), isNull);
    });

    test('speak() replaces the active line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(narrationPlayerProvider.notifier).speak(
            const NarrationLine(text: 'One.', cueId: 'we-try-after-tap-1'),
          );
      expect(container.read(narrationPlayerProvider)?.text, 'One.');
      container.read(narrationPlayerProvider.notifier).speak(
            const NarrationLine(text: 'Two.', cueId: 'we-try-after-tap-2'),
          );
      expect(container.read(narrationPlayerProvider)?.text, 'Two.');
    });

    test('clear() removes the active line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(narrationPlayerProvider.notifier).speak(
            const NarrationLine(text: 'One.'),
          );
      container.read(narrationPlayerProvider.notifier).clear();
      expect(container.read(narrationPlayerProvider), isNull);
    });
  });

  group('recorded-clip lookup', () {
    test('the folder-holding .gitkeep is not mistaken for a clip', () {
      // This is the state the app ships in: the asset directory has to be
      // declared for the build to succeed, so it contains exactly one file
      // and that file is not audio.
      expect(
        narrationClipsFrom(const ['assets/audio/narration/.gitkeep']),
        isEmpty,
      );
    });

    test('only the narration folder is scanned', () {
      final clips = narrationClipsFrom(const [
        'assets/audio/narration/.gitkeep',
        'assets/audio/narration/one__ccbaa073.wav',
        'assets/audio/narration/nested/deep.wav',
        'assets/audio/sfx/coin.mp3',
        'assets/buddy/body/gold.png',
      ]);
      expect(clips, {
        'one__ccbaa073': 'assets/audio/narration/one__ccbaa073.wav',
      });
    });
  });

  group('NarrationCueLog', () {
    test('collapses lines that share words across different cueIds', () {
      // The whole reason the log is keyed by text: 'parade:tap-r0-3' and
      // 'parade:tap-r4-3' are different slots that say the same word, and
      // recording them separately would be two takes of one syllable.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final player = container.read(narrationPlayerProvider.notifier);

      player
        ..speak(const NarrationLine(text: 'Three.', cueId: 'parade:tap-r0-3'))
        ..speak(const NarrationLine(text: 'Three.', cueId: 'parade:tap-r4-3'))
        // A line with no cueId is recordable too -- the words are the key, so
        // there is nothing special about it. The old scheme dropped these.
        ..speak(const NarrationLine(text: 'Nice.'));

      final log = container.read(narrationCueLogProvider);
      expect(log.keys, unorderedEquals(<String>['Three.', 'Nice.']));
      expect(
        log['Three.']!.cueId,
        'parade:tap-r0-3',
        reason: 'first sighting wins, so the export can group by activity',
      );
    });

    test('normalises whitespace so a reflowed literal is not a new line', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(narrationPlayerProvider.notifier)
        ..speak(const NarrationLine(text: 'Look   again.'))
        ..speak(const NarrationLine(text: 'Look again.'));
      expect(container.read(narrationCueLogProvider).length, 1);
    });
  });

  group('the queue', () {
    // Why this exists: `speak` cancels whatever is in flight, so a beat with
    // two things to say used to lose the first one mid-word. Every runner
    // carries a comment about it. `enqueue` is the way to say the second
    // thing without cutting off the first.
    //
    // No clips are bundled in a unit test, so every line here takes the
    // system-TTS path and finishes after `narrationSpokenEstimate`. fakeAsync
    // drives that clock rather than waiting on it.

    test('an enqueued line waits for the one in flight, then speaks', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final player = container.read(narrationPlayerProvider.notifier);

        player.speak(const NarrationLine(text: 'Five fawns! Well counted.'));
        player
            .enqueue(const NarrationLine(text: 'A new friend! Cloud Unicorn.'));

        expect(player.queuedCount, 1);
        expect(
          container.read(narrationPlayerProvider)?.text,
          'Five fawns! Well counted.',
          reason: 'the first line keeps the caption until it is done',
        );

        async.elapse(const Duration(seconds: 30));
        expect(player.queuedCount, 0);
        expect(
          container.read(narrationPlayerProvider)?.text,
          'A new friend! Cloud Unicorn.',
        );
      });
    });

    test('enqueue speaks straight away when nothing is in flight', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final player = container.read(narrationPlayerProvider.notifier);
        player.enqueue(const NarrationLine(text: 'Hello.'));
        expect(container.read(narrationPlayerProvider)?.text, 'Hello.');
        expect(player.queuedCount, 0);
        async.elapse(const Duration(seconds: 30));
      });
    });

    test('speak() drops the queue rather than talking over the interruption',
        () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final player = container.read(narrationPlayerProvider.notifier);

        player.speak(const NarrationLine(text: 'First.'));
        player.enqueue(const NarrationLine(text: 'Queued.'));
        // She tapped. Whatever was going to be said next is stale.
        player.speak(const NarrationLine(text: 'Three.'));

        expect(player.queuedCount, 0);
        async.elapse(const Duration(seconds: 30));
        expect(container.read(narrationPlayerProvider)?.text, 'Three.');
      });
    });

    test('clear() drops the queue too', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final player = container.read(narrationPlayerProvider.notifier);
        player.speak(const NarrationLine(text: 'First.'));
        player.enqueue(const NarrationLine(text: 'Queued.'));
        player.clear();
        expect(player.queuedCount, 0);
        async.elapse(const Duration(seconds: 30));
        expect(container.read(narrationPlayerProvider), isNull);
      });
    });

    test('the queue is bounded, so nothing answers a tap from a minute ago',
        () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final player = container.read(narrationPlayerProvider.notifier);
        player.speak(const NarrationLine(text: 'First.'));
        for (var i = 0; i < 8; i++) {
          player.enqueue(NarrationLine(text: 'Queued $i.'));
        }
        expect(player.queuedCount, lessThanOrEqualTo(2));
        async.elapse(const Duration(seconds: 60));
      });
    });

    test('a longer line is estimated to take longer', () {
      // The estimate is what orders the queue on the synth path, so it has to
      // at least move in the right direction.
      expect(
        narrationSpokenEstimate('One.'),
        lessThan(
          narrationSpokenEstimate(
            'Tap each glowing corner to place a clay ball.',
          ),
        ),
      );
      expect(narrationSpokenEstimate(''), greaterThan(Duration.zero));
    });
  });
}
