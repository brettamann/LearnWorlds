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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/flat_or_solid_shapes.dart';
import '../../data/shape_find_placements.dart';
import '../../data/shape_garden_rounds.dart';
import '../../data/shape_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../ui/common/target_hint.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../../ui/shapes/flat_or_solid_round.dart';
import '../../ui/shapes/shape_scatter_board.dart';
import '../activity_ids.dart';
import '../sub_mode_ids.dart';
import 'shape_garden_sort_by_attribute_runner.dart';
import 'two_attribute_hunt_runner.dart';

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
    answerTargetHint(
      level,
      ring: () => setState(() => _hintedId = next.id),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      demonstrateLine: 'This one is a $_singular.',
      demonstrate: () => _onTap(next, fromHint: true),
    );
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

/// Shape Garden's K.G.3 flat-or-solid sub-mode: five rounds of dragging
/// shapes into the flat and solid baskets.
class ShapeGardenSortingRunner extends StatelessWidget {
  const ShapeGardenSortingRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    return SanctuaryRoundShell(
      activityId: ActivityIds.shapeGarden,
      roundCount: kGardenSortingRounds.length,
      conceptIdFor: (_) => 'K.G.3',
      introLine: kGardenSortingIntro,
      keeperLineFor: (i) => kGardenSortingRounds[i].keeperLine,
      finalLine: kGardenSortingFinal,
      skipIntro: skipIntro,
      celebrationHold: const Duration(milliseconds: 1200),
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.shapeGardenBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => GardenSortRoundBody(c: c),
    );
  }
}

/// One flat-or-solid round. The mechanic, its lines and its completion beat
/// are FlatOrSolidRound's (the K.G.3 lesson plays the same one); this only
/// counts wrong baskets and reports the round.
///
/// Turns on FlatOrSolidRound's idle help: before, a child who did not know
/// where a shape went heard nothing at all.
class GardenSortRoundBody extends StatefulWidget {
  const GardenSortRoundBody({super.key, required this.c});

  final RoundContext c;

  @override
  State<GardenSortRoundBody> createState() => _GardenSortRoundBodyState();
}

class _GardenSortRoundBodyState extends State<GardenSortRoundBody> {
  late final List<FlatOrSolidShape> _shapes =
      gardenSortingShapes(widget.c.index);
  int _wrongDrops = 0;
  bool _helped = false;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.c.locked,
      child: FlatOrSolidRound(
        shapes: _shapes,
        cueIdPrefix: 'shape-garden-sort:r${widget.c.index}',
        headerPrompt: gardenSortingHeader(widget.c.index),
        onMiss: () => _wrongDrops += 1,
        idleHelp: true,
        onHelped: () => _helped = true,
        // Three wrong baskets across a round of four to six shapes is a
        // genuine miss of the flat/solid distinction, not a slip.
        onComplete: () =>
            widget.c.finish(gradeRound(misses: _wrongDrops, helped: _helped)),
      ),
    );
  }
}
