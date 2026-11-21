// CountForwardFromNRunner — K.CC.2 "counting on" sub-mode of the Counting
// Parade. Each round shows N pre-counted creatures (faint numerals above
// them) plus a few new arrivals; the kid taps each new arrival while the
// narrator counts on from N+1.
//
// Three rounds escalate the count: start at 3 (+3 fawns), start at 5 (+3
// gryphons), start at 7 (+3 dragons). The lifecycle is SanctuaryRoundShell's;
// the round is the shared CountOnRoundBody, whose header explains the
// two-beat opening.

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import '../../data/count_forward_from_n_rounds.dart';
import '../../ui/common/count_badge.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import 'count_on_round_body.dart';

/// How long the counted row stands alone before the newcomers walk on —
/// about as long as it takes to say "We already counted three fawns."
const Duration _kArrivalDelay = Duration(milliseconds: 1100);

class CountForwardFromNRunner extends StatelessWidget {
  const CountForwardFromNRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  Widget build(BuildContext context) {
    return SanctuaryRoundShell(
      activityId: ActivityIds.countingParade,
      roundCount: kCountForwardRounds.length,
      conceptIdFor: (_) => 'K.CC.2',
      introLine: kCountForwardIntro,
      keeperLineFor: (i) => kCountForwardRounds[i].keeperLine,
      finalLine: kCountForwardFinal,
      skipIntro: skipIntro,
      celebrationHold: const Duration(seconds: 1),
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.countingParadeMeadow,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) {
        final round = kCountForwardRounds[c.index];
        return CountOnRoundBody(
          c: c,
          spec: CountOnRoundSpec(
            keyPrefix: 'count-forward',
            startN: round.startN,
            arrivalsCount: round.arrivalsCount,
            spriteAsset: round.species.spriteAsset,
            alreadyCountedLine: countForwardAlreadyCountedLine(round),
            prompt: countForwardPrompt(round),
            arrivalDelay: _kArrivalDelay,
            // Climbs from where the parade already is: counting on from five
            // sounds like continuing a scale rather than starting a new one,
            // which is exactly the idea K.CC.2 is teaching.
            stepFor: (taps, value) => value,
            doneHint: kCountForwardDoneHint,
            rowLabel: '— new arrivals —',
            counted: (landed) => _CountedRow(
              startN: round.startN,
              spriteAsset: round.species.spriteAsset,
              landed: landed,
            ),
            badgeSize: CountBadgeSize.medium,
            arrivalSize: 96,
            arrivalHeightFactor: 1.2,
            burstRadius: 70,
            arrivalSpacing: 14,
            scrolls: false,
          ),
        );
      },
    );
  }
}

/// The creatures already counted, each with its faint numeral above it.
class _CountedRow extends StatelessWidget {
  const _CountedRow({
    required this.startN,
    required this.spriteAsset,
    required this.landed,
  });

  final int startN;
  final String spriteAsset;
  final bool landed;

  static const double _spriteSize = 72;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var i = 0; i < startN; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            // Full strength while the narrator is naming these, then dimmed as
            // the newcomers land. That handover is the "your turn now" cue,
            // drawn rather than written.
            opacity: landed ? 0.45 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Image.asset(
                  spriteAsset,
                  width: _spriteSize,
                  height: _spriteSize,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
