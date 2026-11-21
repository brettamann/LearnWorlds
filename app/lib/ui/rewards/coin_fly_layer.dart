// CoinFlyLayer — coins that visibly travel from the playfield to the counter.
//
// Step 5 of the round-pass celebration in specs/shared/k-activity-patterns.md,
// and the last unimplemented one. The CoinHud already rolls its number up, but
// a number that increments on its own is a fact the child is told; coins that
// leave the thing she just finished and land in the counter are a payout she
// watches happen. That difference is the entire reason this file exists.
//
// Mounted as a Positioned.fill in a screen's Stack, above the playfield and
// below any modal. It draws nothing until the balance rises, and it is
// IgnorePointer throughout — a coin must never eat a tap.
//
// Decreases are ignored on purpose: money leaving the wallet in the Buddy shop
// gets its own beat there (the purchase sparkle), and coins flying *out* of the
// counter would read as a penalty.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/wallet_provider.dart';
import '../../theme/app_colors.dart';

/// How many coins can be in the air at once for a single payout. A 5-coin
/// round could draw five, but the arc reads better as a small handful than as
/// a literal tally — and the HUD is where the exact number lives anyway.
const int _kMaxCoinsPerBurst = 5;

class CoinFlyLayer extends ConsumerStatefulWidget {
  const CoinFlyLayer({
    super.key,
    this.origin = const Alignment(0, 0.25),
    this.target = const Alignment(0.86, -1.18),
  });

  /// Where the coins launch from, in Alignment space over this layer. Defaults
  /// to just below centre — roughly where a runner's playfield sits.
  final Alignment origin;

  /// Where they land. Defaults to above the top-right edge, which is where the
  /// app bar's CoinHud is: the layer fills the Scaffold *body*, so the HUD is
  /// off the top of its own coordinate space by design.
  final Alignment target;

  @override
  ConsumerState<CoinFlyLayer> createState() => _CoinFlyLayerState();
}

class _CoinFlyLayerState extends ConsumerState<CoinFlyLayer>
    with TickerProviderStateMixin {
  final List<_Flight> _flights = <_Flight>[];
  final List<Timer> _pending = <Timer>[];
  final math.Random _rng = math.Random();

  @override
  void dispose() {
    for (final t in _pending) {
      t.cancel();
    }
    for (final f in _flights) {
      f.controller.dispose();
    }
    super.dispose();
  }

  void _launch(int delta) {
    final count = delta.clamp(1, _kMaxCoinsPerBurst);
    for (var i = 0; i < count; i++) {
      // Stagger so they arrive as a stream rather than a single blob, which is
      // what makes the HUD's count-up look like it is being fed.
      final timer = Timer(Duration(milliseconds: i * 90), () {
        if (!mounted) return;
        final controller = AnimationController(
          duration: const Duration(milliseconds: 820),
          vsync: this,
        );
        final flight = _Flight(
          controller: controller,
          jitter: (_rng.nextDouble() - 0.5) * 0.34,
          lift: 0.35 + _rng.nextDouble() * 0.30,
          spin: (_rng.nextDouble() - 0.5) * 1.6,
        );
        controller.addStatusListener((status) {
          if (status != AnimationStatus.completed) return;
          if (!mounted) {
            controller.dispose();
            return;
          }
          setState(() => _flights.remove(flight));
          controller.dispose();
        });
        setState(() => _flights.add(flight));
        controller.forward();
      });
      _pending.add(timer);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(walletProvider, (previous, next) {
      // Null previous is boot hydration, not a payout.
      if (previous == null || next <= previous) return;
      _launch(next - previous);
    });

    if (_flights.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return Stack(
            children: [
              for (final flight in _flights)
                AnimatedBuilder(
                  animation: flight.controller,
                  builder: (context, _) => _positioned(flight, size),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _positioned(_Flight flight, Size size) {
    final t = Curves.easeInOutCubic.transform(flight.controller.value);
    final from = widget.origin.alongSize(size);
    final to = widget.target.alongSize(size);

    // Quadratic bezier with the control point lifted above the straight line,
    // so the coin arcs up and over rather than sliding diagonally.
    final control = Offset(
      (from.dx + to.dx) / 2 + flight.jitter * size.width,
      math.min(from.dy, to.dy) - flight.lift * size.height * 0.5,
    );
    final inv = 1 - t;
    final pos = Offset(
      inv * inv * from.dx + 2 * inv * t * control.dx + t * t * to.dx,
      inv * inv * from.dy + 2 * inv * t * control.dy + t * t * to.dy,
    );

    // Pops to full size on launch, shrinks slightly on approach so it reads as
    // travelling away from the child and into the counter.
    final scale = t < 0.18 ? (t / 0.18) : (1.0 - (t - 0.18) * 0.28);
    final opacity = t > 0.82 ? (1 - (t - 0.82) / 0.18).clamp(0.0, 1.0) : 1.0;

    return Positioned(
      left: pos.dx - 18,
      top: pos.dy - 18,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: flight.spin * t * math.pi,
          child: Transform.scale(
            scale: scale,
            child: const Icon(
              Icons.monetization_on,
              size: 36,
              color: AppColors.coinGold,
              shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
            ),
          ),
        ),
      ),
    );
  }
}

class _Flight {
  _Flight({
    required this.controller,
    required this.jitter,
    required this.lift,
    required this.spin,
  });

  final AnimationController controller;

  /// Horizontal offset of the bezier control point, as a fraction of width.
  /// Keeps two coins launched a frame apart from tracing the same path.
  final double jitter;

  /// How far above the straight line the arc peaks, as a fraction of height.
  final double lift;

  /// Rotations over the flight, signed. Small — a spinning coin is charming,
  /// a whirling one is noise.
  final double spin;
}
