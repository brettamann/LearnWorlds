// WheresBuddyRunner — K.G.1 "position words" practice. Three sub-modes share
// the same Sanctuary clearing scene:
//
//   • find-mode  — Buddy hides at a position relative to a landmark
//                  ("behind the hollow tree"). The kid taps where they
//                  think Buddy is. Tolerant of nearby misses.
//   • place-mode — Narration says "Put Buddy above the unicorn
//                  fountain." The kid drags the Buddy into position.
//                  A correctness disc around the target tells them how
//                  close they got.
//   • relational-mode — the challenge. "Put Buddy between the hollow tree and
//                  the giant mushroom." The same drag, but the target is the
//                  midpoint of two landmarks rather than an offset from one:
//                  K.G.1 extended to two references, which is what the
//                  activity spec asks the challenge to be. It gets the
//                  higher-energy bed, like the other two challenges.
//
// All three resolve through `RoundCoordinator` with conceptId K.G.1
// so the mastery streak + coin payout match the rest of the Sanctuary
// activities. `onSequenceComplete` fires after the final keeper line.
//
// Six position words exist; find-mode and place-mode each play four of them,
// offset so the two overlap on two and differ on four. Every word is still
// covered across the activity, but a single sitting is four rounds rather than
// six — and the two modes stop feeling like the identical list played twice.
// See _roundsFor.
//
// relational-mode used to fall through to place-mode, which meant finishing
// both regular sub-modes earned a "Challenge!" chip that replayed the sitting
// she had just done — and paid a challenge chest for it. That was harmless
// while the Sanctuary path dead-ended two nodes earlier and nobody could reach
// this activity at all; it stopped being harmless when the path opened.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../data/wheres_buddy_landmarks.dart';
import '../../data/wheres_buddy_words.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import 'answer_feedback.dart';
import 'buddy_widget.dart';
import 'continue_arrow_shelf.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'next_arrow_button.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';
import 'touch_here_halo.dart';
import 'wheres_buddy_landmark_sprite.dart';

/// Sub-mode ids the activity-screen passes via `launchExtra['subMode']`.
const String kWheresBuddySubModeFindMode = 'find-mode';
const String kWheresBuddySubModePlaceMode = 'place-mode';
const String kWheresBuddySubModeRelationalMode = 'relational-mode';

enum _Phase {
  intro,
  playing,

  /// Keeper speaks over the live clearing and advances the round herself.
  transition,

  celebrating,

  /// Final beat only — the reward payoff, which is meant to interrupt.
  interstitial,
}

/// One round.
///
/// Ordinarily one landmark and one position word; six rounds rotate the six
/// K.G.1 prepositions across the clearing. The challenge instead names *two*
/// landmarks and no position word, and the target becomes the point between
/// them — see [secondLandmarkId] and `_targetPos`.
class _Round {
  const _Round({
    required this.landmarkId,
    required this.keeperLine,
    this.positionId,
    this.secondLandmarkId,
  });

  final String landmarkId;

  /// Null on a relational round: "between" is not an offset from anything, so
  /// there is no vector to apply and no single preposition to speak.
  final String? positionId;

  /// The other end of a relational round, or null for the ordinary ones.
  final String? secondLandmarkId;

  final String keeperLine;

  bool get isRelational => secondLandmarkId != null;
}

const List<_Round> _kRounds = <_Round>[
  _Round(
    landmarkId: 'fountain',
    positionId: 'above',
    keeperLine: 'Above! Right where I asked.',
  ),
  _Round(
    landmarkId: 'mushroom',
    positionId: 'below',
    keeperLine: 'Below the mushroom — perfect.',
  ),
  _Round(
    landmarkId: 'hollow-tree',
    positionId: 'next-to',
    keeperLine: 'Right next to the tree!',
  ),
  _Round(
    landmarkId: 'cottage',
    positionId: 'behind',
    keeperLine: 'Behind the cottage. Sneaky!',
  ),
  _Round(
    landmarkId: 'rock-cluster',
    positionId: 'in-front-of',
    keeperLine: 'In front of the rocks. Nice spot.',
  ),
  _Round(
    landmarkId: 'pond',
    positionId: 'beside',
    keeperLine: 'Beside the pond — you got it.',
  ),
];

