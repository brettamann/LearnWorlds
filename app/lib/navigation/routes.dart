// Routes - every path in the app, and typed ways to go to them.
//
// Screens used to build paths by hand ('/activity/${id}') and pass launch
// options as a Map with string keys. Use these instead: the path is spelled
// once, and an activity or lesson is opened with a typed launch value.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../activities/activity_launch.dart';

abstract final class Routes {
  static const String home = '/';
  static const String sanctuary = '/sanctuary';
  static const String sanctuaryCutscene = '/sanctuary/cutscene';
  static const String settings = '/settings';
  static const String characterCreator = '/home/character-creator';
  static const String buddyShop = '/home/buddy-shop';
  static const String collection = '/collection';
  static const String eggGift = '/reward/k-mystery-egg-gift';

  /// Path pattern for [activity]; the router reads `:id`.
  static const String activityPattern = '/activity/:id';

  /// Path pattern for [lesson]; the router reads `:id`.
  static const String lessonPattern = '/lesson/:id';

  static String activity(String activityId) => '/activity/$activityId';
  static String lesson(String lessonId) => '/lesson/$lessonId';
}

extension AppNavigation on BuildContext {
  /// Opens [activityId] with [launch].
  void goActivity(
    String activityId, [
    ActivityLaunch launch = const ActivityLaunch(),
  ]) =>
      go(Routes.activity(activityId), extra: launch);

  /// Opens the lesson [lessonId], handing off into [subModeId] afterwards
  /// when given.
  void goLesson(String lessonId, {String? subModeId}) =>
      go(Routes.lesson(lessonId), extra: LessonLaunch(subModeId: subModeId));
}
