// Which Sanctuary nodes a child can get to.
//
// The map draws eleven lesson nodes along a fixed path and reveals each one
// when the node before it is completed. A node is completed when all of its
// sub-modes are finished, which requires a runner — and position three of
// eleven is Ten-Frame Pond, which has never had one.
//
// So the path dead-ended at node three. Build-a-Habitat (node four) and
// Where's Buddy (node eight) are both finished, both narrated, both with their
// clips rendered, and neither could be reached in ordinary play: they sat in
// the fog behind an activity that does not exist. Half the built game, walled
// off by a rule that read as obviously correct.
//
// The reveal walk now steps over nodes that can never be completed. They are
// still drawn — specs/shared/map-screens.md is explicit that unbuilt content
// stays on the map so the region has a shape — they are simply not a wall.

import 'package:critmath/activities/activity_runners.dart';
import 'package:critmath/data/playable_activities.dart';
import 'package:critmath/data/sanctuary_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// Everything up to and including [activityId], as the save would look after
/// playing straight down the path.
Set<int> exploredThrough(String activityId) {
  final stop = kSanctuaryCodeByActivity[activityId]!;
  final explored = <int>{kSanctuaryCutsceneCode};
  for (final code in kSanctuarySequence) {
    if (!isSanctuaryNodePlayable(code)) continue;
    explored.add(code);
    if (code == stop) break;
  }
  return explored;
}

/// The activity behind each visible lesson node.
List<String> visibleActivities(Set<int> explored) => [
  for (final code in kSanctuarySequence)
    if (code != kSanctuaryCutsceneCode &&
        isSanctuaryNodeVisible(code, explored))
      kSanctuaryActivityByCode[code]!,
];

void main() {
  group('the path', () {
    test('a fresh save shows the cutscene and nothing else', () {
      const fresh = <int>{};
      expect(isSanctuaryNodeVisible(kSanctuaryCutsceneCode, fresh), isTrue);
      expect(
        visibleActivities(fresh),
        isEmpty,
        reason: 'the story beat is the way in; the first lesson comes after it',
      );
      expect(
        visibleActivities(<int>{kSanctuaryCutsceneCode}),
        ['counting-parade'],
        reason: 'one node ahead of where she is, and no further',
      );
    });

    test('an unbuilt node is never a wall', () {
      debugPlayableOverride = kFourActivitySanctuary;
      addTearDown(() => debugPlayableOverride = null);
      // Finishing Shape Garden (node two) has to reveal node three, which is
      // asleep, AND node four, which is not. Under the old rule it revealed
      // only node three and the map stopped there for good.
      final explored = exploredThrough('shape-garden');
      final visible = visibleActivities(explored);
      expect(visible, contains('ten-frame-pond'));
      expect(
        visible,
        contains('build-a-habitat'),
        reason: 'walled off behind an activity that does not exist',
      );
    });

    test('every built activity is reachable by playing', () {
      // The property that actually matters. Play down the path finishing
      // whatever is playable, and check nothing built is left in the fog.
      final explored = <int>{kSanctuaryCutsceneCode};
      // Repeat until it settles: each completion can reveal the next.
      for (var pass = 0; pass < kSanctuarySequence.length; pass++) {
        for (final code in kSanctuarySequence) {
          if (!isSanctuaryNodeVisible(code, explored)) continue;
          if (!isSanctuaryNodePlayable(code)) continue;
          explored.add(code);
        }
      }
      for (final id in kPlayableActivities) {
        final code = kSanctuaryCodeByActivity[id];
        expect(
          code,
          isNotNull,
          reason: '$id is playable but has no node on the map',
        );
        expect(
          isSanctuaryNodeVisible(code!, explored),
          isTrue,
          reason: '$id is finished and narrated but cannot be reached',
        );
      }
    });

    test('a sleeping node between two others does not hide the far one', () {
      debugPlayableOverride = kFourActivitySanctuary;
      addTearDown(() => debugPlayableOverride = null);
      // Nodes five, six and seven are all asleep, and Where's Buddy is eight.
      // A walk that only looked back one step would lose it three times over.
      final explored = exploredThrough('build-a-habitat');
      expect(visibleActivities(explored), contains('wheres-buddy'));
    });

    test('the reveal is still one lesson at a time', () {
      // The fix must not turn into "show everything", which would cost the map
      // its sense of opening up. Playable nodes still arrive one at a time;
      // the sleeping ones between them come along for free, because holding
      // them back would put the wall straight back.
      expect(
        visibleActivities(<int>{kSanctuaryCutsceneCode}),
        isNot(contains('shape-garden')),
        reason: 'node two before node one has been played',
      );
      expect(
        visibleActivities(exploredThrough('counting-parade')),
        isNot(contains('build-a-habitat')),
        reason: 'node four while node two is still ahead of her',
      );
    });
  });

  group('the playable set', () {
    test('is exactly the activities with a runner', () {
      // A drifted list is worse than no list: an id with no runner sends a
      // child to a line of English on a blank screen. The set is now derived
      // from the runner registry, so this pins that it still is.
      expect(kPlayableActivities, kActivityRunners.keys.toSet());
      expect(kPlayableActivities, isNotEmpty);
    });

    test('every playable id is a real registered activity', () {
      final json = activityRegistryJson();
      final registered = <String>{
        for (final a in json['activities'] as List<dynamic>)
          (a as Map<String, dynamic>)['id'] as String,
      };
      for (final id in kPlayableActivities) {
        expect(registered, contains(id));
      }
    });
  });

  group('placeholder names', () {
    test('a node the registry has never heard of still reads as a place', () {
      // Four nodes have a spec and a map position but no registry entry, and
      // the map printed the raw id on the parchment.
      expect(placeholderActivityName('care-pantry'), 'Care Pantry');
      expect(placeholderActivityName('fluency-within-5'), 'Fluency Within 5');
    });
  });
}
