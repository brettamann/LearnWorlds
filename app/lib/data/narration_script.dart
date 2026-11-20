// NarrationScript — every line the game can say, enumerated for recording.
//
// The problem this solves: you cannot record a voice for lines you cannot
// list. Playing the game and logging what it said (NarrationCueLog) works but
// demands one heroic playthrough that touches every branch, and it still
// misses the species and counts that session's seed happened not to pick.
//
// So this walks the same catalogs and calls the same line-building functions
// the runners call — paradeIntroDialog, warmMissLine, kSpelledCounts — and
// emits the result as batches sized for a single sitting at a microphone.
// Calling the real functions rather than restating the templates is the whole
// discipline here: if a line is reworded, this file emits the new wording
// automatically, and the old recording shows up as an orphan in the export.
//
// Two things it is honest about:
//
//   - **Sharing.** Recorded clips are keyed by their words, so "Seven." is one
//     take that serves Counting Parade, Count On By Ones, Count Forward From
//     N, Count Out N and the challenge layer. The number batch is 100 lines,
//     not 100 lines per activity.
//
//   - **Combinatorial families.** paradeTransitionLine names the count, the
//     species just finished and the species coming next — 1,792 variants,
//     of which one session speaks four. Those are marked incomplete and left to
//     system TTS on purpose. Recording them is not a long afternoon, it is a
//     career, and the export says so rather than letting you find out at line
//     three hundred.

import '../activities/activity_ids.dart';
import '../engines/activity_runner/round_plan.dart';
import '../engines/mastery/round_outcome.dart';
import '../models/reward_track.dart';
import '../platform/narration_clip_key.dart';
import 'button_labels.dart';
import 'care_pantry_words.dart';
import 'caretakers_bench_words.dart';
import 'count_forward_from_n_rounds.dart';
import 'count_on_by_ones_rounds.dart';
import 'count_out_n_rounds.dart';
import 'creature_card_catalog.dart';
import 'fluency_words.dart';
import 'habitat_words.dart';
import 'long_parade_rounds.dart';
import 'map_labels.dart';
import 'number_words.dart';
import 'parade_species.dart';
import 'picnic_baskets_words.dart';
import 'sanctuary_decor_catalog.dart';
import 'scribes_tower_words.dart';
import 'shape_words.dart';
import 'sort_attribute_words.dart';
import 'storytellers_pond_words.dart';
import 'sub_mode_picker_data.dart';
import 'ten_frame_words.dart';
import 'tens_parade_words.dart';
import 'warm_lines.dart';
import 'wheres_buddy_words.dart';

/// A group of lines meant to be recorded in one continuous take.
class ScriptBatch {
  const ScriptBatch({
    required this.id,
    required this.title,
    required this.note,
    required this.lines,
    int? variants,
  }) : _variants = variants;

  /// Stable slug, used as the batch filename in the export.
  final String id;

  /// What a human calls this batch.
  final String title;

  /// Direction for the person reading it aloud.
  final String note;

  /// The exact sentences, in reading order.
  final List<String> lines;

  final int? _variants;

  /// How many distinct lines this family can produce. Equal to `lines.length`
  /// for a complete batch; larger for a sampled one.
  int get variants => _variants ?? lines.length;

  /// False when the family is too large to record exhaustively, so the
  /// un-recorded remainder stays on system TTS by design.
  bool get isComplete => variants == lines.length;
}

/// Coin totals the parade reward line can report: one per plausible round
/// count, at the clean-round rate RoundCoordinator pays.
const List<int> _kRewardRoundCounts = <int>[3, 4, 5, 6, 7, 8];

