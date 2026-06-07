// Loads a lesson-runtime/<id>.json into a LessonRuntime model. Sprint 1 keeps
// loads ad-hoc; once a second lesson is wired we'll add a registry-style
// cache. Currently called from the LessonScreen's FutureBuilder.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/lesson_runtime.dart';
import 'asset_paths.dart';

class LessonLoader {
  const LessonLoader();

  Future<LessonRuntime> load(String lessonId) async {
    final raw = await rootBundle.loadString(AssetPaths.lessonRuntime(lessonId));
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return LessonRuntime.fromJson(json);
  }
}
