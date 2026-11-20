import 'package:critmath/engines/mastery/round_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('gradeRound', () {
    test('a clean, unhelped round is a success', () {
      expect(gradeRound(), RoundResult.success);
    });

    test('any help makes it soft', () {
      expect(gradeRound(helped: true), RoundResult.softSuccess);
    });

    test('a miss or two is soft, three fails', () {
      expect(gradeRound(misses: 1), RoundResult.softSuccess);
      expect(gradeRound(misses: 2), RoundResult.softSuccess);
      expect(gradeRound(misses: kMissesToFail), RoundResult.failure);
    });

    test('an activity can set its own threshold', () {
      expect(gradeRound(misses: 3, failAt: 4), RoundResult.softSuccess);
      expect(gradeRound(misses: 4, failAt: 4), RoundResult.failure);
    });

    test('a round with no failure threshold cannot fail', () {
      expect(gradeRound(misses: 99, failAt: null), RoundResult.softSuccess);
    });
  });

  test('every result pays something, and a clean round pays most', () {
    for (final r in RoundResult.values) {
      expect(coinsFor(r), greaterThan(0));
      expect(coinsFor(r), lessThanOrEqualTo(kCoinsForCleanRound));
    }
    expect(coinsFor(RoundResult.success), kCoinsForCleanRound);
  });
}
