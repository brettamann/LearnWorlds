// The sweep that finds spoken lines written directly in Dart.
//
// This exists because of a real and badly-shaped bug. The narration was
// rendered in three passes, and after each one it *seemed* fixed: first only
// the counting words and Counting Parade were voiced, then the lesson JSON,
// and both times the remaining lines fell back to the browser synth. That is
// worse than silence — it is Haddock speaking in one voice on the map and a
// different voice in the lesson, which reads as broken rather than missing.
//
// The failure was invisible from inside Dart: nothing crashes, nothing logs,
// the fallback works exactly as designed. So the guard has to be a test.

import 'package:critmath/data/narration_script.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/narration_sources.dart';

void main() {
  // Walking lib/ once is cheap, and every test here asks about the same sweep.
  final literals = dartNarrationLiterals('lib').toSet();

  group('dartNarrationLiterals', () {
    test('finds the sanctuary prologue, which is a plain const list', () {
      // sanctuary_cutscene_screen.dart speaks `_pages[_page]` — an identifier,
      // not a literal — so extracting the `text:` argument of NarrationLine
      // could never find these. It is the first thing anyone hears in the game.
      expect(literals, contains("Well hello there, adventurer! I'm Haddock."));
      expect(literals, contains("You'll be my honorary keeper!"));
      expect(
        literals,
        contains('I need your help around the various parts of the sanctuary.'),
      );
    });

    test('handles both quote styles and escaped apostrophes', () {
      // The prologue mixes them: 'I\'m Haddock.' next to "Thing is, it's...".
      // A regex over one quote style silently drops half the monologue.
      expect(literals, contains("Thing is, it's a lot for anyone to do."));
      expect(literals, contains("I'm in charge of this mystical sanctuary."));
    });

    test('finds keeperLines held in data catalogs that never mention narration',
        () {
      // build_a_habitat_blueprints.dart contains no NarrationLine and no
      // narration provider — the runner speaks its strings. Scoping the sweep
      // to "files that narrate" would drop these.
      expect(literals, contains('A fawn shelter! Beautifully built.'));
    });

    test('joins adjacent literals into the one sentence they form', () {
      // Long lines are wrapped as 'part one ' 'part two', which Dart
      // concatenates. Treating those as two fragments would render two clips,
      // neither of which matches what is spoken.
      final joined = literals.where((l) => l.length > 90);
      expect(
        joined,
        isNotEmpty,
        reason: 'no long line survived the sweep, so concatenation is broken',
      );
    });

    test('drops interpolated templates rather than rendering the raw text', () {
      // 'Tap all the $_targetPlural.' is a template. Rendering it literally
      // would produce a clip saying the variable name, keyed to a sentence
      // nothing ever speaks.
      for (final line in literals) {
        expect(
          line,
          isNot(contains(r'$')),
          reason: 'interpolated template leaked into the script: $line',
        );
      }
    });

    test('leaves UI copy out of the script', () {
      // Settings descriptions read like sentences and are never spoken. They
      // come from files that never narrate, which is exactly the signal used
      // to exclude them.
      for (final line in literals) {
        expect(
          line,
          isNot(contains('Clears exploration, reward stage')),
          reason: 'settings copy is not narration',
        );
      }
    });

    test('does not sweep the script generator and render its own notes', () {
      // narration_script.dart lives in lib/data/ and so counted as a catalog,
      // which meant its `note:` fields — developer prose explaining each
      // batch — were lexed as spoken lines. Twelve got rendered, one of them
      // nineteen seconds explaining a const in a runner. Nothing could ever
      // play them, because a clip is only looked up by the text of a line
      // someone actually speaks, so they were pure download weight.
      for (final batch in buildNarrationScript()) {
        expect(
          literals,
          isNot(contains(batch.note)),
          reason: 'batch "${batch.id}" note leaked into the script',
        );
      }
    });

    test('still reaches the other catalogs in lib/data/', () {
      // The exclusion above is one filename, not a retreat from sweeping
      // lib/data/ — which is where the habitat keeperLines live.
      expect(literals, contains('A fawn shelter! Beautifully built.'));
    });

    test('never yields something that would make a nonsense filename', () {
      for (final line in literals) {
        expect(line.trim(), line, reason: 'untrimmed: "$line"');
        expect(line, isNotEmpty);
        expect(
          line.length,
          lessThanOrEqualTo(300),
          reason: 'suspiciously long, probably not a spoken line: $line',
        );
      }
    });
  });
}
