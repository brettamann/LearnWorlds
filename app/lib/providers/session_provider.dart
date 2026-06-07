// SessionId — a stable id for the current launch. Mastery counts distinct
// sessions for promotion to Mastered; the simplest source-of-truth is
// "one id per process start." Sleep/foreground events that should split
// sessions arrive in a later sprint.

import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionIdProvider = Provider<String>((ref) {
  return 'session-${DateTime.now().microsecondsSinceEpoch}';
});
