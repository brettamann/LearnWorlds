// The one place tests know where data lives on disk. Paths are relative to
// app/, which is the working directory `flutter test` runs in.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/platform/narration_clip_key.dart';

const String kActivityRegistryPath =
    'assets/data/activity-registry/kindergarten.json';
const String kRewardCatalogPath =
    'assets/data/reward-catalog/kindergarten.json';
const String kLessonRuntimeDir = 'assets/data/lesson-runtime';
const String kNarrationClipDir = 'assets/audio/narration';

Map<String, dynamic> readJsonFile(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The kindergarten activity registry, decoded.
Map<String, dynamic> activityRegistryJson() =>
    readJsonFile(kActivityRegistryPath);

/// The kindergarten reward catalog, decoded.
Map<String, dynamic> rewardCatalogJson() => readJsonFile(kRewardCatalogPath);

/// One lesson runtime by file name, with or without `.json`.
Map<String, dynamic> lessonRuntimeJson(String name) => readJsonFile(
      '$kLessonRuntimeDir/${name.endsWith('.json') ? name : '$name.json'}',
    );

/// Every lesson runtime file, sorted by name for stable test order.
List<File> lessonRuntimeFiles() => Directory(kLessonRuntimeDir)
    .listSync()
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'))
    .toList()
  ..sort((a, b) => a.path.compareTo(b.path));

/// The rendered narration clip for [text], or null if none exists.
File? narrationClipFor(String text) {
  final dir = Directory(kNarrationClipDir);
  if (!dir.existsSync()) return null;
  final key = narrationClipKey(text);
  for (final file in dir.listSync().whereType<File>()) {
    if (file.uri.pathSegments.last.startsWith('$key.')) return file;
  }
  return null;
}
