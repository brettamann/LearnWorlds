// ShapeFindRound — the interactive beat that follows each ShapeIntroLayer
// in the K.G.2 sequence. The narrator says "Now tap all the triangles!" and
// the kid taps every target while ignoring distractor shapes (and the odd
// butterfly / frog / watering can — "alive but not a shape", the K.G.2
// invariance message in another form).
//
// Targets pop a glitter burst on correct tap; distractors play a gentle
// "try again, find the {targetPlural}" line so wrong
// taps are framed as more practice, never as punishment. When every target
// is tapped, the runner waits a short celebratory beat then fires
// `onComplete` so the LessonScreen can advance to the next shape's intro.
//
// Layout is a fixed-seed scatter so the placement is deterministic across
// reruns (good for tests, predictable for the kid on a re-watch). The
// random seed is derived from the targetKind so each shape's round has
// its own scatter but is stable per-shape.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shape_find_placements.dart';
import '../../data/shape_garden_rounds.dart';
import '../../data/shape_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_player.dart';
import '../shapes/shape_scatter_board.dart';

/// Re-export of the variant table for callers that previously imported it
/// from this file. The canonical home is `shape_find_placements.dart`.
const Map<String, List<String>> kFindRoundVariantsByKind = kShapeFindVariants;

class ShapeFindRound extends ConsumerStatefulWidget {
  const ShapeFindRound({
    super.key,
    required this.targetKind,
    required this.previousKinds,
    required this.onComplete,
    this.roundsPerShape = 3,
  });

  /// The shape the kid is hunting for this round.
  final String targetKind;

  /// Kinds the kid has already met (in sequence order). The round picks
  /// distractor sprites from this list so the kid only sees shapes they
  /// can name. Empty on the very first round (circle) — the round falls
  /// back to decor-only distractors.
  final List<String> previousKinds;

  /// Fired after the *last* round's targets are all tapped + a short
  /// celebratory beat. Earlier rounds re-scatter internally without
  /// notifying the parent.
  final VoidCallback onComplete;

  /// How many distinct "find them all" mini-rounds to play before
  /// advancing. Each round uses a fresh scatter seed so the kid sees a
  /// different layout. Defaults to 3 — enough practice to feel earned,
  /// short enough to not drag.
  final int roundsPerShape;

  @override
  ConsumerState<ShapeFindRound> createState() => _ShapeFindRoundState();
}

class _ShapeFindRoundState extends ConsumerState<ShapeFindRound> {
  static const int _targetCount = 3;
  static const int _distractorCount = 4;

  List<ShapeFindPlacement> _placements = const <ShapeFindPlacement>[];
  Set<String> _tappedIds = <String>{};
  Map<String, int> _burstCounters = <String, int>{};

  /// Placement id -> wrong taps on it, driving the shake. The wrong branch
  /// here used to be narration and nothing else — no sound, no movement.
  Map<String, int> _wrongTokens = <String, int>{};
  int _missRotation = 0;
  bool _promptSpoken = false;
  bool _completed = false;
  int _currentRound = 0;
  Timer? _roundTimer;

  String get _targetDisplay =>
      kShapeDisplayName[widget.targetKind] ?? widget.targetKind;
  String get _targetPlural =>
      kShapeDisplayPlural[widget.targetKind] ?? '${_targetDisplay}s';

  @override
  void initState() {
    super.initState();
    _placements = _generatePlacements(_currentRound);
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    super.dispose();
  }

  /// Seed mixes (targetKind, roundIndex) so round 2 of a shape lays out
  /// differently from round 1 but each (kind, round) pair is reproducible.
  List<ShapeFindPlacement> _generatePlacements(int roundIndex) {
    return buildShapeFindPlacements(
      targetKind: widget.targetKind,
      distractorKindPool: widget.previousKinds,
      seed: shapeFindSeed(widget.targetKind, roundIndex),
      targetCount: _targetCount,
      distractorCount: _distractorCount,
    );
  }

  void _maybeSpeakPrompt() {
    if (_promptSpoken) return;
    _promptSpoken = true;
    final String text;
    switch (_currentRound) {
      case 0:
        text = 'Now you try! Tap all the $_targetPlural.';
      case 1:
        text = 'Another round — tap all the $_targetPlural!';
      default:
        text = 'One more time! Find every $_targetDisplay.';
    }
    ref.narration.say(
      text,
      cueId: 'find:${widget.targetKind}:r$_currentRound:prompt',
    );
  }

  void _advanceToNextRound() {
    if (!mounted) return;
    setState(() {
      _currentRound += 1;
      _placements = _generatePlacements(_currentRound);
      _tappedIds = <String>{};
      _burstCounters = <String, int>{};
      _wrongTokens = <String, int>{};
      _missRotation = 0;
      _promptSpoken = false;
    });
    ref.read(feedbackEngineProvider).resetRound();
  }

  void _handleTap(ShapeFindPlacement p) {
    if (_completed) return;
    if (_tappedIds.contains(p.id)) return;
    if (p.isTarget) {
      setState(() {
        _tappedIds.add(p.id);
        _burstCounters[p.id] = (_burstCounters[p.id] ?? 0) + 1;
      });
      ref.read(feedbackEngineProvider).countStep(_tappedIds.length);
      final remaining = _placements.where(
        (q) => q.isTarget && !_tappedIds.contains(q.id),
      );
      if (remaining.isEmpty) {
        final isLastRound = _currentRound + 1 >= widget.roundsPerShape;
        if (isLastRound) {
          ref.read(feedbackEngineProvider).celebrate();
          ref.narration.say(
            'Nicely done! You found all the $_targetPlural.',
            cueId: 'find:${widget.targetKind}:done',
          );
          _completed = true;
          _roundTimer = Timer(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            widget.onComplete();
          });
        } else {
          ref.read(feedbackEngineProvider).roundPass(payout: false);
          ref.narration.say(
            'Nice work!',
            cueId: 'find:${widget.targetKind}:r$_currentRound:done',
          );
          _roundTimer = Timer(
            const Duration(milliseconds: 1600),
            _advanceToNextRound,
          );
        }
      } else {
        ref.narration.say(
          kShapeFoundLine,
          cueId: 'find:${widget.targetKind}:r$_currentRound:hit-${p.id}',
        );
      }
    } else {
      // Wrong tap: a gentle redirect. It used to open by naming what she
      // tapped ("That's a frog."), which made hundreds of sentences no voice
      // could record; Shape Garden dropped that long ago and this copy never
      // caught up. The shape she tapped is under her finger.
      setState(() {
        _wrongTokens = <String, int>{
          ..._wrongTokens,
          p.id: (_wrongTokens[p.id] ?? 0) + 1,
        };
      });
      ref.read(feedbackEngineProvider).wrong();
      _missRotation += 1;
      ref.narration.say(
        '${warmMissLine(_missRotation)} Find the $_targetPlural.',
        cueId:
            'find:${widget.targetKind}:r$_currentRound:miss-${p.id}-$_missRotation',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defer the prompt narration to the first frame so the parent's
    // setState that mounted us has fully settled before we touch the
    // narration player.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeSpeakPrompt();
    });

    return ShapeScatterBoard(
      keyPrefix: 'find-${widget.targetKind}-r$_currentRound',
      targetPlural: _targetPlural,
      roundLabel: 'Round ${_currentRound + 1} of ${widget.roundsPerShape}',
      placements: _placements,
      tappedIds: _tappedIds,
      burstCounters: _burstCounters,
      wrongTokens: _wrongTokens,
      onTap: _handleTap,
    );
  }
}
