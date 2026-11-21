// Reward-track advancement — specifically the per-sub-mode cadence added so
// the mystery egg stops being a static picture.
//
// The egg used to advance only when an entire activity was cleared, which for
// Counting Parade means all five non-challenge sub-modes: about thirty-one
// rounds before Haddock hands the egg over at all. These tests pin the two
// properties that fix matters for: events advance the track, and they never
// drag it *backwards* for a save written before events existed.

import 'package:critmath/models/reward_track.dart';
import 'package:critmath/providers/reward_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RewardTrack.computeTargetStage', () {
    test('stage grants alone still decide the stage when no events exist', () {
      // This is the pre-existing save shape: `completed` populated, `events`
      // absent. It must land exactly where it always did.
      expect(kMysteryEggTrack.computeTargetStage({'counting-parade'}), 1);
      expect(
        kMysteryEggTrack.computeTargetStage({'counting-parade', 'care-pantry'}),
        2,
      );
    });

    test('completion events advance the track on their own', () {
      final track = _twoPerStage;
      expect(track.computeTargetStage(const {}, const <String>{}), 0);
      // The first event is a stage by itself - the gift at the end of her
      // first sitting - and the pace applies from there.
      expect(track.computeTargetStage(const {}, const {'a/one'}), 1);
      expect(track.computeTargetStage(const {}, const {'a/one', 'a/two'}), 1);
      expect(
        track.computeTargetStage(const {}, const {'a/1', 'a/2', 'a/3'}),
        2,
      );
      expect(
        track.computeTargetStage(const {}, const {'a/1', 'a/2', 'a/3', 'a/4'}),
        2,
      );
    });

    test('grants act as a floor — whichever source is further ahead wins', () {
      // Against the fixture rather than the shipping egg, which this used to
      // use with numbers derived from its cadence: retuning eventsPerStage
      // then failed a test about a rule that has nothing to do with the dial.
      final track = _bothSources;
      // Grant ahead: four events are stage 2 on their own, the grant says 3.
      // She keeps the better of the two rather than being walked back.
      expect(
        track.computeTargetStage(
          const {'granted-three'},
          const {'a/1', 'a/2', 'a/3', 'a/4'},
        ),
        3,
      );
      // And the other way round — eight events beat the same grant.
      expect(
        track.computeTargetStage(
          const {'granted-three'},
          const {'a/1', 'a/2', 'a/3', 'a/4', 'a/5', 'a/6', 'a/7', 'a/8'},
        ),
        4,
      );
    });

    test('never exceeds the final stage', () {
      final many = <String>{for (var i = 0; i < 100; i++) 'activity/sub-$i'};
      expect(
        kMysteryEggTrack.computeTargetStage(const {}, many),
        kMysteryEggTrack.finalStage,
      );
    });

    test('eventsPerStage of 0 ignores events entirely', () {
      final track = _grantsOnly;
      expect(
        track.computeTargetStage(const {}, const {'a/1', 'a/2', 'a/3'}),
        0,
      );
    });
  });

  group('RewardProgress.markCompletionEvent', () {
    late ProviderContainer container;
    late RewardProgress progress;

    setUp(() {
      // The notifier reads `state`, which only exists once the provider has
      // been built — so it has to come off a container rather than `new`.
      container = ProviderContainer();
      progress = container.read(rewardProgressProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('is idempotent by key so replays cannot farm the track', () {
      progress
        ..markCompletionEvent(trackId: 't', key: 'a/one')
        ..markCompletionEvent(trackId: 't', key: 'a/one')
        ..markCompletionEvent(trackId: 't', key: 'a/one');
      expect(progress.stateFor('t').completionEvents, {'a/one'});
    });

    test('accumulates distinct sub-modes', () {
      progress
        ..markCompletionEvent(trackId: 't', key: 'a/one')
        ..markCompletionEvent(trackId: 't', key: 'a/two');
      expect(progress.stateFor('t').completionEvents, {'a/one', 'a/two'});
    });

    test('leaves completedActivities untouched', () {
      progress
        ..markActivityCompleted(trackId: 't', activityId: 'counting-parade')
        ..markCompletionEvent(trackId: 't', key: 'counting-parade/long-parade');
      final state = progress.stateFor('t');
      expect(state.completedActivities, {'counting-parade'});
      expect(state.completionEvents, {'counting-parade/long-parade'});
    });
  });
}

/// Minimal two-stage track: two events per stage.
final RewardTrack _twoPerStage = RewardTrack(
  id: 'test-two',
  name: 'Test',
  stages: List<RewardStage>.unmodifiable(const [_stage, _stage, _stage]),
  stageGrants: const {},
  eventsPerStage: 2,
  completeStage: _stage,
);

/// A track with both sources live, so the floor rule can be tested in both
/// directions without borrowing the shipping egg's cadence.
final RewardTrack _bothSources = RewardTrack(
  id: 'test-both',
  name: 'Test',
  stages: List<RewardStage>.unmodifiable(const [
    _stage,
    _stage,
    _stage,
    _stage,
    _stage,
  ]),
  stageGrants: const {'granted-three': 3},
  eventsPerStage: 2,
  completeStage: _stage,
);

/// Grants-only track, to prove events are opt-in.
final RewardTrack _grantsOnly = RewardTrack(
  id: 'test-grants',
  name: 'Test',
  stages: List<RewardStage>.unmodifiable(const [_stage, _stage]),
  stageGrants: const {'thing': 1},
  completeStage: _stage,
);

const RewardStage _stage = RewardStage(
  spriteAsset: 'assets/none.png',
  message: 'x',
  ambient: RewardAmbient.still,
);
