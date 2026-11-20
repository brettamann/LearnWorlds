// ShapeGardenRunner — multi-round K.G.2 "find the shape" practice.
//
// The kid hunts a single target kind per round across a mock garden of
// decoys (other shapes the kid has met + decor butterflies / frogs /
// watering cans). Each round resolves through the RoundCoordinator so
// mastery streak + coin payout match honest play, then the keeper steps
// in with a short transition line into the next target shape.
//
// Phases:
//   1. intro         — Keeper greets the kid. Skipped on lesson hand-off.
//   2. finding       — Board of shapes; tap every target, then Done.
//   3. celebrating   — Hold beat after the last target is tapped.
//   4. transition    — Keeper speaks over the LIVE garden and advances the
//                      round herself. No tap required.
//   5. interstitial  — Blocking, final round only: the reward beat.
//
// Round sequence is fixed at 8 — same shape ladder the lesson taught.
// `distractorPool` per round is the set of kinds the kid has already met
// in this sequence, so a kid can always *name* every shape on the board.
//
// Eight rounds is only twenty taps in total, so the round count was never
// what made this drag — the eight full-screen keeper modals were. Those are
// gone; the sequence stays at eight because trimming it would cost shape
// coverage (each round is a different kind) for no pacing gain.
//
// Final round → onSequenceComplete fires so the host (ActivityScreen)
// can run the standard round-complete sheet / Sanctuary navigation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../activities/sub_mode_ids.dart';
import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/flat_or_solid_shapes.dart';
import '../../data/sfx_catalog.dart';
import '../../data/shape_find_placements.dart';
import '../../data/shape_garden_rounds.dart';
import '../../data/shape_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import 'flat_or_solid_round.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'playfield_scaffold.dart';
import 'sanctuary_round_shell.dart';
import 'shape_garden_sort_by_attribute_runner.dart';
import 'shape_scatter_board.dart';
import 'two_attribute_hunt_runner.dart';

enum _Phase {
  intro,
  finding,

  /// Keeper speaks over the live garden and advances the round herself.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

/// Top-level Shape Garden runner: picks the body for the sub-mode.
class ShapeGardenRunner extends StatelessWidget {
  const ShapeGardenRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = ShapeGardenModes.findShape,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  Widget build(BuildContext context) {
    if (subMode == ShapeGardenModes.flatOrSolid) {
      return ShapeGardenSortingRunner(
        onSequenceComplete: onSequenceComplete,
        skipIntro: skipIntro,
      );
    }
    if (subMode == ShapeGardenModes.sortByAttribute) {
      return ShapeGardenSortByAttributeRunner(
        onSequenceComplete: onSequenceComplete,
        skipIntro: skipIntro,
      );
    }
    if (subMode == ShapeGardenModes.twoAttributeHunt) {
      return TwoAttributeHuntRunner(
        onSequenceComplete: onSequenceComplete,
        skipIntro: skipIntro,
      );
    }
    return ShapeGardenFindingRunner(
      onSequenceComplete: onSequenceComplete,
      skipIntro: skipIntro,
    );
  }
}

class ShapeGardenFindingRunner extends StatelessWidget {
  const ShapeGardenFindingRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;

  /// True after a lesson hand-off, where the keeper's intro has played.
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    return SanctuaryRoundShell(
      activityId: ActivityIds.shapeGarden,
      roundCount: kGardenRounds.length,
      conceptIdFor: (_) => 'K.G.2',
      introLine: kGardenIntro,
      startLabel: kGardenStartLabel,
      keeperLineFor: (i) => kGardenRounds[i].keeperLine,
      finalLine: kGardenFinal,
      skipIntro: skipIntro,
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.shapeGardenBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => GardenFindRoundBody(c: c),
    );
  }
}

/// One round of the garden hunt: tap every shape of this round's kind.
class GardenFindRoundBody extends ConsumerStatefulWidget {
  const GardenFindRoundBody({super.key, required this.c});

  final RoundContext c;

  @override
  ConsumerState<GardenFindRoundBody> createState() =>
      _GardenFindRoundBodyState();
}

class _GardenFindRoundBodyState extends ConsumerState<GardenFindRoundBody> {
  late final GardenRound _round = kGardenRounds[widget.c.index];
  late final List<ShapeFindPlacement> _placements = buildShapeFindPlacements(
    targetKind: _round.targetKind,
    // Every kind met earlier in the hunt, so she can name everything on the
    // board.
    distractorKindPool: <String>[
      for (var i = 0; i < widget.c.index; i++) kGardenRounds[i].targetKind,
    ],
    seed: shapeFindSeed(_round.targetKind, widget.c.index),
    targetCount: _round.targetCount,
    distractorCount: _round.distractorCount,
  );

