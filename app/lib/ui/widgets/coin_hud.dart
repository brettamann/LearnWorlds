// CoinHud — the kid's coin balance, on screen.
//
// The wallet has been paying out 5 coins per round since the first sprint and
// showing them nowhere: `walletProvider` was read only by the developer
// settings screen. A currency a child never sees can't motivate anything, so
// this is the smallest fix — put the number where she can watch it move.
//
// The count-up matters as much as the number. A balance that jumps from 15 to
// 20 between frames reads as a static label; one that rolls up and pops reads
// as a payout that just happened *because of something she did*.
//
// Numerals are set well above the 40pt floor specs/shared/ui-affordances.md
// requires for progress figures — this is a number a five-year-old is meant to
// read across a room.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/wallet_provider.dart';

class CoinHud extends ConsumerStatefulWidget {
  const CoinHud({super.key, this.compact = false});

  /// Tighter padding and a smaller coin, for app-bar mounting where vertical
  /// space is fixed.
  final bool compact;

  @override
  ConsumerState<CoinHud> createState() => _CoinHudState();
}

class _CoinHudState extends ConsumerState<CoinHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _shown = ref.read(walletProvider);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(walletProvider);

    // Fire the pop when the balance actually changes, not on every rebuild.
    ref.listen<int>(walletProvider, (previous, next) {
      if (previous != next) _pop.forward(from: 0);
    });

    final double coinSize = widget.compact ? 26 : 34;
    final double fontSize = widget.compact ? 26 : 42;

    return AnimatedBuilder(
      animation: _pop,
      builder: (context, child) {
        // Half-sine swell: out and back to rest, so the HUD never ends up
        // parked at a size it wasn't laid out for.
        final t = _pop.value;
        final scale = 1.0 + (t == 0 ? 0.0 : (1 - (2 * t - 1).abs()) * 0.18);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 18,
          vertical: widget.compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on,
              color: const Color(0xFFFFC94A),
              size: coinSize,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
            ),
            const SizedBox(width: 8),
            // Rolls from the previously shown value to the new one rather than
            // snapping, so the payout is legible as an event.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _shown.toDouble(),
                end: coins.toDouble(),
              ),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              onEnd: () => _shown = coins,
              builder: (context, value, _) => Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