/// Every batch, most-heard first. Recording strictly down this list means the
/// game gets warmer fastest per minute at the microphone.
List<ScriptBatch> buildNarrationScript() => <ScriptBatch>[
      // ---- Ten-Frame Pond ----------------------------------------
      ScriptBatch(
        id: ActivityIds.tenFramePond,
        title: 'Ten-Frame Pond - frogs on lily pads',
        note:
            'Every line the pond says, generated from the same round plans the '
            'runner plays. The done lines are the arithmetic said out loud - '
            '"Three green and two orange make five" - so give the two numbers '
            'equal weight and let the total land.',
        lines: tenFrameScriptLines(),
      ),
      // ---- Care Pantry ------------------------------------------
      ScriptBatch(
        id: ActivityIds.carePantry,
        title: 'Care Pantry - putting the food away',
        note: 'A tidy-up, not a test. The put-away prompts are an invitation; '
            'the counted lines ("Four acorns.") close a crate, so let them '
            'settle.',
        lines: pantryScriptLines(),
      ),
      // ---- Scribe's Tower ----------------------------------------
      ScriptBatch(
        id: ActivityIds.scribesTower,
        title: "Scribe's Tower - writing numbers",
        note: 'Unhurried and encouraging; she is tracing with a finger and '
            'will be concentrating. The done lines celebrate the number she '
            'has just made, so let it ring.',
        lines: scribeScriptLines(),
      ),
      // ---- Storyteller's Pond -------------------------------------
      ScriptBatch(
        id: ActivityIds.storytellersPond,
        title: "Storyteller's Pond - the turtle's stories",
        note: 'Told, not read out: these are tiny stories for a five-year-old '
            'at dusk. Warm and a little slow, with a small pause before the '
            'invitation to tap. The done lines are the sum said as a sentence '
            '("Three and two more make five") - let the total land last.',
        lines: storyScriptLines(),
      ),
      // ---- Caretaker's Bench -------------------------------------
      ScriptBatch(
        id: ActivityIds.caretakersBench,
        title: "Caretaker's Bench - weighing and measuring",
        note: 'Curious and careful, like a naturalist at a workbench. The '
            'attribute words - heavy, light, long, short, heavier, lighter - '
            'are what she is learning, so give each one a little weight.',
        lines: benchScriptLines(),
      ),
      // ---- Picnic Baskets ----------------------------------------
      ScriptBatch(
        id: ActivityIds.picnicBaskets,
        title: 'Picnic Baskets - who has more',
        note: 'A picnic - relaxed and cheerful. The done lines settle a '
            'small friendly argument between a unicorn and a dragon, so they '
            'can have a smile in them.',
        lines: picnicScriptLines(),
      ),
      // ---- Fluency Within 5 --------------------------------------
      ScriptBatch(
        id: ActivityIds.fluencyWithin5,
        title: 'Fluency Within 5 - quick puzzles with Buddy',
        note: 'Brisk and light, like a friendly game rather than a quiz. '
            'Questions end on a lifted "?"; the answers are said with a '
            'little flourish on the last number.',
        lines: fluencyScriptLines(),
      ),
      // ---- Maps ---------------------------------------------------
      const ScriptBatch(
        id: 'map-labels',
        title: 'The maps - the name of a place, on tap',
        note: 'First in the list even though it is five lines, because these '
            'are the first words of every session and they cost one minute at '
            'the microphone. Say a place name the way you would point one out '
            'on a walk - naming, not announcing. No full stop at the end: '
            'these are labels, and a falling full-stop cadence makes a map '
            'sound like a list.',
        lines: <String>[
          ...kSpokenMapLabels,
          // Not a label — a full sentence, and the only one in this
          // batch. It answers a tap on a place that is not built yet,
          // so read it as reassurance rather than as a refusal.
          kAsleepPlaceLine,
        ],
      ),
      ScriptBatch(
        id: 'button-labels',
        title: 'Buttons - the word a control says when she presses it',
        note: 'The single most-heard set of words in the game after the number '
            'words: every ReadAloudGate speaks its label on the tap that acts, '
            'and the big arrow ends every round in every activity. All of it '
            'was in the browser synth voice, because a label is one or two '
            'words and the literal sweep only keeps strings that end like a '
            'sentence. Read them as a person handing something over - light '
            'and quick, no announcing. "Flat" and "Solid" are answers rather '
            'than navigation, so give those two the same even weight you would '
            'give a shape name.',
        lines: spokenButtonLabels(),
      ),
      ScriptBatch(
        id: 'sub-mode-picker',
        title: 'The picker - what do you want to play?',
        note: 'Second because this sheet stands between a tap on an activity '
            'and the activity itself, every visit after the first, and it '
            'used to make no sound at all. Read the question as a real '
            'question - an offer, not a prompt - and the option names the way '
            'you would point at things on a shelf. They are names of games, '
            'so no full stop and no falling cadence.',
        lines: spokenSubModeLabels(),
      ),
      ScriptBatch(
        id: 'mystery-egg',
        title: 'The mystery egg - what Haddock says as it changes',
        note: 'The whole story arc of the long-cycle reward, and until now it '
            'had never been said out loud - not once, in any voice. The eight '
            'stage messages live on `kMysteryEggTrack` in lib/models/, which '
            'the literal sweep does not read (it reads lib/data/ and files '
            'that mention narration), so the renderer could not see them and '
            'the game showed them as paragraphs of prose to a child who '
            'cannot read. Read them the way you would read the next page of a '
            'bedtime story: something is happening in there, and she is the '
            'reason.',
        lines: <String>[
          for (final stage in kMysteryEggTrack.stages) stage.message,
          kMysteryEggTrack.completeStage.message,
          // What the same sheet says when there is no egg to talk about.
          kRoundCompleteFallbackLine,
        ],
      ),
      ScriptBatch(
        id: 'counts',
        title: 'Number words, one to one hundred',
        note: 'The most-heard lines in the game by a wide margin — one sounds '
            'on every single tap in five different activities. Read them '
            'evenly and briskly, like counting objects with a child, not like '
            'reading a list. Leave a beat of silence between each.',
        lines: <String>[
          for (var n = 1; n < kSpelledCounts.length; n++)
            '${kSpelledCounts[n]}.',
        ],
      ),
      ScriptBatch(
        id: 'warm-miss',
        title: 'Wrong-answer lines',
        note: 'Warm and unbothered. A miss is information, not a verdict — '
            'never disappointed, never sing-song.',
        lines: <String>[for (var n = 0; n < 4; n++) warmMissLine(n)],
      ),
      ScriptBatch(
        id: 'warm-hint',
        title: 'Hint lines',
        note: 'Spoken by a friend who noticed she is stuck, at five and ten '
            'seconds of stillness. Unhurried.',
        lines: <String>[
          for (var level = 1; level <= 3; level++) warmHintLine(level),
        ],
      ),
      // ---- Shape Garden -------------------------------------------
      ScriptBatch(
        id: 'shape-target',
        title: 'Shape Garden — naming and asking for a shape',
        note: 'Spoken as each find-round opens, and when a shape is '
            'introduced. Two lines per shape kind.',
        lines: <String>[
          for (final kind in kShapeKinds)
            'This one is a ${kShapeDisplayName[kind]}.',
          for (final kind in kShapeKinds)
            'Tap all the ${kShapeDisplayPlural[kind]}.',
        ],
      ),
      ScriptBatch(
        id: 'shape-miss',
        title: 'Shape Garden — the wrong-tap line',
        note: 'It used to open by naming the shape she tapped, which made it '
            '18 leads x 4 warm lines x 9 plurals = 648 sentences and left the '
            'line on the browser synth voice at the exact moment she got '
            'something wrong. Now warm line x target plural.',
        lines: <String>[
          for (var n = 0; n < 4; n++)
            for (final kind in kShapeKinds)
              '${warmMissLine(n)} Find the ${kShapeDisplayPlural[kind]}.',
        ],
      ),

      ScriptBatch(
        id: 'sort-attribute',
        title: 'Shape Garden — sort by attribute',
        note: 'The round prompt, the basket labels (read aloud when a basket '
            'is tapped), and the wrong-basket line.',
        lines: <String>[
          for (final id in kSortAttributeWords.keys) sortAttributePrompt(id),
          for (final label in kSortBinLabels.values) label,
          for (var n = 0; n < 4; n++)
            for (final word in kSortAttributeWords.values)
              '${warmMissLine(n)} Sort by $word.',
        ],
      ),

      // ---- Where's Buddy ------------------------------------------
      ScriptBatch(
        id: 'wheres-buddy-restate',
        title: "Where's Buddy — the demonstrate line",
        note: 'wheres-buddy.md mandates this after three wrong taps: the '
            'narrator says where Buddy is while the zone glows. Every '
            'position against every landmark.',
        lines: <String>[
          for (final position in kWheresBuddyPrepositions.values)
            for (final landmark in kWheresBuddyLandmarkNames.values)
              'Here — Buddy is $position $landmark. Right there.',
        ],
      ),

      ScriptBatch(
        id: 'wheres-buddy-prompt',
        title: "Where's Buddy — the instruction",
        note: 'Every position against every landmark, in both modes: one asks '
            'her to put Buddy somewhere, the other to say where Buddy is. '
            'Nothing on screen says this, so the line is the whole task. Keep '
            'the preposition clear - above and below are the point.',
        lines: <String>[
          for (final placing in <bool>[true, false])
            for (final preposition in kWheresBuddyPrepositions.values)
              for (final landmark in kWheresBuddyLandmarkNames.values)
                wheresBuddyPrompt(
                  preposition: preposition,
                  landmark: landmark,
                  placing: placing,
                ),
        ],
      ),

      // ---- Where's Buddy, the challenge ----------------------------
      ScriptBatch(
        id: 'wheres-buddy-relational',
        title: "Where's Buddy — the between challenge",
        note: 'Four pairs only, not every combination: "between" needs two '
            'named things, and the challenge asks about four specific pairs '
            'rather than all thirty. Lean on the word itself - it is the one '
            'being taught, and it is the hardest of the seven. The restate '
            'line is said while she is being shown the answer, so it should '
            'sound like company rather than correction.',
        lines: <String>[
          for (final (a, b) in kWheresBuddyRelationalPairs)
            wheresBuddyRelationalPrompt(a, b),
          for (final (a, b) in kWheresBuddyRelationalPairs)
            wheresBuddyRelationalRestate(a, b),
        ],
      ),

      // ---- Count Out N --------------------------------------------
      ScriptBatch(
        id: 'count-out-n',
        title: 'Count Out N — the ask, and "you have enough"',
        note: 'The ask is the whole instruction: a pre-reader has nothing '
            'else telling her how many to bring. Land on the number. The '
            'three over-cap lines are said to a child who keeps dragging '
            'after the basket is full, so they are gentle and a little '
            'amused, never a correction.',
        lines: <String>[
          for (final round in kCountOutNRounds) countOutNBasketPrompt(round),
          for (final round in kCountOutNRounds)
            for (var r = 0; r < kCountOutNOverCapRotations; r++)
              countOutNOverCapLine(round, r),
        ],
      ),

      // ---- Count Forward From N -----------------------------------
      ScriptBatch(
        id: 'count-forward',
        title: 'Count Forward From N — the two-beat opening',
        note: 'The round opens on two lines with the new creatures walking on '
            'between them, so read them as a pair. The first settles what is '
            'already done — calm, a little final, and the number carries it, '
            'because trusting that number instead of starting over at one is '
            'the whole skill. The second is the go signal and lands as the '
            'creatures arrive: brighten on "Here come", then hand it over.',
        lines: <String>[
          for (final round in kCountForwardRounds) ...<String>[
            countForwardAlreadyCountedLine(round),
            countForwardPrompt(round),
          ],
        ],
      ),

      // ---- Count On By Ones ---------------------------------------
      ScriptBatch(
        id: 'count-on-by-ones',
        title: 'Count On By Ones — the two-beat opening',
        note: 'A pair, with the new creatures walking on between them. The '
            'first settles where the parade has got to; the second is the go '
            'signal and lands as they arrive. Say the two tens the same way so '
            'the journey sounds like one between them rather than two '
            'unrelated numbers.',
        lines: <String>[
          for (final round in kCountOnByOnesRounds) ...<String>[
            countOnByOnesAlreadyCountedLine(round),
            countOnByOnesPrompt(round),
          ],
        ],
      ),

      // ---- Long Parade --------------------------------------------
      ScriptBatch(
        id: 'long-parade',
        title: 'Long Parade — the instruction',
        note: 'One line per creature. No number in it: which ten she is on '
            'is what the taps say, not the prompt.',
        lines: <String>[
          for (final round in kLongParadeRounds)
            longParadeCountingPrompt(round),
        ],
      ),

      // ---- Build-a-Habitat ----------------------------------------
      ScriptBatch(
        id: 'habitat-build',
        title: 'Build-a-Habitat — the build instruction',
        note: 'Three steps in one breath, so keep it moving and let the '
            'habitat name land at the end - that is the part she is being '
            'asked to care about.',
        lines: <String>[
          for (final id in kHabitatDisplayNames.keys) habitatBuildPrompt(id),
        ],
      ),

      // ---- Counting challenge -------------------------------------
      ScriptBatch(
        id: 'challenge-target',
        title: 'Counting challenge — the opening call',
        note: 'The target is a const in the runner (100 today) and the layer '
            'is generic, so every ten up to a hundred is enumerated rather '
            'than the one value in use. Ten clips is cheap insurance against '
            'a target being retuned and the line silently dropping back to '
            'the synth voice.',
        lines: <String>[
          for (var target = 10; target <= 100; target += 10)
            'Tap the creatures as they go by — count all the way to $target!',
        ],
      ),

      // ---- Sanctuary decor ----------------------------------------
      ScriptBatch(
        id: 'sanctuary-decor',
        title: 'Decorating — the tray and the map',
        note: 'Every name is spoken because the tray labels mean nothing to a '
            'pre-reader, and because naming a thing she chose is the only '
            'teaching this surface does. The invite line is the one place in '
            'the game that says out loud there is no wrong answer.',
        lines: <String>[
          for (final item in kSanctuaryDecor) decorNameLine(item),
          kDecorTooExpensiveLine,
          kDecorInviteLine,
        ],
      ),

      // ---- Parade species cards -----------------------------------
      ScriptBatch(
        id: 'parade-species-intro',
        title: 'Counting Parade — the card that names the creature',
        note: 'Held up before every round. It is the only place in the game a '
            'pre-reader can learn what she is looking at, so land on the name '
            'and let the second half be the invitation it is.',
        lines: <String>[
          for (final species in kParadeSpecies) paradeSpeciesIntroLine(species),
        ],
      ),

      // ---- Creature card album ------------------------------------
      ScriptBatch(
        id: 'card-album',
        title: 'Creature Cards — tapping a card in the album',
        note: 'The album shows no text a pre-reader can decode, so the name '
            'of the creature she met is only available out loud. One line per '
            'card, plus the one for a silhouette she has not earned yet.',
        lines: <String>[
          for (final card in kCreatureCards) cardFoundLine(card),
          kCardNotFoundLine,
          // The reveal says a warmer version of the same name, and the nudge
          // is what a child who cannot read "Tap anywhere" gets instead.
          for (final card in kCreatureCards) cardRevealLine(card),
          kCardTapToContinueLine,
        ],
      ),

      // ---- Tens Parade reward -------------------------------------
      ScriptBatch(
        id: 'tens-parade-reward',
        title: 'Tens Parade — the hundredth tap',
        note: 'The payoff for a hundred taps, and the loudest single moment '
            'in the game. Two wordings: the run that earns the Cloud Unicorn, '
            'and every replay after it. Built by calling the same function '
            'the runner calls, so a reworded line cannot leave a stale clip '
            'behind.',
        lines: <String>[
          for (final earned in <bool>[true, false])
            tensParadeRewardLine(earnedCard: earned),
        ],
      ),

      // ---- Two-attribute hunt -------------------------------------
      ScriptBatch(
        id: 'two-attribute-miss',
        title: 'Two-attribute hunt — the wrong-tap line',
        note: 'One shape matched but not both. The warm line rotates.',
        lines: <String>[
          for (var n = 0; n < 4; n++) "That's not both. ${warmMissLine(n)}",
        ],
      ),

      ScriptBatch(
        id: 'parade-prompt',
        title: 'Counting Parade — the instruction, one per creature',
        note: 'Spoken as each round opens. One line per species.',
        lines: <String>[
          for (final s in kParadeSpecies) paradeCountingPrompt(s),
        ],
      ),
      ScriptBatch(
        id: 'parade-reward',
        title: 'Counting Parade — the coin payout',
        note: 'The keeper handing over the coins at the end of a visit.',
        lines: <String>[
          for (final rounds in _kRewardRoundCounts)
            paradeRewardLine(rounds * kCoinsForCleanRound),
        ],
      ),
      ScriptBatch(
        id: 'parade-final',
        title: 'Counting Parade — the last-round wrap-up',
        note: 'Names the total, which is the whole point of K.CC.4b, so land '
            'on the number. Every count crossed with every species.',
        lines: <String>[
          for (final s in kParadeSpecies)
            for (var n = kMinParadeCount; n <= kMaxParadeCount; n++)
              paradeFinalLine(count: n, done: s),
        ],
      ),
      ScriptBatch(
        id: 'parade-intro',
        title: "Counting Parade — the keeper's opening ask",
        note: 'The longest line in the game and the first one she hears each '
            'visit, so it is worth the takes. Every count crossed with every '
            'species. Skip this batch if you are short on time — it falls back '
            'to the synth voice cleanly.',
        lines: <String>[
          for (final s in kParadeSpecies)
            for (var n = kMinParadeCount; n <= kMaxParadeCount; n++)
              paradeIntroDialog(count: n, species: s),
        ],
      ),
      ScriptBatch(
        id: 'parade-transition',
        title: 'Counting Parade — the between-round line',
        note: 'Carries the cardinality, so it is the only thing spoken at the '
            'round boundary. It used to name the species coming next as well, '
            'which made it 1,792 sentences and put it permanently out of reach '
            'of a recorded voice - the one beat in a round that fell back to '
            'the browser synth. It no longer does, and the family is now '
            'count x species x rotation.',
        lines: <String>[
          for (var count = kMinParadeCount; count <= kMaxParadeCount; count++)
            for (final species in kParadeSpecies)
              for (var rotation = 0; rotation < 4; rotation++)
                paradeTransitionLine(
                  count: count,
                  done: species,
                  rotation: rotation,
                ),
        ],
      ),
    ];

/// Every distinct sentence the static script covers.
Set<String> narrationScriptTexts() => <String>{
      for (final batch in buildNarrationScript())
        for (final line in batch.lines) narrationTextNormalize(line),
    };

/// Clip keys for everything the static script covers, for orphan detection.
Set<String> narrationScriptClipKeys() =>
    narrationScriptTexts().map(narrationClipKey).toSet();