/// The challenge: four rounds, each naming two landmarks.
///
/// Pairs come from `kWheresBuddyRelationalPairs` so the narration script can
/// enumerate the same list without importing this file — it has to stay
/// Flutter-free, and this one holds widgets.
const List<_Round> _kRelationalRounds = <_Round>[
  _Round(
    landmarkId: 'hollow-tree',
    secondLandmarkId: 'mushroom',
    keeperLine: 'Right in the middle. That is what between means!',
  ),
  _Round(
    landmarkId: 'pond',
    secondLandmarkId: 'rock-cluster',
    keeperLine: 'Between the pond and the rocks. Exactly.',
  ),
  _Round(
    landmarkId: 'fountain',
    secondLandmarkId: 'cottage',
    keeperLine: 'Halfway between the two. Well done.',
  ),
  _Round(
    landmarkId: 'rock-cluster',
    secondLandmarkId: 'hollow-tree',
    keeperLine: 'You found the middle again. Buddy is impressed.',
  ),
];

/// How many of the six words a single sitting plays.
const int _kRoundsPerSitting = 4;

/// Wrong attempts before the narrator stops repeating the cue and just shows
/// her. Three, straight from specs/activities/kindergarten/wheres-buddy.md.
const int _kDemonstrateAfter = 3;

/// The four rounds this sub-mode plays, offset by mode.
///
/// find-mode takes words 0–3, place-mode takes 2–5. Both modes still teach
/// four prepositions, all six are covered across the activity, and a kid who
/// plays both doesn't get the same six-item list twice in a row — which was
/// a large part of why the activity felt like a worksheet.
List<_Round> _roundsFor(_Mode mode) {
  if (mode == _Mode.relational) return _kRelationalRounds;
  final offset = mode == _Mode.find ? 0 : _kRounds.length - _kRoundsPerSitting;
  return _kRounds.sublist(offset, offset + _kRoundsPerSitting);
}

class WheresBuddyRunner extends StatelessWidget {
  const WheresBuddyRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.subMode = kWheresBuddySubModePlaceMode,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String subMode;

  @override
  Widget build(BuildContext context) {
    return _WheresBuddyBody(
      key: ValueKey('wheres-buddy-$subMode'),
      onSequenceComplete: onSequenceComplete,
      skipIntro: skipIntro,
      mode: switch (subMode) {
        kWheresBuddySubModeFindMode => _Mode.find,
        kWheresBuddySubModeRelationalMode => _Mode.relational,
        // place-mode, and anything unrecognised: dragging Buddy somewhere is
        // the safer thing to hand a child than a mode she cannot finish.
        _ => _Mode.place,
      },
    );
  }
}

enum _Mode { find, place, relational }

