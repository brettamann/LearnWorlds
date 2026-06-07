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

import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';

class CountingChallengeLayer extends ConsumerStatefulWidget {
  const CountingChallengeLayer({
    super.key,
    required this.target,
    required this.spriteAssets,
    required this.onCountChanged,
    required this.onTargetReached,
  });

  /// How many taps win the challenge (typically 20).
  final int target;

  /// Sprites to randomly pull from when spawning a new creature.
  final List<String> spriteAssets;

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

  static const List<String> _spelled = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
    'Twenty',
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(narrationPlayerProvider.notifier).speak(
            NarrationLine(
              text:
                  'Tap the creatures as they go by — count all the way to ${widget.target}!',
              cueId: 'challenge:start',
            ),
          );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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

  void _onCreatureTap(_FlyingCreature c) {
    if (c.tapped) return;
    setState(() {
      c.tapped = true;
      c.speed *= 2;
      _count++;
    });
    widget.onCountChanged(_count);
    final word =
        _count < _spelled.length ? _spelled[_count] : _count.toString();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: '$word.',
            cueId: 'challenge:tap-$_count',
          ),
        );
    if (_count >= widget.target) {
      _stopped = true;
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onCreatureTap(c),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: c.tapped ? 0.65 : 1.0,
                    child: Transform.scale(
                      scaleX: 1 + math.sin(c.wigglePhase * 1.5) * 0.07,
                      scaleY: 1 - math.sin(c.wigglePhase * 1.5) * 0.07,
                      child: Image.asset(c.spriteAsset, fit: BoxFit.contain),
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
