// The one place that knows which widget plays which activity.
//
// ActivityScreen used to pick a runner with an eleven-branch
// `if (activityId == '...')` chain, kept a second hand-typed table of every
// activity's default sub-mode beside it, and the Sanctuary map kept a third
// list of which activities were playable at all - with a test that
// regex-scraped the screen's source to keep the three in step. Now a runner
// is registered here once; being registered is what makes an activity
// playable, and the default sub-mode comes from the activity registry.

import 'package:flutter/widgets.dart';

import 'activity_ids.dart';
import 'activity_launch.dart';
import 'build_a_habitat/build_a_habitat_runner.dart';
import 'care_pantry/care_pantry_runner.dart';
import 'caretakers_bench/caretakers_bench_runner.dart';
import 'counting_parade/counting_parade_runner.dart';
import 'fluency/fluency_runner.dart';
import 'picnic_baskets/picnic_baskets_runner.dart';
import 'scribes_tower/scribes_tower_runner.dart';
import 'shape_garden/shape_garden_runner.dart';
import 'storytellers_pond/storytellers_pond_runner.dart';
import 'ten_frame_pond/ten_frame_pond_runner.dart';
import 'wheres_buddy/wheres_buddy_runner.dart';

/// What a runner is built from. [subModeId] is already resolved - a launch
/// with no sub-mode has been given the activity's registry default.
class RunnerArgs {
  const RunnerArgs({
    required this.subModeId,
    required this.launch,
    required this.onSequenceComplete,
  });

  final String subModeId;
  final ActivityLaunch launch;
  final VoidCallback onSequenceComplete;

  /// A lesson has already played the keeper's intro.
  bool get skipIntro => launch.fromLesson;
}

typedef ActivityRunnerBuilder = Widget Function(RunnerArgs a);

/// Every playable activity's runner, by activity id.
final Map<String, ActivityRunnerBuilder> kActivityRunners =
    <String, ActivityRunnerBuilder>{
  ActivityIds.countingParade: (a) => CountingParadeRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        // Lesson JSON carries a roundParameters block for the parade, so
        // authored content can shape a round.
        roundParameters: a.launch.roundParameters,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.shapeGarden: (a) => ShapeGardenRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.wheresBuddy: (a) => WheresBuddyRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.buildAHabitat: (a) => BuildAHabitatRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.tenFramePond: (a) => TenFramePondRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.carePantry: (a) => CarePantryRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.scribesTower: (a) => ScribesTowerRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.storytellersPond: (a) => StorytellersPondRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.caretakersBench: (a) => CaretakersBenchRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.picnicBaskets: (a) => PicnicBasketsRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
  ActivityIds.fluencyWithin5: (a) => FluencyRunner(
        skipIntro: a.skipIntro,
        subMode: a.subModeId,
        onSequenceComplete: a.onSequenceComplete,
      ),
};