class _WheresBuddyBody extends ConsumerStatefulWidget {
  const _WheresBuddyBody({
    super.key,
    required this.onSequenceComplete,
    required this.skipIntro,
    required this.mode,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final _Mode mode;

  @override
  ConsumerState<_WheresBuddyBody> createState() => _WheresBuddyBodyState();
}

class _WheresBuddyBodyState extends ConsumerState<_WheresBuddyBody> {
  late _Phase _phase = widget.skipIntro ? _Phase.playing : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;

  /// Place-mode: Buddy's current drag position in normalized coords.
  /// Starts off-target so the kid sees where they're moving it to.
  Offset _buddyPos = kClearingBuddyHome;
  bool _placedThisRound = false;

  Timer? _celebrationTimer;

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Wrong taps or drops this round. specs/activities/kindergarten/wheres-buddy.md
  /// specifies the behaviour exactly: soft "no", narrator repeats the cue,
  /// and after three the narrator demonstrates by glowing the correct zone.
  int _wrongAttempts = 0;
  int _missRotation = 0;
  int _wrongToken = 0;

  /// True once the demonstration has fired, which glows the target zone.
  bool _demonstrating = false;

  /// The hint ladder is ringing the Buddy: "you can pick him up".
  bool _ringBuddy = false;

  HintLadder? _hints;

  /// Read eagerly — `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  late final List<_Round> _rounds = _roundsFor(widget.mode);

  _Round get _currentRound => _rounds[_roundIndex];
  WheresBuddyLandmark get _currentLandmark =>
      wheresBuddyLandmark(_currentRound.landmarkId);

  /// Only meaningful on a non-relational round: "between" has no vector.
  WheresBuddyPosition get _currentPosition =>
      wheresBuddyPosition(_currentRound.positionId ?? 'above');

  bool get _isLastRound => _roundIndex == _rounds.length - 1;
  double get _progress => _completedRounds / _rounds.length;

  /// The landmarks this round is about — one, or two on the challenge.
  Set<String> get _highlightLandmarkIds => <String>{
        _currentRound.landmarkId,
        if (_currentRound.secondLandmarkId != null)
          _currentRound.secondLandmarkId!,
      };

  /// Target the kid is aiming for, in normalized coords.
  ///
  /// Ordinarily the landmark centre plus the position word's vector. On a
  /// relational round it is the midpoint of the two named landmarks, which is
  /// what "between" means and the only definition a five-year-old can act on
  /// by dragging.
  Offset get _targetPos {
    final round = _currentRound;
    if (round.isRelational) {
      final a = wheresBuddyLandmark(round.landmarkId).position;
      final b = wheresBuddyLandmark(round.secondLandmarkId!).position;
      return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    return clearingSpotFor(
      landmarkId: _currentLandmark.id,
      positionId: _currentPosition.id,
    );
  }

  String get _introDialog => switch (widget.mode) {
        _Mode.place => "I'll tell you where the Buddy should go. Drag the "
            'Buddy next to, above, or behind the things in the meadow.',
        _Mode.relational =>
          'Here is a tricky one. I will name two things, and you put '
              'Buddy right in the middle of them.',
        _Mode.find => "The Buddy loves to play hide-and-seek. I'll tell you "
            'where they are hiding — tap the right spot!',
      };

  String get _prompt {
    final round = _currentRound;
    if (round.isRelational) {
      return wheresBuddyRelationalPrompt(
        round.landmarkId,
        round.secondLandmarkId!,
      );
    }
    return wheresBuddyPrompt(
      preposition: _currentPosition.preposition,
      landmark: _currentLandmark.displayName,
      placing: widget.mode == _Mode.place,
    );
  }

  String get _finalKeeperLine => widget.mode == _Mode.relational
      ? 'Every middle found. Between is a hard one, and you have it.'
      : 'Every position found! You really know your above, below, and '
          'beside.';

  @override
  void initState() {
    super.initState();
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    // The higher-energy bed for the challenge, the same as Tens Parade and
    // the Two-Attribute Hunt: opting into the hard one should sound like it.
    unawaited(
      _sfxForDispose!.startMusicBed(
        widget.mode == _Mode.relational ? kChallengeMusicBed : kDefaultMusicBed,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.playing) {
        _speakPrompt();
        _startHints();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _speakPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _prompt,
            cueId: 'wheres-buddy:${widget.mode.name}:r$_roundIndex:prompt',
          ),
        );
  }

  void _onStartFromIntro() {
    setState(() => _phase = _Phase.playing);
    _startHints();
    _speakPrompt();
  }

  /// Distance threshold for "close enough" — 14 % of the shorter side.
  /// Generous so the kid doesn't lose for a small motor miss.
  static const double _kHitToleranceFraction = 0.14;

  bool _isCloseEnough(Offset normalized) {
    final t = _targetPos;
    final dx = normalized.dx - t.dx;
    final dy = normalized.dy - t.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    return dist <= _kHitToleranceFraction;
  }

  void _onFindTap(Offset normalized) {
    if (_phase != _Phase.playing) return;
    if (!_isCloseEnough(normalized)) {
      _onWrongAttempt();
      return;
    }
    _resolveRound();
  }

  void _onPlaceDragUpdate(Offset normalized) {
    // Dragging is "she is doing something", so the ladder goes back to the
    // bottom - a child moving the Buddy around while she thinks is not stuck,
    // and being demonstrated at mid-drag would take the answer off her.
    _hints?.poke();
    setState(() {
      _buddyPos = normalized;
      _ringBuddy = false;
    });
  }

  void _onPlaceDragEnd() {
    if (_phase != _Phase.playing) return;
    if (_isCloseEnough(_buddyPos)) {
      // Buddy landing, before the round resolves. The sound of a thing being
      // put down is the half of a drag the player is waiting for, and
      // `Sfx.drop` had never been played by anything.
      ref.read(feedbackEngineProvider).drop();
      _resolveRound();
    } else {
      // Snap Buddy back onto the centre line so the kid can try again.
      setState(() => _buddyPos = kClearingBuddyHome);
      _onWrongAttempt();
    }
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  /// Escalating help for a child who has not moved.
  ///
  /// The spec already had one half of this - "after 3 wrong taps, narrator
  /// demonstrates by glowing the correct zone" - and it is implemented in
  /// [_onWrongAttempt]. But it only ever fires if she *guesses*, and the
  /// natural response to not knowing what "next to" means is not to guess.
  /// She sits still, and until now nothing in the activity noticed.
  ///
  /// The first rung rings the Buddy rather than the answer, because in the
  /// two drag modes the first thing that can go wrong is not knowing he can
  /// be picked up at all - a mechanical problem, not a positional one, and
  /// worth ruling out before giving anything away.
  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.playing || _demonstrating) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _ringBuddy = true);
      case HintLevel.point:
        setState(() => _ringBuddy = true);
        feedback.hint();
        // The round's own sentence again, not a generic nudge: the whole task
        // is one preposition, and repeating it is the hint.
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: _prompt,
                cueId: 'wheres-buddy:${widget.mode.name}:r$_roundIndex:'
                    'hint-point',
              ),
            );
      case HintLevel.demonstrate:
        _demonstrate();
    }
  }

  /// A miss, in either mode.
  ///
  /// specs/activities/kindergarten/wheres-buddy.md already spelled this out
  /// and nothing implemented it: "soft 'no' SFX, narrator gently repeats …
  /// After 3 wrong taps, narrator demonstrates by glowing the correct zone
  /// and revealing the Buddy there." Until now a wrong tap re-spoke the
  /// prompt and did nothing else — no sound, no movement, nothing on screen.
  void _onWrongAttempt() {
    _hints?.poke();
    setState(() {
      _wrongAttempts += 1;
      _wrongToken += 1;
    });
    ref.read(feedbackEngineProvider).wrong();

    if (_wrongAttempts >= _kDemonstrateAfter && !_demonstrating) {
      _demonstrate();
      return;
    }
    // Repeat the cue, but re-worded on alternate misses. Hearing the exact
    // same sentence a third time is how a helpful line becomes noise.
    final restate = _missRotation.isEven
        ? _prompt
        : '${warmMissLine(_missRotation)} $_prompt';
    _missRotation += 1;
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: restate,
            cueId: 'wheres-buddy:${widget.mode.name}:r$_roundIndex:'
                'miss-$_wrongAttempts',
          ),
        );
  }

  /// Show her the answer rather than leaving her stuck. Glows the target zone
  /// and walks the Buddy there; the round still resolves as a soft success so
  /// nothing about it reads as a penalty.
  void _demonstrate() {
    _hints?.pause();
    setState(() {
      _demonstrating = true;
      _ringBuddy = false;
      _buddyPos = _targetPos;
    });
    ref.read(feedbackEngineProvider).hint();
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _currentRound.isRelational
                ? wheresBuddyRelationalRestate(
                    _currentRound.landmarkId,
                    _currentRound.secondLandmarkId!,
                  )
                : 'Here — Buddy is ${_currentPosition.preposition} '
                    '${_currentLandmark.displayName}. Right there.',
            cueId: 'wheres-buddy:${widget.mode.name}:r$_roundIndex:demo',
          ),
        );
    _celebrationTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || _phase != _Phase.playing) return;
      _resolveRound();
    });
  }

  void _resolveRound() {
    if (_placedThisRound) return;
    _placedThisRound = true;
    _celebrationTimer?.cancel();

    // Three misses is a genuine miss of the concept — that is also exactly
    // the threshold the activity spec picked for demonstrating, so the two
    // agree by construction. A demonstration she got by waiting rather than
    // by guessing is not a failure, but it is not clean either: the game put
    // the Buddy where it goes.
    _hints?.pause();
    final result = _wrongAttempts >= _kDemonstrateAfter
        ? RoundResult.failure
        : (_wrongAttempts == 0 && (_hints?.hintsUsed ?? 0) == 0
            ? RoundResult.success
            : RoundResult.softSuccess);
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: 'wheres-buddy',
          conceptId: 'K.G.1',
          result: result,
        );
    setState(() {
      _completedRounds += 1;
      // Snap the Buddy to the target for the celebration beat in
      // place-mode; in find-mode we reveal it at the target instead.
      _buddyPos = _targetPos;
      _phase = _Phase.celebrating;
    });

    final feedback = ref.read(feedbackEngineProvider);
    if (_isLastRound) {
      feedback.celebrate();
      _celebrationTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _phase = _Phase.interstitial);
        ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
              NarrationLine(
                text: _finalKeeperLine,
                cueId: 'wheres-buddy:${widget.mode.name}:r$_roundIndex:'
                    'interstitial',
                speaker: 'sanctuary-keeper-mystic',
              ),
            );
      });
      return;
    }

    feedback.roundPass();
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.transition;
        _asideToken += 1;
      });
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: _currentRound.keeperLine,
              cueId:
                  'wheres-buddy:${widget.mode.name}:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    setState(() {
      _roundIndex += 1;
      _placedThisRound = false;
      _wrongAttempts = 0;
      _missRotation = 0;
      _demonstrating = false;
      _ringBuddy = false;
      _buddyPos = kClearingBuddyHome;
      _phase = _Phase.playing;
    });
    _startHints();
    ref.read(feedbackEngineProvider).resetRound();
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: "Let's play!",
          startButtonKey: const ValueKey('wheres-buddy-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.playing || _Phase.celebrating || _Phase.transition => _PlayLayer(
          mode: widget.mode,
          buddyPos: _buddyPos,
          targetPos: _targetPos,
          highlightLandmarkIds: _highlightLandmarkIds,
          revealBuddy: _phase != _Phase.playing ||
              widget.mode != _Mode.find ||
              _demonstrating,
          glowTarget: _demonstrating,
          ringBuddy: _ringBuddy,
          wrongToken: _wrongToken,
          inputLocked: _phase != _Phase.playing,
          onFindTap: _onFindTap,
          onPlaceDragUpdate: _onPlaceDragUpdate,
          onPlaceDragEnd: _onPlaceDragEnd,
          replayPrompt: _prompt,
          replayCueId: 'wheres-buddy:${widget.mode.name}:replay-r$_roundIndex',
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _finalKeeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('wheres-buddy-interstitial-next'),
          onStart: widget.onSequenceComplete,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.wheresBuddyBackground, fit: BoxFit.cover),
        PlayfieldScaffold(
          progress: _progress,
          celebrate: _phase == _Phase.celebrating,
          child: phaseContent,
        ),
        if (_phase == _Phase.transition)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KeeperAside(
              text: _currentRound.keeperLine,
              token: _asideToken,
              onDismissed: _advanceToNextRound,
            ),
          ),
      ],
    );
  }
}

