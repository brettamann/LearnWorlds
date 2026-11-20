// "Next!" goes one step simpler for a child who is struggling, and never
// shuts a door.
//
// Step two of the staggered demotion in adaptive-scaffolding.md - drop to a
// simpler sub-mode once there is no CPA layer left to drop - was deferred
// from the first sprint, and with it the only route to the two sub-modes
// written for a struggling child. These run against the real registry, so a
// sub-mode reordered or re-flagged there is checked the day it happens.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/engines/mastery/concept_state.dart';
import 'package:critmath/engines/scaffolding/next_sub_mode.dart';
import 'package:critmath/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Activity> _registry() {
  final json = jsonDecode(
    File('../data/activity-registry/kindergarten.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return <String, Activity>{
    for (final raw in json['activities'] as List<dynamic>)
      (raw as Map<String, dynamic>)['id'] as String: Activity.fromJson(raw),
  };
}

const ConceptState _fine = ConceptState(conceptId: 'x');
const ConceptState _struggling =
    ConceptState(conceptId: 'x', consecutiveFailures: 2);

void main() {
  final registry = _registry();

  String? next(
    String activity,
    String played, {
    ConceptState state = _fine,
    Set<String>? completed,
  }) =>
      nextSubModeAfter(
        activity: registry[activity]!,
        playedId: played,
        completed: completed ?? <String>{played},
        state: state,
      )?.id;

  group('a child who is doing fine', () {
    test('walks the chain in order', () {
      expect(next('care-pantry', 'simple-pantry'), 'full-pantry');
      expect(
        next(
          'counting-parade',
          'count-forward-from-n',
          completed: {'count-the-parade', 'count-forward-from-n'},
        ),
        'count-out-n',
      );
    });

    test('is never sent into a floor', () {
      expect(
        next(
          'build-a-habitat',
          'creature-home',
          completed: {'simple-shelter', 'creature-home'},
        ),
        isNull,
      );
    });
  });

  group('a child who is struggling at the concrete layer', () {
    test('goes one step back down the chain', () {
      expect(
        next('care-pantry', 'full-pantry', state: _struggling),
        'simple-pantry',
      );
      expect(
        next('storytellers-pond', 'take-from', state: _struggling),
        'add-to',
      );
    });

    test('reaches the floor below the entry point, the only way in', () {
      expect(
        next('care-pantry', 'simple-pantry', state: _struggling),
        'categorize-only',
      );
      expect(
        next('build-a-habitat', 'simple-shelter', state: _struggling),
        'frame-only',
      );
    });

    test('at an entry point with nothing below it, carries on as normal', () {
      expect(
        next('ten-frame-pond', 'fill-to-target', state: _struggling),
        'two-ways',
      );
    });

    test('is not sent backwards out of a challenge', () {
      expect(
        registry['care-pantry']!.simplerThan('unfamiliar-rules'),
        isNull,
      );
      expect(
        next(
          'care-pantry',
          'unfamiliar-rules',
          state: _struggling,
          completed: {'simple-pantry', 'full-pantry', 'unfamiliar-rules'},
        ),
        isNull,
      );
    });

    test('and after the easier one, "Next!" moves on - a detour, not a loop',
        () {
      // full-pantry was marked done even though it went badly; after the
      // simpler one she is not sent straight back into it.
      final after = next(
        'care-pantry',
        'simple-pantry',
        completed: {'simple-pantry', 'full-pantry'},
      );
      expect(after, isNull);
    });
  });

  test(
      'struggling means the concrete layer - above it the engine has a '
      'layer to drop', () {
    expect(isStrugglingAtFloor(_struggling), isTrue);
    expect(
      isStrugglingAtFloor(
        const ConceptState(
          conceptId: 'x',
          currentLayer: CpaLayer.pictorial,
          consecutiveFailures: 2,
        ),
      ),
      isFalse,
    );
    expect(
      isStrugglingAtFloor(
        const ConceptState(conceptId: 'x', consecutiveFailures: 1),
      ),
      isFalse,
    );
  });

  test('every floor below an entry point can be reached', () {
    for (final a in registry.values) {
      for (final m in a.subModes) {
        if (!m.isDemotionFloor || m.isChainStep) continue;
        final reached = a.subModes.any((from) => a.simplerThan(from.id) == m);
        expect(reached, isTrue, reason: '${a.id}/${m.id} is unreachable');
      }
    }
  });
}
