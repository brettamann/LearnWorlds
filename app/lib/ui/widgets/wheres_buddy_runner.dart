// WheresBuddyRunner — K.G.1 "position words" practice. Two playable
// sub-modes share the same Sanctuary clearing scene:
//
//   • find-mode  — Buddy hides at a position relative to a landmark
//                  ("behind the hollow tree"). The kid taps where they
//                  think Buddy is. Tolerant of nearby misses.
//   • place-mode — Narration says "Put Buddy above the unicorn
//                  fountain." The kid drags the Buddy into position.
//                  A correctness disc around the target tells them how
//                  close they got.
//
// Both modes resolve through `RoundCoordinator` with conceptId K.G.1
// so the mastery streak + coin payout match the rest of the Sanctuary
// activities. `onSequenceComplete` fires after the final keeper line.
//
// Six rounds per sub-mode — one per position word — rotated against
// different landmarks so every word lands on at least one familiar
// scene anchor. The challenge sub-mode (`relational-mode`) wraps two
// landmarks per round and isn't wired here yet; the dispatcher falls
// back to `place-mode` when it's selected.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/wheres_buddy_landmarks.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'buddy_widget.dart';
import 'continue_arrow_shelf.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';
import 'replay_demo_button.dart';

/// Sub-mode ids the activity-screen passes via `launchExtra['subMode']`.
const String kWheresBuddySubModeFindMode = 'find-mode';
const String kWheresBuddySubModePlaceMode = 'place-mode';
const String kWheresBuddySubModeRelationalMode = 'relational-mode';

enum _Phase { intro, playing, celebrating, interstitial }

/// One round: one landmark + one position word. Six rounds rotate the
/// six K.G.1 prepositions across the clearing.
class _Round {
  const _Round({
    required this.landmarkId,
    required this.positionId,
    required this.keeperLine,
  });

  final String landmarkId;
  final String positionId;
  final String keeperLine;
}

const List<_Round> _kRounds = <_Round>[
  _Round(
    landmarkId: 'fountain',
    positionId: 'above',
    keeperLine: 'Above! Right where I asked.',
  ),
  _Round(
    landmarkId: 'mushroom',
    positionId: 'below',
    keeperLine: 'Below the mushroom — perfect.',
  ),
  _Round(
    landmarkId: 'hollow-tree',
    positionId: 'next-to',
    keeperLine: 'Right next to the tree!',
  ),
  _Round(
    landmarkId: 'cottage',
    positionId: 'behind',
    keeperLine: 'Behind the cottage. Sneaky!',
  ),
  _Round(
    landmarkId: 'rock-cluster',
    positionId: 'in-front-of',
    keeperLine: 'In front of the rocks. Nice spot.',
  ),
  _Round(
    landmarkId: 'pond',
    positionId: 'beside',
    keeperLine: 'Beside the pond — you got it.',
  ),
];

class WheresBuddyRunner extends StatelessWidget {
  const WheresBuddyRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = kWheresBuddySubModePlaceMode,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  Widget build(BuildContext context) {
    final isFind = subMode == kWheresBuddySubModeFindMode;
    return _WheresBuddyBody(
      key: ValueKey('wheres-buddy-$subMode'),
      onSequenceComplete: onSequenceComplete,
      skipIntro: skipIntro,
      mode: isFind ? _Mode.find : _Mode.place,
    );
  }
}

enum _Mode { find, place }

