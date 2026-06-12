// Kg3PairingIntroLayer — one shape-pairing's introduction beat in the K.G.3
// lesson. Three stages cross-fade in the centre of the screen while the
// narrator walks through the flat-vs-solid correspondence:
//
//   Stage 1 (3 s): the painted 2D example fades in.
//     "This is a flat circle. But every shape has a solid version you
//      could hold in your hand!"
//
//   Stage 2 (3 s): cross-fade into the abstract 3D outline.
//     "When a circle is solid, instead of flat, we call it a sphere or a
//      ball! It's something you could hold in your hand."
//
//   Stage 3 (3 s): cross-fade into the themed creature sprite.
//     "These shapes can take many forms. See how this jellyfish looks
//      like a sphere or ball?"
//
// All three sprites are stacked at the same Positioned bounds; an opacity
// per stage drives the cross-fade. `onComplete` fires after stage 3's
// fade-out so the lesson layer can advance to the per-pairing sort round.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/flat_or_solid_shapes.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';

class Kg3PairingIntroLayer extends ConsumerStatefulWidget {
  const Kg3PairingIntroLayer({
    super.key,
    required this.pairing,
    required this.onComplete,
  });

  final FlatSolidPairing pairing;
  final VoidCallback onComplete;

  @override
  ConsumerState<Kg3PairingIntroLayer> createState() =>
      _Kg3PairingIntroLayerState();
}

enum _Stage { hidden, flat, outline, themed, done }

class _Kg3PairingIntroLayerState extends ConsumerState<Kg3PairingIntroLayer> {
  final List<Timer> _timers = [];
  _Stage _stage = _Stage.hidden;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleTimeline();
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _schedule(int ms, VoidCallback action) {
    _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (!mounted) return;
        action();
      }),
    );
  }

  void _speak(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  void _scheduleTimeline() {
    final p = widget.pairing;
    final cuePrefix = 'kg3-intro:${p.id}';

    // Stage 1 — flat example fades in.
    _schedule(150, () => setState(() => _stage = _Stage.flat));
    _schedule(
      700,
      () => _speak(
        'This is a flat ${p.flatName}. But every shape has a solid '
        'version you could hold in your hand!',
        '$cuePrefix:flat',
      ),
    );

    // Stage 2 — cross-fade to the 3D outline.
    _schedule(5000, () => setState(() => _stage = _Stage.outline));
    _schedule(
      5400,
      () => _speak(
        'When a ${p.flatName} is solid, instead of flat, we call it a '
        '${p.solidName} or a ${p.solidAltName}! '
        "It's something you could hold in your hand.",
        '$cuePrefix:outline',
      ),
    );

    // Stage 3 — cross-fade to themed creature sprite.
    _schedule(10500, () => setState(() => _stage = _Stage.themed));
    _schedule(
      10900,
      () => _speak(
        'These shapes can take many forms. See how this ${p.creatureName} '
        'looks like a ${p.solidName} or ${p.solidAltName}?',
        '$cuePrefix:themed',
      ),
    );

    // Fade out + complete.
    _schedule(15500, () => setState(() => _stage = _Stage.done));
    _schedule(16000, widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shapeSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight,
            ) *
            0.55;
        final left = (constraints.maxWidth - shapeSize) / 2;
        final top = (constraints.maxHeight - shapeSize) / 2;
        final p = widget.pairing;

        // Per-stage opacities. At any moment two adjacent sprites might
        // both be partly visible (cross-fade), so each stage has its own
        // opacity rather than a single shared "current sprite" flag.
        final flatOpacity = switch (_stage) {
          _Stage.flat => 1.0,
          _Stage.outline => 0.0,
          _Stage.themed => 0.0,
          _ => 0.0,
        };
        final outlineOpacity = switch (_stage) {
          _Stage.outline => 1.0,
          _Stage.themed => 0.0,
          _ => 0.0,
        };
        final themedOpacity = switch (_stage) {
          _Stage.themed => 1.0,
          _ => 0.0,
        };

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            _StackedSprite(
              left: left,
              top: top,
              size: shapeSize,
              assetPath: p.flatExampleAsset,
              opacity: flatOpacity,
            ),
            _StackedSprite(
              left: left,
              top: top,
              size: shapeSize,
              assetPath: p.solidOutlineAsset,
              opacity: outlineOpacity,
            ),
            _StackedSprite(
              left: left,
              top: top,
              size: shapeSize,
              assetPath: p.solidThemedAsset,
              opacity: themedOpacity,
            ),
          ],
        );
      },
    );
  }
}

class _StackedSprite extends StatelessWidget {
  const _StackedSprite({
    required this.left,
    required this.top,
    required this.size,
    required this.assetPath,
    required this.opacity,
  });

  final double left;
  final double top;
  final double size;
  final String assetPath;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 700),
        opacity: opacity,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          scale: opacity > 0 ? 1.0 : 0.85,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
