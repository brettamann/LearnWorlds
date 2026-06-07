// CountingParadeRunner — multi-round K.CC.4a practice.
//
// The kid counts a sequence of creature groups. Each round increments both
// the target count and the species; the keeper appears between rounds with a
// short transition line. Final round → onSequenceComplete fires, so the
// host (ActivityScreen) can show the round-complete sheet.
//
// Phases:
//   1. intro         — Keeper Wisp greets the kid. Skipped when the lesson
//                      hand-off already played the intro.
//   2. counting      — N current-creature sprites; tap each one, then Done.
//   3. interstitial  — Keeper appears with "Great! All N. Next: X" between
//                      rounds, including after the final round.
//
// Mastery + coins: each completed round fires
// `RoundCoordinator.resolveRound` so K.CC.4a streak and the wallet update
// per round, not per sequence. Pattern doc: specs/shared/counting-sequence.md.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import 'animated_fawn.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';

enum _Phase { intro, counting, celebrating, interstitial }

/// Holds the bouncing coin on screen this long after the final round before
/// the keeper interstitial appears with the reward message.
const Duration _kFinalCelebrationHold = Duration(seconds: 2);

/// Mirrors `RoundCoordinator._coinsPerRoundPass`. The final reward line
/// reports `_coinsPerRound * _paradeSequence.length` total coins; the
/// constant lives here too so the wording stays in sync if either side
/// changes. (Both sides should land in a shared reward config later.)
const int _coinsPerRound = 5;

class _ParadeCreature {
  const _ParadeCreature({
    required this.spriteAsset,
    required this.singularName,
    required this.pluralName,
    required this.keeperLine,
  });

  /// Sprite drawn during the round.
  final String spriteAsset;

  /// Lowercase singular, used in the counting prompt
  /// ("Touch each {singular} — one at a time.").
  final String singularName;

  /// Lowercase plural, used in the keeper's closing line for non-final rounds
  /// (kept available for future flavor; current keeperLine string already
  /// embeds the next creature's name).
  final String pluralName;

  /// The short keeper transition shown AFTER this creature's round finishes.
  /// For non-final rounds this introduces the next species; for the final
  /// round it's the celebratory wrap-up.
  final String keeperLine;
}

/// Counts run 3 → 10, one species per round. Kitten and puppy sprites ship in
/// the folder but stay off the parade — the Sanctuary's parade is mythical
/// creatures by design. Edit this list to extend the sequence; counts
/// auto-advance from `_startingCount` upward, capping at `_maxCount`.
const int _startingCount = 3;
const int _maxCount = 10;

const _paradeSequence = <_ParadeCreature>[
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeFawn,
    singularName: 'fawn',
    pluralName: 'fawns',
    keeperLine: 'Great! All three fawns. Now the gryphon babies.',
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeBabyGryphon,
    singularName: 'gryphon',
    pluralName: 'gryphons',
    keeperLine: 'Four gryphons! On to the baby dragons.',
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeBabyDragon,
    singularName: 'dragon',
    pluralName: 'dragons',
    keeperLine: "Five dragons! Let's check the unicorns.",
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeBabyUnicorn,
    singularName: 'unicorn',
    pluralName: 'unicorns',
    keeperLine: 'Six unicorns! Phoenix babies, please.',
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeBabyPhoenix,
    singularName: 'phoenix',
    pluralName: 'phoenixes',
    keeperLine: 'Seven phoenixes! Centaur babies next.',
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeBabyCentaur,
    singularName: 'centaur',
    pluralName: 'centaurs',
    keeperLine: 'Eight centaurs! The toucan babies are waiting.',
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeBabyToucan,
    singularName: 'toucan',
    pluralName: 'toucans',
    keeperLine: 'Nine toucans! Last group — the golden eggs.',
  ),
  _ParadeCreature(
    spriteAsset: AssetPaths.countingParadeGoldenEgg,
    singularName: 'golden egg',
    pluralName: 'golden eggs',
    keeperLine: 'All ten counted! Beautifully done.',
  ),
];

class CountingParadeRunner extends ConsumerStatefulWidget {
  const CountingParadeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  /// Fires once when every round in `_paradeSequence` has been counted +
  /// the final interstitial dismissed. Host shows the round-complete sheet.
  final VoidCallback onSequenceComplete;

  /// When true, jump straight to the first counting round — used after a
  /// lesson hand-off where the keeper intro has already played.
  final bool skipIntro;

  @override
  ConsumerState<CountingParadeRunner> createState() =>
      _CountingParadeRunnerState();
}

class _CountingParadeRunnerState extends ConsumerState<CountingParadeRunner> {
  Set<int> _tapped = <int>{};
  late _Phase _phase =
      widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Timer? _celebrationTimer;

