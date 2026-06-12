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
//   4. interstitial  — Keeper "Great! Now the triangles." or final reward.
//
// Round sequence is fixed at 8 — same shape ladder the lesson taught.
// `distractorPool` per round is the set of kinds the kid has already met
// in this sequence, so a kid can always *name* every shape on the board.
//
// Final round → onSequenceComplete fires so the host (ActivityScreen)
// can run the standard round-complete sheet / Sanctuary navigation.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/flat_or_solid_shapes.dart';
import '../../data/shape_find_placements.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'animated_shape.dart';
import 'flat_or_solid_round.dart';
import 'glitter_burst.dart';
import 'keeper_intro_overlay.dart';
import 'progress_bar_to_reward.dart';
import 'shape_intro_layer.dart' show kShapeDisplayName, kShapeDisplayPlural;

enum _Phase { intro, finding, celebrating, interstitial }

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

/// Mirrors `RoundCoordinator._coinsPerRoundPass`. Used by the final keeper
/// line so the kid hears the total coins they earned.
const int _coinsPerRound = 5;

/// Sub-modes the Shape Garden activity supports. `find-shape` ships first
/// (K.G.2 invariance practice); `flat-or-solid` ships next (K.G.3 sort by
/// dimensionality). Any unknown sub-mode falls back to find-shape.
const String kShapeGardenSubModeFindShape = 'find-shape';
const String kShapeGardenSubModeFlatOrSolid = 'flat-or-solid';

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

  static const Duration _kCelebrationHold = Duration(seconds: 1, milliseconds: 400);

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
    final coins = _kRoundSequence.length * _coinsPerRound;
    return 'You found every shape in the garden! Here are $coins coins '
        'for your help.';
  }

  @override
  void initState() {
    super.initState();
    _placements = _buildPlacementsForRound(_roundIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.intro) {
        _speakIntroOnce();
      } else {
        _speakRoundPromptOnce();
      }
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
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
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _introDialog,
            cueId: 'shape-garden:intro',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _speakRoundPromptOnce() {
    if (_promptSpoken) return;
    _promptSpoken = true;
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: 'Tap all the $_targetPlural.',
            cueId: 'shape-garden:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.finding);
    _promptSpoken = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakRoundPromptOnce();
    });
  }

  void _onTap(ShapeFindPlacement p) {
    if (_phase != _Phase.finding) return;
    if (_tappedIds.contains(p.id)) return;
    if (p.isTarget) {
      setState(() {
        _tappedIds.add(p.id);
        _burstCounters[p.id] = (_burstCounters[p.id] ?? 0) + 1;
      });
      if (_allTargetsTapped) {
        _onAllTargetsFound();
      } else {
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: "There's one!",
                cueId: 'shape-garden:r$_roundIndex:hit-${p.id}',
              ),
            );
      }
    } else {
      final wrongName = p.isDecor
          ? _decorName(p.assetPath)
          : (kShapeDisplayName[p.kind] ?? p.kind);
      ref.read(narrationPlayerProvider.notifier).speak(
            NarrationLine(
              text:
                  "That's a $wrongName — try again. Find the $_targetPlural.",
              cueId: 'shape-garden:r$_roundIndex:miss-${p.id}',
            ),
          );
    }
  }

  String _decorName(String assetPath) {
    if (assetPath.contains('butterfly')) return 'butterfly';
    if (assetPath.contains('frog')) return 'frog';
    if (assetPath.contains('watering-can')) return 'watering can';
    return 'thing';
  }

  void _onAllTargetsFound() {
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'shape-garden',
          conceptId: 'K.G.2',
          success: true,
        );
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });
    _celebrationTimer = Timer(_kCelebrationHold, () {
      if (!mounted) return;
      setState(() => _phase = _Phase.interstitial);
      final line = _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: line,
              cueId: 'shape-garden:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  void _advanceFromInterstitial() {
    if (_isLastRound) {
      widget.onSequenceComplete();
      return;
    }
    setState(() {
      _roundIndex += 1;
      _placements = _buildPlacementsForRound(_roundIndex);
      _tappedIds = <String>{};
      _burstCounters = <String, int>{};
      _phase = _Phase.finding;
      _promptSpoken = false;
    });
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
      _Phase.finding || _Phase.celebrating => _FindingLayer(
          roundIndex: _roundIndex,
          totalRounds: _kRoundSequence.length,
          targetPlural: _targetPlural,
          placements: _placements,
          tappedIds: _tappedIds,
          burstCounters: _burstCounters,
          onTap: _onTap,
          // Lock input during the post-round hold so a stray tap doesn't
          // trigger a "wrong" line during the celebration beat.
          inputLocked: _phase == _Phase.celebrating,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey:
              const ValueKey('shape-garden-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AssetPaths.shapeGardenBackground,
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ProgressBarToReward(
                  progress: _progress,
                  celebrate: _phase == _Phase.celebrating,
                ),
              ),
              Expanded(child: phaseContent),
            ],
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
    required this.onTap,
    required this.inputLocked,
  });

  final int roundIndex;
  final int totalRounds;
  final String targetPlural;
  final List<ShapeFindPlacement> placements;
  final Set<String> tappedIds;
  final Map<String, int> burstCounters;
  final ValueChanged<ShapeFindPlacement> onTap;
  final bool inputLocked;

  static const double _spriteSize = 144;
  static const double _spriteSizeDecor = 120;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
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
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
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
                top: p.center.dy * h -
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
                    child: p.isDecor
                        ? Image.asset(
                            p.assetPath,
                            fit: BoxFit.contain,
                          )
                        : AnimatedShape(
                            spriteAsset: p.assetPath,
                            active: tappedIds.contains(p.id),
                            pose: ShapePose(
                              rotationDegrees: p.rotationDegrees,
                            ),
                            size: _spriteSize,
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
                    final size = placement.isDecor
                        ? _spriteSizeDecor
                        : _spriteSize;
                    return Positioned(
                      left: placement.center.dx * w - size / 2 - 22,
                      top: placement.center.dy * h - size / 2 + 24 - 22,
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
    final coins = _kSortingSequence.length * _coinsPerRound;
    return 'You sorted every shape! Here are $coins coins for your help.';
  }

  @override
  void initState() {
    super.initState();
    _currentShapes = _buildShapesForRound(_roundIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.intro) _speakIntro();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
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
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _introDialog,
            cueId: 'shape-garden-sort:intro',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.finding);
  }

  void _onRoundComplete() {
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'shape-garden',
          conceptId: 'K.G.3',
          success: true,
        );
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });
    _celebrationTimer = Timer(_kCelebrationHold, () {
      if (!mounted) return;
      setState(() => _phase = _Phase.interstitial);
      final line = _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: line,
              cueId: 'shape-garden-sort:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  void _advanceFromInterstitial() {
    if (_isLastRound) {
      widget.onSequenceComplete();
      return;
    }
    setState(() {
      _roundIndex += 1;
      _currentShapes = _buildShapesForRound(_roundIndex);
      _roundResetKey += 1;
      _phase = _Phase.finding;
    });
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
      _Phase.finding || _Phase.celebrating => FlatOrSolidRound(
          key: ValueKey('garden-sort-r$_roundIndex-$_roundResetKey'),
          shapes: _currentShapes,
          cueIdPrefix: 'shape-garden-sort:r$_roundIndex',
          headerPrompt:
              'Round ${_roundIndex + 1} of ${_kSortingSequence.length} — '
              'flat or solid?',
          onComplete: _onRoundComplete,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey:
              const ValueKey('shape-garden-sort-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AssetPaths.shapeGardenBackground,
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ProgressBarToReward(
                  progress: _progress,
                  celebrate: _phase == _Phase.celebrating,
                ),
              ),
              Expanded(child: phaseContent),
            ],
          ),
        ),
      ],
    );
  }
}
