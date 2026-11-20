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
//   3. transition    — Keeper speaks over the LIVE meadow in a non-blocking
//                      aside that retires itself and advances the round. No
//                      tap required; play never stops between rounds.
//   4. interstitial  — Blocking, final round only: the reward beat.
//
// Round content comes from ParadeRoundPlanner, seeded off the session, so the
// species order and counts differ between visits. Lesson JSON drives it via
// `youDo.roundParameters`.
//
// Mastery + coins: each completed round fires
// `RoundCoordinator.resolveRound` so K.CC.4a streak and the wallet update
// per round, not per sequence. Pattern doc: specs/shared/counting-sequence.md.
//
// The opt-in "count to 100" challenge that used to fire at the end of this
// sub-mode now lives at the end of the activity's chain as its own
// `tens-parade` sub-mode — see TensParadeRunner. The pattern going forward
// is: challenge modes live at the end of the lesson chain, unlocked after
// every regular sub-mode is done.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/number_words.dart';
import '../../data/parade_species.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/activity_runner/round_plan.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../models/buddy_mood.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/progress_provider.dart';
import '../../providers/session_provider.dart';
import 'animated_fawn.dart';
import 'answer_feedback.dart';
import 'buddy_companion.dart';
import 'caption_overlay.dart';
import 'continue_arrow_shelf.dart';
import 'count_forward_from_n_runner.dart';
import 'count_on_by_ones_runner.dart';
import 'count_out_n_runner.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'long_parade_runner.dart';
import 'next_arrow_button.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';
import 'reveal_card.dart';
import 'tens_parade_runner.dart';

enum _Phase {
  intro,

  /// A card naming the creature this round, before any counting starts.
  ///
  /// A pre-reader had no way to learn what she was looking at: she would count
  /// fawns for a round and never find out they were fawns, because the sprite
  /// is a picture of an animal and nothing named it. Naming it first also
  /// gives the count something to be *about*.
  ///
  /// It advances itself, like the between-round aside — a card she has to
  /// dismiss five times a sitting would put back a chunk of the stop-start
  /// rhythm the KeeperAside work removed. A tap skips it early.
  speciesIntro,

  counting,

  /// Between rounds. The meadow stays on screen and the keeper speaks over it
  /// in a non-blocking aside, which then advances the round by itself.
  ///
  /// This replaced a full-screen modal that needed an arrow tap — roughly
  /// sixteen of them per sub-mode. Removing that is the single biggest pacing
  /// change in the activity: play now runs continuously from the first tap to
  /// the last instead of stopping every five taps.
  transition,

  celebrating,

  /// The final beat only. This one is still blocking on purpose — it is the
  /// reward payoff specs/shared/activity-progress-bar.md requires, and it is
  /// meant to interrupt.
  interstitial,
}

/// How big the Buddy standing in the meadow is.
///
/// It was 150 in a bottom corner and read as a sticker on the frame rather
/// than a character in the scene — which defeats the point of putting the
/// companion on the playfield at all. Bigger, and it walks (see
/// `_buddyVisitOffset`), so it is now the thing on screen that moves when
/// nothing else does.
const double _kBuddySize = 208;

/// Buddy's resting spot, as an inset from the bottom-left of the playfield.
///
/// Left rather than right because the Continue arrow owns the right shelf. The
/// vertical inset clears the caption bar: at 8px Buddy stood at the very
/// bottom of the meadow with the semi-transparent black band lying across it,
/// so the one character in the scene spent every round behind a subtitle.
const Offset _kBuddyHomeInset = Offset(12, kCaptionBandClearance);

/// How long Buddy takes to cross the meadow to the creature it is pointing at.
///
/// Slow enough to be a journey she can watch and follow — the whole value of
/// the hint is that she sees where help is going.
const Duration _kBuddyWalk = Duration(milliseconds: 850);

/// Holds the bouncing coin on screen this long after the final round before
/// the keeper interstitial appears with the reward message.
const Duration _kFinalCelebrationHold = Duration(seconds: 2);