class _WheresBuddyBody extends ConsumerStatefulWidget {
  const _WheresBuddyBody({
    super.key,
    required this.onSequenceComplete,
    required this.skipIntro,
    required this.mode,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final _Mode mode;

  @override
  ConsumerState<_WheresBuddyBody> createState() => _WheresBuddyBodyState();
}

class _WheresBuddyBodyState extends ConsumerState<_WheresBuddyBody> {
  late _Phase _phase = widget.skipIntro ? _Phase.playing : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;

  /// Place-mode: Buddy's current drag position in normalized coords.
  /// Starts off-target so the kid sees where they're moving it to.
  Offset _buddyPos = const Offset(0.5, 0.92);
  bool _placedThisRound = false;

  Timer? _celebrationTimer;

  _Round get _currentRound => _kRounds[_roundIndex];
  WheresBuddyLandmark get _currentLandmark =>
      wheresBuddyLandmark(_currentRound.landmarkId);
  WheresBuddyPosition get _currentPosition =>
      wheresBuddyPosition(_currentRound.positionId);

  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  double get _progress => _completedRounds / _kRounds.length;

  /// Target the kid is aiming for, in normalized coords (relative to
  /// landmark centre + position vector).
  Offset get _targetPos {
    final lm = _currentLandmark.position;
    final v = _currentPosition.vector;
    return Offset(
      (lm.dx + v.dx).clamp(0.05, 0.95),
      (lm.dy + v.dy).clamp(0.10, 0.92),
    );
  }

  String get _introDialog {
    if (widget.mode == _Mode.place) {
      return "I'll tell you where the Buddy should go. Drag the Buddy "
          'next to, above, or behind the things in the meadow.';
    }
    return "The Buddy loves to play hide-and-seek. I'll tell you where "
        'they are hiding — tap the right spot!';
  }

  String get _prompt {
    final pos = _currentPosition.preposition;
    final lm = _currentLandmark.displayName;
    return widget.mode == _Mode.place
        ? 'Put Buddy $pos $lm.'
        : 'Find Buddy — they are $pos $lm.';
  }

  String get _finalKeeperLine =>
      'Every position found! You really know your above, below, and '
      'beside.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.playing) _speakPrompt();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  void _speakPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _prompt,
            cueId: 'wheres-buddy:${widget.mode.name}:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.playing);
    _speakPrompt();
  }

  /// Distance threshold for "close enough" — 14 % of the shorter side.
  /// Generous so the kid doesn't lose for a small motor miss.
  static const double _kHitToleranceFraction = 0.14;

  bool _isCloseEnough(Offset normalized) {
    final t = _targetPos;
    final dx = normalized.dx - t.dx;
    final dy = normalized.dy - t.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    return dist <= _kHitToleranceFraction;
  }

  void _onFindTap(Offset normalized) {
    if (_phase != _Phase.playing) return;
    if (!_isCloseEnough(normalized)) {
      // Gentle nudge — narrate the position again, don't penalize.
      _speakPrompt();
      return;
    }
    _resolveRoundSuccess();
  }

  void _onPlaceDragUpdate(Offset normalized) {
    setState(() => _buddyPos = normalized);
  }

  void _onPlaceDragEnd() {
    if (_phase != _Phase.playing) return;
    if (_isCloseEnough(_buddyPos)) {
      _resolveRoundSuccess();
    } else {
      // Snap Buddy back onto the centre line so the kid can try again
      // and re-hear the prompt.
      setState(() => _buddyPos = const Offset(0.5, 0.92));
      _speakPrompt();
    }
  }

  void _resolveRoundSuccess() {
    if (_placedThisRound) return;
    _placedThisRound = true;
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'wheres-buddy',
          conceptId: 'K.G.1',
          success: true,
        );
    setState(() {
      _completedRounds += 1;
      // Snap the Buddy to the target for the celebration beat in
      // place-mode; in find-mode we reveal it at the target instead.
      _buddyPos = _targetPos;
      _phase = _Phase.celebrating;
    });
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.interstitial);
      final line =
          _isLastRound ? _finalKeeperLine : _currentRound.keeperLine;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: line,
              cueId:
                  'wheres-buddy:${widget.mode.name}:r$_roundIndex:interstitial',
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
      _placedThisRound = false;
      _buddyPos = const Offset(0.5, 0.92);
      _phase = _Phase.playing;
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's play!",
          startButtonKey: const ValueKey('wheres-buddy-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.playing ||
      _Phase.celebrating =>
        _PlayLayer(
          mode: widget.mode,
          buddyPos: _buddyPos,
          targetPos: _targetPos,
          revealBuddy: _phase == _Phase.celebrating ||
              widget.mode == _Mode.place,
          inputLocked: _phase == _Phase.celebrating,
          onFindTap: _onFindTap,
          onPlaceDragUpdate: _onPlaceDragUpdate,
          onPlaceDragEnd: _onPlaceDragEnd,
          replayPrompt: _prompt,
          replayCueId:
              'wheres-buddy:${widget.mode.name}:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _isLastRound ? _finalKeeperLine : _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : "Let's go!",
          startButtonKey: const ValueKey('wheres-buddy-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.wheresBuddyBackground, fit: BoxFit.cover),
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

class _PlayLayer extends StatelessWidget {
  const _PlayLayer({
    required this.mode,
    required this.buddyPos,
    required this.targetPos,
    required this.revealBuddy,
    required this.inputLocked,
    required this.onFindTap,
    required this.onPlaceDragUpdate,
    required this.onPlaceDragEnd,
    required this.replayPrompt,
    required this.replayCueId,
  });

  final _Mode mode;
  final Offset buddyPos;
  final Offset targetPos;
  final bool revealBuddy;
  final bool inputLocked;
  final ValueChanged<Offset> onFindTap;
  final ValueChanged<Offset> onPlaceDragUpdate;
  final VoidCallback onPlaceDragEnd;
  final String replayPrompt;
  final String replayCueId;

  static const double _kBuddySizeFraction = 0.16;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            kReplayDemoShelf(
              child: ReplayDemoButton(
                label: replayPrompt,
                cueId: replayCueId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final shortest = math.min(w, h);
                  final buddySize = shortest * _kBuddySizeFraction;
                  final target = Offset(targetPos.dx * w, targetPos.dy * h);
                  final buddy = Offset(buddyPos.dx * w, buddyPos.dy * h);
                  return Stack(
                    children: [
                      // Landmark labels — drawn as soft chips so a
                      // pre-reader still recognises "the cottage" by
                      // the placeholder shape underneath while a reader
                      // can confirm the word.
                      for (final lm in kWheresBuddyLandmarks)
                        Positioned(
                          left: lm.position.dx * w - 56,
                          top: lm.position.dy * h - 20,
                          width: 112,
                          height: 40,
                          child: IgnorePointer(
                            child: _LandmarkChip(
                              label: lm.displayName,
                              highlighted:
                                  lm.id == _findCurrentLandmarkId(context),
                            ),
                          ),
                        ),
                      // Target halo — only shown in place-mode so the
                      // kid has something to aim for while dragging.
                      if (mode == _Mode.place)
                        Positioned(
                          left: target.dx - buddySize * 0.6,
                          top: target.dy - buddySize * 0.6,
                          width: buddySize * 1.2,
                          height: buddySize * 1.2,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Colors.amber.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: Colors.amber.shade400
                                      .withValues(alpha: 0.85),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Find-mode taps — full-bleed gesture detector.
                      if (mode == _Mode.find)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: inputLocked
                                ? null
                                : (details) {
                                    final local = details.localPosition;
                                    onFindTap(
                                      Offset(local.dx / w, local.dy / h),
                                    );
                                  },
                          ),
                        ),
                      // Buddy — draggable in place-mode, visible at the
                      // revealed position in find-mode after a correct
                      // tap, hidden otherwise so the kid hunts.
                      if (mode == _Mode.place || revealBuddy)
                        Positioned(
                          left: buddy.dx - buddySize / 2,
                          top: buddy.dy - buddySize / 2,
                          width: buddySize,
                          height: buddySize,
                          child: _DraggableBuddy(
                            size: buddySize,
                            enabled: mode == _Mode.place && !inputLocked,
                            onDragUpdate: (global) {
                              onPlaceDragUpdate(
                                Offset(global.dx / w, global.dy / h),
                              );
                            },
                            onDragEnd: onPlaceDragEnd,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: revealBuddy && inputLocked
                  ? const NextArrowButton(
                      key: ValueKey('wheres-buddy-done-arrow'),
                      idleHintEnabled: true,
                      onPressed: _noop,
                      label: 'Nice!',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Find the landmark id we should highlight this round. The
  /// `_PlayLayer` doesn't know it directly so we read it off the closest
  /// ancestor state via an InheritedWidget would be cleaner — for now
  /// we just compare landmark positions to the round's target landmark
  /// at the surrounding `_WheresBuddyBodyState` level.
  String? _findCurrentLandmarkId(BuildContext context) {
    // The target position is `landmark + position`; the nearest landmark
    // to the target is the one the kid should focus on.
    String? nearest;
    var bestDist = double.infinity;
    for (final lm in kWheresBuddyLandmarks) {
      final dx = lm.position.dx - targetPos.dx;
      final dy = lm.position.dy - targetPos.dy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d < bestDist) {
        bestDist = d;
        nearest = lm.id;
      }
    }
    return nearest;
  }
}

void _noop() {}

class _DraggableBuddy extends StatelessWidget {
  const _DraggableBuddy({
    required this.size,
    required this.enabled,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double size;
  final bool enabled;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return BuddyWidget(size: size);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Use pan to track the Buddy's position smoothly under the
      // finger. We hand global coords up so the parent can normalize.
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        // Buddy's centre = local origin + delta from gesture.
        final globalCentre = details.globalPosition;
        final parentBox =
            context.findAncestorRenderObjectOfType<RenderBox>();
        if (parentBox == null) return;
        final local = parentBox.globalToLocal(globalCentre);
        onDragUpdate(local);
      },
      onPanEnd: (_) => onDragEnd(),
      child: BuddyWidget(size: size),
    );
  }
}

class _LandmarkChip extends StatelessWidget {
  const _LandmarkChip({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (highlighted ? Colors.amber.shade100 : Colors.white)
            .withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: highlighted
            ? Border.all(color: Colors.amber.shade400, width: 2)
            : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}
