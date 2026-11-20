// CountBadge - the "3 / 7" pill above a counting board.

import 'package:flutter/material.dart';

import '../../theme/app_decor.dart';

/// How big the badge is. The three sizes are the three the counting screens
/// already used; [large] for a board with room to spare, [small] where the
/// badge shares the top strip with something else.
enum CountBadgeSize {
  large(fontSize: 40, weight: FontWeight.w700, h: 24, v: 12, radius: 24),
  medium(fontSize: 36, weight: FontWeight.w800, h: 22, v: 10, radius: 22),
  small(fontSize: 32, weight: FontWeight.w800, h: 22, v: 10, radius: 22);

  const CountBadgeSize({
    required this.fontSize,
    required this.weight,
    required this.h,
    required this.v,
    required this.radius,
  });

  final double fontSize;
  final FontWeight weight;
  final double h;
  final double v;
  final double radius;
}

class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.value,
    required this.target,
    this.size = CountBadgeSize.large,
  });

  final int value;
  final int target;
  final CountBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.h, vertical: size.v),
      decoration: AppDecor.card(radius: size.radius),
      child: Text(
        '$value / $target',
        style: TextStyle(
          fontSize: size.fontSize,
          fontWeight: size.weight,
          color: Colors.black87,
        ),
      ),
    );
  }
}
