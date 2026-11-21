// The recording script and the clip key it names files with.
//
// The properties worth pinning are the ones whose failure is silent. A clip
// key that drifts doesn't crash — it just quietly stops matching, and every
// recorded line reverts to the synth voice with nothing in the logs. A key
// that collides is worse: two different sentences share a file and one of them
// speaks the other's words to a child.

import 'dart:io';

import 'package:critmath/data/narration_script.dart';
import 'package:critmath/data/number_words.dart';
import 'package:critmath/data/parade_species.dart';
import 'package:critmath/data/warm_lines.dart';
import 'package:critmath/engines/narration/narration_cue_log.dart';
import 'package:critmath/engines/narration/narration_export.dart';
import 'package:critmath/platform/narration_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('narrationClipKey', () {
    test('is stable for the vectors the JS harness pins too', () {
      // tools/tts/record/index.html implements this transform independently.
      // These exact strings appear in its self-check; if either side changes,
      // one of the two fails loudly instead of silently writing files the app
      // will never look up.
      expect(narrationClipKey('One.'), 'one__ccbaa073');
      expect(
        narrationClipKey('Not that one. Look again.'),
        'not-that-one-look-again__c6dc8490',
      );
      // Non-ASCII matters: the em dash has to hash as UTF-8 bytes, or Dart and
      // JS disagree about every prompt in the game.
      expect(
        narrationClipKey('Touch each fawn — and count out loud with me!'),
        'touch-each-fawn-and-count-out-loud-with-me__4a5087aa',
      );
    });

    test('collapses whitespace but respects case and punctuation', () {
      // A source reflow rewraps a concatenated literal without changing a
      // word. That must not orphan the recording.
      expect(
        narrationClipKey('One   two\n three'),
        narrationClipKey('One two three'),
      );
      // These read aloud differently, so they are different recordings.
      expect(narrationClipKey('Three.'), isNot(narrationClipKey('three.')));
      expect(narrationClipKey('Three.'), isNot(narrationClipKey('Three!')));
    });

    test('stays a legal, readable filename', () {
      final key = narrationClipKey(
        'Oh, thank goodness you are here! The fawns wander off every time I '
        'blink, and I cannot keep up with them at all.',
      );
      expect(key, matches(RegExp(r'^[a-z0-9-]+__[0-9a-f]{8}$')));
      expect(key.length, lessThanOrEqualTo(48 + 2 + 8));
      expect(
        key,
        startsWith('oh-thank-goodness'),
        reason: 'a folder of takes has to be browsable by eye',
      );
    });

    test('degenerate text still produces a usable name', () {
      // Punctuation-only would otherwise slug to the empty string and collide
      // every such line into one file.
      expect(narrationClipKey('...'), startsWith('line__'));
      expect(narrationClipKey('!!!'), startsWith('line__'));
      expect(narrationClipKey('...'), isNot(narrationClipKey('!!!')));
    });
  });

  group('the script', () {
    final batches = buildNarrationScript();

    test('batch ids are unique and no batch is empty', () {
      expect(batches.map((b) => b.id).toSet().length, batches.length);
      for (final b in batches) {
        expect(b.lines, isNotEmpty, reason: b.id);
      }
    });

    test('no two lines in the whole script share a clip key', () {
      // The failure this guards is a child hearing the wrong sentence.
      final texts = narrationScriptTexts();
      expect(narrationScriptClipKeys().length, texts.length);
    });

    test('covers every number word every counting runner can speak', () {
      // All five counting activities speak '<word>.' from the same table, so
      // one take of "Seven." serves all of them. That sharing is the entire
      // payoff of keying by text, and it silently breaks if a runner's word
      // list drifts from kSpelledCounts.
      final counts = batches.firstWhere((b) => b.id == 'counts');
      expect(counts.lines.length, 100);
      expect(counts.lines.first, 'One.');
      expect(counts.lines.last, 'One hundred.');
      for (final tens in kSpelledTens.skip(1)) {
        expect(counts.lines, contains('$tens.'));
      }
    });

    test('enumerated parade lines match what the runner would say', () {
      // The generator calls the same functions the runner calls. If someone
      // reworded one by restating the template here, this catches it.
      final prompts = batches.firstWhere((b) => b.id == 'parade-prompt');
      expect(prompts.lines.length, kParadeSpecies.length);
      expect(
        prompts.lines,
        contains(paradeCountingPrompt(kParadeSpecies.first)),
      );
    });

    test('no line asks an inanimate species to move under its own power', () {
      // The bug this guards. The keeper's opening ask used to say the
      // creatures "wander off every time I blink", which is fine for seven of
      // the eight species and nonsense for the eighth: golden-egg sits in
      // kAllParadeSpeciesIds, so about one visit in eight opened with "The
      // golden eggs wander off every time I blink."
      //
      // Nothing about the pool is wrong -- an egg is a perfectly good thing to
      // count. The template was wrong to assume its subject could walk.
      const inanimate = <String>['golden egg'];
      const locomotion = <String>[
        'wander',
        'walk',
        'run ',
        'trot',
        'fly',
        'flutter',
        'scamper',
        'scurry',
        'follow',
      ];
      for (final text in narrationScriptTexts()) {
        final lower = text.toLowerCase();
        if (!inanimate.any(lower.contains)) continue;
        for (final verb in locomotion) {
          expect(
            lower,
            isNot(contains(verb)),
            reason: 'an egg cannot "$verb": $text',
          );
        }
      }
    });

    test('template families expand to exactly what the runner speaks', () {
      // These lines are assembled at runtime by interpolating a catalog value
      // into a template. The script has to reproduce the result character for
      // character - em dash, spacing, punctuation - or the clip is filed under
      // a key the game never looks up, and the line silently reverts to the
      // browser voice with nothing reporting it. That is the exact failure
      // this whole batch of work was chasing, so it gets pinned.
      final texts = narrationScriptTexts().toSet();

      // wheres_buddy_runner: 'Here — Buddy is $prep ' '$landmark. Right there.'
      expect(texts, contains('Here — Buddy is above the pond. Right there.'));
      // shape_garden_runner: 'This one is a $_targetDisplay.'
      expect(texts, contains('This one is a right triangle.'));
      // shape_garden_runner: 'Tap all the $_targetPlural.'
      expect(texts, contains('Tap all the half circles.'));
      // two_attribute_hunt_runner
      expect(texts, contains("That's not both. ${warmMissLine(0)}"));
      // shape_garden_runner, after the lead was dropped:
      //   '${warmMissLine(n)} ' 'Find the $_targetPlural.'
      expect(
        texts,
        contains('${warmMissLine(1)} Find the pentagons.'),
        reason: 'the Shape Garden miss line no longer names the wrong shape',
      );
      // shape_garden_sort_by_attribute_runner
      expect(texts, contains('${warmMissLine(2)} Sort by size.'));
    });

    test('no family is left too large to voice', () {
      // Two used to be. `paradeTransitionLine` named the count, the species
      // finished AND the species coming next (1,792 sentences); Shape Garden's
      // wrong-tap line named the shape she tapped, a rotating warm line and
      // the target (648). Both were therefore stuck on the browser synth
      // voice, and both switched voice at a bad moment - between rounds, and
      // at the instant she got something wrong.
      //
      // Both were fixed upstream, by dropping the slot that was not earning
      // its place, rather than by recording 2,440 sentences. This test is what
      // stops a third one appearing quietly: a template whose variants
      // multiply past a few hundred cannot be voiced, and the right response
      // is to simplify the line, not to mark it incomplete.
      for (final batch in batches) {
        expect(
          batch.isComplete,
          isTrue,
          reason:
              '${batch.id} enumerates ${batch.lines.length} of '
              '${batch.variants} variants. Collapse the template instead of '
              'sampling it - see paradeTransitionLine for how.',
        );
        expect(
          batch.variants,
          lessThan(300),
          reason:
              '${batch.id} has ${batch.variants} variants, which is too '
              'many to record and a sign the line names one thing too many',
        );
      }
    });
  });

  group('the script stays runnable outside Flutter', () {
    // `tool/dump_narration_script.dart` hands the words to the Kokoro renderer,
    // and `dart run` cannot compile anything that reaches package:flutter. It
    // used to: narration_script.dart imported narration_audio.dart purely for
    // narrationClipKey, and narration_audio.dart imports flutter/services,
    // riverpod and just_audio. The compiler failure was a bare
    // "type 'InvalidType' is not a subtype of type 'FunctionType'", which names
    // nothing useful, so this test exists to fail with a sentence instead.
    test('nothing reachable from narration_script.dart imports Flutter', () {
      final seen = <String>{};
      final offenders = <String>[];

      void walk(String relativePath) {
        if (!seen.add(relativePath)) return;
        final file = File(relativePath);
        if (!file.existsSync()) return;
        final source = file.readAsStringSync();

        for (final match in RegExp(
          r"^import\s+'([^']+)'",
          multiLine: true,
        ).allMatches(source)) {
          final target = match.group(1)!;
          if (target.startsWith('package:flutter') ||
              target.startsWith('package:just_audio') ||
              target.startsWith('package:flutter_riverpod')) {
            offenders.add('$relativePath -> $target');
            continue;
          }
          if (target.startsWith('dart:') || target.startsWith('package:')) {
            continue;
          }
          walk(p.normalize(p.join(p.dirname(relativePath), target)));
        }
      }

      walk('lib/data/narration_script.dart');
      expect(
        offenders,
        isEmpty,
        reason:
            'these imports break `dart run '
            'tool/dump_narration_script.dart`: '
            '${offenders.join(", ")}',
      );
    });
  });

  group('the export', () {
    test('counts recorded, remaining and orphaned clips', () {
      final scripted = narrationScriptTexts().toList()..sort();
      final recordedTwo = <String>{
        narrationClipKey(scripted[0]),
        narrationClipKey(scripted[1]),
        // A clip whose line no longer exists: recorded, then reworded.
        'some-retired-line__deadbeef',
      };

      final coverage = narrationCoverage(
        observed: const <ObservedCue>[],
        clipKeys: recordedTwo,
      );
      expect(coverage.scripted, scripted.length);
      expect(coverage.recorded, 2);
      expect(coverage.remaining, scripted.length - 2);
      expect(coverage.orphaned, 1);

      final export = buildNarrationExport(
        observed: const <ObservedCue>[],
        clipKeys: recordedTwo,
      );
      expect(export['orphans'], ['some-retired-line__deadbeef']);
      expect((export['coverage'] as Map<String, int>)['recorded'], 2);
    });

    test('lines heard while playing land in their own batch', () {
      final export = buildNarrationExport(
        observed: const <ObservedCue>[
          ObservedCue(
            text: 'Put the round one in the round basket.',
            cueId: 'sort-attr:r0:prompt',
          ),
          // Already enumerated, so it must NOT be duplicated into 'observed'.
          ObservedCue(text: 'One.', cueId: 'parade:tap-r0-1'),
        ],
        clipKeys: const <String>{},
      );
      final batches = export['batches'] as List<dynamic>;
      final observed =
          batches.firstWhere(
                (b) => (b as Map<String, dynamic>)['id'] == 'observed',
              )
              as Map<String, dynamic>;
      final lines = observed['lines'] as List<dynamic>;
      expect(lines.length, 1);
      expect(
        (lines.single as Map<String, dynamic>)['text'],
        'Put the round one in the round basket.',
      );
    });

    test('omits the observed batch entirely when nothing is left over', () {
      final export = buildNarrationExport(
        observed: const <ObservedCue>[
          ObservedCue(text: 'One.', cueId: 'parade:tap-r0-1'),
        ],
        clipKeys: const <String>{},
      );
      final ids = (export['batches'] as List<dynamic>)
          .map((b) => (b as Map<String, dynamic>)['id'])
          .toList();
      expect(ids, isNot(contains('observed')));
    });
  });
}