/// Sub-modes the Counting Parade activity supports.
const String kCountingParadeSubModeCountTheParade = 'count-the-parade';
const String kCountingParadeSubModeCountForwardFromN = 'count-forward-from-n';
const String kCountingParadeSubModeCountOutN = 'count-out-n';
const String kCountingParadeSubModeLongParade = 'long-parade';
const String kCountingParadeSubModeCountOnByOnes = 'count-on-by-ones';
const String kCountingParadeSubModeTensParade = 'tens-parade';

/// Top-level Counting Parade runner. Dispatches on `subMode` to one of
/// four bodies: the existing 8-round parade (K.CC.4a/b), the count-on
/// rounds (K.CC.2), the count-out drag rounds (K.CC.5), or the bigger-
/// numbers parade (K.CC.1). All four resolve through RoundCoordinator
/// for mastery + coins; the host's `onSequenceComplete` fires when the
/// full sub-mode sequence wraps.
class CountingParadeRunner extends StatelessWidget {
  const CountingParadeRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = kCountingParadeSubModeCountTheParade,
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
      case kCountingParadeSubModeCountForwardFromN:
        return CountForwardFromNRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case kCountingParadeSubModeCountOutN:
        return CountOutNRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case kCountingParadeSubModeLongParade:
        return LongParadeRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case kCountingParadeSubModeCountOnByOnes:
        return CountOnByOnesRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case kCountingParadeSubModeTensParade:
        return TensParadeRunner(
          onSequenceComplete: onSequenceComplete,
          skipIntro: skipIntro,
        );
      case kCountingParadeSubModeCountTheParade:
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

  /// Fires once every planned round has been counted and the final
  /// interstitial dismissed. Host shows the round-complete sheet.
  final VoidCallback onSequenceComplete;

  /// When true, jump straight to the first counting round — used after a
  /// lesson hand-off where the keeper intro has already played.
  final bool skipIntro;

  /// See CountingParadeRunner.roundParameters.
  final Map<String, dynamic>? roundParameters;

  @override
  ConsumerState<CountTheParadeRunner> createState() =>
      _CountingParadeRunnerState();
}

class _CountingParadeRunnerState extends ConsumerState<CountTheParadeRunner> {
  Set<int> _tapped = <int>{};
  // Counted creatures wander off the screen a beat after their tap so kids
  // who keep trying to re-tap "the same one" see it leave and look for the
  // remaining ones. Each tap gets its own delayed exit timer (so a fast
  // tapper doesn't sync them all into a wave).
  Set<int> _exited = <int>{};
  final Map<int, Timer> _exitTimers = <int, Timer>{};
  late _Phase _phase = widget.skipIntro ? _Phase.counting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Timer? _celebrationTimer;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Decor slot -> number of wrong taps on it, driving the shake.
  final Map<int, int> _wrongTokens = <int, int>{};

  /// Wrong taps and demonstrations this round. Together they decide whether
  /// the round resolves clean, soft, or as a failure — which is what finally
  /// gives the mastery ladder something to react to.
  int _wrongTaps = 0;
  int _missRotation = 0;

  /// Creature the hint ladder is glowing, if any.
  int? _hintedIndex;

  /// Where Buddy has walked to, in playfield coordinates, or null when it is
  /// standing at home.
  Offset? _buddyVisit;

  /// Set while the species card is up, so a second tap cannot skip two beats.
  Timer? _speciesIntroTimer;

  /// Walks Buddy back after it has demonstrated a tap.
  ///
  /// A demonstration is the one hint the child does not answer, so nothing
  /// else sends Buddy home afterwards and it stood over the creature it had
  /// just counted for the rest of the round.
  Timer? _buddyReturnTimer;

  /// The playfield, for converting a creature's position into the coordinate
  /// space Buddy is positioned in.
  final GlobalKey _fieldKey = GlobalKey();

  /// One per creature index this round, so Buddy can be sent to a specific
  /// creature rather than to a guess about where it is.
  final Map<int, GlobalKey> _creatureKeys = <int, GlobalKey>{};

  GlobalKey _creatureKey(int index) =>
      _creatureKeys[index] ??= GlobalKey(debugLabel: 'parade-creature-$index');

  HintLadder? _hints;

  /// Resolved eagerly in initState, not lazily: `ref.read` throws once
  /// disposal has begun, and dispose() is exactly where this is needed — the
  /// music bed has to stop when the child leaves, rather than following them
  /// back out to the Sanctuary map.
  SfxEngine? _sfxForDispose;

