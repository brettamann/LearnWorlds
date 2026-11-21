// WheresBuddyRunner — K.G.1 "position words" practice. Three sub-modes share
// the same Sanctuary clearing scene:
//
//   • find-mode  — Buddy hides at a position relative to a landmark
//                  ("behind the hollow tree"). The kid taps where they
//                  think Buddy is. Tolerant of nearby misses.
//   • place-mode — Narration says "Put Buddy above the star fountain." The
//                  kid drags the Buddy into position. A correctness disc
//                  around the target tells them how close they got.
//   • relational-mode — the challenge. "Put Buddy between the hollow tree and
//                  the toadstools." The same drag, but the target is the
//                  midpoint of two landmarks rather than an offset from one:
//                  K.G.1 extended to two references, which is what the
//                  activity spec asks the challenge to be. It gets the
//                  higher-energy bed, like the other two challenges.
//
// The lifecycle is SanctuaryRoundShell's; this file is the clearing. The
// rounds and every line live in `wheres_buddy_words.dart`.
//
// It is the one activity that resolves a round for a child who does nothing:
// its spec demonstrates the answer after three misses - and the hint ladder's
// top rung does the same for a child who sits still - and then moves on.
// `play_it_through_test.dart` exempts it by name.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../data/wheres_buddy_landmarks.dart';
import '../../data/wheres_buddy_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../ui/characters/buddy_widget.dart';
import '../../ui/common/answer_feedback.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/common/touch_here_halo.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import '../sub_mode_ids.dart';
import 'wheres_buddy_landmark_sprite.dart';

/// Wrong attempts before the narrator stops repeating the cue and just shows
/// her. Three, straight from specs/activities/kindergarten/wheres-buddy.md -
/// and also the failure threshold, so the two agree by construction.
const int _kDemonstrateAfter = 3;

class WheresBuddyRunner extends StatelessWidget {
  const WheresBuddyRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = WheresBuddyModes.placeMode,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  Widget build(BuildContext context) {
    final mode = wheresBuddyMode(subMode);
    final rounds = wheresBuddyRoundsFor(mode);
    return SanctuaryRoundShell(
      key: ValueKey('wheres-buddy-$mode'),
      activityId: ActivityIds.wheresBuddy,
      roundCount: rounds.length,
      conceptIdFor: (_) => 'K.G.1',
      introLine: wheresBuddyIntro(mode),
      keeperLineFor: (i) => rounds[i].keeperLine,
      finalLine: wheresBuddyFinal(mode),
      skipIntro: skipIntro,
      onSequenceComplete: onSequenceComplete,
      // The higher-energy bed for the challenge, the same as Tens Parade and
      // the Two-Attribute Hunt: opting into the hard one should sound like it.
      musicBed: mode == WheresBuddyModes.relationalMode
          ? kChallengeMusicBed
          : kDefaultMusicBed,
      // Buddy is the puzzle here, out on the clearing; a second one in the
      // corner would be one too many.
      showBuddy: false,
      celebrationHold: const Duration(seconds: 1),
      background: Image.asset(
        AssetPaths.wheresBuddyBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) =>
          WheresBuddyRoundBody(round: rounds[c.index], mode: mode, c: c),
    );
  }
}

/// One round on the clearing: find Buddy, or put him somewhere.
class WheresBuddyRoundBody extends ConsumerStatefulWidget {
  const WheresBuddyRoundBody({
    super.key,
    required this.round,
    required this.mode,
    required this.c,
  });

  final WheresBuddyRound round;

  /// A [WheresBuddyModes] id, already normalised by [wheresBuddyMode].
  final String mode;
  final RoundContext c;

  @override
  ConsumerState<WheresBuddyRoundBody> createState() =>
      _WheresBuddyRoundBodyState();
}

