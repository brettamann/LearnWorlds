// LongParadeRunner — K.CC.1 "count by tens" sub-mode of the Counting
// Parade. The K.CC.1 lesson teaches that a tight group of ten can be
// counted as one chunk; this activity practices that exact skill:
// each round presents N groups of 10 creatures (laid out as 2 × 5
// grids inside cluster cards) and the kid taps each cluster in order.
// The narrator says "Ten. Twenty. Thirty." while the count badge ticks
// up by ten per tap.
//
// Four rounds: 3 clusters (30) → 5 (50) → 7 (70) → 10 (100). The cluster
// cards wrap so they use the full vertical area on a tablet and stay big
// enough to tap comfortably.
//
// Each cluster tapped sounds the next note up the scale, so counting by tens
// *sounds* like climbing. The lifecycle - intro, grading, celebration, the
// keeper's aside over the live meadow, the finale - is SanctuaryRoundShell's.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/long_parade_rounds.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../ui/common/count_badge.dart';
import '../../ui/common/glitter_burst.dart';
import '../../ui/common/target_hint.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import 'parade_pieces.dart';

class LongParadeRunner extends StatelessWidget {
  const LongParadeRunner({
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
      roundCount: kLongParadeRounds.length,
      conceptIdFor: (_) => 'K.CC.1',
      introLine: kLongParadeIntro,
      keeperLineFor: (i) => kLongParadeRounds[i].keeperLine,
      finalLine: kLongParadeFinal,
      skipIntro: skipIntro,
      celebrationHold: const Duration(seconds: 1),
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.countingParadeMeadow,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => LongParadeRoundBody(c: c),
    );
  }
}

/// One round: tap each group of ten, counting by tens.
class LongParadeRoundBody extends ConsumerStatefulWidget {
  const LongParadeRoundBody({super.key, required this.c});

  final RoundContext c;

  @override
  ConsumerState<LongParadeRoundBody> createState() =>
      _LongParadeRoundBodyState();
}

class _LongParadeRoundBodyState extends ConsumerState<LongParadeRoundBody>
    with TimerScope<LongParadeRoundBody> {
  late final LongParadeRound _round = kLongParadeRounds[widget.c.index];
  final Set<int> _tapped = <int>{};

  /// A counted cluster wanders off, so she stops re-tapping a group she has
  /// already counted.
  final Set<int> _exited = <int>{};
  final Map<int, int> _bursts = <int, int>{};
  int? _hinted;
  HintLadder? _hints;
  bool _done = false;

  bool get _open => !_done && !widget.c.locked;
  bool get _allTapped => _tapped.length == _round.clusterCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(longParadeCountingPrompt(_round));
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  int? get _nextUntapped {
    for (var i = 0; i < _round.clusterCount; i++) {
      if (!_tapped.contains(i)) return i;
    }
    return null;
  }

  /// There is no wrong cluster to tap here, so being stuck looks like doing
  /// nothing at all - exactly the state that used to produce no response.
  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextUntapped;
    if (next == null) return;
    answerTargetHint(
      level,
      ring: () => setState(() => _hinted = next),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      demonstrate: () => _tap(next, fromHint: true),
    );
  }

  void _tap(int i, {bool fromHint = false}) {
    if (!_open || _tapped.contains(i)) return;
    setState(() {
      _tapped.add(i);
      _bursts[i] = (_bursts[i] ?? 0) + 1;
      _hinted = null;
    });
    // A hint-driven tap must not reset the ladder, or a stalled kid would be
    // demonstrated at forever instead of the round resolving as a soft pass.
    if (!fromHint) _hints?.poke();
    final n = _tapped.length;
    // Same pitch ladder as counting by ones: ten, twenty, thirty each sound a
    // step higher, so counting by tens is audibly the same kind of climb.
    countAloud(
      widget.c.say,
      ref.read(feedbackEngineProvider),
      step: n,
      value: n * 10,
      fromHint: fromHint,
    );
    after(const Duration(milliseconds: 1100), () {
      setState(() => _exited.add(i));
    });
  }

  void _onDone() {
    if (_done || !_allTapped) return;
    setState(() => _done = true);
    _hints?.pause();
    // Every cluster is a correct target, so only help separates a clean
    // round from a soft one (adaptive-scaffolding.md §Hint Layer).
    widget.c.finish(gradeRound(helped: (_hints?.hintsUsed ?? 0) > 0));
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.c.index;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              CountBadge(
                value: _tapped.length * 10,
                target: _round.totalCreatures,
                size: CountBadgeSize.small,
              ),
              const SizedBox(height: 12),
              Expanded(
                // The ten-cluster round overflows the natural Wrap height,
                // so it scrolls on a small device.
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (var i = 0; i < _round.clusterCount; i++)
                          _ClusterCard(
                            key: ValueKey('long-parade-r$index-cluster-$i'),
                            spriteAsset: _round.species.spriteAsset,
                            tapped: _tapped.contains(i),
                            gone: _exited.contains(i),
                            hinted: _hinted == i,
                            burstCounter: _bursts[i] ?? 0,
                            onTap: (!_open || _exited.contains(i))
                                ? null
                                : () => _tap(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        ParadeDoneShelf(
          arrowKey: const ValueKey('long-parade-done-arrow'),
          visible: _allTapped && !_done,
          idleHintText: kLongParadeDoneHint,
          onDone: _onDone,
        ),
      ],
    );
  }
}

/// One group-of-ten card — 2 cols × 5 rows of creature sprites with a
/// "10" label and a tap-to-count interaction.
class _ClusterCard extends StatelessWidget {
  const _ClusterCard({
    super.key,
    required this.spriteAsset,
    required this.tapped,
    required this.gone,
    required this.hinted,
    required this.burstCounter,
    required this.onTap,
  });

  final String spriteAsset;
  final bool tapped;

  /// Once true the cluster slides off-screen + fades. Hit-testing is
  /// already disabled by the parent passing `onTap: null`.
  final bool gone;

  /// The hint ladder is pointing here. Same soft amber glow AnimatedFawn uses
  /// for its `pointed` state, so help looks the same everywhere in the game.
  final bool hinted;

  final int burstCounter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInQuart,
      offset: gone ? const Offset(2.0, 0) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: gone ? 0 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: tapped || hinted ? 0.75 : 0.55,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: tapped || hinted
                      ? const [
                          BoxShadow(
                            color: Colors.amber,
                            blurRadius: 26,
                            spreadRadius: 3,
                          ),
                        ]
                      : const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TenClusterGrid(
                      spriteAsset: spriteAsset,
                      spriteSize: 44,
                      gap: 6,
                      rowGap: 2,
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tapped
                            ? Colors.amber.shade100
                            : Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '10',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (burstCounter > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey('long-parade-cluster-burst-$burstCounter'),
                      maxRadius: 110,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
