// AppColors - the game's palette, by role.
//
// Every colour used in more than one place is named here for what it does,
// not what it looks like, so "the glow on the thing she should touch" is the
// same amber everywhere and changes in one place. One-off colours that belong
// to a single illustration (a frog, a basket) stay local to their painter.

import 'package:flutter/painting.dart';

abstract final class AppColors {
  // --- Highlights -----------------------------------------------------------

  /// The amber ring/fill on whatever the game is pointing her at (hint glow,
  /// a lit crate, the tracer's ink).
  static const Color hintGlow = Color(0xFFFFB300);

  /// Sparkle and burst particles.
  static const Color glitter = Color(0xFFFFE08A);

  // --- Gold family ----------------------------------------------------------

  /// Coins: the HUD, the flying coin, every price.
  static const Color coinGold = Color(0xFFFFC94A);

  /// The primary arrow button and the reward progress bar.
  static const Color buttonGold = Color(0xFFFFC53D);

  /// Something she owns or has found: an owned decor slot, a found card,
  /// a rare card's rim, an affordable price.
  static const Color treasureGold = Color(0xFFE0A53C);

  /// The selected option in the character creator.
  static const Color selectGold = Color(0xFFEAA916);

  // --- Number cards and wood ------------------------------------------------

  /// Rim of an unlit number card / answer tile.
  static const Color cardRim = Color(0xFFD8C6A0);

  /// The numeral printed on a number card.
  static const Color cardInk = Color(0xFF4A3220);

  /// Unlit wood: crates, shelves, an empty ten-frame cell.
  static const Color wood = Color(0xFF8A5A2B);

  /// A neutral rim on an unselected option or an idle sort bin.
  static const Color neutralRim = Color(0xFFD8D2C2);

  // --- Parchment (collection album, decor tray, reward card) ----------------

  static const Color parchment = Color(0xFFFFF8E7);
  static const Color parchmentInk = Color(0xFF3B3226);

  /// A slot she has not filled yet.
  static const Color emptySlot = Color(0xFF4A443A);
}
