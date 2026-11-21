// ActivityLaunch - what a screen hands an activity when it opens one.
//
// Replaces the untyped `Map<String, dynamic>` route extra, whose keys
// ('subMode', 'fromLesson', 'roundParameters') were spelled out by hand at
// every call site and read back by hand in two screens. A typo there failed
// silently; a typo here does not compile.

import '../models/activity.dart';

class ActivityLaunch {
  const ActivityLaunch({
    this.subModeId,
    this.fromLessonId,
    this.roundParameters,
  });

  /// The sub-mode to play, or null for the activity's default.
  final String? subModeId;

  /// The lesson that handed off into this visit, if any. A lesson has
  /// already played the keeper's intro, so the runner skips its own.
  final String? fromLessonId;

  /// Authored round shaping from the lesson's `youDo.roundParameters`.
  final Map<String, dynamic>? roundParameters;

  bool get fromLesson => fromLessonId != null;

  /// [subModeId], or [activity]'s default sub-mode when none was given.
  String subModeFor(Activity activity) =>
      subModeId ?? activity.defaultSubMode.id;
}

/// What a screen hands a lesson when it opens one.
class LessonLaunch {
  const LessonLaunch({this.subModeId});

  /// The sub-mode the lesson should hand off into, overriding the lesson's
  /// own `youDo.subMode` (one lesson can introduce several sub-modes).
  final String? subModeId;
}
