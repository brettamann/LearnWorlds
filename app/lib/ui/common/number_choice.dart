// Number cards a pre-reader can answer with.
//
// Four of the Sanctuary's activities end a round by asking her to pick a
// number - how many frogs now, which basket has more, what two and one make.
// She is five and she is still learning what the marks mean, so a numeral on
// its own is a reading test stacked on top of whatever the round is about.
// Every card can therefore carry the quantity as well: a small ten-frame of
// dots under the numeral, filling the top row of five before the bottom one,
// which is the same picture Ten-Frame Pond builds out of lily pads. Seven is
// visibly "a full row and two more" on every card in the game.
//
// A round about reading numerals (Scribe's Tower) turns the dots off, and a
// round that wants to fade the support turns them off for the later rounds.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'answer_feedback.dart';
import 'glitter_burst.dart';
import 'touch_here_halo.dart';
import 'touch_target.dart';

/// A small ten-frame: five columns, one row up to five and two rows above.
class DotFrame extends StatelessWidget {
  const DotFrame({
    super.key,
    required this.count,
    this.cell = 18,
    this.color = const Color(0xFF6B4A2B),
    this.showEmptyCells = true,
  });

  final int count;
  final double cell;
  final Color color;

  /// The faint outline of the unfilled cells. It is what makes "seven" read
  /// as "seven out of ten", and what makes zero a picture rather than blank.
  final bool showEmptyCells;

  @override
  Widget build(BuildContext context) {
    final rows = count > 5 ? 2 : 1;
    return CustomPaint(
      size: Size(cell * 5, cell * rows),
      painter: _DotFramePainter(
        count: count,
        rows: rows,
        color: color,
        showEmptyCells: showEmptyCells,
      ),
    );
  }
}

class _DotFramePainter extends CustomPainter {
  const _DotFramePainter({
    required this.count,
    required this.rows,
    required this.color,
    required this.showEmptyCells,
  });

  final int count;
  final int rows;
  final Color color;
  final bool showEmptyCells;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 5;
    final r = cell * 0.36;
    final fill = Paint()..color = color;
    final empty = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, cell * 0.07)
      ..color = color.withValues(alpha: 0.28);
    for (var i = 0; i < rows * 5; i++) {
      final c = Offset((i % 5 + 0.5) * cell, (i ~/ 5 + 0.5) * cell);
      if (i < count) {
        canvas.drawCircle(c, r, fill);
      } else if (showEmptyCells) {
        canvas.drawCircle(c, r, empty);
      }
    }
  }

  @override
  bool shouldRepaint(_DotFramePainter old) =>
      old.count != count ||
      old.rows != rows ||
      old.color != color ||
      old.showEmptyCells != showEmptyCells;
}

/// One card. Big: the smallest a card is ever drawn is well over
/// [kMinTouchTarget], because this is the answer and not a control.
class NumberCard extends StatelessWidget {
  const NumberCard({
    super.key,
    required this.value,
    this.width = 150,
    this.showNumeral = true,
    this.showDots = true,
    this.hinted = false,
    this.glowing = false,
    this.dimmed = false,
    this.wrongToken = 0,
    this.burstToken = 0,
    this.onTap,
  });

  final int value;
  final double width;
  final bool showNumeral;
  final bool showDots;
  final bool hinted;

  /// The right answer, once found.
  final bool glowing;

  /// Everything else, once the answer is found - so the eye goes to it.
  final bool dimmed;

  final int wrongToken;
  final int burstToken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = math.max(width, kMinTouchTarget);
    final h = w * (showNumeral && showDots ? 1.15 : 1.0);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: glowing ? const Color(0xFFFFF4C9) : const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(w * 0.16),
        border: Border.all(
          color: glowing ? AppColors.hintGlow : AppColors.cardRim,
          width: glowing ? 5 : 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      // Scaled down rather than clipped if a window is ever too small for it:
      // a numeral cut in half is a different numeral.
      padding: EdgeInsets.all(w * 0.06),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showNumeral)
              Text(
                '$value',
                style: TextStyle(
                  fontSize: w * (showDots ? 0.46 : 0.6),
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cardInk,
                ),
              ),
            if (showNumeral && showDots) SizedBox(height: w * 0.06),
            if (showDots)
              DotFrame(
                count: value,
                cell: w * (showNumeral ? 0.13 : 0.17),
              ),
          ],
        ),
      ),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnswerFeedback(
          wrongToken: wrongToken,
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: card),
                if (hinted) TouchHereRingOutside(around: Size(w, h)),
                if (burstToken > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: GlitterBurst(
                        key: ValueKey('number-burst-$value-$burstToken'),
                        maxRadius: w * 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of answer cards.
class NumberChoiceRow extends StatelessWidget {
  const NumberChoiceRow({
    super.key,
    required this.choices,
    required this.onPick,
    this.answered,
    this.hinted,
    this.wrongTokens = const <int, int>{},
    this.showNumeral = true,
    this.showDots = true,
    this.cardWidth = 150,
    this.locked = false,
  });

  final List<int> choices;
  final ValueChanged<int> onPick;

  /// The right answer, once she has found it.
  final int? answered;
  final int? hinted;
  final Map<int, int> wrongTokens;
  final bool showNumeral;
  final bool showDots;
  final double cardWidth;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < choices.length; i++) ...[
          if (i > 0) SizedBox(width: cardWidth * 0.22),
          NumberCard(
            key: ValueKey('number-card-${choices[i]}'),
            value: choices[i],
            width: cardWidth,
            showNumeral: showNumeral,
            showDots: showDots,
            hinted: hinted == choices[i] && answered == null,
            glowing: answered == choices[i],
            dimmed: answered != null && answered != choices[i],
            wrongToken: wrongTokens[choices[i]] ?? 0,
            burstToken: answered == choices[i] ? 1 : 0,
            onTap: locked || answered != null ? null : () => onPick(choices[i]),
          ),
        ],
      ],
    );
  }
}

/// Three distinct choices containing [answer], none below [min] or above
/// [max], in an order that does not always put the answer in the middle.
///
/// Deterministic in [seed] so a round is the same round every time it is
/// built - a board that reshuffles on rebuild would move the card out from
/// under her finger.
List<int> numberChoicesFor(
  int answer, {
  required int seed,
  int min = 0,
  int max = 10,
}) {
  final rng = math.Random(seed * 7919 + answer * 31);
  // Near misses - one or two either side - because that is the confusion a
  // child actually has. A far distractor teaches nothing.
  final near = <int>[answer - 1, answer + 1, answer - 2, answer + 2]
      .where((n) => n >= min && n <= max)
      .toList()
    ..shuffle(rng);
  final out = <int>[answer, ...near.take(2)];
  for (var n = min; out.length < 3 && n <= max; n++) {
    if (!out.contains(n)) out.add(n);
  }
  return out..shuffle(rng);
}
