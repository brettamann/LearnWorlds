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

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/flat_or_solid_shapes.dart';
import '../../data/sfx_catalog.dart';
import '../../data/shape_find_placements.dart';
import '../../data/shape_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import '../../theme/app_decor.dart';
import 'animated_shape.dart';
import 'answer_feedback.dart';
import 'buddy_companion.dart';
import 'flat_or_solid_round.dart';
import 'glitter_burst.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'playfield_scaffold.dart';
import 'shape_garden_sort_by_attribute_runner.dart';
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

/// One round of the garden hunt. The list defines the activity sequence.
class _GardenRound {
  const _GardenRound({
    required this.targetKind,
    required this.targetCount,
    required this.distractorCount,
    required this.keeperLine,
  });

  final String targetKind;
  final int targetCount;
  final int distractorCount;

  /// Short keeper line that runs AFTER this round finishes. Non-final
  /// rounds set up the next target; the final round wraps the whole hunt.
  final String keeperLine;
}

/// 8 rounds — one shape per round, easy → harder. Mirrors the K.G.2 lesson
/// sequence so the activity feels like a continuation of what the keeper
/// just taught. Edit this list to extend or rebalance the hunt.
const List<_GardenRound> _kRoundSequence = <_GardenRound>[
  _GardenRound(
    targetKind: 'circle',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: 'Wonderful! All the circles. Now find the triangles.',
  ),
  _GardenRound(
    targetKind: 'triangle',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: "Nice work! Let's find the squares next.",
  ),
  _GardenRound(
    targetKind: 'square',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: 'Great squares! How about the rectangles?',
  ),
  _GardenRound(
    targetKind: 'rectangle',
    targetCount: 3,
    distractorCount: 4,
    keeperLine: "Lovely! Let's hunt some pentagons.",
  ),
  _GardenRound(
    targetKind: 'pentagon',
    targetCount: 2,
    distractorCount: 4,
    keeperLine: 'Pentagons found! Now the hexagons.',
  ),
  _GardenRound(
    targetKind: 'hexagon',
    targetCount: 2,
    distractorCount: 4,
    keeperLine: "Excellent! Let's spot the right triangles.",
  ),
  _GardenRound(
    targetKind: 'triangle-right',
    targetCount: 2,
    distractorCount: 5,
    keeperLine: 'You got them! One more — half circles.',
  ),
  _GardenRound(
    targetKind: 'semicircle_half',
    targetCount: 2,
    distractorCount: 5,
    keeperLine: "You found every shape in the garden! That's amazing.",
  ),
];

/// Sub-modes the Shape Garden activity supports.
/// `find-shape` (K.G.2), `flat-or-solid` (K.G.3), `sort-by-attribute`
/// (K.G.4), and `two-attribute-hunt` (K.G.4 challenge). Any unknown
/// sub-mode falls back to find-shape so a registry-only sub-mode that
/// hasn't shipped a runner yet stays playable.
const String kShapeGardenSubModeFindShape = 'find-shape';
const String kShapeGardenSubModeFlatOrSolid = 'flat-or-solid';
const String kShapeGardenSubModeSortByAttribute = 'sort-by-attribute';
const String kShapeGardenSubModeTwoAttributeHunt = 'two-attribute-hunt';

