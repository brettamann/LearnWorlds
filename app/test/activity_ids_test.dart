// ActivityIds is the Dart name for every id the activity registry owns. These
// keep the two, the Sanctuary path and the runner registry in step.

import 'package:critmath/activities/activity_ids.dart';
import 'package:critmath/activities/activity_runners.dart';
import 'package:critmath/activities/sub_mode_ids.dart';
import 'package:critmath/data/sanctuary_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  final registered = <String>{
    for (final a in activityRegistryJson()['activities'] as List<dynamic>)
      (a as Map<String, dynamic>)['id'] as String,
  };

  test('ActivityIds names exactly the registered activities', () {
    expect(ActivityIds.all.toSet(), registered);
    expect(ActivityIds.all.toSet().length, ActivityIds.all.length);
  });

  test('every activity has a place on the Sanctuary path', () {
    expect(kSanctuaryActivityByCode.values.toSet(), ActivityIds.all.toSet());
  });

  test('every runner is for a registered activity', () {
    expect(registered, containsAll(kActivityRunners.keys));
  });

  test("every activity's sub-mode ids match the registry, in order", () {
    for (final a in activityRegistryJson()['activities'] as List<dynamic>) {
      final json = a as Map<String, dynamic>;
      final ids = [
        for (final m in json['subModes'] as List<dynamic>)
          (m as Map<String, dynamic>)['id'] as String,
      ];
      expect(kSubModeIdsByActivity[json['id']], ids, reason: '${json['id']}');
    }
  });

  test('an activity is marked built exactly when it has a runner', () {
    final built = <String>{
      for (final a in activityRegistryJson()['activities'] as List<dynamic>)
        if ((a as Map<String, dynamic>)['status'] == 'built') a['id'] as String,
    };
    expect(built, kActivityRunners.keys.toSet());
  });
}