  /// The rounds for this visit. Built once in initState from the lesson's
  /// `roundParameters` (or defaults on a direct map tap), shuffled against a
  /// session-derived seed so a replay isn't the same eight rounds again.
  late final List<ParadeRound> _rounds;

  ParadeRound get _round => _rounds[_roundIndex];
  ParadeSpecies get _currentCreature => _round.species;
  int get _currentCount => _round.targetCount;

  bool get _isLastRound => _roundIndex == _rounds.length - 1;
  bool get _allTapped => _tapped.length == _currentCount;

  double get _sequenceProgress => _completedRounds / _rounds.length;

  /// Reward line spoken by the keeper after the final celebration. Reports
  /// the total coins earned this visit so the kid hears the concrete result.
  String get _finalKeeperLine =>
      paradeRewardLine(_rounds.length * kCoinsForCleanRound);

  /// The between-round line. Generated rather than authored per-species,
  /// because a shuffled order can't use a hardcoded "now the gryphons".
  String get _transitionLine => _isLastRound
      ? paradeFinalLine(count: _currentCount, done: _currentCreature)
      : paradeTransitionLine(
          count: _currentCount,
          done: _currentCreature,
          rotation: _roundIndex,
        );

  String get _introDialog =>
      paradeIntroDialog(count: _currentCount, species: _currentCreature);

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    // The lesson JSON has always scripted a music bed for this scene; until
    // now nothing consumed it and the activity played in total silence.
    unawaited(_sfxForDispose!.startMusicBed(kDefaultMusicBed));

