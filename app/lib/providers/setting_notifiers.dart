// The two shapes every device setting takes: an on/off switch, and a level
// from 0 to 1. Sound effects, music, narration and the read-aloud gate were
// four copies of the first; the two volumes were two copies of the second.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An on/off setting.
class BoolSetting extends Notifier<bool> {
  BoolSetting([this._initial = true]);

  final bool _initial;

  @override
  bool build() => _initial;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// A level between 0 and 1. Values outside are clamped.
class VolumeSetting extends Notifier<double> {
  VolumeSetting(this._initial);

  final double _initial;

  @override
  double build() => _initial;

  void set(double value) => state = value.clamp(0.0, 1.0);
}
