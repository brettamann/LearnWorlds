// LessonScreen — plays a lesson as a captioned + animated preview that
// mirrors the activity round the kid is about to play.
//
// Two top-level shapes:
//   - **Fawn / iShow lessons** (K.CC.4a-style): keeper intro → iShow scene
//     scheduled from runtime.iShow narration + animation steps → Continue
//     hands off to /activity.
//   - **Shape lessons** (K.G.2): keeper intro → fixed 9-step per-shape
//     sequence (circle, triangle, right-triangle, square, rectangle,
//     pentagon, hexagon, half-circle, quarter-circle). Each step is a
//     ShapeIntroLayer beat (sprite + count its sides) followed by a
//     ShapeFindRound beat (tap all the X). After the last shape, a
//     Continue arrow hands off to /activity.
//
// Detection: `runtime.iShow.shapes.isNotEmpty` picks the shape branch.
// K.CC.4a-style lessons skip the per-shape sequence entirely and run the
// existing iShow scheduler (badge, fawns, hand pointer pre-glide).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activities/activity_launch.dart';
import '../../data/asset_paths.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../data/button_labels.dart';
import '../../data/lesson_loader.dart';
import '../../data/sfx_catalog.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/lesson_runtime.dart';
import '../../navigation/routes.dart';
import '../../platform/sfx_engine.dart';
import '../common/caption_overlay.dart';
import '../common/next_arrow_button.dart';
import '../common/round_back_button.dart';
import '../lesson/clearing_lesson_stage.dart';
import '../lesson/habitat_lesson_stage.dart';
import '../lesson/ishow_timeline.dart';
import '../lesson/kg3_flat_or_solid_lesson_layer.dart';
import '../lesson/kg4_sort_by_attribute_lesson_layer.dart';
import '../lesson/lesson_scene.dart';
import '../lesson/lesson_stages.dart';
import '../lesson/lesson_target_registry.dart';
import '../lesson/shape_find_demo.dart';
import '../lesson/shape_find_round.dart';
import '../lesson/shape_intro_layer.dart';
import '../lesson/we_try_halo.dart';
import '../lesson/we_try_runner.dart';
import '../round/keeper_intro_overlay.dart';