  final Set<String> _tapped = <String>{};
  final Map<String, int> _bursts = <String, int>{};

  /// Placement id -> wrong taps on it, driving the shake. Without it a wrong
  /// tap made a spoken line and nothing else, which to a child who cannot
  /// read is the app freezing.
  final Map<String, int> _wrongTokens = <String, int>{};
  int _wrongTaps = 0;
  String? _hintedId;
  HintLadder? _hints;
  bool _done = false;

  String get _plural =>
      kShapeDisplayPlural[_round.targetKind] ?? '${_round.targetKind}s';
  String get _singular =>
      kShapeDisplayName[_round.targetKind] ?? _round.targetKind;
  bool get _open => !_done && !widget.c.locked;

  ShapeFindPlacement? get _nextTarget => _placements
      .where((p) => p.isTarget && !_tapped.contains(p.id))
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say('Tap all the $_plural.');
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextTarget;
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hintedId = next.id);
      case HintLevel.point:
        setState(() => _hintedId = next.id);
        feedback.hint();
        widget.c.say(warmHintLine(2), replay: false);
      case HintLevel.demonstrate:
        feedback.hint();
        widget.c.say('This one is a $_singular.', replay: false);
        _onTap(next, fromHint: true);
    }
  }

  void _onTap(ShapeFindPlacement p, {bool fromHint = false}) {
    if (!_open || _tapped.contains(p.id)) return;
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (!p.isTarget) {
      setState(() {
        _wrongTaps += 1;
        _wrongTokens[p.id] = (_wrongTokens[p.id] ?? 0) + 1;
      });
      feedback.wrong();
      // Never names the shape she tapped: that made 648 sentences no voice
      // could record, at the exact moment she got something wrong.
      widget.c.say(
        '${warmMissLine(_wrongTaps)} Find the $_plural.',
        replay: false,
      );
      return;
    }
    setState(() {
      _tapped.add(p.id);
      _bursts[p.id] = (_bursts[p.id] ?? 0) + 1;
      _hintedId = null;
    });
    // Each find sounds a step up the scale: three circles are audibly three.
    feedback.countStep(_tapped.length);
    if (_nextTarget == null) {
      _done = true;
      _hints?.pause();
      widget.c.finish(
        gradeRound(
          misses: _wrongTaps,
          helped: (_hints?.hintsUsed ?? 0) > 0,
        ),
      );
      return;
    }
    // Queued when the ladder made this tap, so it does not cut off the
    // demonstration's own explanation.
    widget.c.say(kShapeFoundLine, replay: false, queue: fromHint);
  }

  @override
  Widget build(BuildContext context) {
    return ShapeScatterBoard(
      keyPrefix: 'garden-r${widget.c.index}',
      targetPlural: _plural,
      roundLabel: 'Round ${widget.c.index + 1} of ${widget.c.count}',
      placements: _placements,
      tappedIds: _tapped,
      burstCounters: _bursts,
      wrongTokens: _wrongTokens,
      hintedId: _hintedId,
      inputLocked: !_open,
      onTap: _onTap,
    );
  }
}

// ============================================================================
// K.G.3 — Flat or Solid sub-mode
// ============================================================================

/// One sorting round's shape mix. `flatCount` + `solidCount` shapes are
/// drawn from the flat/solid pools using a deterministic round-keyed
/// rotation so the kid sees variety without unfair surprise repeats.
class _SortingRound {
  const _SortingRound({
    required this.flatCount,
    required this.solidCount,
    required this.keeperLine,
  });

  final int flatCount;
  final int solidCount;

  /// Short keeper line that runs AFTER this round finishes. Non-final
  /// rounds set up the next; the final round wraps the whole hunt.
  final String keeperLine;
}

const List<_SortingRound> _kSortingSequence = <_SortingRound>[
  _SortingRound(
    flatCount: 2,
    solidCount: 2,
    keeperLine: 'Wonderful sorting! Try another round.',
  ),
  _SortingRound(
    flatCount: 2,
    solidCount: 2,
    keeperLine: "You're getting the hang of it. One more.",
  ),
  _SortingRound(
    flatCount: 3,
    solidCount: 2,
    keeperLine: 'Lovely! Let me bring out a few more shapes.',
  ),
  _SortingRound(
    flatCount: 2,
    solidCount: 3,
    keeperLine: 'Almost done — one last basket-round!',
  ),
  _SortingRound(
    flatCount: 3,
    solidCount: 3,
    keeperLine: 'You sorted every shape! Wonderful work.',
  ),
];

/// Shape Garden activity body for the K.G.3 flat-or-solid sub-mode. Same
/// phase machine as the finding runner — only the round body and round
/// metadata differ.
class ShapeGardenSortingRunner extends ConsumerStatefulWidget {
  const ShapeGardenSortingRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<ShapeGardenSortingRunner> createState() =>
      _ShapeGardenSortingRunnerState();
}

