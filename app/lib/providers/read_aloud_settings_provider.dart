// ReadAloudGate enabled — per-kid setting that gates every interactive
// element (NextArrowButton, map regions, lesson nodes) behind a
// first-tap-reads / second-tap-acts pattern. Defaults to ON because K and
// 1st grade can't read button labels reliably yet; older kids should turn
// it off via the Settings screen (or set a grade-aware default once we
// thread kid profiles through).
//
// Persisted by SaveCoordinator alongside ttsEnabled.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setting_notifiers.dart';

final readAloudGateEnabledProvider =
    NotifierProvider<BoolSetting, bool>(BoolSetting.new);
