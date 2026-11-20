// TimerScope - timers that belong to a widget and die with it.
//
// Runners and lesson layers sequence a lot of beats on timers ("pause, then
// point, then say it"), and every one of those callbacks must not run against
// an unmounted widget. Each State used to keep its own `List<Timer>`, its own
// mounted-checking `_after` / `_schedule` wrapper and its own cancel loop in
// dispose(); this mixin is that, once.

import 'dart:async';

import 'package:flutter/widgets.dart';

mixin TimerScope<T extends StatefulWidget> on State<T> {
  final List<Timer> _scopedTimers = <Timer>[];

  /// Runs [action] after [delay], unless this widget has been unmounted by
  /// then. Cancelled automatically on dispose.
  Timer after(Duration delay, VoidCallback action) {
    final timer = Timer(delay, () {
      if (mounted) action();
    });
    _scopedTimers.add(timer);
    return timer;
  }

  /// [after] in milliseconds, for choreography written as a list of beats.
  Timer afterMs(int ms, VoidCallback action) =>
      after(Duration(milliseconds: ms), action);

  /// Cancels every pending timer started through this scope.
  void cancelTimers() {
    for (final t in _scopedTimers) {
      t.cancel();
    }
    _scopedTimers.clear();
  }

  @override
  void dispose() {
    cancelTimers();
    super.dispose();
  }
}
