// LessonScene, the lesson stage's state, without a widget in sight.

import 'package:critmath/models/lesson_runtime.dart';
import 'package:critmath/ui/lesson/lesson_scene.dart';
import 'package:critmath/ui/widgets/habitat_lesson_stage.dart';
import 'package:flutter_test/flutter_test.dart';

AnimationStep _step(String action, [Map<String, dynamic> params = const {}]) =>
    AnimationStep(at: '0s', action: action, params: params);

void main() {
  test('a touch pokes, sparkles and replays the burst each time', () {
    final scene = LessonScene();
    scene.apply(_step('pointer-touch', {'target': 'fawn-1'}));
    scene.apply(_step('sparkle', {'target': 'fawn-1'}));
    scene.apply(_step('sparkle', {'target': 'fawn-1'}));
    expect(scene.pointerTargetId, 'fawn-1');
    expect(scene.handAtTarget, isTrue);
    expect(scene.pokeCounter, 1);
    expect(scene.sparkled, {'fawn-1'});
    expect(scene.burstCounters['fawn-1'], 2);
  });

  test('pointer-appear strips the left-of- prefix', () {
    final scene = LessonScene()
      ..apply(_step('pointer-appear', {'position': 'left-of-fawn-0'}));
    expect(scene.pointerTargetId, 'fawn-0');
    expect(scene.handAtTarget, isFalse);
  });

  test('the badge shows and updates', () {
    final scene = LessonScene()..apply(_step('count-badge-show', {'value': 1}));
    expect(scene.badgeValue, 1);
    scene.apply(_step('count-badge-update', {'value': 3}));
    expect(scene.badgeValue, 3);
  });

  test('habitat pieces go down where they are placed', () {
    final scene = LessonScene()
      ..apply(_step('pointer-pickup-from-pool', {'itemType': 'clay-ball'}));
    expect(scene.carrying, HabitatCarry.clay);
    expect(scene.handVisible, isTrue);
    scene.apply(_step('pointer-place-clay', {'target': 'vertex-2'}));
    expect(scene.placedCorners, {1});
    expect(scene.carrying, HabitatCarry.none);
    expect(scene.handTarget, isNotNull);
    scene.apply(_step('pointer-place-stick', {'target': 'edge-1'}));
    expect(scene.placedEdges, {0});
  });

  test('"next" in a halo action is whatever is still missing', () {
    final scene = LessonScene()
      ..apply(_step('pointer-place', {'target': 'vertex-1'}));
    expect(scene.nextUnplacedFramePiece('halo-pulse-next-vertex'), [
      'vertex-2',
    ]);
    scene.autoCompleteFrame('pointer-auto-place-clay');
    expect(scene.nextUnplacedFramePiece('halo-pulse-next-vertex'), isEmpty);
    expect(scene.nextUnplacedFramePiece('halo-pulse-next-edge'), ['edge-1']);
  });

  test(
      'a settled gate puts Buddy where the prompt asked, and sparkles only '
      'what she touched', () {
    final scene = LessonScene()..halo(['above-fountain']);
    scene.settleGate(['above-fountain'], byHer: false);
    expect(scene.haloed, isEmpty);
    expect(scene.sparkled, isEmpty);
    expect(scene.buddySpot?.positionId, 'above');
    expect(scene.facingLandmarkId, 'fountain');

    scene.settleGate(['vertex-3'], byHer: true);
    expect(scene.sparkled, {'vertex-3'});
    expect(scene.placedCorners, {2});
  });

  test('every change notifies the screen', () {
    final scene = LessonScene();
    var changes = 0;
    scene.addListener(() => changes++);
    scene
      ..apply(_step('sparkle', {'target': 'a'}))
      ..aimAt('a')
      ..reachFor('a')
      ..touch('a')
      ..handAway()
      ..halo(['a'])
      ..completeFrame();
    expect(changes, 7);
  });
}