class _PlayLayer extends StatelessWidget {
  const _PlayLayer({
    required this.mode,
    required this.buddyPos,
    required this.targetPos,
    required this.highlightLandmarkIds,
    required this.revealBuddy,
    required this.glowTarget,
    required this.ringBuddy,
    required this.wrongToken,
    required this.inputLocked,
    required this.onFindTap,
    required this.onPlaceDragUpdate,
    required this.onPlaceDragEnd,
    required this.replayPrompt,
    required this.replayCueId,
  });

  final _Mode mode;
  final Offset buddyPos;
  final Offset targetPos;

  /// True in the two modes where she moves Buddy herself.
  ///
  /// find-mode is the odd one out — she taps a spot and Buddy is hidden until
  /// she is right. Written as "not find" rather than "place or relational" so
  /// that a fourth mode has to opt out of dragging on purpose rather than by
  /// being forgotten here, which is how relational-mode shipped with an
  /// undraggable Buddy and an instruction she could not follow.
  bool get _isDragMode => mode != _Mode.find;

  /// Which landmark chips wear the amber highlight this round.
  ///
  /// Passed down rather than guessed from [targetPos]. It used to be inferred
  /// as "whichever landmark is nearest the target", which happened to be right
  /// while every target was an offset from exactly one of them — and is wrong
  /// the moment a round names two, because the midpoint of a pair is not
  /// nearest to either in any useful sense and only one chip would light up.
  final Set<String> highlightLandmarkIds;
  final bool revealBuddy;