/// Order the K.G.2 lesson introduces shapes in. Simple → complex; circles
/// first (no sides, easiest), then the polygon ladder, then the imperfect
/// circles which depend on understanding "side" already. 3D shapes land in
/// a later sprint per the lesson spec.
const List<String> kShapeIntroSequence = <String>[
  'circle',
  'triangle',
  'triangle-right',
  'square',
  'rectangle',
  'pentagon',
  'hexagon',
  'semicircle_half',
  'semicircle_quarter',
];

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId, this.subModeOverride});

  final String lessonId;

  /// When set, overrides the lesson runtime's `youDo.subMode` on the
  /// hand-off to the activity. Used by the Sanctuary node picker so a
  /// kid who picked one sub-mode but a lesson covering a different
  /// sub-mode is required (e.g. the K.CC.1 lesson is shared across the
  /// long-parade and count-on-by-ones chain entries) doesn't get
  /// dropped into the wrong activity body. Null = use the lesson's own
  /// youDo.subMode.
  final String? subModeOverride;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _LessonPhase {
  keeperIntro,
  shapeIntro,
  shapeFindDemo,
  shapeFindRound,
  shapesDone,
  flatOrSolidLesson,
  sortByAttributeLesson,
  iShow,

  /// Guided practice. Authored in all 22 lessons since the content was
  /// written; until now the screen went straight from `iShow` to You-Do, so
  /// the middle third of every lesson existed only on disk.
  weTry,
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Future<LessonRuntime>? _future;
  bool _continueEnabled = false;
  bool _skipEnabled = false;
  LessonRuntime? _runtime;
  _LessonPhase _phase = _LessonPhase.keeperIntro;
  bool _musicClaimed = false;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  // Per-shape sequence cursor (K.G.2 only). Indexes kShapeIntroSequence.
  int _currentShapeIdx = 0;

  /// What the stage shows, and the rules for moving it. Driven by the I-Show
  /// timeline and the We-Try beats; observed here.
  final LessonScene _scene = LessonScene();

  /// The I-Show's clock, while it runs.
  IShowTimeline? _iShow;

  /// The We-Try's interpreter, while it runs.
  WeTryRunner? _weTry;

  final LessonTargetRegistry _targets = LessonTargetRegistry();

  /// Idempotent keeper-intro narration. The post-frame callback in the
  /// FutureBuilder calls this on every rebuild; the flag makes it a no-op
  /// after the first fire.
  bool _keeperIntroSpoken = false;

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    _future = const LessonLoader().load(widget.lessonId);
    _scene.addListener(_onSceneChanged);
  }

  void _onSceneChanged() {
    if (mounted) setState(() {});
  }

  /// Claim the scene's bed as soon as the lesson has loaded.
  ///
  /// The kid usually arrives here from a runner that was already playing this
  /// same file, so this is normally a no-op that cancels that runner's pending
  /// release — the music simply keeps going across the route change instead of
  /// fading out for the length of the lesson and starting over afterwards.
  void _claimMusicOnce(LessonRuntime runtime) {
    if (_musicClaimed) return;
    _musicClaimed = true;
    unawaited(
      ref
          .read(sfxEngineProvider)
          .startMusicBed(runtime.iShow.musicBed ?? kDefaultMusicBed),
    );
  }

  void _speakKeeperIntroOnce(LessonRuntime runtime) {
    if (_keeperIntroSpoken) return;
    _keeperIntroSpoken = true;
    ref.narration.say(
      runtime.presentation.keeperIntro,
      cueId: 'lesson:keeper-intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  /// Where the lesson opens, from the stage it is authored onto.
  void _onKeeperStartPressed() {
    final runtime = _runtime;
    if (runtime == null) return;
    switch (runtime.presentation.stage) {
      case LessonStage.flatOrSolid:
        setState(() => _phase = _LessonPhase.flatOrSolidLesson);
      case LessonStage.sortByAttribute:
        setState(() => _phase = _LessonPhase.sortByAttributeLesson);
      case LessonStage.shapeSequence:
        setState(() {
          _currentShapeIdx = 0;
          _phase = _LessonPhase.shapeIntro;
        });
      case LessonStage.fawns:
      case LessonStage.clusters:
      case LessonStage.countOn:
      case LessonStage.habitat:
      case LessonStage.clearing:
        setState(() => _phase = _LessonPhase.iShow);
        _scheduleIShow(runtime);
    }
  }

  void _onFlatOrSolidLessonComplete() {
    if (!mounted) return;
    _goToYouDo();
  }

  void _onSortByAttributeLessonComplete() {
    if (!mounted) return;
    _goToYouDo();
  }

  void _onShapeIntroComplete() {
    if (!mounted) return;
    // Show the auto-walk demo only before the *first* find round of the
    // whole sequence (index 0 — circles). After that the kid already
    // knows the mechanic; subsequent shapes go straight to interactive
    // play.
    final nextPhase = _currentShapeIdx == 0
        ? _LessonPhase.shapeFindDemo
        : _LessonPhase.shapeFindRound;
    setState(() => _phase = nextPhase);
  }

  void _onShapeFindDemoComplete() {
    if (!mounted) return;
    setState(() => _phase = _LessonPhase.shapeFindRound);
  }

  void _onShapeFindRoundComplete() {
    if (!mounted) return;
    final next = _currentShapeIdx + 1;
    if (next >= kShapeIntroSequence.length) {
      // All 9 shapes done — celebratory beat, then hand off via the
      // Continue arrow.
      ref.narration.say(
        'Wow! You learned every shape in the garden.',
        cueId: 'lesson:shapes-done',
      );
      setState(() {
        _phase = _LessonPhase.shapesDone;
        _continueEnabled = true;
      });
      return;
    }
    setState(() {
      _currentShapeIdx = next;
      _phase = _LessonPhase.shapeIntro;
    });
  }

  void _scheduleIShow(LessonRuntime runtime) {
    _iShow?.dispose();
    _iShow = IShowTimeline(
      show: runtime.iShow,
      scene: _scene,
      say: (text, cueId) => ref.narration.say(text, cueId: cueId),
      onSkipAvailable: () {
        if (mounted) setState(() => _skipEnabled = true);
      },
      onContinueAvailable: () {
        if (mounted) setState(() => _continueEnabled = true);
      },
    )..start();
  }

  /// Her turn: guided practice, run by WeTryRunner.
  void _startWeTry(LessonRuntime runtime) {
    _iShow?.dispose();
    _iShow = null;
    setState(() {
      _phase = _LessonPhase.weTry;
      _continueEnabled = false;
      _skipEnabled = false;
    });
    final feedback = ref.read(feedbackEngineProvider);
    _weTry =
        WeTryRunner(
            phase: runtime.weTry,
            scene: _scene,
            say: (text, cueId) => ref.narration.say(text, cueId: cueId),
            chime: feedback.hint,
            pop: feedback.correct,
            hits: _targets.hits,
            onFinished: _goToYouDo,
          )
          ..addListener(_onSceneChanged)
          ..start();
  }

  /// End of the demonstration. Her turn, unless this lesson does its own.
  void _afterIShow() {
    final runtime = _runtime;
    if (runtime == null) return;
    // A stage that is its own guided practice (the shape lessons) must not
    // also run the generic one: she would do the same thing twice in a row.
    if (runtime.presentation.stage.ownsPractice ||
        !runtime.weTry.script.hasGate) {
      _goToYouDo();
      return;
    }
    _startWeTry(runtime);
  }

  void _goToYouDo() {
    final runtime = _runtime;
    if (runtime == null) return;
    ref.narration.clear();
    final subMode = widget.subModeOverride ?? runtime.youDo.subMode;
    context.goActivity(
      runtime.youDo.activityId,
      ActivityLaunch(
        subModeId: subMode,
        fromLessonId: widget.lessonId,
        roundParameters: runtime.youDo.roundParameters,
      ),
    );
  }

  @override
  void dispose() {
    _iShow?.dispose();
    _weTry?.dispose();
    // Only if it was actually claimed. The claim happens from build(), once a
    // runtime has loaded, so a lesson closed before that never took one — and
    // SfxEngine counts claims, so releasing without claiming would give away
    // the next screen's music instead.
    if (_musicClaimed) _sfxForDispose?.releaseMusicBed();
    _scene.dispose();
    super.dispose();
  }

  String _backgroundAsset(LessonRuntime? runtime) =>
      switch (runtime?.presentation.backdrop) {
        LessonBackdrop.garden => AssetPaths.shapeGardenBackground,
        LessonBackdrop.meadow || null => AssetPaths.countingParadeMeadow,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_backgroundAsset(_runtime), fit: BoxFit.cover),
          FutureBuilder<LessonRuntime>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white70,
                    child: Text('Lesson load failed: ${snap.error}'),
                  ),
                );
              }
              final runtime = snap.requireData;
              _runtime ??= runtime;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _claimMusicOnce(runtime);
                _speakKeeperIntroOnce(runtime);
              });

              if (_phase == _LessonPhase.keeperIntro) {
                return KeeperIntroOverlay(
                  dialog: runtime.presentation.keeperIntro,
                  startLabel: runtime.presentation.startLabel,
                  startButtonKey: const ValueKey('lesson-keeper-start-button'),
                  onStart: _onKeeperStartPressed,
                );
              }

              if (_phase == _LessonPhase.shapeIntro &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                return ShapeIntroLayer(
                  key: ValueKey('shape-intro-$kind'),
                  shapeKind: kind,
                  onComplete: _onShapeIntroComplete,
                );
              }

              if (_phase == _LessonPhase.shapeFindDemo &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                return ShapeFindDemo(
                  key: ValueKey('shape-find-demo-$kind'),
                  targetKind: kind,
                  onComplete: _onShapeFindDemoComplete,
                );
              }

              if (_phase == _LessonPhase.shapeFindRound &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                final previousKinds = kShapeIntroSequence.sublist(
                  0,
                  _currentShapeIdx,
                );
                return ShapeFindRound(
                  key: ValueKey('shape-find-$kind'),
                  targetKind: kind,
                  previousKinds: previousKinds,
                  onComplete: _onShapeFindRoundComplete,
                );
              }

              if (_phase == _LessonPhase.shapesDone) {
                return const ShapesDoneCelebration();
              }

              if (_phase == _LessonPhase.flatOrSolidLesson) {
                return Kg3FlatOrSolidLessonLayer(
                  key: const ValueKey('kg3-flat-or-solid-layer'),
                  onComplete: _onFlatOrSolidLessonComplete,
                );
              }

              if (_phase == _LessonPhase.sortByAttributeLesson) {
                return Kg4SortByAttributeLessonLayer(
                  key: const ValueKey('kg4-sort-by-attribute-layer'),
                  onComplete: _onSortByAttributeLessonComplete,
                );
              }

              // Fawn / iShow path — K.CC.4a-style lessons.
              switch (runtime.presentation.stage) {
                case LessonStage.clusters:
                  return LessonClusterStage(
                    badgeValue: _scene.badgeValue,
                    targets: _targets,
                  );
                case LessonStage.countOn:
                  return LessonCountOnStage(
                    badgeValue: _scene.badgeValue,
                    targets: _targets,
                  );
                case LessonStage.habitat:
                  return HabitatLessonStage(
                    blueprint: kHabitatBlueprints[0],
                    // K.G.6 opens on the frame the kid just laid in K.G.5 -
                    // "the frame is the base, we add shapes on top" - so its
                    // sticks and clay start down rather than as ghosts.
                    placedCorners:
                        runtime.iShow.framePrebuilt &&
                            _phase != _LessonPhase.weTry
                        ? <int>{0, 1, 2}
                        : _scene.placedCorners,
                    placedEdges:
                        runtime.iShow.framePrebuilt &&
                            _phase != _LessonPhase.weTry
                        ? <int>{0, 1, 2}
                        : _scene.placedEdges,
                    placedRoof: _scene.placedRoof,
                    showRoof: _phase == _LessonPhase.weTry
                        ? runtime.weTry.showsRoof
                        : runtime.iShow.showsRoof,
                    carrying: _scene.carrying,
                    handVisible: _scene.handVisible,
                    pointerTarget: _scene.handTarget,
                    fawnHome: _scene.fawnHome,
                    targets: _targets,
                  );
                case LessonStage.clearing:
                  return ClearingLessonStage(
                    landmarkIds: _phase == _LessonPhase.weTry
                        ? runtime.weTry.landmarkIds
                        : runtime.iShow.landmarkIds,
                    facingLandmarkId: _scene.facingLandmarkId,
                    spot: _scene.buddySpot,
                    pointerVisible: _scene.pointerVisible,
                    targets: _targets,
                    zoneIds: _phase == _LessonPhase.weTry
                        ? _scene.haloed
                        : const {},
                  );
                // The three shape stages are drawn by their own phases above
                // and never reach here.
                case LessonStage.fawns:
                case LessonStage.shapeSequence:
                case LessonStage.flatOrSolid:
                case LessonStage.sortByAttribute:
                  break;
              }
              // Creatures in a meadow, which is right for exactly the counting
              // lessons it was built for. `lesson_scene_test.dart` holds the
              // line: a lesson whose scene is not made of creatures must not
              // land here.
              return LessonFawnStage(
                sparkled: _scene.sparkled,
                badgeValue: _scene.badgeValue,
                pointerVisible: _scene.pointerVisible,
                pointerTargetId: _scene.pointerTargetId,
                handAtTarget: _scene.handAtTarget,
                pokeCounter: _scene.pokeCounter,
                burstCounters: _scene.burstCounters,
                count: _phase == _LessonPhase.weTry
                    ? runtime.weTry.creatureCount
                    : runtime.iShow.creatureCount,
                targets: _targets,
              );
            },
          ),
          // Her turn. Above every stage so all five families get the same
          // affordance from one widget, and below the captions and the
          // back-out button so neither is ever swallowed by the gate.
          if (_phase == _LessonPhase.weTry)
            Positioned.fill(
              child: WeTryHaloLayer(
                key: const ValueKey('we-try-layer'),
                registry: _targets,
                targets: _scene.haloed,
                urgent: _weTry?.urgent ?? false,
                onTouch: (_weTry?.waiting ?? false) ? _weTry!.touch : null,
              ),
            ),
          const CaptionOverlay(),
          // Persistent back-to-Sanctuary affordance — kids can bail from
          // any phase.
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: RoundBackButton(
                onPressed: () {
                  ref.narration.clear();
                  context.go(Routes.sanctuary);
                },
              ),
            ),
          ),
          if (_phase == _LessonPhase.iShow && _skipEnabled && !_continueEnabled)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: LessonPillButton(
                  onPressed: _goToYouDo,
                  label: kLabelIveGotThis,
                ),
              ),
            ),
          if ((_phase == _LessonPhase.iShow ||
                  _phase == _LessonPhase.shapesDone) &&
              _continueEnabled)
            Positioned(
              right: 32,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: NextArrowButton(
                    key: const ValueKey('lesson-continue-arrow'),
                    idleHintEnabled: true,
                    onPressed: _phase == _LessonPhase.iShow
                        ? _afterIShow
                        : _goToYouDo,
                    label: kLabelContinue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