    // Round content is planned once, here. Seeding off the session id means
    // the order is stable for the whole visit (so a rebuild can't reshuffle
    // mid-round) but differs the next time she plays. Tests pin it by
    // overriding sessionIdProvider.
    //
    // `streak` feeds the invisible session-level escalation in
    // adaptive-scaffolding.md: a child who is finding this easy gets slightly
    // bigger groups without ever being told she levelled up.
    final streak = ref.read(kidProgressProvider)['K.CC.4a']?.currentStreak ?? 0;
    _rounds = const ParadeRoundPlanner().plan(
      params: ParadeRoundParameters.fromJson(widget.roundParameters),
      seed: ref.read(sessionIdProvider).hashCode,
      streak: streak,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.intro) {
        _speakKeeperIntro();
      } else {
        _beginRound();
      }
    });
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(
      thresholds: ParadeRoundParameters.fromJson(widget.roundParameters).hints,
      onLevel: _onHintLevel,
    )..start();
  }

  /// Escalating help for a kid who has gone quiet. Before this there was no
  /// math hint anywhere in the game — only the navigation arrow's idle wiggle
  /// — so a stuck child could sit indefinitely with nothing happening.
  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.counting) return;
    final next = _nextUntapped();
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);

    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        // Glow only, no words. She may simply be thinking, and interrupting a
        // thinking child is worse than waiting.
        setState(() => _hintedIndex = next);
      case HintLevel.point:
        // Buddy walks over and touches it. Routing help through the companion
        // is deliberate: a friend noticing reads very differently from the
        // game announcing that you're failing — and a Buddy that *goes* to the
        // creature says which one without a word, which matters more here than
        // anywhere, because the child cannot read the hint that comes with it.
        setState(() {
          _hintedIndex = next;
          _buddyVisit = _buddyStopFor(next);
        });
        feedback.hint();
        ref.narration
            .say(warmHintLine(2), cueId: 'parade:hint-point-r$_roundIndex');
      case HintLevel.demonstrate:
        // Do one for her. "Prefer demoting to skipping" — a kid learns nothing
        // from being stuck, and there is deliberately no skip button. Buddy is
        // already standing over it from the rung before, so the tap reads as
        // Buddy doing it rather than the creature counting itself.
        setState(() => _buddyVisit = _buddyStopFor(next));
        feedback.hint();
        _buddyReturnTimer?.cancel();
        _buddyReturnTimer = Timer(_kBuddyLingerAfterDemo, () {
          if (!mounted) return;
          _sendBuddyHome();
        });
        ref.narration
            .say(warmHintLine(3), cueId: 'parade:hint-demo-r$_roundIndex');
        _tap(next, fromHint: true);
    }
  }

  /// Where Buddy should stand to be touching creature [index], in playfield
  /// coordinates, or null if the creature is not on screen yet.
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
    // Stand slightly left of and below the creature, so the sprite overlaps it
    // the way a child's hand would rather than covering it.
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
    _buddyReturnTimer?.cancel();
    _buddyReturnTimer = null;
    if (_buddyVisit == null) return;
    setState(() => _buddyVisit = null);
  }

  /// Long enough for her to see Buddy touch the creature and the count tick
  /// over, short enough that Buddy is out of the way before she reaches for
  /// the next one.
  static const Duration _kBuddyLingerAfterDemo = Duration(milliseconds: 1100);

  int? _nextUntapped() {
    for (final cell in _round.cells) {
      final i = cell.creatureIndex;
      if (i != null && !_tapped.contains(i)) return i;
    }
    return null;
  }

  /// A tap on meadow decor — a butterfly, a frog, the watering can. The only
  /// wrong answer this round has, and the reason it can be failed at all.
  void _onDecorTap(int slot) {
    if (_phase != _Phase.counting) return;
    setState(() {
      _wrongTaps++;
      _wrongTokens[slot] = (_wrongTokens[slot] ?? 0) + 1;
    });
    _hints?.poke();
    ref.read(feedbackEngineProvider).wrong();
    ref.narration.say(
      warmMissLine(_missRotation++),
      cueId: 'parade:miss-r$_roundIndex-$slot',
    );
  }

  void _speakKeeperIntro() {
    // Keeper line is shown in the speech bubble — skip the bottom caption
    // overlay so the same text doesn't render twice.
    ref.narration.say(
      _introDialog,
      cueId: 'parade:intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  String get _countingPromptText => paradeCountingPrompt(_currentCreature);

  void _speakCountingPrompt() {
    ref.narration.say(
      _countingPromptText,
      cueId: 'parade:counting-prompt-r$_roundIndex',
    );
  }

  /// Opens a round with the card that names its creature, then counts.
  void _beginRound() {
    _speciesIntroTimer?.cancel();
    setState(() => _phase = _Phase.speciesIntro);
    ref.narration.say(
      paradeSpeciesIntroLine(_currentCreature),
      cueId: 'parade:species-intro-r$_roundIndex',
      speaker: kKeeperSpeaker,
      caption: false,
    );
    // Held long enough to outlast the spoken line rather than the read — the
    // same rule KeeperAside uses, and for the same reason: for a pre-reader
    // the voice is the whole message.
    _speciesIntroTimer = Timer(
      Duration(
        milliseconds:
            (paradeSpeciesIntroLine(_currentCreature).length * 70).clamp(
          2400,
          5000,
        ),
      ),
      _startCounting,
    );
  }

  void _startCounting() {
    _speciesIntroTimer?.cancel();
    if (!mounted || _phase != _Phase.speciesIntro) return;
    setState(() => _phase = _Phase.counting);
    _startHints();
    _speakCountingPrompt();
  }

  void _tap(int index, {bool fromHint = false}) {
    if (_tapped.contains(index)) return; // one-to-one rule: ignore double-taps
    setState(() {
      _tapped.add(index);
      _hintedIndex = null;
    });
    // A hint-driven tap must not reset the ladder, or a stuck kid would get
    // demonstrated at forever instead of the round resolving as a soft pass.
    if (!fromHint) {
      _hints?.poke();
      _sendBuddyHome();
    }
    // The counting ladder: each object in the count sounds a note one step up
    // the scale, so the child *hears* the quantity climb rather than just
    // hearing it named. Counting three is three rising notes; counting ten
    // climbs past the octave and resolves. The ladder resets each round, so
    // every round restarts at the bottom of the scale.
    ref.read(feedbackEngineProvider).countStep(_tapped.length);
    final spoken = spellNumberCapitalized(_tapped.length);
    // Queued, not spoken, when the ladder did this tap. `speak` cuts off
    // whatever is in flight, and what is in flight at that moment is the
    // demonstration's own explanation - the one line in the round that
    // says why. See HintLadder.
    final say = ref.narration;
    final line = NarrationLine(
      text: '$spoken.',
      cueId: 'parade:tap-r$_roundIndex-${_tapped.length}',
    );
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
    _exitTimers[index] = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _exited.add(index));
    });
  }

  void _finishRound() {
    if (!_allTapped) return;
    _hints?.pause();

    // The real outcome, not the hardcoded `true` every runner used to pass.
    //
    //   clean          — no wrong taps, no demonstrations: advances the
    //                    promotion streak.
    //   soft success   — she got there with help or after a stumble: nothing
    //                    punitive, coins still pay, but it doesn't buy
    //                    progress toward the next CPA layer.
    //   failure        — three or more wrong taps; two in a row demote a
    //                    layer.
    //
    // adaptive-scaffolding.md §Hint Layer: a round that needed a hint "counts
    // as soft-success; does NOT advance promotion streak".
    final hintsUsed = _hints?.hintsUsed ?? 0;
    final result = gradeRound(misses: _wrongTaps, helped: hintsUsed > 0);

    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'counting-parade',
          conceptId: 'K.CC.4a',
          result: result,
        );
    setState(() => _completedRounds++);

    final feedback = ref.read(feedbackEngineProvider);
    if (_isLastRound) {
      feedback.celebrate();
    } else {
      feedback.roundPass();
    }

    if (_isLastRound) {
      // Final round: hold on the bouncing-coin celebration for a beat, then
      // let the keeper step in with the reward line. The hold lives in
      // _kFinalCelebrationHold so tuning is in one place per the
      // progress-bar-to-reward pattern.
      setState(() => _phase = _Phase.celebrating);
      _celebrationTimer = Timer(_kFinalCelebrationHold, () {
        if (!mounted) return;
        setState(() => _phase = _Phase.interstitial);
        ref.narration.say(
          _finalKeeperLine,
          cueId: 'parade:reward',
          speaker: kKeeperSpeaker,
          caption: false,
        );
      });
      return;
    }

    // Non-final round: the keeper talks over the live meadow and the round
    // advances when the aside retires itself. No tap required.
    //
    // Exactly one spoken line per beat. The keeper's transition already names
    // the count, so there is nothing to add here.
    //
    // NarrationPlayer can queue a second line now, so this is a pacing choice
    // rather than a limitation: two lines at a round boundary would stretch a
    // gap that the KeeperAside work exists to keep short. The queue is for
    // beats that stop anyway — the card reveal waits for a tap, so it can
    // afford to wait for the keeper to finish first.
    setState(() {
      _phase = _Phase.transition;
      _asideToken++;
    });
    ref.narration.say(
      _transitionLine,
      cueId: 'parade:interstitial-r$_roundIndex',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  /// Fired by the keeper aside retiring itself, not by a button. Guards on
  /// the phase because the aside's exit animation can land after the widget
  /// has already moved on (a fast Done tap, or a rebuild mid-slide).
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    _exitTimers.clear();
    setState(() {
      _roundIndex++;
      _tapped = <int>{};
      _exited = <int>{};
      _wrongTokens.clear();
      _wrongTaps = 0;
      _missRotation = 0;
      _hintedIndex = null;
      _buddyVisit = null;
      _creatureKeys.clear();
    });
    // Back to the bottom of the scale — every round is its own musical climb.
    ref.read(feedbackEngineProvider).resetRound();
    _beginRound();
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    _speciesIntroTimer?.cancel();
    _buddyReturnTimer?.cancel();
    for (final t in _exitTimers.values) {
      t.cancel();
    }
    // Read the engine off the container directly: `ref.read` is illegal once
    // dispose() has started, and the bed has to fade out when the child leaves
    // the activity rather than following them onto the map.
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's count!",
          startButtonKey: const ValueKey('parade-start-button'),
          onStart: _beginRound,
        ),
      // The creatures are already in the meadow behind the card, dimmed.
      // Showing them there is the point — the card names what she can see,
      // rather than naming something and then producing it.
      _Phase.speciesIntro => _CountingLayer(
          fieldKey: _fieldKey,
          creatureKey: _creatureKey,
          spriteAsset: _currentCreature.spriteAsset,
          targetCount: _currentCount,
          cells: _round.cells,
          tapped: _tapped,
          exited: _exited,
          onTap: (_) {},
          onDecorTap: (_) {},
          onDone: () {},
          allTapped: false,
          replayPrompt: _countingPromptText,
          replayCueId: 'parade:replay-r$_roundIndex',
        ),
      _Phase.counting => _CountingLayer(
          fieldKey: _fieldKey,
          creatureKey: _creatureKey,
          spriteAsset: _currentCreature.spriteAsset,
          targetCount: _currentCount,
          cells: _round.cells,
          tapped: _tapped,
          exited: _exited,
          onTap: _tap,
          onDecorTap: _onDecorTap,
          onDone: _finishRound,
          allTapped: _allTapped,
          hintedIndex: _hintedIndex,
          wrongTokens: _wrongTokens,
          replayPrompt: _countingPromptText,
          replayCueId: 'parade:replay-r$_roundIndex',
        ),
      // The round is over but the meadow stays put — the keeper talks over it
      // rather than replacing it. Input is off; the aside advances the round.
      _Phase.transition => _CountingLayer(
          fieldKey: _fieldKey,
          creatureKey: _creatureKey,
          spriteAsset: _currentCreature.spriteAsset,
          targetCount: _currentCount,
          cells: _round.cells,
          tapped: _tapped,
          exited: _exited,
          onTap: (_) {},
          onDecorTap: (_) {},
          onDone: () {},
          allTapped: false,
          replayPrompt: _countingPromptText,
          replayCueId: 'parade:replay-r$_roundIndex',
        ),
      _Phase.celebrating => _CountingLayer(
          fieldKey: _fieldKey,
          creatureKey: _creatureKey,
          spriteAsset: _currentCreature.spriteAsset,
          targetCount: _currentCount,
          cells: _round.cells,
          tapped: _tapped,
          exited: _exited,
          onTap: (_) {},
          onDecorTap: (_) {},
          onDone: () {},
          // Suppress the Done button while the coin bounces — input is locked
          // during the celebration beat.
          allTapped: false,
          replayPrompt: _countingPromptText,
          replayCueId: 'parade:replay-r$_roundIndex',
        ),
      // Only reachable after the final round. Deliberately still blocking:
      // this is the reward beat, and specs/shared/activity-progress-bar.md
      // requires the kid be handed their reward rather than sliding past it.
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('parade-interstitial-next'),
          onStart: widget.onSequenceComplete,
        ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // Buddy is positioned from the top-left rather than the bottom, so
        // that walking to a creature and standing at home are the same kind of
        // value and one AnimatedPositioned can carry it between them.
        final home = Offset(
          _kBuddyHomeInset.dx,
          // Clamped: on a short window the caption clearance would otherwise
          // push Buddy off the top of the playfield, which is a stranger bug
          // than the one it fixes.
          (constraints.maxHeight - _kBuddySize - _kBuddyHomeInset.dy)
              .clamp(0.0, double.infinity),
        );
        final buddyAt = _buddyVisit ?? home;

        return Stack(
          fit: StackFit.expand,
          children: [
            const _MeadowBackground(),
            PlayfieldScaffold(
              progress: _sequenceProgress,
              celebrate: _phase == _Phase.celebrating,
              child: phaseContent,
            ),
            // The Buddy stands in the meadow alongside the child and reacts to
            // every tap. It lives in the OUTER stack rather than inside
            // _CountingLayer because that layer's left edge is the replay-demo
            // shelf, and the two would fight for the same corner.
            //
            // On the point rung of the hint ladder it walks across the meadow
            // and stands over the creature she has missed. That is the hint —
            // the spoken line beside it is a warmth, but a child who cannot
            // read and may not be listening can still see where her friend
            // went.
            AnimatedPositioned(
              left: buddyAt.dx,
              top: buddyAt.dy,
              duration: _kBuddyWalk,
              curve: Curves.easeInOutCubic,
              child: BuddyCompanion(
                size: _kBuddySize,
                // Face the way it is travelling, so walking back to its own
                // corner doesn't read as moonwalking.
                facing: buddyAt.dx >= home.dx
                    ? BuddyFacing.right
                    : BuddyFacing.left,
              ),
            ),
            // The between-round keeper line, laid over the live meadow.
            // Mounted unconditionally so its exit animation can finish even
            // after the phase has moved on.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: KeeperAside(
                text: _phase == _Phase.transition ? _transitionLine : null,
                token: _asideToken,
                onDismissed: _advanceToNextRound,
              ),
            ),
            // The card naming this round's creature. Above everything,
            // including Buddy, because it is the only thing on screen during
            // its beat.
            if (_phase == _Phase.speciesIntro)
              RevealCardStage(
                key: const ValueKey('parade-species-card'),
                animation: const AlwaysStoppedAnimation<double>(1),
                dim: 0.42,
                onTap: _startCounting,
                child: RevealCardFace(
                  eyebrow: "Look who's next!",
                  spriteAsset: _currentCreature.spriteAsset,
                  title: paradeSpeciesTitle(_currentCreature),
                  accent: const Color(0xFFE0A53C),
                ),
              ),
          ],
        );
      },
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
    required this.fieldKey,
    required this.creatureKey,
    required this.spriteAsset,
    required this.targetCount,
    required this.cells,
    required this.tapped,
    required this.exited,
    required this.onTap,
    required this.onDecorTap,
    required this.onDone,
    required this.allTapped,
    required this.replayPrompt,
    required this.replayCueId,
    this.hintedIndex,
    this.wrongTokens = const <int, int>{},
  });

  /// Identifies the playfield box, so the runner can convert a creature's
  /// position into the coordinates Buddy walks in.
  final GlobalKey fieldKey;

  /// One key per creature index, for the same reason.
  final GlobalKey Function(int creatureIndex) creatureKey;

  final String spriteAsset;
  final int targetCount;

  /// Creatures and decor in render order, from ParadeRoundPlanner.
  final List<ParadeCell> cells;

  final Set<int> tapped;

  /// Indices that have completed their wander-offscreen animation. Once
  /// in this set the creature slides + fades out so the kid stops
  /// re-tapping it.
  final Set<int> exited;

  final ValueChanged<int> onTap;

  /// A decor tap — the wrong answer. Argument is the cell slot, which keys
  /// the shake so only the thing she actually tapped reacts.
  final ValueChanged<int> onDecorTap;

  final VoidCallback onDone;
  final bool allTapped;

  /// Creature the hint ladder is currently glowing, if any.
  final int? hintedIndex;

  /// Slot -> wrong-tap count, driving AnswerFeedback's shake.
  final Map<int, int> wrongTokens;

  /// Narration the (?) button replays. Same line the runner spoke at
  /// the start of the round.
  final String replayPrompt;
  final String replayCueId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: fieldKey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // (?) replay button on the left edge so the kid who's lost
            // track of "what was I supposed to do?" can re-hear the
            // prompt without leaving the round.
            kReplayDemoShelf(
              child: ReplayDemoButton(
                label: replayPrompt,
                cueId: replayCueId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _CountBadge(value: tapped.length, target: targetCount),
                  const Spacer(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      for (var slot = 0; slot < cells.length; slot++)
                        if (cells[slot].isCreature)
                          KeyedSubtree(
                            key: creatureKey(cells[slot].creatureIndex!),
                            child: _Creature(
                              key:
                                  ValueKey('fawn-${cells[slot].creatureIndex}'),
                              spriteAsset: spriteAsset,
                              tapped:
                                  tapped.contains(cells[slot].creatureIndex),
                              gone: exited.contains(cells[slot].creatureIndex),
                              pointed: hintedIndex == cells[slot].creatureIndex,
                              onTap: () => onTap(cells[slot].creatureIndex!),
                            ),
                          )
                        else
                          _Decor(
                            key: ValueKey('decor-$slot'),
                            asset: cells[slot].decorAsset!,
                            wrongToken: wrongTokens[slot] ?? 0,
                            onTap: () => onDecorTap(slot),
                          ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // Continue arrow lives on the right edge of every practice
            // surface — same shelf the LessonScreen Continue uses, so
            // the kid always knows where to look.
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: allTapped
                  ? NextArrowButton(
                      key: const ValueKey('parade-done-arrow'),
                      idleHintEnabled: true,
                      idleHintText:
                          'You counted them all! Tap the arrow to keep going.',
                      onPressed: onDone,
                      label: kLabelDone,
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