class _ShapeGardenSortingRunnerState
    extends ConsumerState<ShapeGardenSortingRunner> {
  late _Phase _phase = widget.skipIntro ? _Phase.finding : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  late List<FlatOrSolidShape> _currentShapes;
  Timer? _celebrationTimer;
  int _roundResetKey = 0;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Wrong-bin drops this round, reported by FlatOrSolidRound.
  int _wrongDrops = 0;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  static const Duration _kCelebrationHold =
      Duration(seconds: 1, milliseconds: 200);

  _SortingRound get _currentRound => _kSortingSequence[_roundIndex];
  bool get _isLastRound => _roundIndex == _kSortingSequence.length - 1;
  double get _progress => _completedRounds / _kSortingSequence.length;

  String get _introDialog =>
      'Some shapes are flat — like drawings on a page. Others are solid '
      '— you can hold them in your hand. Help me sort them into the right '
      'baskets!';

  String get _finalKeeperLine {
    final coins = _kSortingSequence.length * kCoinsForCleanRound;
    return 'You sorted every shape! Here are $coins coins for your help.';
  }

  @override
  void initState() {
    super.initState();
    _currentShapes = _buildShapesForRound(_roundIndex);
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    unawaited(_sfxForDispose!.startMusicBed(kDefaultMusicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.intro) _speakIntro();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  /// Picks `flatCount + solidCount` shapes from the registry pools using
  /// a round-keyed offset so each round shows a different mix.
  List<FlatOrSolidShape> _buildShapesForRound(int idx) {
    final round = _kSortingSequence[idx];
    final shapes = <FlatOrSolidShape>[];
    for (var i = 0; i < round.flatCount; i++) {
      shapes.add(kFlatShapes[(idx * 2 + i) % kFlatShapes.length]);
    }
    for (var i = 0; i < round.solidCount; i++) {
      shapes.add(kSolidShapes[(idx + i) % kSolidShapes.length]);
    }
    return shapes;
  }

  void _speakIntro() {
    ref.narration.say(
      _introDialog,
      cueId: 'shape-garden-sort:intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.finding);
  }

  void _onRoundComplete() {
    // Three wrong baskets across a round of four to six shapes is a genuine
    // miss of the flat/solid distinction, not a slip.
    final result = gradeRound(misses: _wrongDrops);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: ActivityIds.shapeGarden,
          conceptId: 'K.G.3',
          result: result,
        );
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });

    final feedback = ref.read(feedbackEngineProvider);
    if (_isLastRound) {
      feedback.celebrate();
      _celebrationTimer = Timer(_kCelebrationHold, () {
        if (!mounted) return;
        setState(() => _phase = _Phase.interstitial);
        ref.narration.say(
          _finalKeeperLine,
          cueId: 'shape-garden-sort:r$_roundIndex:interstitial',
          speaker: kKeeperSpeaker,
          caption: false,
        );
      });
      return;
    }

    feedback.roundPass();
    _celebrationTimer = Timer(_kCelebrationHold, () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.transition;
        _asideToken += 1;
      });
      ref.narration.say(
        _currentRound.keeperLine,
        cueId: 'shape-garden-sort:r$_roundIndex:interstitial',
        speaker: kKeeperSpeaker,
        caption: false,
      );
    });
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    setState(() {
      _roundIndex += 1;
      _currentShapes = _buildShapesForRound(_roundIndex);
      _roundResetKey += 1;
      _wrongDrops = 0;
      _phase = _Phase.finding;
    });
    ref.read(feedbackEngineProvider).resetRound();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's sort!",
          startButtonKey: const ValueKey('shape-garden-sort-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.finding ||
      _Phase.celebrating ||
      _Phase.transition =>
        FlatOrSolidRound(
          key: ValueKey('garden-sort-r$_roundIndex-$_roundResetKey'),
          shapes: _currentShapes,
          cueIdPrefix: 'shape-garden-sort:r$_roundIndex',
          headerPrompt:
              'Round ${_roundIndex + 1} of ${_kSortingSequence.length} — '
              'flat or solid?',
          onComplete: _onRoundComplete,
          onMiss: () => _wrongDrops += 1,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('shape-garden-sort-interstitial-next'),
          onStart: widget.onSequenceComplete,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AssetPaths.shapeGardenBackground,
          fit: BoxFit.cover,
        ),
        PlayfieldScaffold(
          progress: _progress,
          celebrate: _phase == _Phase.celebrating,
          child: phaseContent,
        ),
        if (_phase == _Phase.transition)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KeeperAside(
              text: _currentRound.keeperLine,
              token: _asideToken,
              onDismissed: _advanceToNextRound,
            ),
          ),
      ],
    );
  }
}
