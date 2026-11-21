// CountingParadeRunner — the Counting Parade's sub-mode dispatcher, and
// CountTheParadeRunner, its multi-round K.CC.4a practice.
//
// The kid counts a sequence of creature groups. Each round opens on a card
// that names the creature, then she touches each one while the narrator
// counts, and presses Done. The lifecycle - the keeper's intro, grading into
// mastery and coins, the progress bar, the celebration, the keeper's aside
// over the live meadow between rounds, the finale - is SanctuaryRoundShell's.
//
// Round content comes from ParadeRoundPlanner, seeded off the session, so the
// species order and counts differ between visits. Lesson JSON drives it via
// `youDo.roundParameters`. Pattern doc: specs/shared/counting-sequence.md.
//
// The opt-in "count to 100" challenge that used to fire at the end of this
// sub-mode now lives at the end of the activity's chain as its own
// `tens-parade` sub-mode — see TensParadeRunner. The pattern going forward
// is: challenge modes live at the end of the lesson chain, unlocked after
// every regular sub-mode is done.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/parade_species.dart';
import '../../data/round_pick.dart';
import '../../data/warm_lines.dart';
import '../../engines/activity_runner/round_plan.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../models/buddy_mood.dart';
import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../../ui/characters/animated_fawn.dart';
import '../../ui/characters/buddy_companion.dart';
import '../../ui/common/answer_feedback.dart';
import '../../ui/common/count_badge.dart';
import '../../ui/common/timer_scope.dart';
import '../../ui/rewards/reveal_card.dart';
import '../../ui/round/sanctuary_round_shell.dart';
import '../activity_ids.dart';
import '../sub_mode_ids.dart';
import 'count_forward_from_n_runner.dart';
import 'count_on_by_ones_runner.dart';
import 'count_out_n_runner.dart';
import 'long_parade_runner.dart';
import 'parade_pieces.dart';
import 'tens_parade_runner.dart';

/// How big the Buddy standing in the meadow is.
///
/// It was 150 in a bottom corner and read as a sticker on the frame rather
/// than a character in the scene — which defeats the point of putting the
/// companion on the playfield at all. Bigger, and it walks (see
/// `_buddyStopFor`), so it is now the thing on screen that moves when
/// nothing else does.
const double _kBuddySize = 208;

/// How long Buddy takes to cross the meadow to the creature it is pointing at.
///
/// Slow enough to be a journey she can watch and follow — the whole value of
/// the hint is that she sees where help is going.
const Duration _kBuddyWalk = Duration(milliseconds: 850);

/// Holds the bouncing coin on screen this long after the final round before
/// the keeper's reward beat. Between rounds there is no hold at all: the
/// keeper's aside goes up as Done is pressed, and her line waits for the last
/// count to finish rather than cutting it off.
const Duration _kFinalCelebrationHold = Duration(seconds: 2);

/// Long enough for her to see Buddy touch the creature and the count tick
/// over, short enough that Buddy is out of the way before she reaches for
/// the next one.
const Duration _kBuddyLingerAfterDemo = Duration(milliseconds: 1100);

/// Top-level Counting Parade runner. Dispatches on `subMode` to the body for
/// that sub-mode; every one of them is a SanctuaryRoundShell, and the host's
/// `onSequenceComplete` fires when the sub-mode's sequence wraps.
class CountingParadeRunner extends StatelessWidget {
  const CountingParadeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = CountingParadeModes.countTheParade,
    this.roundParameters,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  /// Raw `phases.youDo.roundParameters` from the lesson that handed off here.
  /// Null on a direct tap from the Sanctuary map, in which case the planner's
  /// defaults apply. Only count-the-parade consumes it so far.
  final Map<String, dynamic>? roundParameters;

  @override
  Widget build(BuildContext context) {
    switch (subMode) {
      case CountingParadeModes.countForwardFromN:
        return CountForwardFromNRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case CountingParadeModes.countOutN:
        return CountOutNRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case CountingParadeModes.longParade:
        return LongParadeRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case CountingParadeModes.countOnByOnes:
        return CountOnByOnesRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case CountingParadeModes.tensParade:
        return TensParadeRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case CountingParadeModes.countTheParade:
      default:
        return CountTheParadeRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
          roundParameters: roundParameters,
        );
    }
  }
}

