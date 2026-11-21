// CountOnByOnesRunner — K.CC.1 "count to 100 by ones" + K.CC.2 "count
// forward from a given number" sub-mode of the Counting Parade. Each
// round joins the parade at a given number and counts the next decade by
// ones: 10 → 20, then 40 → 50, 70 → 80, and 90 → 100.
//
// It used to walk all nine decades in order, picking up exactly where the
// previous round stopped. That was ninety taps of the identical interaction
// in one sitting. Sampling four decades instead keeps the hard part — the
// decade boundary, which is the whole difficulty of counting on — and drops
// the sitting to forty taps. Starting somewhere other than "wherever we
// happened to stop" is also a truer reading of K.CC.2, which is about
// counting on from *any* given number rather than from the beginning.
//
// Layout per round: filled cluster-of-ten cards show the kid where we are
// (e.g. "10"), and ten individual creatures are the new arrivals to tap
// one-by-one. The narrator confirms each tap with the next number ("Eleven.
// Twelve. ...") and the count badge ticks up alongside it.
//
// The lifecycle is SanctuaryRoundShell's, and the round is the shared
// CountOnRoundBody (Count Forward From N's too), whose header explains the
// two-beat opening. What is this activity's own is the picture of what is
// already counted, and the animated demo that stands in for the keeper's
// intro.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/count_on_by_ones_rounds.dart';
import '../../data/number_words.dart';
import '../../engines/narration/narration_player.dart';
import '../../ui/common/continue_arrow_shelf.dart';
import '../../ui/common/count_badge.dart';
import '../../ui/common/next_arrow_button.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import 'count_on_round_body.dart';
import 'parade_pieces.dart';

/// How long the counted cluster stands alone before the newcomers walk on —
/// about as long as it takes to say "We're at forty already."
const Duration _kArrivalDelay = Duration(milliseconds: 1000);

class CountOnByOnesRunner extends StatelessWidget {
  const CountOnByOnesRunner({
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
      roundCount: kCountOnByOnesRounds.length,
      conceptIdFor: (_) => 'K.CC.1',
      // Never spoken: the demo below is the opening, and owns its narration.
      introLine: kCountOnByOnesDemoKickoff,
      introBuilder: (context, start) => _DemoLayer(onComplete: start),
      keeperLineFor: (i) => kCountOnByOnesRounds[i].keeperLine,
      finalLine: kCountOnByOnesFinal,
      skipIntro: skipIntro,
      celebrationHold: const Duration(seconds: 1),
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.countingParadeMeadow,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) {
        final round = kCountOnByOnesRounds[c.index];
        final sprite = round.species.spriteAsset;
        return CountOnRoundBody(
          c: c,
          spec: CountOnRoundSpec(
            keyPrefix: 'count-on-ones',
            startN: round.startN,
            arrivalsCount: round.arrivalsCount,
            spriteAsset: sprite,
            alreadyCountedLine: countOnByOnesAlreadyCountedLine(round),
            prompt: countOnByOnesPrompt(round),
            arrivalDelay: _kArrivalDelay,
            // Keyed off the taps *this round*, not the absolute count: the
            // scale climbs the same ten steps whether the parade is at ten or
            // at ninety, so crossing each decade sounds identical. That is the
            // point of the exercise — ninety-one through one hundred is the
            // same walk as eleven through twenty.
            stepFor: (taps, value) => taps,
            doneHint: kCountOnByOnesDoneHint,
            rowLabel: '— count by ones —',
            // Full strength while the narrator names it, then dimmed as the
            // newcomers land. That handover is the "your turn now" cue, drawn
            // rather than written.
            counted: (landed) => AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: landed ? 0.6 : 1,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var t = 0; t < round.startN ~/ 10; t++)
                    _CompletedClusterCard(
                      spriteAsset: sprite,
                      label: decadeLabel(t),
                    ),
                ],
              ),
            ),
            badgeSize: CountBadgeSize.small,
            // Large enough for K pointer accuracy but small enough that ten
            // fit in a wrap.
            arrivalSize: 76,
            arrivalHeightFactor: 1.15,
            burstRadius: 56,
            arrivalSpacing: 10,
            scrolls: true,
          ),
        );
      },
    );
  }
}

/// A small filled cluster card showing one completed group of ten with
/// its running total label. Anchors the kid in the count — "we've
/// already counted these tens, now we add ones."
class _CompletedClusterCard extends StatelessWidget {
  const _CompletedClusterCard({
    super.key,
    required this.spriteAsset,
    required this.label,
  });

