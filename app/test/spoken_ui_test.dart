// The two places the game still spoke in the browser's voice.
//
// `ReadAloudGate` speaks a control's label on the tap that acts, and it has
// done since the gate was written. What was never true is that those words
// could be recorded: they were typed inline at each call site, and the literal
// sweep in `tool/narration_sources.dart` keeps only strings that end like a
// sentence — the filter that stops every semantic string in `lib/` becoming a
// clip, and which throws out "Done", "Nice!", "Flat" and "Continue" with them.
// So the most-pressed control in the game answered in a synth voice, one beat
// after the keeper had finished a sentence in the narrator's, once a round, on
// every screen.
//
// The other is the mystery egg. Its eight stage messages — a jump, a crack, a
// snout — are the whole story of the game's long-cycle reward, and not one of
// them had ever been said out loud in any voice. They live on
// `kMysteryEggTrack` in `lib/models/`, which the sweep does not read (it reads
// `lib/data/` and files that mention narration), so the renderer could not see
// them; what a child got when she tapped her egg was a paragraph of prose and
// a button reading "Close".
//
// This is the same failure in the same shape for the third and fourth time —
// see map_labels_test.dart and sub_mode_picker_test.dart. The shape is always
// a spoken string somewhere no enumeration can reach it, and the symptom is
// never an error: it is a change of narrator mid-session.

import 'dart:io';

import 'package:critmath/data/button_labels.dart';
import 'package:critmath/data/narration_script.dart';
import 'package:critmath/data/warm_lines.dart';
import 'package:critmath/models/reward_track.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fixtures.dart';

/// Files that are allowed to hold a `label:` string literal, because holding
/// them is their job.
const Set<String> _labelCatalogs = <String>{
  'lib/data/button_labels.dart',
  'lib/data/map_labels.dart',
  'lib/data/sub_mode_picker_data.dart',
  'lib/data/sort_attribute_words.dart',
};

void main() {
  group('every word a button says', () {
    test('is in the recording script', () {
      final script = narrationScriptTexts();
      for (final label in spokenButtonLabels()) {
        expect(
          script,
          contains(narrationTextNormalize(label)),
          reason: '"$label" is spoken by ReadAloudGate and the renderer will '
              'never see it',
        );
      }
    });

    test('has a rendered clip', () {
      for (final label in spokenButtonLabels()) {
        expect(
          narrationClipFor(label),
          isNotNull,
          reason: 'no clip for "$label". Re-render:\n'
              '  cd app && dart run tool/dump_narration_script.dart '
              '> ../tools/tts/kokoro/script.json\n'
              '  node tools/tts/kokoro/render.mjs render',
        );
      }
    });

    test('and no two controls say the same thing', () {
      final labels = spokenButtonLabels();
      expect(labels.toSet(), hasLength(labels.length));
    });

    test('and none is typed inline where nothing can enumerate it', () {
      // The check that actually holds the line. Every fix above is one
      // `label: 'Whatever'` away from being undone, and it would render
      // fine, speak fine, and speak in the wrong voice.
      //
      // `caption:` is in here now because the first version was not, and the
      // five side-rail buttons on the two map screens went straight through
      // it: their words are passed as `caption:`, and MapRailButton was not
      // gated at all, so they were not in the wrong voice - they were in no
      // voice, and made no sound either. A guard that names one parameter
      // catches only the parameter it names.
      final offenders = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        final rel = path.substring(path.indexOf('lib/'));
        if (_labelCatalogs.contains(rel)) continue;
        // Adult-facing; nothing here is read to a child.
        if (rel.contains('settings_screen')) continue;
        final source = file.readAsStringSync();
        if (RegExp(r'''\b(label|caption):\s*['"]''').hasMatch(source)) {
          offenders.add(rel);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'a spoken label is typed inline in: $offenders — it belongs '
            'in lib/data/button_labels.dart',
      );
    });

    test('the decade chips read as words', () {
      // The button shows "40" because the numeral is what K.CC.3 is teaching.
      // The clip says "forty", because Kokoro reads the digits — which is the
      // pairing the chip exists for. A chip captioned "Forty" would be
      // teaching her the word she already has.
      expect(decadeLabel(0), '10');
      expect(decadeLabel(9), '100');
      for (var i = 0; i < 10; i++) {
        final clip = narrationClipFor(decadeLabel(i));
        expect(clip, isNotNull, reason: 'no clip for ${decadeLabel(i)}');
        // A render that failed on a numeral would leave a near-empty file
        // rather than an error, and it would be silent in the game.
        expect(
          clip!.lengthSync(),
          greaterThan(2000),
          reason: '${decadeLabel(i)} rendered to almost nothing',
        );
      }
    });
  });

  group('the mystery egg', () {
    test('says every one of its stages out loud', () {
      final script = narrationScriptTexts();
      for (final stage in kMysteryEggTrack.stages) {
        expect(
          script,
          contains(narrationTextNormalize(stage.message)),
          reason: 'stage message not in the script: "${stage.message}"',
        );
        expect(narrationClipFor(stage.message), isNotNull);
      }
    });

    test('including the one it hatches on', () {
      // The payoff line of the whole arc, and the easiest to forget because
      // completeStage is not in `stages`.
      final done = kMysteryEggTrack.completeStage.message;
      expect(narrationScriptTexts(), contains(narrationTextNormalize(done)));
      expect(narrationClipFor(done), isNotNull);
    });

    test('and the sheet has something to say without one', () {
      // Only reachable from a save older than the reward track, but the whole
      // content of that sheet is the egg, so the fallback has to speak too.
      expect(
        narrationScriptTexts(),
        contains(narrationTextNormalize(kRoundCompleteFallbackLine)),
      );
      expect(narrationClipFor(kRoundCompleteFallbackLine), isNotNull);
    });

    test('and every stage has a sprite on disk to say it over', () {
      for (final stage in kMysteryEggTrack.stages) {
        expect(
          File(stage.spriteAsset).existsSync(),
          isTrue,
          reason: '${stage.spriteAsset} is missing',
        );
      }
      expect(
        File(kMysteryEggTrack.completeStage.spriteAsset).existsSync(),
        isTrue,
      );
    });
  });
}