class CountTheParadeRunner extends ConsumerStatefulWidget {
  const CountTheParadeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.roundParameters,
  });

  /// Fires once every planned round has been counted and the final beat
  /// dismissed. Host shows the round-complete sheet.
  final VoidCallback onSequenceComplete;

  /// When true, jump straight to the first round — used after a lesson
  /// hand-off where the keeper intro has already played.
  final bool skipIntro;

  /// See CountingParadeRunner.roundParameters.
  final Map<String, dynamic>? roundParameters;

  @override
  ConsumerState<CountTheParadeRunner> createState() =>
      _CountTheParadeRunnerState();
}

class _CountTheParadeRunnerState extends ConsumerState<CountTheParadeRunner> {
  late final ParadeRoundParameters _params =
      ParadeRoundParameters.fromJson(widget.roundParameters);

  /// The rounds for this visit, planned once. Seeding off the session means
  /// the order is stable for the whole visit (a rebuild cannot reshuffle
  /// mid-round) but differs the next time she plays; tests pin it by
  /// overriding sessionIdProvider.
  ///
  /// `streak` feeds the invisible session-level escalation in
  /// adaptive-scaffolding.md: a child who is finding this easy gets slightly
  /// bigger groups without ever being told she levelled up.
  late final List<ParadeRound> _rounds = const ParadeRoundPlanner().plan(
    params: _params,
    seed: roundSeed(
      ref.read(sessionIdProvider),
      CountingParadeModes.countTheParade,
    ),
    streak: ref.read(kidProgressProvider)['K.CC.4a']?.currentStreak ?? 0,
  );

  /// Set once the last round is on screen, which is when the celebration
  /// hold changes from none to the final two-second beat.
  bool _onFinalRound = false;

  @override
  Widget build(BuildContext context) {
    final first = _rounds.first;
    return SanctuaryRoundShell(
      activityId: ActivityIds.countingParade,
      roundCount: _rounds.length,
      conceptIdFor: (_) => 'K.CC.4a',
      introLine: paradeIntroDialog(
        count: first.targetCount,
        species: first.species,
      ),
      // Generated rather than authored per-species, because a shuffled order
      // can't use a hardcoded "now the gryphons". It carries the count, so it
      // is the only thing said at the round boundary.
      keeperLineFor: (i) => paradeTransitionLine(
        count: _rounds[i].targetCount,
        done: _rounds[i].species,
        rotation: i,
      ),
      finalLine: kParadeRewardLine,
      skipIntro: widget.skipIntro,
      celebrationHold: _onFinalRound ? _kFinalCelebrationHold : Duration.zero,
      // This round's Buddy walks the meadow, so it draws its own.
      showBuddy: false,
      onSequenceComplete: widget.onSequenceComplete,
      background: Image.asset(
        AssetPaths.countingParadeMeadow,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) {
        if (c.index == c.count - 1 && !_onFinalRound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _onFinalRound = true);
          });
        }
        return ParadeRoundBody(
          c: c,
          round: _rounds[c.index],
          hintThresholds: _params.hints,
        );
      },
    );
  }
}

/// One round of the parade: meet the creature, touch each one, press Done.
class ParadeRoundBody extends ConsumerStatefulWidget {
  const ParadeRoundBody({
    super.key,
    required this.c,
    required this.round,
    required this.hintThresholds,
  });

  final RoundContext c;
  final ParadeRound round;
  final HintThresholds hintThresholds;

  @override
  ConsumerState<ParadeRoundBody> createState() => _ParadeRoundBodyState();
}