/// Top-level Shape Garden runner. Dispatches on `subMode` so the activity
/// screen doesn't need to know which K.G.* concept is being practiced —
/// it just hands off `launchExtra['subMode']` and lets this widget pick
/// the right body.
class ShapeGardenRunner extends StatelessWidget {
  const ShapeGardenRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = kShapeGardenSubModeFindShape,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  Widget build(BuildContext context) {
    if (subMode == kShapeGardenSubModeFlatOrSolid) {
      return ShapeGardenSortingRunner(
        onSequenceComplete: onSequenceComplete,
        skipIntro: skipIntro,
      );
    }
    if (subMode == kShapeGardenSubModeSortByAttribute) {
      return ShapeGardenSortByAttributeRunner(
        onSequenceComplete: onSequenceComplete,
        skipIntro: skipIntro,
      );
    }
    if (subMode == kShapeGardenSubModeTwoAttributeHunt) {
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

class ShapeGardenFindingRunner extends ConsumerStatefulWidget {
  const ShapeGardenFindingRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  /// Fires once every round in `_kRoundSequence` resolves + the final
  /// interstitial is dismissed.
  final VoidCallback onSequenceComplete;

  /// When true, jump straight to the first finding round — used after a
  /// lesson hand-off where the keeper intro has already played.
  final bool skipIntro;

  @override
  ConsumerState<ShapeGardenFindingRunner> createState() =>
      _ShapeGardenRunnerState();
}

class _ShapeGardenRunnerState extends ConsumerState<ShapeGardenFindingRunner> {
  late _Phase _phase = widget.skipIntro ? _Phase.finding : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<String> _tappedIds = <String>{};
  Map<String, int> _burstCounters = <String, int>{};
  List<ShapeFindPlacement> _placements = const <ShapeFindPlacement>[];
  Timer? _celebrationTimer;
  bool _promptSpoken = false;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Placement id → wrong taps on it, driving the shake. Before this existed
  /// a wrong tap in the garden produced a spoken line and nothing else: no
  /// sound, no movement, no colour change. To a child who can't read and has
  /// learned to tune out the synth voice, that is indistinguishable from the
  /// app having frozen.
  Map<String, int> _wrongTokens = <String, int>{};

  int _wrongTaps = 0;
  int _missRotation = 0;

  /// Placement the hint ladder is glowing, if any.
  String? _hintedId;

  HintLadder? _hints;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  static const Duration _kCelebrationHold =
      Duration(seconds: 1, milliseconds: 400);

  _GardenRound get _currentRound => _kRoundSequence[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRoundSequence.length - 1;
  bool get _allTargetsTapped {
    for (final p in _placements) {
      if (p.isTarget && !_tappedIds.contains(p.id)) return false;
    }
    return _placements.any((p) => p.isTarget);
  }

  double get _progress => _completedRounds / _kRoundSequence.length;

  String get _targetDisplay =>
      kShapeDisplayName[_currentRound.targetKind] ?? _currentRound.targetKind;
  String get _targetPlural =>
      kShapeDisplayPlural[_currentRound.targetKind] ?? '${_targetDisplay}s';

  String get _introDialog =>
      'Look — some plants in the garden have grown into shapes! Help me find '
      "them all, won't you? We'll start with the circles.";

  String get _finalKeeperLine {
    final coins = _kRoundSequence.length * kCoinsForCleanRound;
    return 'You found every shape in the garden! Here are $coins coins '
        'for your help.';
  }

  @override
  void initState() {
    super.initState();
    _placements = _buildPlacementsForRound(_roundIndex);
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    unawaited(_sfxForDispose!.startMusicBed(kDefaultMusicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.intro) {
        _speakIntroOnce();
      } else {
        _startHints();
        _speakRoundPromptOnce();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  /// Escalating help. This activity had none at all: a kid who genuinely
  /// didn't know which shape was a hexagon could sit in front of the board
  /// indefinitely with nothing happening.
  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.finding) return;
    final next = _nextUntappedTarget();
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
        ref.narration.say(
          warmHintLine(2),
          cueId: 'shape-garden:r$_roundIndex:hint-point',
        );
      case HintLevel.demonstrate:
        feedback.hint();
        ref.narration.say(
          'This one is a $_targetDisplay.',
          cueId: 'shape-garden:r$_roundIndex:hint-demo',
        );
        _onTap(next, fromHint: true);
    }
  }

  ShapeFindPlacement? _nextUntappedTarget() {
    for (final p in _placements) {
      if (p.isTarget && !_tappedIds.contains(p.id)) return p;
    }
    return null;
  }

  List<ShapeFindPlacement> _buildPlacementsForRound(int idx) {
    final round = _kRoundSequence[idx];
    // Pool of distractor kinds — every kind earlier in the sequence.
    final pool = <String>[
      for (var i = 0; i < idx; i++) _kRoundSequence[i].targetKind,
    ];
    return buildShapeFindPlacements(
      targetKind: round.targetKind,
      distractorKindPool: pool,
      seed: round.targetKind.hashCode ^ (idx + 1) * 0x9E3779B1,
      targetCount: round.targetCount,
      distractorCount: round.distractorCount,
    );
  }

  void _speakIntroOnce() {
    ref.narration.say(
      _introDialog,
      cueId: 'shape-garden:intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  void _speakRoundPromptOnce() {
    if (_promptSpoken) return;
    _promptSpoken = true;
    ref.narration.say(
      'Tap all the $_targetPlural.',
      cueId: 'shape-garden:r$_roundIndex:prompt',
    );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.finding);
    _promptSpoken = false;
    _startHints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakRoundPromptOnce();
    });
  }

  void _onTap(ShapeFindPlacement p, {bool fromHint = false}) {
    if (_phase != _Phase.finding) return;
    if (_tappedIds.contains(p.id)) return;
    if (!fromHint) _hints?.poke();
    if (p.isTarget) {
      setState(() {
        _tappedIds.add(p.id);
        _burstCounters[p.id] = (_burstCounters[p.id] ?? 0) + 1;
        _hintedId = null;
      });
      // Each target found sounds a step up the scale, so a round of three
      // circles is audibly three, not three identical chimes.
      ref.read(feedbackEngineProvider).countStep(_tappedIds.length);
      if (_allTargetsTapped) {
        _onAllTargetsFound();
      } else {
        // Queued, not spoken, when the ladder did this tap. `speak` cuts off
        // whatever is in flight, and what is in flight at that moment is the
        // demonstration's own explanation - the one line in the round that
        // says why. See HintLadder.
        final say = ref.narration;
        final line = NarrationLine(
          text: "There's one!",
          cueId: 'shape-garden:r$_roundIndex:hit-${p.id}',
        );
        if (fromHint) {
          say.enqueue(line);
        } else {
          say.speak(line);
        }
      }
    } else {
      setState(() {
        _wrongTaps += 1;
        _wrongTokens[p.id] = (_wrongTokens[p.id] ?? 0) + 1;
      });
      ref.read(feedbackEngineProvider).wrong();
      // This used to open by naming what she tapped ("That's a circle.")
      // before the warm line. That was three variables in one sentence - the
      // wrong shape, the rotating warm line, and the target - which is 648
      // possible sentences, and it put the line permanently out of reach of a
      // recorded voice: it was the one beat in Shape Garden that switched back
      // to the browser synth, at the exact moment she got something wrong.
      //
      // Dropping the lead costs less than it looks. The shape she tapped is
      // under her finger, and k-activity-patterns.md never asks the game to
      // name a child's mistake back to her. The family is now 36.
      _missRotation += 1;
      ref.narration.say(
        '${warmMissLine(_missRotation)} '
        'Find the $_targetPlural.',
        cueId: 'shape-garden:r$_roundIndex:miss-${p.id}-$_wrongTaps',
      );
    }
  }

  void _onAllTargetsFound() {
    _hints?.pause();

    // The real outcome, not the hardcoded `true` this used to pass. Three
    // wrong taps is a genuine miss of the shape; anything less, or a
    // demonstration, resolves soft.
    final hintsUsed = _hints?.hintsUsed ?? 0;
    final result = gradeRound(misses: _wrongTaps, helped: hintsUsed > 0);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'shape-garden',
          conceptId: 'K.G.2',
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
          cueId: 'shape-garden:r$_roundIndex:interstitial',
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
        cueId: 'shape-garden:r$_roundIndex:interstitial',
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
      _placements = _buildPlacementsForRound(_roundIndex);
      _tappedIds = <String>{};
      _burstCounters = <String, int>{};
      _wrongTokens = <String, int>{};
      _wrongTaps = 0;
      _missRotation = 0;
      _hintedId = null;
      _phase = _Phase.finding;
      _promptSpoken = false;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _startHints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakRoundPromptOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's hunt!",
          startButtonKey: const ValueKey('shape-garden-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.finding ||
      _Phase.celebrating ||
      _Phase.transition =>
        _FindingLayer(
          roundIndex: _roundIndex,
          totalRounds: _kRoundSequence.length,
          targetPlural: _targetPlural,
          placements: _placements,
          tappedIds: _tappedIds,
          burstCounters: _burstCounters,
          wrongTokens: _wrongTokens,
          hintedId: _hintedId,
          onTap: _onTap,
          // Lock input outside the finding phase so a stray tap doesn't
          // trigger a "wrong" line during the celebration or the aside.
          inputLocked: _phase != _Phase.finding,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('shape-garden-interstitial-next'),
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
        if (_phase != _Phase.intro && _phase != _Phase.interstitial)
          const BuddyCompanionCorner(),
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

class _FindingLayer extends StatelessWidget {
  const _FindingLayer({
    required this.roundIndex,
    required this.totalRounds,
    required this.targetPlural,
    required this.placements,
    required this.tappedIds,
    required this.burstCounters,
    required this.wrongTokens,
    required this.hintedId,
    required this.onTap,
    required this.inputLocked,
  });

  final int roundIndex;
  final int totalRounds;
  final String targetPlural;
  final List<ShapeFindPlacement> placements;
  final Set<String> tappedIds;
  final Map<String, int> burstCounters;

  /// Placement id → wrong taps on it. Drives the shake.
  final Map<String, int> wrongTokens;

  /// Placement the hint ladder wants glowed, or null.
  final String? hintedId;

  final ValueChanged<ShapeFindPlacement> onTap;
  final bool inputLocked;

  static const double _spriteSize = 144;
  static const double _spriteSizeDecor = 120;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The scatter is a 4x3 grid of fractions laid over this box. The box
        // already stops above the caption band - `PlayfieldScaffold` reserves
        // it - so what is left to guard against is the sprite itself: a
        // placement puts a *centre*, and a fixed 144-pixel shape hangs 72
        // pixels past it in every direction. On a small window that was
        // enough to push the bottom row back under the band.
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const margin = _spriteSizeDecor / 2 + 24;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration:
                      AppDecor.card(radius: 18, shadow: AppShadows.soft),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap all the $targetPlural!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Round ${roundIndex + 1} of $totalRounds',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (final p in placements)
              Positioned(
                left: p.center.dx * w -
                    (p.isDecor ? _spriteSizeDecor : _spriteSize) / 2,
                top: margin +
                    p.center.dy * (h - margin * 2) -
                    (p.isDecor ? _spriteSizeDecor : _spriteSize) / 2 +
                    24,
                width: p.isDecor ? _spriteSizeDecor : _spriteSize,
                height: p.isDecor ? _spriteSizeDecor : _spriteSize,
                child: IgnorePointer(
                  ignoring: inputLocked,
                  child: GestureDetector(
                    key: ValueKey(
                      'garden-r$roundIndex-${p.id}',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(p),
                    // The sparkle burst is already drawn separately in this
                    // layer, so only the wrong reaction is wanted here.
                    child: AnswerFeedback(
                      wrongToken: wrongTokens[p.id] ?? 0,
                      child: p.isDecor
                          ? Image.asset(
                              p.assetPath,
                              fit: BoxFit.contain,
                            )
                          : AnimatedShape(
                              spriteAsset: p.assetPath,
                              active: tappedIds.contains(p.id),
                              pointed: hintedId == p.id,
                              pose: ShapePose(
                                rotationDegrees: p.rotationDegrees,
                              ),
                              size: _spriteSize,
                            ),
                    ),
                  ),
                ),
              ),
            for (final entry in burstCounters.entries)
              if (entry.value > 0)
                Builder(
                  builder: (_) {
                    final placement = placements.firstWhere(
                      (p) => p.id == entry.key,
                    );
                    final size =
                        placement.isDecor ? _spriteSizeDecor : _spriteSize;
                    return Positioned(
                      left: placement.center.dx * w - size / 2 - 22,
                      top: margin +
                          placement.center.dy * (h - margin * 2) -
                          size / 2 +
                          24 -
                          22,
                      width: size + 44,
                      height: size + 44,
                      child: GlitterBurst(
                        key: ValueKey(
                          'garden-burst-r$roundIndex-${entry.key}-${entry.value}',
                        ),
                      ),
                    );
                  },
                ),
          ],
        );
      },
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
          activityId: 'shape-garden',
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
