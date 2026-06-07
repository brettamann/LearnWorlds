// ActivityRegistry — in-memory snapshot of activity-registry/<grade>.json.
// Loaded once at boot via the activityRegistryProvider.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/activity.dart';
import 'asset_paths.dart';

class ActivityRegistry {
  const ActivityRegistry({
    required this.version,
    required this.activities,
  });

  final int version;
  final List<Activity> activities;

  Activity byId(String id) => activities.firstWhere(
        (a) => a.id == id,
        orElse: () => throw StateError('No activity registered with id "$id"'),
      );

  /// Null-safe variant for surfaces (e.g. the Sanctuary map) that pre-declare
  /// activity ids and want to render placeholders for any that aren't in the
  /// registry yet.
  Activity? byIdOrNull(String id) {
    for (final a in activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Activity> forGrade(String grade) =>
      activities.where((a) => a.grade == grade).toList(growable: false);

  static Future<ActivityRegistry> loadKindergarten() async {
    final raw =
        await rootBundle.loadString(AssetPaths.kindergartenActivityRegistry);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ActivityRegistry(
      version: json['version'] as int,
      activities: (json['activities'] as List<dynamic>)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
