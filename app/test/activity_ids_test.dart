// ActivityIds is the Dart name for every id the activity registry owns. These
// keep the two, the Sanctuary path and the runner registry in step.

import 'package:critmath/activities/activity_ids.dart';
import 'package:critmath/activities/activity_runners.dart';
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
}