class _WheresBuddyRoundBodyState extends ConsumerState<WheresBuddyRoundBody>
    with TimerScope<WheresBuddyRoundBody> {
  /// Buddy's position in normalized coords. Starts off-target so the kid sees
  /// where they're moving it to.
  Offset _buddyPos = kClearingBuddyHome;
  bool _done = false;

  /// Wrong taps or drops this round. specs/activities/kindergarten/wheres-buddy.md
  /// specifies the behaviour exactly: soft "no", narrator repeats the cue,
  /// and after three the narrator demonstrates by glowing the correct zone.
  int _wrongAttempts = 0;
  int _missRotation = 0;
  int _wrongToken = 0;

  /// True once the demonstration has fired, which glows the target zone.
  bool _demonstrating = false;

  /// The hint ladder is ringing the Buddy: "you can pick him up".
  bool _ringBuddy = false;

  HintLadder? _hints;

  WheresBuddyRound get _r => widget.round;
  bool get _isFind => widget.mode == WheresBuddyModes.findMode;
  bool get _open => !_done && !widget.c.locked;

  String get _prompt => wheresBuddyRoundPrompt(
        _r,
        placing: widget.mode == WheresBuddyModes.placeMode,
      );

  /// The landmarks this round is about — one, or two on the challenge.
  Set<String> get _highlightLandmarkIds => <String>{
        _r.landmarkId,
        if (_r.secondLandmarkId != null) _r.secondLandmarkId!,
      };

  /// Target the kid is aiming for, in normalized coords.
  ///
  /// Ordinarily the landmark centre plus the position word's vector. On a
  /// relational round it is the midpoint of the two named landmarks, which is
  /// what "between" means and the only definition a five-year-old can act on
  /// by dragging.
  Offset get _targetPos {
    if (_r.isRelational) {
      final a = wheresBuddyLandmark(_r.landmarkId).position;
      final b = wheresBuddyLandmark(_r.secondLandmarkId!).position;
      return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    return clearingSpotFor(
      landmarkId: wheresBuddyLandmark(_r.landmarkId).id,
      positionId: wheresBuddyPosition(_r.positionId ?? 'above').id,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(_prompt);
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  /// Distance threshold for "close enough" — 14 % of the shorter side.
  /// Generous so the kid doesn't lose for a small motor miss.
  static const double _kHitToleranceFraction = 0.14;

  bool _isCloseEnough(Offset normalized) {
    final t = _targetPos;
    final dx = normalized.dx - t.dx;
    final dy = normalized.dy - t.dy;
    return math.sqrt(dx * dx + dy * dy) <= _kHitToleranceFraction;
  }

  void _onFindTap(Offset normalized) {
    if (!_open) return;
    if (!_isCloseEnough(normalized)) {
      _onWrongAttempt();
      return;
    }
    _resolve();
  }

  void _onDragUpdate(Offset normalized) {
    // Dragging is "she is doing something", so the ladder goes back to the
    // bottom - a child moving the Buddy around while she thinks is not stuck,
    // and being demonstrated at mid-drag would take the answer off her.
    _hints?.poke();
    setState(() {
      _buddyPos = normalized;
      _ringBuddy = false;
    });
  }

  void _onDragEnd() {
    if (!_open) return;
    if (_isCloseEnough(_buddyPos)) {
      // Buddy landing, before the round resolves: the sound of a thing being
      // put down is the half of a drag the player is waiting for.
      ref.read(feedbackEngineProvider).drop();
      _resolve();
    } else {
      // Snap Buddy back onto the centre line so the kid can try again.
      setState(() => _buddyPos = kClearingBuddyHome);
      _onWrongAttempt();
    }
  }

  /// Escalating help for a child who has not moved.
  ///
  /// Its own handler rather than `answerTargetHint`: the first rung rings the
  /// Buddy rather than the answer, because in the two drag modes the first
  /// thing that can go wrong is not knowing he can be picked up at all - a
  /// mechanical problem, not a positional one, and worth ruling out before
  /// giving anything away. The top rung is the spec's demonstration.
  void _onHint(HintLevel level) {
    if (!mounted || !_open || _demonstrating) return;
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _ringBuddy = true);
      case HintLevel.point:
        setState(() => _ringBuddy = true);
        ref.read(feedbackEngineProvider).hint();
        // The round's own sentence again, not a generic nudge: the whole task
        // is one preposition, and repeating it is the hint.
        widget.c.say(_prompt);
      case HintLevel.demonstrate:
        _demonstrate();
    }
  }

  /// A miss, in either mode: soft "no", the cue again, and after three the
  /// demonstration.
  void _onWrongAttempt() {
    _hints?.poke();
    setState(() {
      _wrongAttempts += 1;
      _wrongToken += 1;
    });
    ref.read(feedbackEngineProvider).wrong();

    if (_wrongAttempts >= _kDemonstrateAfter && !_demonstrating) {
      _demonstrate();
      return;
    }
    // Repeat the cue, with a warm line in front of it on alternate misses.
    // Hearing the exact same sentence a third time is how a helpful line
    // becomes noise. Two lines, queued, rather than one glued sentence: each
    // is a recorded clip, where the glued one never could be.
    if (_missRotation.isEven) {
      widget.c.say(_prompt);
    } else {
      widget.c.say(warmMissLine(_missRotation), replay: false);
      widget.c.say(_prompt, queue: true);
    }
    _missRotation += 1;
  }

  /// Show her the answer rather than leaving her stuck. Glows the target zone
  /// and walks the Buddy there; the round then resolves on its own, graded by
  /// how it got here.
  void _demonstrate() {
    _hints?.pause();
    setState(() {
      _demonstrating = true;
      _ringBuddy = false;
      _buddyPos = _targetPos;
    });
    ref.read(feedbackEngineProvider).hint();
    widget.c.say(wheresBuddyRoundRestate(_r), replay: false);
    afterMs(2200, _resolve);
  }

  void _resolve() {
    if (!_open) return;
    _hints?.pause();
    setState(() {
      _done = true;
      // Buddy at the target for the celebration beat: snapped there in the
      // drag modes, revealed there in find-mode.
      _buddyPos = _targetPos;
    });
    // Three misses is a genuine miss of the concept. A demonstration she got
    // by waiting rather than by guessing is not a failure, but it is not
    // clean either: the game put the Buddy where it goes.
    widget.c.finish(
      gradeRound(
        misses: _wrongAttempts,
        helped: (_hints?.hintsUsed ?? 0) > 0,
        failAt: _kDemonstrateAfter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _open;
    // find-mode is the odd one out — she taps a spot and Buddy is hidden until
    // she is right. Written as "not find" rather than "place or relational" so
    // that a fourth mode has to opt out of dragging on purpose.
    final isDrag = !_isFind;
    final revealBuddy = !open || isDrag || _demonstrating;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Everything is placed inside the clearing, which stops above the
        // caption band.
        final clearing = ClearingGeometry(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final w = clearing.width;
        final h = clearing.height;
        final shortest = clearing.shortest;
        final buddySize = clearing.buddySize;
        final target = clearing.place(_targetPos);
        final buddy = clearing.place(_buddyPos);
        // The whole clearing takes the miss reaction, because in this
        // activity the wrong answer is a *place*, not an object.
        return AnswerFeedback(
          wrongToken: _wrongToken,
          shakeExtent: 6,
          child: Stack(
            children: [
              for (final lm in kWheresBuddyLandmarks)
                Positioned(
                  left: lm.position.dx * w - shortest * lm.sizeFraction / 2,
                  top: lm.position.dy * h - shortest * lm.sizeFraction / 2,
                  width: shortest * lm.sizeFraction,
                  child: IgnorePointer(
                    child: _Landmark(
                      landmark: lm,
                      size: shortest * lm.sizeFraction,
                      highlighted: _highlightLandmarkIds.contains(lm.id),
                    ),
                  ),
                ),
              // Target halo — in place-mode so the kid has something to aim
              // for while dragging, and in any mode once the demonstration
              // fires, which is the "glowing the correct zone" the spec asks
              // for after three misses.
              //
              // Deliberately NOT in relational-mode. There the halo would sit
              // exactly on the answer, and dragging onto a circle is not
              // reasoning about between-ness.
              if (widget.mode == WheresBuddyModes.placeMode || _demonstrating)
                Positioned(
                  left: target.dx - buddySize * 0.6,
                  top: target.dy - buddySize * 0.6,
                  width: buddySize * 1.2,
                  height: buddySize * 1.2,
                  child: IgnorePointer(
                    child: _TargetHalo(glow: _demonstrating),
                  ),
                ),
              if (_isFind)
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('wheres-clearing'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: open
                        ? (details) {
                            final local = details.localPosition;
                            _onFindTap(Offset(local.dx / w, local.dy / h));
                          }
                        : null,
                  ),
                ),
              // Buddy — draggable in both drag modes, visible at the revealed
              // position in find-mode after a correct tap, hidden otherwise so
              // the kid hunts.
              if (revealBuddy)
                Positioned(
                  left: buddy.dx - buddySize / 2,
                  top: buddy.dy - buddySize / 2,
                  width: buddySize,
                  height: buddySize,
                  child: _DraggableBuddy(
                    key: const ValueKey('wheres-buddy-sprite'),
                    size: buddySize,
                    enabled: isDrag && open,
                    onDragUpdate: (local) =>
                        _onDragUpdate(Offset(local.dx / w, local.dy / h)),
                    onDragEnd: _onDragEnd,
                  ),
                ),
              // The ring goes on last so it is not painted over by the sprite
              // it is pointing at.
              if (_ringBuddy && isDrag)
                TouchHereHalo(
                  rect: Rect.fromCenter(
                    center: buddy,
                    width: buddySize,
                    height: buddySize,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TargetHalo extends StatelessWidget {
  const _TargetHalo({required this.glow});

  /// Demonstration is running: ring the target zone so she can see where the
  /// answer was, not just be told again.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.amber.withValues(alpha: glow ? 0.32 : 0.18),
        border: Border.all(
          color: Colors.amber.shade400.withValues(alpha: 0.85),
          width: 3,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.7),
                  blurRadius: 28,
                  spreadRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

class _DraggableBuddy extends StatelessWidget {
  const _DraggableBuddy({
    super.key,
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
      // Pan tracks the Buddy smoothly under the finger; the position is
      // handed up in the clearing's own coordinates.
      onPanUpdate: (details) {
        final parentBox = context.findAncestorRenderObjectOfType<RenderBox>();
        if (parentBox == null) return;
        onDragUpdate(parentBox.globalToLocal(details.globalPosition));
      },
      onPanEnd: (_) => onDragEnd(),
      child: BuddyWidget(size: size),
    );
  }
}

class _Landmark extends StatelessWidget {
  const _Landmark({
    required this.landmark,
    required this.size,
    required this.highlighted,
  });

  final WheresBuddyLandmark landmark;
  final double size;

  /// True for the place (or places) the prompt just named.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // A pool of warm light on the ground, not an outline: an amber
              // ring means "the answer is here" on the target halo, and two
              // rings meaning different things is worse than one meaning
              // nothing. Soft and negative-spread so it does not read as a
              // filled disc like the halo.
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 34,
                        spreadRadius: -8,
                      ),
                    ]
                  : null,
            ),
            child: Image.asset(landmark.spriteAsset, fit: BoxFit.contain),
          ),
        ),
        // Named only while it is the place under discussion: that is what ties
        // a spoken "the hollow tree" to the tree, and six permanent captions
        // would be six pieces of text a pre-reader cannot use.
        if (highlighted) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade100.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade400, width: 2),
            ),
            child: Text(
              landmark.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
