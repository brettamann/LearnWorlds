// AppDecor - the floating white card every badge, banner and bubble sits on.
//
// The same 92%-white rounded card with a soft drop shadow was written out by
// hand in some thirty places, in three shadow strengths that had drifted into
// existence without anyone choosing them. These are those three, named.

import 'package:flutter/material.dart';

abstract final class AppShadows {
  /// Small chips and in-board banners.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Count badges and stage labels.
  static const List<BoxShadow> medium = [
    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
  ];

  /// Speech bubbles and dialogs that sit over the whole scene.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
  ];
}

abstract final class AppDecor {
  /// Fill of the floating card.
  static final Color cardFill = Colors.white.withValues(alpha: 0.92);

  /// The floating white card.
  static BoxDecoration card({
    required double radius,
    List<BoxShadow> shadow = AppShadows.medium,
  }) => BoxDecoration(
    color: cardFill,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadow,
  );
}