  final String spriteAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TenClusterGrid(
            spriteAsset: spriteAsset,
            spriteSize: 22,
            gap: 3,
            rowGap: 1,
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated lead-in for the count-on-by-ones sub-mode. Plays a three-act
/// demo:
///
///   1. **Count to ten** — ten fawn sprites pop into a 2×5 grid one by
///      one; narrator says "one… two… three… ten" in time with each
///      appearance.
///   2. **Collapse to a "10" cluster** — the grid becomes a labelled
///      cluster card; narrator: "When we count to ten we get a special
///      new number. The ones start over." (Mirrors how the count-by-tens
///      lesson visualises a group-of-ten.)
///   3. **Build the decades** — nine more cluster cards land one at a
///      time, narrator counting "twenty… thirty… … one hundred."
///
/// After the decades land, the narrator says "Let's count all the
/// different tens!" and the Start arrow appears. Tapping Start fires
/// `onComplete` (which advances the runner into the counting rounds).
class _DemoLayer extends ConsumerStatefulWidget {
  const _DemoLayer({required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<_DemoLayer> createState() => _DemoLayerState();
}

class _DemoLayerState extends ConsumerState<_DemoLayer>
    with TimerScope<_DemoLayer> {
  // `_step` encodes the entire demo timeline:
  //   0       — idle (pre-first-frame)
  //   1..10   — counting sprites (visible count == _step)
  //   11      — first cluster collapses + "ones start over" narration
  //   12..20  — additional decade clusters; total clusters == _step - 10
  //   21      — kickoff line + Start arrow visible
  int _step = 0;
  bool _showStart = false;

  /// The whole demo uses a single species — keeps the visual story
  /// simple. Mythical creatures are picked over the fawn so the demo
  /// feels distinct from the count-the-parade intro.
  static const String _sprite = AssetPaths.countingParadeBabyGryphon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleDemo();
    });
  }

  void _scheduleDemo() {
    var t = 350;
    // Count one through ten. 600ms between arrivals keeps pace with the
    // narrator without feeling slow for a tablet audience.
    for (var i = 1; i <= 10; i++) {
      final value = i;
      after(Duration(milliseconds: t), () {
        setState(() => _step = value);
        ref.narration.say('${spellCount(value)}.', cueId: 'demo:count-$value');
      });
      t += 600;
    }
    // Beat after the last "ten" before the cluster collapses + the
    // explanation plays. Long enough to feel deliberate.
    t += 700;
    after(Duration(milliseconds: t), () {
      setState(() => _step = 11);
      ref.narration.say(kCountOnByOnesDemoCollapse, cueId: 'demo:collapse');
    });
    // Hold on the single "10" cluster long enough for the narration to
    // breathe (~5s spoken).
    t += 5200;
    // Decades two through ten — one card slides in per beat.
    for (var i = 2; i <= 10; i++) {
      final value = i;
      after(Duration(milliseconds: t), () {
        setState(() => _step = 10 + value);
        ref.narration.say(
          '${spellCount(value * 10)}.',
          cueId: 'demo:decade-$value',
        );
      });
      t += 1100;
    }
    // Kickoff — narration + Start arrow appear together.
    t += 500;
    after(Duration(milliseconds: t), () {
      setState(() {
        _step = 21;
        _showStart = true;
      });
      ref.narration.say(kCountOnByOnesDemoKickoff, cueId: 'demo:kickoff');
    });
  }

  /// Top-of-stage badge value. Climbs by ones during the counting
  /// phase, then by tens once the first cluster lands.
  int get _badgeValue {
    if (_step >= 1 && _step <= 10) return _step;
    if (_step >= 11) return ((_step - 10).clamp(1, 10)) * 10;
    return 0;
  }

  /// Number of completed cluster cards to draw.
  int get _clusterCount {
    if (_step < 11) return 0;
    return (_step - 10).clamp(1, 10);
  }

  bool get _isCounting => _step >= 1 && _step <= 10;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  CountBadge(
                    value: _badgeValue,
                    target: 100,
                    size: CountBadgeSize.small,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 650),
                      child: _isCounting
                          ? _DemoCountingGrid(
                              key: const ValueKey('demo-grid'),
                              spriteAsset: _sprite,
                              visibleCount: _step,
                            )
                          : _DemoClusterWrap(
                              key: const ValueKey('demo-clusters'),
                              spriteAsset: _sprite,
                              clusterCount: _clusterCount,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: _showStart
                  ? NextArrowButton(
                      key: const ValueKey('count-on-ones-demo-start'),
                      idleHintEnabled: true,
                      idleHintText: kCountOnByOnesDemoStartHint,
                      onPressed: widget.onComplete,
                      label: kLabelStart,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The "count to ten" stage — a 2×5 grid of sprite slots inside a soft
/// white card. Sprites pop in as `visibleCount` climbs.
class _DemoCountingGrid extends StatelessWidget {
  const _DemoCountingGrid({
    super.key,
    required this.spriteAsset,
    required this.visibleCount,
  });

  final String spriteAsset;
  final int visibleCount;

  static const double _spriteSize = 64;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 5; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var col = 0; col < 2; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PopInSprite(
                          spriteAsset: spriteAsset,
                          visible: (row * 2 + col + 1) <= visibleCount,
                          size: _spriteSize,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One sprite slot in the counting grid. Hidden slots take their full
/// space (so the grid doesn't reflow as sprites appear) and reveal with
/// an `easeOutBack` pop so each arrival has a beat to it.
class _PopInSprite extends StatelessWidget {
  const _PopInSprite({
    required this.spriteAsset,
    required this.visible,
    required this.size,
  });

  final String spriteAsset;
  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        scale: visible ? 1.0 : 0.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1.0 : 0.0,
          child: Image.asset(
            spriteAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// The "decade clusters" stage — a Wrap of completed cluster cards.
/// Adds one card per beat as `clusterCount` climbs from 1 to 10.
class _DemoClusterWrap extends StatelessWidget {
  const _DemoClusterWrap({
    super.key,
    required this.spriteAsset,
    required this.clusterCount,
  });

  final String spriteAsset;
  final int clusterCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var c = 0; c < clusterCount; c++)
                _CompletedClusterCard(
                  key: ValueKey('demo-cluster-$c'),
                  spriteAsset: spriteAsset,
                  label: decadeLabel(c),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