  static const List<String> _spelled = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
  ];

  _ParadeCreature get _currentCreature => _paradeSequence[_roundIndex];
  int get _currentCount {
    final n = _startingCount + _roundIndex;
    return n > _maxCount ? _maxCount : n;
  }

  bool get _isLastRound => _roundIndex == _paradeSequence.length - 1;
  bool get _allTapped => _tapped.length == _currentCount;

  /// 0.0 → 1.0 over the full sequence. Drives the persistent progress bar.
  double get _sequenceProgress => _completedRounds / _paradeSequence.length;

  /// Reward line spoken by the keeper after the final celebration. Reports
  /// the total coins earned this visit so the kid hears the concrete result.
  String get _finalKeeperLine {
    final coins = _paradeSequence.length * _coinsPerRound;
    return 'Thank you, friend! Here are $coins coins from the Sanctuary.';
  }

  String get _introDialog {
    final n = _spelled.length > _currentCount
        ? _spelled[_currentCount].toLowerCase()
        : _currentCount.toString();
    return "Oh, thank goodness you're here. The fawns wander off every time I "
        'blink. Can you help me make sure all $n are still in the meadow?';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.intro) {
        _speakKeeperIntro();
      } else {
        _speakCountingPrompt();
      }
    });
  }

  void _speakKeeperIntro() {
    // Keeper line is shown in the speech bubble — skip the bottom caption
    // overlay so the same text doesn't render twice.
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _introDialog,
            cueId: 'parade:intro',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _speakCountingPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text:
                'Touch each ${_currentCreature.singularName} — one at a time.',
            cueId: 'parade:counting-prompt-r$_roundIndex',
          ),
        );
  }

  void _startCounting() {
    setState(() => _phase = _Phase.counting);
    _speakCountingPrompt();
  }

  void _tap(int index) {
    if (_tapped.contains(index)) return; // one-to-one rule: ignore double-taps
    setState(() => _tapped.add(index));
    final spoken = _spelled.length > _tapped.length
        ? _spelled[_tapped.length]
        : _tapped.length.toString();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: '$spoken.',
            cueId: 'parade:tap-r$_roundIndex-${_tapped.length}',
          ),
        );
  }

  void _finishRound() {
    if (!_allTapped) return;
    // Record the round outcome: mastery streak + coins per round, per spec
    // (each round-pass is a success event in adaptive-scaffolding.md).
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.4a',
          success: true,
        );
    setState(() => _completedRounds++);

    if (_isLastRound) {
      // Final round: hold on the bouncing-coin celebration for a beat, then
      // let the keeper step in with the reward line. The hold lives in
      // _kFinalCelebrationHold so tuning is in one place per the
      // progress-bar-to-reward pattern.
      setState(() => _phase = _Phase.celebrating);
      _celebrationTimer = Timer(_kFinalCelebrationHold, () {
        if (!mounted) return;
        setState(() => _phase = _Phase.interstitial);
        ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
              NarrationLine(
                text: _finalKeeperLine,
                cueId: 'parade:reward',
                speaker: 'sanctuary-keeper-mystic',
              ),
            );
      });
      return;
    }

    setState(() => _phase = _Phase.interstitial);
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _currentCreature.keeperLine,
            cueId: 'parade:interstitial-r$_roundIndex',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  void _advanceFromInterstitial() {
    if (_isLastRound) {
      widget.onSequenceComplete();
      return;
    }
    setState(() {
      _roundIndex++;
      _tapped = <int>{};
      _phase = _Phase.counting;
    });
    _speakCountingPrompt();
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's count!",
          startButtonKey: const ValueKey('parade-start-button'),
          onStart: _startCounting,
        ),
      _Phase.counting => _CountingLayer(
          spriteAsset: _currentCreature.spriteAsset,
          targetCount: _currentCount,
          tapped: _tapped,
          onTap: _tap,
          onDone: _finishRound,
          allTapped: _allTapped,
        ),
      _Phase.celebrating => _CountingLayer(
          spriteAsset: _currentCreature.spriteAsset,
          targetCount: _currentCount,
          tapped: _tapped,
          onTap: (_) {},
          onDone: () {},
          // Suppress the Done button while the coin bounces — input is locked
          // during the celebration beat.
          allTapped: false,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _isLastRound
              ? _finalKeeperLine
              : _currentCreature.keeperLine,
          startLabel: _isLastRound ? 'Finish' : "Let's go!",
          startButtonKey: const ValueKey('parade-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        const _MeadowBackground(),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ProgressBarToReward(
                  progress: _sequenceProgress,
                  celebrate: _phase == _Phase.celebrating,
                ),
              ),
              Expanded(child: phaseContent),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeadowBackground extends StatelessWidget {
  const _MeadowBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetPaths.countingParadeMeadow,
      fit: BoxFit.cover,
    );
  }
}

class _CountingLayer extends StatelessWidget {
  const _CountingLayer({
    required this.spriteAsset,
    required this.targetCount,
    required this.tapped,
    required this.onTap,
    required this.onDone,
    required this.allTapped,
  });

  final String spriteAsset;
  final int targetCount;
  final Set<int> tapped;
  final ValueChanged<int> onTap;
  final VoidCallback onDone;
  final bool allTapped;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _CountBadge(value: tapped.length, target: targetCount),
            const Spacer(),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: List.generate(targetCount, (i) {
                return _Creature(
                  key: ValueKey('fawn-$i'),
                  spriteAsset: spriteAsset,
                  tapped: tapped.contains(i),
                  onTap: () => onTap(i),
                );
              }),
            ),
            const Spacer(),
            // Big wiggling arrow only appears once the kid has tapped every
            // creature — same affordance the LessonScreen Continue uses,
            // per specs/shared/ui-affordances.md.
            SizedBox(
              height: 170,
              child: allTapped
                  ? Center(
                      child: NextArrowButton(
                        key: const ValueKey('parade-done-arrow'),
                        onPressed: onDone,
                        label: 'Done',
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value, required this.target});

  final int value;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$value / $target',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _Creature extends StatelessWidget {
  const _Creature({
    super.key,
    required this.spriteAsset,
    required this.tapped,
    required this.onTap,
  });

  final String spriteAsset;
  final bool tapped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedFawn(
        active: tapped,
        spriteAsset: spriteAsset,
      ),
    );
  }
}
