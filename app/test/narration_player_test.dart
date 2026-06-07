// NarrationPlayer unit tests — proves the state transitions independent of UI.

import 'package:critmath/engines/narration/narration_line.dart';
import 'package:critmath/engines/narration/narration_player.dart';
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
}