class _ParadeRoundBodyState extends ConsumerState<ParadeRoundBody>
    with TimerScope<ParadeRoundBody> {
  /// True while the card naming this round's creature is up.
  ///
  /// A pre-reader had no way to learn what she was looking at: she would count
  /// fawns for a round and never find out they were fawns, because the sprite
  /// is a picture of an animal and nothing named it. Naming it first also
  /// gives the count something to be *about*. It advances itself, like the
  /// between-round aside; a tap skips it early.
  bool _card = true;
  bool _done = false;

  final Set<int> _tapped = <int>{};

  /// Counted creatures wander off a beat after their tap, so a kid who keeps
  /// trying to re-tap "the same one" sees it leave and looks for the rest.
  final Set<int> _exited = <int>{};

  /// Decor slot -> wrong taps on it, driving the shake.
  final Map<int, int> _wrongTokens = <int, int>{};

  /// Wrong taps this round. Together with help they decide whether the round
  /// resolves clean, soft, or as a failure.
  int _wrongTaps = 0;
  int _missRotation = 0;

  /// Creature the hint ladder is glowing, if any.
  int? _hinted;

  /// Where Buddy has walked to, or null when it is standing at home.
  Offset? _buddyVisit;

  /// Walks Buddy back after it has demonstrated a tap. A demonstration is
  /// the one hint the child does not answer, so nothing else sends Buddy home.
  Timer? _buddyReturn;
  Timer? _cardTimer;
  HintLadder? _hints;

  /// The meadow, for converting a creature's position into the coordinates
  /// Buddy walks in.
  final GlobalKey _fieldKey = GlobalKey();

  /// One per creature, so Buddy can be sent to a specific creature rather
  /// than to a guess about where it is.
  final Map<int, GlobalKey> _creatureKeys = <int, GlobalKey>{};

  GlobalKey _creatureKey(int index) =>
      _creatureKeys[index] ??= GlobalKey(debugLabel: 'parade-creature-$index');

  ParadeSpecies get _species => widget.round.species;
  bool get _open => !_card && !_done && !widget.c.locked;
  bool get _allTapped => _tapped.length == widget.round.targetCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showCard();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _showCard() {
    final line = paradeSpeciesIntroLine(_species);
    ref.narration.say(
      line,
      cueId: 'parade:species-intro-r${widget.c.index}',
      speaker: kKeeperSpeaker,
      caption: false,
    );
    // Held long enough to outlast the spoken line rather than the read — the
    // same rule KeeperAside uses, and for the same reason: for a pre-reader
    // the voice is the whole message.
    _cardTimer = after(
      Duration(milliseconds: (line.length * 70).clamp(2400, 5000)),
      _startCounting,
    );
  }

  void _startCounting() {
    _cardTimer?.cancel();
    if (!mounted || !_card) return;
    setState(() => _card = false);
    _hints = HintLadder(thresholds: widget.hintThresholds, onLevel: _onHint)
      ..start();
    widget.c.say(paradeCountingPrompt(_species));
  }

  /// Escalating help for a kid who has gone quiet. Its own handler rather
  /// than answerTargetHint, because here the help walks: Buddy goes to the
  /// creature.
  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextUntapped;
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        // Glow only, no words. She may simply be thinking, and interrupting a
        // thinking child is worse than waiting.
        setState(() => _hinted = next);
      case HintLevel.point:
        // Buddy walks over and touches it. A friend noticing reads very
        // differently from the game announcing that you're failing — and a
        // Buddy that *goes* to the creature says which one without a word.
        setState(() {
          _hinted = next;
          _buddyVisit = _buddyStopFor(next);
        });
        feedback.hint();
        widget.c.say(warmHintLine(2), replay: false);
      case HintLevel.demonstrate:
        // Do one for her. Buddy is already standing over it from the rung
        // before, so the tap reads as Buddy doing it.
        setState(() => _buddyVisit = _buddyStopFor(next));
        feedback.hint();
        _buddyReturn?.cancel();
        _buddyReturn = after(_kBuddyLingerAfterDemo, _sendBuddyHome);
        widget.c.say(warmHintLine(3), replay: false);
        _tap(next, fromHint: true);
    }
  }

  /// Where Buddy should stand to be touching creature [index], in meadow
  /// coordinates, or null if the creature is not laid out yet.
  ///
  /// Reads the real position off the laid-out widget rather than recomputing
  /// the Wrap's arithmetic, because the Wrap reflows with the window and any
  /// second guess at it would drift — a Buddy pointing at empty grass is worse
  /// than no hint at all.
  Offset? _buddyStopFor(int index) {
    final field = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final target =
        _creatureKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
    if (field == null || target == null) return null;
    if (!field.hasSize || !target.hasSize) return null;
    final centre = field.globalToLocal(
      target.localToGlobal(target.size.center(Offset.zero)),
    );
    // Slightly left of and below the creature, so the sprite overlaps it the
    // way a child's hand would rather than covering it.
    final stop = Offset(
      centre.dx - _kBuddySize * 0.62,
      centre.dy - _kBuddySize * 0.42,
    );
    return Offset(
      stop.dx.clamp(0.0, (field.size.width - _kBuddySize).clamp(0.0, 4000.0)),
      stop.dy.clamp(0.0, (field.size.height - _kBuddySize).clamp(0.0, 4000.0)),
    );
  }

  /// Buddy walks home. Called whenever the child does something, because help
  /// that stays parked over a creature after she has moved on is in the way.
  void _sendBuddyHome() {
    _buddyReturn?.cancel();
    _buddyReturn = null;
    if (_buddyVisit == null) return;
    setState(() => _buddyVisit = null);
  }

  int? get _nextUntapped {
    for (final cell in widget.round.cells) {
      final i = cell.creatureIndex;
      if (i != null && !_tapped.contains(i)) return i;
    }
    return null;
  }

  /// A tap on meadow decor — a butterfly, a frog, the watering can. The only
  /// wrong answer this round has, and the reason it can be failed at all.
  void _onDecorTap(int slot) {
    if (!_open) return;
    setState(() {
      _wrongTaps++;
      _wrongTokens[slot] = (_wrongTokens[slot] ?? 0) + 1;
    });
    _hints?.poke();
    ref.read(feedbackEngineProvider).wrong();
    widget.c.say(warmMissLine(_missRotation++), replay: false);
  }

  void _tap(int index, {bool fromHint = false}) {
    // One-to-one rule: a creature is counted once.
    if (!_open || _tapped.contains(index)) return;
    setState(() {
      _tapped.add(index);
      _hinted = null;
    });
    // A hint-driven tap must not reset the ladder, or a stuck kid would get
    // demonstrated at forever instead of the round resolving as a soft pass.
    if (!fromHint) {
      _hints?.poke();
      _sendBuddyHome();
    }
    // Each object in the count sounds a note one step up the scale, so the
    // child *hears* the quantity climb; every round restarts at the bottom.
    countAloud(
      widget.c.say,
      ref.read(feedbackEngineProvider),
      step: _tapped.length,
      value: _tapped.length,
      fromHint: fromHint,
    );
    after(const Duration(milliseconds: 900), () {
      setState(() => _exited.add(index));
    });
  }

  void _onDone() {
    if (_done || !_allTapped) return;
    setState(() => _done = true);
    _hints?.pause();
    // The real outcome: clean advances the promotion streak; a stumble or a
    // demonstration is a soft success (coins, no progress toward the next
    // layer); three wrong taps fail it, and two failures demote a layer.
    widget.c.finish(
      gradeRound(
        misses: _wrongTaps,
        helped: (_hints?.hintsUsed ?? 0) > 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = widget.round.cells;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Positioned from the top-left, so that walking to a creature and
        // standing at home are the same kind of value and one
        // AnimatedPositioned can carry it between them. The round already
        // sits above the caption band, so home is the bottom-left corner.
        final home = Offset(
          0,
          (constraints.maxHeight - _kBuddySize).clamp(0.0, double.infinity),
        );
        final buddyAt = _buddyVisit ?? home;
        return Stack(
          key: _fieldKey,
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CountBadge(
                        value: _tapped.length,
                        target: widget.round.targetCount,
                      ),
                      const Spacer(),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          for (var slot = 0; slot < cells.length; slot++)
                            if (cells[slot].isCreature)
                              KeyedSubtree(
                                key: _creatureKey(cells[slot].creatureIndex!),
                                child: _Creature(
                                  key: ValueKey(
                                    'fawn-${cells[slot].creatureIndex}',
                                  ),
                                  spriteAsset: _species.spriteAsset,
                                  tapped: _tapped
                                      .contains(cells[slot].creatureIndex),
                                  gone: _exited
                                      .contains(cells[slot].creatureIndex),
                                  pointed: _hinted == cells[slot].creatureIndex,
                                  onTap: () => _tap(cells[slot].creatureIndex!),
                                ),
                              )
                            else
                              _Decor(
                                key: ValueKey('decor-$slot'),
                                asset: cells[slot].decorAsset!,
                                wrongToken: _wrongTokens[slot] ?? 0,
                                onTap: () => _onDecorTap(slot),
                              ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                ParadeDoneShelf(
                  arrowKey: const ValueKey('parade-done-arrow'),
                  visible: _allTapped && !_done && !widget.c.locked,
                  idleHintText: kParadeDoneHint,
                  onDone: _onDone,
                ),
              ],
            ),
            // On the point rung of the hint ladder Buddy walks across the
            // meadow and stands over the creature she has missed. That is the
            // hint — the spoken line beside it is a warmth, but a child who
            // cannot read and may not be listening can still see where her
            // friend went.
            AnimatedPositioned(
              left: buddyAt.dx,
              top: buddyAt.dy,
              duration: _kBuddyWalk,
              curve: Curves.easeInOutCubic,
              // Standing over a creature, Buddy is pointing at the very
              // thing she is about to touch - so it lets the touch through
              // rather than taking it.
              child: IgnorePointer(
                ignoring: _buddyVisit != null,
                child: BuddyCompanion(
                  size: _kBuddySize,
                  // Face the way it is travelling, so walking back to its own
                  // corner doesn't read as moonwalking.
                  facing: buddyAt.dx >= home.dx
                      ? BuddyFacing.right
                      : BuddyFacing.left,
                ),
              ),
            ),
            // The card naming this round's creature, over the meadow it names
            // - the creatures are already there behind it, dimmed. Showing
            // them is the point: the card names what she can see, rather than
            // naming something and then producing it.
            if (_card)
              RevealCardStage(
                key: const ValueKey('parade-species-card'),
                animation: const AlwaysStoppedAnimation<double>(1),
                dim: 0.42,
                onTap: _startCounting,
                child: RevealCardFace(
                  eyebrow: "Look who's next!",
                  spriteAsset: _species.spriteAsset,
                  title: paradeSpeciesTitle(_species),
                  accent: AppColors.treasureGold,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A butterfly, frog, or watering can sitting in the meadow. Tapping one is
/// the wrong answer — and, crucially, the only way this round CAN be wrong.
///
/// The reaction is a shake and a colour-drain, never a red flash or a buzzer.
/// It exists so a wrong tap is distinguishable from the app having frozen,
/// which is what it looked like before any of this feedback existed.
class _Decor extends StatelessWidget {
  const _Decor({
    super.key,
    required this.asset,
    required this.wrongToken,
    required this.onTap,
  });

  final String asset;
  final int wrongToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnswerFeedback(
        wrongToken: wrongToken,
        child: SizedBox(
          width: 96,
          height: 120,
          child: Image.asset(asset, fit: BoxFit.contain),
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
    required this.gone,
    required this.onTap,
    this.pointed = false,
  });

  final String spriteAsset;
  final bool tapped;

  /// Hint ladder rung 1: a soft amber glow on the next creature to count.
  /// AnimatedFawn already implements this, so the hint costs nothing new.
  final bool pointed;

  /// Once true the creature wanders off-screen (slide right + fade out)
  /// and stops responding to taps so the kid quits re-tapping it.
  final bool gone;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: gone ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInQuart,
        offset: gone ? const Offset(2.2, 0) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 700),
          opacity: gone ? 0 : 1,
          child: AnimatedFawn(
            active: tapped,
            pointed: pointed,
            spriteAsset: spriteAsset,
          ),
        ),
      ),
    );
  }
}
