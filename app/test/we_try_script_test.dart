// The We-Try compiler, and the one thing it must never do.
//
// The phase is a participation beat — every lesson's `passCondition` says so —
// so almost nothing here is about grading. It is about two failure modes that
// would both look, to a five-year-old, exactly like the app having stopped:
//
//   1. A phase with no gate. She is never asked to do anything, so We-Try is a
//      second I-Show and the middle third of the lesson is still missing.
//   2. A phase that keeps waiting on the wall clock after she has touched
//      something. The authored `22s phase-end` is right if she watches the
//      whole demonstration and wrong the moment she taps at 11s: the beats
//      after her touch have nothing left to wait for, and honouring the clock
//      parks her in front of a finished scene for eleven seconds.
//
// The compiler is Flutter-free on purpose, so the timing arithmetic is pinned
// here rather than being inferred from a rendered frame.

import 'package:critmath/models/we_try_script.dart';
import 'package:flutter_test/flutter_test.dart';

WeTryScript compile(
  List<Map<String, dynamic>> choreography, {
  Map<String, String> narration = const {},
  Map<String, dynamic>? hesitation,
}) =>
    WeTryScript.compile(
      choreography: choreography,
      narrationByCueId: narration,
      hesitationRule: hesitation,
    );

Map<String, dynamic> say(String at, String cueId) => {
      'at': at,
      'type': 'system-action',
      'params': {'action': 'narration', 'cueId': cueId},
    };

Map<String, dynamic> kid(String at, Map<String, dynamic> params) => {
      'at': at,
      'type': 'kid-action-expected',
      'params': params,
    };

void main() {
  group('timing', () {
    test('absolute times are gaps from the start of the phase', () {
      final s = compile(
        [
          say('0s', 'a'),
          say('4s', 'b'),
          say('7s', 'c'),
        ],
        narration: {'a': 'One.', 'b': 'Two.', 'c': 'Three.'},
      );
      expect(s.beats.map((b) => b.delay.inMilliseconds), [0, 4000, 3000]);
    });

    test('relative times are gaps from the beat before', () {
      final s = compile(
        [
          say('10s', 'a'),
          say('+0.5s', 'b'),
          say('+1.5s', 'c'),
        ],
        narration: {'a': 'One.', 'b': 'Two.', 'c': 'Three.'},
      );
      expect(s.beats.map((b) => b.delay.inMilliseconds), [10000, 500, 1500]);
    });

    test('her touch takes over the pacing from the clock', () {
      // The shape every lesson ends with: prompt on the clock, gate, then a
      // trailing absolute `phase-end` written for a kid who watched all of it.
      final s = compile(
        [
          say('10s', 'prompt'),
          kid('on-kid-input', {'expectedTarget': 'frog-1'}),
          say('+0.5s', 'closing'),
          {
            'at': '22s',
            'type': 'system-action',
            'params': {'action': 'phase-end'},
          },
        ],
        narration: {'prompt': 'Count the frogs.', 'closing': 'Five frogs.'},
      );
      expect(s.beats.last, isA<WeTryEnd>());
      expect(
        s.beats.last.delay,
        Duration.zero,
        reason: 'the 22s deadline is a wall clock she has already overtaken; '
            'honouring it strands her on a finished scene',
      );
    });

    test('a gap is never negative', () {
      // Out-of-order or duplicated absolute times are authored (two beats both
      // at "0s" is the commonest shape in the corpus). A negative gap would
      // throw out of Timer.
      final s = compile(
        [say('7s', 'a'), say('4s', 'b'), say('0s', 'c')],
        narration: {'a': 'One.', 'b': 'Two.', 'c': 'Three.'},
      );
      for (final beat in s.beats) {
        expect(beat.delay, greaterThanOrEqualTo(Duration.zero));
      }
    });
  });

  group('beats', () {
    test('a kid step absorbs the feedback step that answers it', () {
      final s = compile(
        [
          kid('on-kid-input', {
            'expectedZone': 'above-well',
            'tolerantOfMiss': true,
          }),
          {
            'at': 'on-kid-input',
            'type': 'system-action',
            'params': {
              'action': 'drop-feedback',
              'passCue': 'good',
              'failCue': 'steer',
            },
          },
        ],
        narration: {'good': 'Above the well — yes.', 'steer': 'Try higher.'},
      );
      expect(s.beats, hasLength(1), reason: 'feedback is the gate, not a beat');
      final gate = s.beats.single as WeTryGate;
      expect(gate.targets, ['above-well']);
      expect(gate.passText, 'Above the well — yes.');
      expect(gate.failText, 'Try higher.');
    });

    test('on-correct and on-incorrect branch on the gate above them', () {
      final s = compile(
        [
          kid('on-kid-input', {'expectedTarget': 'tile-3'}),
          say('on-correct', 'yes'),
          say('on-incorrect', 'no'),
        ],
        narration: {'yes': 'That one.', 'no': 'This one is three.'},
      );
      expect(s.beats.map((b) => b.when), [
        WeTryWhen.always,
        WeTryWhen.onPass,
        WeTryWhen.onFail,
      ]);
    });

    test('a step naming no target accepts any touch', () {
      // Authored, not missing: these are the steps whose passCondition says
      // any drag passes. An empty target list means "anything", and reading it
      // as "nothing" would make the gate unpassable.
      final s = compile([
        kid('on-kid-input', {
          'expectedAction': 'drag-fish-to-pad',
          'tolerantOfMiss': true,
        }),
      ]);
      expect((s.beats.single as WeTryGate).targets, isEmpty);
    });

    test('a cue with no authored text is dropped, never spoken as its id', () {
      final s = compile([say('0s', 'we-try-prompt-1')]);
      expect(s.beats, isEmpty);
    });
  });

  group('hesitation', () {
    test('defaults to five seconds when a lesson authors no rule', () {
      expect(compile([]).hesitation.after, const Duration(seconds: 5));
    });

    test('reads the authored threshold and action', () {
      final s = compile(
        [],
        hesitation: {'thresholdSec': 5, 'action': 'auto-complete'},
      );
      expect(s.hesitation.after, const Duration(seconds: 5));
      expect(s.hesitation.autoCompletes, isTrue);
    });
  });
}
