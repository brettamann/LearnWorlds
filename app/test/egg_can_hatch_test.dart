// The mystery egg has to be able to hatch.
//
// It is the long-cycle reward — the one `reward-tracks.md` says "carries the
// kid through the dry middle of the curriculum" — and it advances on cleared
// sub-modes. The cadence was tuned against the *authored* K curriculum, eleven
// activities' worth, on the reasoning that one stage per sub-mode "would hatch
// in the first week and leave the rest of the grade with no track running".
//
// Four of those eleven activities exist. Against the content that is actually
// built, the arithmetic came out the other way: every non-optional sub-mode in
// the game, cleared, was not enough events to reach the final stage. A child
// could finish everything there is to play and never see the egg hatch — and
// never even reach stage eight, whose line is "It's about to hatch any second!
// Finish your last lesson to find out what's inside!"
//
// So the dial is checked against the content rather than against a plan. This
// test is also the signal for turning it back up: when the remaining seven
// activities land, it will still pass at a slower cadence, and that is the
// moment to slow it down.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/data/playable_activities.dart';
import 'package:critmath/data/sanctuary_sequence.dart';
import 'package:critmath/models/reward_track.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sub-modes of playable activities, split by whether a child has to play them.
({List<String> required, List<String> optional}) _subModes() {
  final json = jsonDecode(
    File('../data/activity-registry/kindergarten.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final required = <String>[];
  final optional = <String>[];
  for (final raw in json['activities'] as List<dynamic>) {
    final activity = raw as Map<String, dynamic>;
    final id = activity['id'] as String;
    if (!isActivityPlayable(id)) continue;
    for (final rawSub in activity['subModes'] as List<dynamic>) {
      final subMode = rawSub as Map<String, dynamic>;
      final key = '$id/${subMode['id']}';
      // Two kinds of sub-mode the arc must never depend on. A challenge is
      // opt-in by design — it only appears once every regular sub-mode of its
      // activity is done, and a child can ignore it forever. A demotion floor
      // is worse: it is where the scaffolding puts a kid who is struggling,
      // so a track that needs it only closes for a child who had a hard time.
      //
      // Except the entry point, which is always a step whatever else it is
      // marked (`SubMode.isChainStep`): most activities' default is also their
      // floor. Treating those as optional left eight places' first sub-mode
      // out of the count.
      final optIn = !(subMode['isDefault'] as bool? ?? false) &&
          ((subMode['isChallenge'] as bool? ?? false) ||
              (subMode['isDemotionFloor'] as bool? ?? false));
      (optIn ? optional : required).add(key);
    }
  }
  return (required: required, optional: optional);
}

void main() {
  test('clearing the game hatches the egg, without the optional challenges',
      () {
    final subModes = _subModes();
    final earned = subModes.required.toSet();

    expect(
      kMysteryEggTrack.computeTargetStage(const <String>{}, earned),
      kMysteryEggTrack.finalStage,
      reason: 'every non-optional sub-mode in the game is '
          '${earned.length} events, and the egg needs '
          '${kMysteryEggTrack.finalStage * kMysteryEggTrack.eventsPerStage}. '
          'The payoff the whole track exists for cannot happen.',
    );
  });

  test('the gift lands at the end of the first sitting', () {
    // `isFirstEggMoment` in activity_screen.dart fires the moment the track
    // reaches stage 1, so this is when Haddock hands the egg over. Pinned
    // because it moved as a consequence of the cadence rather than a decision,
    // and it is worth it being a decision: a first session that ends with
    // someone giving her a mystery to look after is the reason to come back.
    final first = _subModes().required.take(1).toSet();
    expect(kMysteryEggTrack.computeTargetStage(const <String>{}, first), 1);
  });

  test('and it does not hatch on the first couple of sittings', () {
    // The other failure. A reward that arrives immediately is not a long-cycle
    // reward, and there would be nothing left to carry her through the rest.
    final subModes = _subModes();
    final firstThree = subModes.required.take(3).toSet();
    expect(
      kMysteryEggTrack.computeTargetStage(const <String>{}, firstThree),
      lessThan(kMysteryEggTrack.finalStage),
    );
  });

  test('the opt-in sub-modes are a bonus, not the difference', () {
    // If the arc only closes when every challenge is played too, then the
    // challenges are not optional and the picker's "you can ignore this"
    // framing is a lie. Same for the demotion floor, which the picker does
    // not offer at all.
    final subModes = _subModes();
    expect(
      subModes.optional,
      isNotEmpty,
      reason: 'the split is reading nothing',
    );
    final withoutChallenges =
        kMysteryEggTrack.computeTargetStage(const <String>{}, {
      ...subModes.required,
    });
    final withChallenges =
        kMysteryEggTrack.computeTargetStage(const <String>{}, {
      ...subModes.required,
      ...subModes.optional,
    });
    expect(withoutChallenges, withChallenges);
  });

  test('the stage-grant floor only hatches the egg for the whole Sanctuary',
      () {
    // stageGrants was written when six of its eight activities did not exist,
    // and this used to check that the table could not carry the track on its
    // own. Every Sanctuary place is built now, so finishing all of them
    // legitimately hatches the egg; what must still hold is that nothing
    // short of all of them does - the events path is what paces the arc.
    final last = kSanctuaryActivityByCode[kSanctuarySequence.last]!;
    final allButLast = <String>{
      for (final id in kPlayableActivities)
        if (id != last) id,
    };
    expect(
      kMysteryEggTrack.computeTargetStage(allButLast),
      lessThan(kMysteryEggTrack.finalStage),
      reason: 'the grant table is doing work the events path should do',
    );
  });

  test('it hatches near the end of the path, not the middle', () {
    // Walk the Sanctuary in map order, clearing every chain sub-mode of each
    // place, and record where the egg first reaches its last stage. At two
    // sub-modes a stage that was Care Pantry - place five of eleven - which
    // left six places with no long-cycle reward at all.
    final json = jsonDecode(
      File('../data/activity-registry/kindergarten.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final byId = <String, Map<String, dynamic>>{
      for (final raw in json['activities'] as List<dynamic>)
        (raw as Map<String, dynamic>)['id'] as String: raw,
    };
    final events = <String>{};
    final done = <String>{};
    int? hatchPlace;
    var place = 0;
    for (final code in kSanctuarySequence) {
      final id = kSanctuaryActivityByCode[code];
      if (id == null) continue;
      place += 1;
      for (final raw in byId[id]!['subModes'] as List<dynamic>) {
        final m = raw as Map<String, dynamic>;
        final chain = (m['isDefault'] as bool? ?? false) ||
            (!(m['isChallenge'] as bool? ?? false) &&
                !(m['isDemotionFloor'] as bool? ?? false));
        if (chain) events.add('$id/${m['id']}');
      }
      done.add(id);
      if (hatchPlace == null &&
          kMysteryEggTrack.computeTargetStage(done, events) ==
              kMysteryEggTrack.finalStage) {
        hatchPlace = place;
      }
    }
    expect(hatchPlace, isNotNull);
    expect(
      hatchPlace,
      greaterThanOrEqualTo(place - 2),
      reason: 'the egg reaches its last stage at place $hatchPlace of $place',
    );
  });

  test('slowing the pace never moves an egg backwards', () {
    // The pace went from one sitting a stage to two on 2026-09-24. A child
    // whose egg was already at stage six must still see stage six.
    final events = <String>{for (var i = 0; i < 6; i++) 'a/s$i'};
    expect(
      kMysteryEggTrack.computeTargetStage(const <String>{}, events, 6),
      greaterThanOrEqualTo(6),
    );
  });
}
