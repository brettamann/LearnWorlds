// The We-Try does not do, for her, the thing it just asked her to do.
//
// From the first real play session: "On the first activity during the counting
// fawns I selected the first two and then suddenly the last two automatically
// selected themselves and continued. that was very jarring given the player
// had been instructed to do the tapping."
//
// She was right on both counts, and it was two faults on top of each other.
//
// The content: four counting lessons ended their We-Try with
// `pointer-auto-tap` / `pointer-auto-tap-sequence` over the countables she was
// in the middle of counting. K.CC.4b's own prompt is "Your turn. Touch each
// fawn" - and then it touched two of them for her. As a reading of guided
// practice that is defensible; as an experience it takes the controls out of
// a five-year-old's hands mid-task, and one-to-one correspondence is precisely
// the standard where *her* finger has to land on each one.
//
// The interpreter: `pointer-auto-*` lit every named target in a single frame,
// with no hand and ignoring the `spacingSec` the content asked for. So even
// the authored version - keeper's hand, one per second - arrived as two fawns
// flashing on at once. That is the difference between "we'll finish this
// together" and the screen twitching.
//
// Both are fixed, and this is what keeps them fixed. The rule below is not
// "never finish anything for her": twelve lessons still end with the system
// completing a construction - the frame standing up, the bins sweeping clear -
// and those are payoff beats, not her task. The rule is narrower and it is the
// one that was broken: **the We-Try never makes a target react unless it asked
// her for that target.**

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Actions that make a scene object respond the way a touch makes it respond.
/// A child cannot tell these apart from her own tap having landed.
const Set<String> _reactions = <String>{
  'sparkle',
  'sparkle-on-target',
  'cluster-pulse',
  'ten-label-rise',
};

typedef _WeTry = ({String id, List<dynamic> choreography});

List<_WeTry> _weTrys() {
  final out = <_WeTry>[];
  for (final e in Directory('../data/lesson-runtime').listSync()) {
    if (e is! File || !e.path.endsWith('.json')) continue;
    final doc = jsonDecode(e.readAsStringSync()) as Map<String, dynamic>;
    final phases = doc['phases'] as Map<String, dynamic>?;
    final weTry = phases?['weTry'] as Map<String, dynamic>?;
    final chor = weTry?['choreography'] as List<dynamic>?;
    if (chor == null) continue;
    out.add((id: doc['id'] as String? ?? e.path, choreography: chor));
  }
  return out;
}

Map<String, dynamic> _params(dynamic beat) =>
    (beat as Map<String, dynamic>)['params'] as Map<String, dynamic>? ??
    const <String, dynamic>{};

Set<String> _named(Map<String, dynamic> params) => <String>{
      if (params['target'] is String) params['target'] as String,
      for (final t in params['targets'] as List<dynamic>? ?? const [])
        if (t is String) t,
    };

void main() {
  final lessons = _weTrys();

  test('there are We-Trys to check', () {
    expect(lessons.length, greaterThanOrEqualTo(20));
  });

  group('a We-Try', () {
    for (final lesson in lessons) {
      test('${lesson.id}: never stands in for her on a target it named', () {
        final offenders = <String>[];
        for (final beat in lesson.choreography) {
          final params = _params(beat);
          final action = params['action'] as String? ?? '';
          if (!action.startsWith('pointer-auto')) continue;
          final named = _named(params);
          if (named.isEmpty) continue;
          offenders.add('$action -> ${named.toList()..sort()}');
        }
        expect(
          offenders,
          isEmpty,
          reason: 'a `pointer-auto-*` that names targets is the system doing '
              'her turn on specific objects. Give each one a '
              '`kid-action-expected` instead and let the hesitation rule be '
              'the safety net - it is three rungs deep and it demonstrates '
              'with the hand. An auto-complete that names nothing is fine: '
              'that is the construction finishing, which is a payoff and not '
              'a task.',
        );
      });

      test('${lesson.id}: only makes something react if it asked for it', () {
        final gated = <String>{};
        for (final beat in lesson.choreography) {
          if ((beat as Map<String, dynamic>)['type'] != 'kid-action-expected') {
            continue;
          }
          final t = _params(beat)['expectedTarget'];
          if (t is String) gated.add(t);
        }
        final unasked = <String>{};
        for (final beat in lesson.choreography) {
          final params = _params(beat);
          final action = params['action'] as String? ?? '';
          if (!_reactions.contains(action) &&
              !action.startsWith('pointer-auto')) {
            continue;
          }
          unasked.addAll(_named(params).difference(gated));
        }
        expect(
          unasked,
          isEmpty,
          reason: 'these react as though touched, and she was never asked to '
              'touch them. From her side a thing she was counting counted '
              'itself. (Haloing something she is not asked for is fine - a '
              'halo is context. Sparkling it is not.)',
        );
      });
    }
  });

  test('the reaction check is not vacuous', () {
    // It passes trivially if nothing sparkles at all, which is also what a
    // renamed action would look like.
    var reacting = 0;
    for (final lesson in lessons) {
      for (final beat in lesson.choreography) {
        if (_reactions.contains(_params(beat)['action'])) reacting++;
      }
    }
    expect(reacting, greaterThanOrEqualTo(15));
  });
}
