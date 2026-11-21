// CountingChallengeLayer — the opt-in "count to 20" mini-game that opens
// after the Counting Parade's main practice. Creatures from the parade
// sprite pool drift across the screen from right to left, wiggle gently
// (squash/stretch on a low amplitude), and double their speed when tapped.
// Tapped creatures contribute to the kid's running count; the layer stops
// spawning + reports completion as soon as `target` taps are reached.
//
// Wiggle amplitudes are tuned to feel alive without making the tap target
// hard to hit (a 7-year-old's pointer accuracy is what limits how much we
// can move things). Each creature also fades to ~70% opacity once tapped
// so kids can see what they already counted.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tens_parade_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../ui/common/target_hint.dart';
import '../../ui/common/touch_here_halo.dart';
import 'parade_pieces.dart';

class CountingChallengeLayer extends ConsumerStatefulWidget {
  const CountingChallengeLayer({
    super.key,
    required this.target,
    required this.spriteAssets,
    required this.say,
    required this.onCountChanged,
    required this.onTargetReached,
  });

  /// How many taps win the challenge (typically 20).
  final int target;

  /// Sprites to randomly pull from when spawning a new creature.
  final List<String> spriteAssets;

  /// How the layer speaks - a round body's `c.say`, so the opening call is
  /// what the "?" button replays.
  final SayLine say;

  /// Fires each time a creature is successfully tapped.
  final ValueChanged<int> onCountChanged;

  /// Fires once when `target` taps have been registered.
  final VoidCallback onTargetReached;

  @override
  ConsumerState<CountingChallengeLayer> createState() =>
      _CountingChallengeLayerState();
}

class _CountingChallengeLayerState extends ConsumerState<CountingChallengeLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_FlyingCreature> _creatures = [];
  int _count = 0;
  Duration? _lastTick;
  Duration _nextSpawnAt = Duration.zero;
  final math.Random _rng = math.Random();
  Size? _stageSize;
  int _idCounter = 0;
  bool _stopped = false;
  HintLadder? _hints;

  /// The creature the hint ladder is ringing, by id.
  int? _ringed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.say(countingChallengePrompt(widget.target));
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hints?.dispose();
    super.dispose();
  }

  /// Idle help, the same three rungs as everywhere: ring a creature, then
  /// ring it and point it out, then count it for her. It used to have none,
  /// so a child who froze in front of a hundred moving things got nothing.
  void _onHint(HintLevel level) {
    if (!mounted || _stopped) return;
    final width = _stageSize?.width ?? 0;
    // The untapped creature most fully on screen, so the ring has time to be
    // seen before it flies off.
    final candidates =
        _creatures
            .where((c) => !c.tapped && c.x > c.size && c.x < width - c.size)
            .toList()
          ..sort((a, b) => b.x.compareTo(a.x));
    if (candidates.isEmpty) return;
    final next = candidates.first;
    answerTargetHint(
      level,
      ring: () => setState(() => _ringed = next.id),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.say(line, replay: false),
      demonstrate: () => _onCreatureTap(next, fromHint: true),
    );
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _stopped) return;
    final size = _stageSize;
    if (size == null) return;
    final dt = _lastTick == null ? Duration.zero : elapsed - _lastTick!;
    _lastTick = elapsed;
    final dtSec = dt.inMicroseconds / 1000000.0;
    setState(() {
      for (final c in _creatures) {
        c.x -= c.speed * dtSec;
        c.wigglePhase += c.wiggleFreq * dtSec;
      }
      _creatures.removeWhere((c) => c.x < -c.size);
      if (elapsed >= _nextSpawnAt && _count < widget.target) {
        _spawn(size);
        _nextSpawnAt =
            elapsed + Duration(milliseconds: 700 + _rng.nextInt(700));
      }
    });
  }

  void _spawn(Size size) {
    final spriteSize = math.min(size.width, size.height) * 0.16;
    // Random y, leaving margin for the count badge at top and wiggle play.
    final topMargin = spriteSize * 0.6 + 60; // 60px reserved for count badge
    final bottomMargin = spriteSize * 0.6 + 16;
    final yRange = (size.height - topMargin - bottomMargin).clamp(
      spriteSize,
      double.infinity,
    );
    final y = topMargin + _rng.nextDouble() * yRange;
    final spriteAsset =
        widget.spriteAssets[_rng.nextInt(widget.spriteAssets.length)];
    _creatures.add(
      _FlyingCreature(
        id: _idCounter++,
        spriteAsset: spriteAsset,
        x: size.width + spriteSize,
        y: y,
        speed: 55 + _rng.nextDouble() * 25,
        wiggleFreq: 1.6 + _rng.nextDouble() * 1.6,
        wigglePhase: _rng.nextDouble() * math.pi * 2,
        size: spriteSize,
      ),
    );
  }

  void _onCreatureTap(_FlyingCreature c, {bool fromHint = false}) {
    // Stopped at the target: the board stays up under the celebration, and a
    // hundred-and-first tap would count past it and talk over the reward.
    if (c.tapped || _stopped) return;
    if (!fromHint) _hints?.poke();
    setState(() {
      if (_ringed == c.id) _ringed = null;
      c.tapped = true;
      c.speed *= 2;
      _count++;
    });
    widget.onCountChanged(_count);
    // The pitch ladder, cycled per decade rather than clamped. This
    // challenge runs to a hundred and the scale is twelve notes, so a
    // straight climb would flatten out at the top and leave eighty-odd taps
    // sounding identical. Restarting the run every ten turns the rollover
    // into something audible: each new decade starts the climb again, which
    // is exactly the structure of the number names she is reciting.
    countAloud(
      widget.say,
      ref.read(feedbackEngineProvider),
      step: (_count - 1) % 10 + 1,
      value: _count,
      fromHint: fromHint,
    );
    if (_count >= widget.target) {
      _stopped = true;
      _hints?.pause();
      widget.onTargetReached();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _stageSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final c in _creatures)
              Positioned(
                left: c.x - c.size / 2,
                top: c.y - c.size / 2 + math.sin(c.wigglePhase) * 10,
                width: c.size,
                height: c.size,
                child: GestureDetector(
                  key: ValueKey('challenge-creature-${c.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onCreatureTap(c),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: c.tapped ? 0.65 : 1.0,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.scale(
                          scaleX: 1 + math.sin(c.wigglePhase * 1.5) * 0.07,
                          scaleY: 1 - math.sin(c.wigglePhase * 1.5) * 0.07,
                          child: Image.asset(
                            c.spriteAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (_ringed == c.id)
                          const Positioned.fill(child: TouchHereRing()),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FlyingCreature {
  _FlyingCreature({
    required this.id,
    required this.spriteAsset,
    required this.x,
    required this.y,
    required this.speed,
    required this.wiggleFreq,
    required this.wigglePhase,
    required this.size,
  });

  final int id;
  final String spriteAsset;
  double x;
  final double y;
  double speed;
  final double wiggleFreq;
  double wigglePhase;
  final double size;
  bool tapped = false;
}
