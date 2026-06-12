// ShapeFindRound — the interactive beat that follows each ShapeIntroLayer
// in the K.G.2 sequence. The narrator says "Now tap all the triangles!" and
// the kid taps every target while ignoring distractor shapes (and the odd
// butterfly / frog / watering can — "alive but not a shape", the K.G.2
// invariance message in another form).
//
// Targets pop a glitter burst on correct tap; distractors play a gentle
// "That's a {kind} — try again, find the {targetPlural}" line so wrong
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
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'animated_shape.dart';
import 'glitter_burst.dart';
import 'shape_intro_layer.dart';

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
  // Sprites are ~50% larger than the intro layer's pose for find-rounds
  // so a kid taps comfortably with a fingertip and the shape outline
  // reads clearly at a glance.
  static const double _spriteSize = 144;
  static const double _spriteSizeDecor = 120;

  List<ShapeFindPlacement> _placements = const <ShapeFindPlacement>[];
  Set<String> _tappedIds = <String>{};
  Map<String, int> _burstCounters = <String, int>{};
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

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  /// Seed mixes (targetKind, roundIndex) so round 2 of a shape lays out
  /// differently from round 1 but each (kind, round) pair is reproducible.
  List<ShapeFindPlacement> _generatePlacements(int roundIndex) {
    return buildShapeFindPlacements(
      targetKind: widget.targetKind,
      distractorKindPool: widget.previousKinds,
      seed: widget.targetKind.hashCode ^ (roundIndex + 1) * 0x9E3779B1,
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
    _speak(text, 'find:${widget.targetKind}:r$_currentRound:prompt');
  }

  void _advanceToNextRound() {
    if (!mounted) return;
    setState(() {
      _currentRound += 1;
      _placements = _generatePlacements(_currentRound);
      _tappedIds = <String>{};
      _burstCounters = <String, int>{};
      _promptSpoken = false;
    });
  }

  void _handleTap(ShapeFindPlacement p) {
    if (_completed) return;
    if (_tappedIds.contains(p.id)) return;
    if (p.isTarget) {
      setState(() {
        _tappedIds.add(p.id);
        _burstCounters[p.id] = (_burstCounters[p.id] ?? 0) + 1;
      });
      final remaining = _placements
          .where((q) => q.isTarget && !_tappedIds.contains(q.id));
      if (remaining.isEmpty) {
        final isLastRound = _currentRound + 1 >= widget.roundsPerShape;
        if (isLastRound) {
          _speak(
            'Nicely done! You found all the $_targetPlural.',
            'find:${widget.targetKind}:done',
          );
          _completed = true;
          _roundTimer = Timer(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            widget.onComplete();
          });
        } else {
          _speak(
            'Nice work!',
            'find:${widget.targetKind}:r$_currentRound:done',
          );
          _roundTimer = Timer(
            const Duration(milliseconds: 1600),
            _advanceToNextRound,
          );
        }
      } else {
        _speak(
          "There's one!",
          'find:${widget.targetKind}:r$_currentRound:hit-${p.id}',
        );
      }
    } else {
      // Wrong tap — gentle redirect. Decor gets "that's a butterfly, not a
      // shape"; another shape kind gets "that's a {kind}".
      final wrongName = p.isDecor
          ? _decorName(p.assetPath)
          : (kShapeDisplayName[p.kind] ?? p.kind);
      _speak(
        "That's a $wrongName — try again. Find the $_targetPlural.",
        'find:${widget.targetKind}:r$_currentRound:miss-${p.id}',
      );
    }
  }

  String _decorName(String assetPath) {
    if (assetPath.contains('butterfly')) return 'butterfly';
    if (assetPath.contains('frog')) return 'frog';
    if (assetPath.contains('watering-can')) return 'watering can';
    return 'thing';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Header banner at the top so the kid can also *see* the
            // prompt — accessibility for the audio-supported flow.
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
                        'Tap all the $_targetPlural!',
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
                          'Round ${_currentRound + 1} of ${widget.roundsPerShape}',
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
            for (final p in _placements)
              Positioned(
                left: p.center.dx * w -
                    (p.isDecor ? _spriteSizeDecor : _spriteSize) / 2,
                top: p.center.dy * h -
                    (p.isDecor ? _spriteSizeDecor : _spriteSize) / 2 +
                    24,
                width: p.isDecor ? _spriteSizeDecor : _spriteSize,
                height: p.isDecor ? _spriteSizeDecor : _spriteSize,
                child: GestureDetector(
                  key: ValueKey(
                    'find-${widget.targetKind}-r$_currentRound-${p.id}',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _handleTap(p),
                  child: p.isDecor
                      ? Image.asset(
                          p.assetPath,
                          fit: BoxFit.contain,
                        )
                      : AnimatedShape(
                          spriteAsset: p.assetPath,
                          active: _tappedIds.contains(p.id),
                          pose: ShapePose(
                            rotationDegrees: p.rotationDegrees,
                          ),
                          size: _spriteSize,
                        ),
                ),
              ),
            for (final entry in _burstCounters.entries)
              if (entry.value > 0)
                Builder(
                  builder: (_) {
                    final placement = _placements.firstWhere(
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
                          'find-burst-r$_currentRound-${entry.key}-${entry.value}',
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