  /// Demonstration is running: ring the target zone so she can see where the
  /// answer was, not just be told again.
  final bool glowTarget;

  /// The hint ladder is pointing at the Buddy himself. Only meaningful in the
  /// drag modes - in find-mode he is hidden, which is the whole puzzle.
  final bool ringBuddy;

  /// Bumped on every miss; drives the shake on the scene.
  final int wrongToken;

  final bool inputLocked;
  final ValueChanged<Offset> onFindTap;
  final ValueChanged<Offset> onPlaceDragUpdate;
  final VoidCallback onPlaceDragEnd;
  final String replayPrompt;
  final String replayCueId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            kReplayDemoShelf(
              child: ReplayDemoButton(
                label: replayPrompt,
                cueId: replayCueId,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Everything is placed inside the clearing, which stops
                  // above the caption band. Laying out against the raw
                  // constraints put the Buddy's resting spot underneath it.
                  final clearing = ClearingGeometry(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  );
                  final w = clearing.width;
                  final h = clearing.height;
                  final shortest = clearing.shortest;
                  final buddySize = clearing.buddySize;
                  final target = clearing.place(targetPos);
                  final buddy = clearing.place(buddyPos);
                  // The whole clearing takes the miss reaction, because in
                  // this activity the wrong answer is a *place*, not an
                  // object — there is no single sprite to shake.
                  return AnswerFeedback(
                    wrongToken: wrongToken,
                    shakeExtent: 6,
                    child: Stack(
                      children: [
                        // The six named places, drawn.
                        //
                        // The comment that used to be here said a pre-reader
                        // would recognise "the cottage" by the placeholder
                        // shape underneath the chip. There was no shape
                        // underneath: the background is the Shape Garden
                        // courtyard, which has no cottage, no fountain and no
                        // tree in it, so all six landmarks were white pills of
                        // text and a child who cannot read had nothing on
                        // screen to be above or behind.
                        for (final lm in kWheresBuddyLandmarks)
                          Positioned(
                            left: lm.position.dx * w -
                                shortest * lm.sizeFraction / 2,
                            top: lm.position.dy * h -
                                shortest * lm.sizeFraction / 2,
                            width: shortest * lm.sizeFraction,
                            child: IgnorePointer(
                              child: _Landmark(
                                landmark: lm,
                                size: shortest * lm.sizeFraction,
                                highlighted: highlightLandmarkIds.contains(
                                  lm.id,
                                ),
                              ),
                            ),
                          ),
                        // Target halo — shown in place-mode so the kid has
                        // something to aim for while dragging, and in any
                        // mode once the demonstration fires, which is the
                        // "glowing the correct zone" the activity spec asks
                        // for after three misses.
                        //
                        // Deliberately NOT in relational-mode. There the halo
                        // would sit exactly on the answer, and dragging onto a
                        // circle is not reasoning about between-ness — it
                        // would leave the challenge a re-skin of place-mode
                        // after all. She gets it during the demonstration,
                        // which is when showing her is the point.
                        if (mode == _Mode.place || glowTarget)
                          Positioned(
                            left: target.dx - buddySize * 0.6,
                            top: target.dy - buddySize * 0.6,
                            width: buddySize * 1.2,
                            height: buddySize * 1.2,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber.withValues(
                                    alpha: glowTarget ? 0.32 : 0.18,
                                  ),
                                  border: Border.all(
                                    color: Colors.amber.shade400
                                        .withValues(alpha: 0.85),
                                    width: 3,
                                  ),
                                  boxShadow: glowTarget
                                      ? [
                                          BoxShadow(
                                            color: Colors.amber
                                                .withValues(alpha: 0.7),
                                            blurRadius: 28,
                                            spreadRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        // Find-mode taps — full-bleed gesture detector.
                        if (mode == _Mode.find)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: inputLocked
                                  ? null
                                  : (details) {
                                      final local = details.localPosition;
                                      onFindTap(
                                        Offset(local.dx / w, local.dy / h),
                                      );
                                    },
                            ),
                          ),
                        // Buddy — draggable in both drag modes, visible at
                        // the revealed position in find-mode after a correct
                        // tap, hidden otherwise so the kid hunts.
                        if (_isDragMode || revealBuddy)
                          Positioned(
                            left: buddy.dx - buddySize / 2,
                            top: buddy.dy - buddySize / 2,
                            width: buddySize,
                            height: buddySize,
                            child: _DraggableBuddy(
                              size: buddySize,
                              enabled: _isDragMode && !inputLocked,
                              onDragUpdate: (global) {
                                onPlaceDragUpdate(
                                  Offset(global.dx / w, global.dy / h),
                                );
                              },
                              onDragEnd: onPlaceDragEnd,
                            ),
                          ),
                        // The ring goes on last so it is not painted over by
                        // the sprite it is pointing at.
                        if (ringBuddy && _isDragMode)
                          TouchHereHalo(
                            rect: Rect.fromCenter(
                              center: buddy,
                              width: buddySize,
                              height: buddySize,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 24),
            kContinueArrowShelf(
              child: revealBuddy && inputLocked
                  ? const NextArrowButton(
                      key: ValueKey('wheres-buddy-done-arrow'),
                      idleHintEnabled: true,
                      onPressed: _noop,
                      label: kLabelNice,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _DraggableBuddy extends StatelessWidget {
  const _DraggableBuddy({
    required this.size,
    required this.enabled,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double size;
  final bool enabled;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return BuddyWidget(size: size);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Use pan to track the Buddy's position smoothly under the
      // finger. We hand global coords up so the parent can normalize.
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        // Buddy's centre = local origin + delta from gesture.
        final globalCentre = details.globalPosition;
        final parentBox = context.findAncestorRenderObjectOfType<RenderBox>();
        if (parentBox == null) return;
        final local = parentBox.globalToLocal(globalCentre);
        onDragUpdate(local);
      },
      onPanEnd: (_) => onDragEnd(),
      child: BuddyWidget(size: size),
    );
  }
}

class _Landmark extends StatelessWidget {
  const _Landmark({
    required this.landmark,
    required this.size,
    required this.highlighted,
  });

  final WheresBuddyLandmark landmark;
  final double size;

  /// True for the place (or places) the prompt just named.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // A pool of warm light on the ground, not an outline. The
              // outline treatment is spoken for: an amber ring means "the
              // answer is here" on the target halo a few lines up, and two
              // rings meaning different things is worse than one meaning
              // nothing.
              boxShadow: highlighted
                  ? [
                      // Soft and negative-spread on purpose. At a bigger
                      // alpha with positive spread this read as a filled
                      // amber disc, which is very close to what the target
                      // halo a few lines down looks like - and those two
                      // circles mean opposite things: one is the place being
                      // talked about, the other is the answer.
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 34,
                        spreadRadius: -8,
                      ),
                    ]
                  : null,
            ),
            child: Image.asset(landmark.spriteAsset, fit: BoxFit.contain),
          ),
        ),
        // Named only while it is the place under discussion.
        //
        // Every landmark used to carry its name all the time, which was the
        // whole of the landmark. Now the picture is, and six permanent
        // captions would be six pieces of text a pre-reader cannot use,
        // crowding a clearing she has to judge distances across. Showing it on
        // the one being talked about is what ties a spoken "the hollow tree"
        // to the tree, which is the only moment the word does any work.
        if (highlighted) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.shade100.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade400, width: 2),
            ),
            child: Text(
              landmark.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
