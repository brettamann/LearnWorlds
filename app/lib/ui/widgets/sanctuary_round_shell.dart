// SanctuaryRoundShell - the part of an activity that is not its mechanic.
//
// Every runner in this game walks the same lifecycle: a keeper intro she taps
// through, a prompt, the round, a one-second celebration, a keeper aside over
// the live board that dismisses itself, the next round, and one blocking
// keeper beat at the very end. The first four activities each wrote that out
// by hand, and most of the bugs found in them since have been the same bug in
// four places - a music bed claimed conditionally and released
// unconditionally, a KeeperAside that cut off the last count, a transition
// that left input unlocked, a band-hidden Buddy. When seven more activities
// arrived at once, writing it out seven more times would have been seven more
// chances at each of those.
//
// So the shell owns the lifecycle and the round body owns the mechanic. A body
// is built fresh for every round (it is keyed by the round index), so a
// round's state cannot leak into the next one, and it talks to the shell
// through a [RoundContext]: `say` to speak a prompt (which also becomes what
// the "?" button replays), `finish` to report how it went. Everything else -
// grading into the mastery engine, coins, a card roll, the progress bar, the
// celebration, the aside, the finale - happens here, the same way, for all of
// them.
//
// It deliberately does not own the hint ladder. When a child is stuck is the
// same everywhere; what help looks like is not, and that is the body's job.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coordinators/round_coordinator.dart';
import '../../data/button_labels.dart';
import '../../data/sfx_catalog.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/concept_state.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/buddy_mood.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/progress_provider.dart';
import 'buddy_companion.dart';
import 'keeper_aside.dart';
import 'keeper_intro_overlay.dart';
import 'playfield_scaffold.dart';
import 'replay_demo_button.dart';

/// What the shell hands a round body.
class RoundContext {
  const RoundContext({
    required this.index,
    required this.count,
    required this.locked,
    required this.showDemo,
    required this.say,
    required this.finish,
    this.grade = _noGrade,
    this.layer = CpaLayer.concrete,
  });

  static void _noGrade(String conceptId, RoundResult result) {}

  /// Zero-based round number within this visit.
  final int index;

  /// How many rounds the visit has.
  final int count;

  /// True once the round has been reported finished. The board stays on
  /// screen under the celebration and the keeper aside, and must not take
  /// input while it does.
  final bool locked;

  /// True for the first round of a visit that did not come from a lesson.
  /// The body opens with a short "watch me" on the real board before
  /// handing over - the whole I-Show, on the thing she is about to touch.
  final bool showDemo;

  /// Speak [line]. With `replay: true` (the default) it also becomes what the
  /// "?" button says, which is what a prompt wants and a count does not.
  ///
  /// `queue: true` waits for whatever is being said to finish instead of
  /// cutting it off. A round's closing line wants that - "Six frogs on the
  /// lily pads!" arrives in the same beat as the "Six." it follows, and
  /// `speak` would talk over the count, which is the part she earned.
  final void Function(String line, {bool replay, bool queue}) say;

  /// Report the round done. Safe to call once; later calls are ignored.
  final void Function(RoundResult result) finish;

  /// Grade one more concept now, on top of the one [finish] grades. For a
  /// round that teaches two things in two phases (Build-a-Habitat's frame is
  /// K.G.5, the shape inside it K.G.6): each phase is graded as it ends, and
  /// pays like a round. Does nothing when the shell's `gradeRounds` is off.
  final void Function(String conceptId, RoundResult result) grade;

  /// Where she is on the concrete-pictorial-abstract ladder for this round's
  /// concept, read once as the round opens.
  ///
  /// The mastery engine has moved this up and down since the first sprint -
  /// three clean rounds up, two failed rounds down - and until 2026-09-25 no
  /// round in the game looked at it, so "abstract" was a label on a save file
  /// and a child answered with the same dots on the same cards on her fortieth
  /// round as on her first. A body that has supports to fade reads it: the
  /// dots under the numerals go at pictorial, the counters themselves at
  /// abstract, and a miss brings back one layer for that puzzle (see
  /// [supportLayer]). She is never told; the round just asks a little more of
  /// her, or a little less.
  ///
  /// Read once, not watched: grading the round moves the layer, and the board
  /// she has just finished must not change under the celebration.
  final CpaLayer layer;
}

/// The layer to draw a puzzle at, after [misses] misses on it.
///
/// A miss is answered with one layer more concrete - adaptive-scaffolding.md's
/// "demonstrate at the next layer down" - and only for that puzzle: the next
/// one starts back at her layer. Help from the hint ladder counts the same.
CpaLayer supportLayer(CpaLayer layer, {int misses = 0}) {
  if (misses <= 0) return layer;
  return switch (layer) {
    CpaLayer.abstract => CpaLayer.pictorial,
    _ => CpaLayer.concrete,
  };
}

/// How far from the left edge of a round body the bottom strip is Buddy's.
///
/// The body starts to the right of the "?" shelf; Buddy stands in the
/// bottom-left corner of the whole screen, over the top of it, and takes the
/// touch. So anything a body puts in its bottom strip has to start this far in.
const double kBuddyCornerReserve = 110;

typedef RoundBodyBuilder = Widget Function(
  BuildContext context,
  RoundContext c,
);

enum _ShellPhase { intro, playing, celebrating, transition, finale }

class SanctuaryRoundShell extends ConsumerStatefulWidget {
  const SanctuaryRoundShell({
    super.key,
    required this.activityId,
    required this.roundCount,
    required this.conceptIdFor,
    required this.introLine,
    required this.keeperLineFor,
    required this.finalLine,
    required this.background,
    required this.roundBuilder,
    required this.onSequenceComplete,
    this.skipIntro = false,
    this.startLabel = kLabelLetsGo,
    this.musicBed = kDefaultMusicBed,
    this.showBuddy = true,
    this.buddyFacing = BuddyFacing.right,
    this.celebrationHold = const Duration(milliseconds: 1400),
    this.gradeRounds = true,
    this.introBuilder,
    this.finaleBuilder,
    this.onFinale,
  });

  final String activityId;
  final int roundCount;

  /// The concept a round is graded against. A function because several
  /// activities mix standards across rounds.
  final String Function(int round) conceptIdFor;

  /// What the keeper says before the first round.
  final String introLine;

  /// What the keeper says over the finished board between rounds.
  final String Function(int round) keeperLineFor;

  /// The last beat of the visit - the only one allowed to stop play.
  final String finalLine;

  /// Drawn full-bleed behind everything.
  final Widget background;

  final RoundBodyBuilder roundBuilder;
  final VoidCallback onSequenceComplete;
  final bool skipIntro;
  final String startLabel;
  final String musicBed;

  /// Some mechanics put their own character in Buddy's corner.
  final bool showBuddy;
  final BuddyFacing buddyFacing;

  /// The beat between a round finishing and the keeper speaking over it -
  /// long enough to see the finished board and hear the round's last line.
  final Duration celebrationHold;

  /// False for a visit whose rounds are not graded at all: no mastery, no
  /// per-round coins (a challenge that pays one bonus at the end instead).
  final bool gradeRounds;

  /// Replaces the keeper's intro overlay - for an activity that opens with
  /// its own animated demo. Call `start` when it is done. The shell does not
  /// speak [introLine] when this is given; the builder owns the opening.
  final Widget Function(BuildContext context, VoidCallback start)? introBuilder;

  /// Replaces the finale overlay. Call `done` to end the visit. [finalLine]
  /// is still spoken.
  final Widget Function(BuildContext context, VoidCallback done)? finaleBuilder;

  /// Fired once, as the finale appears (e.g. to pay a challenge's bonus).
  final VoidCallback? onFinale;

  @override
  ConsumerState<SanctuaryRoundShell> createState() =>
      _SanctuaryRoundShellState();
}

class _SanctuaryRoundShellState extends ConsumerState<SanctuaryRoundShell> {
  late _ShellPhase _phase =
      widget.skipIntro ? _ShellPhase.playing : _ShellPhase.intro;
  int _round = 0;
  int _completed = 0;
  int _asideToken = 0;
  String _prompt = '';
  bool _finishedThisRound = false;
  Timer? _beat;
  CpaLayer _layer = CpaLayer.concrete;

  /// Read eagerly - `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfx;

  bool get _isLastRound => _round >= widget.roundCount - 1;

  @override
  void initState() {
    super.initState();
    _sfx = ref.read(sfxEngineProvider);
    _layer = _layerFor(0);
    // Claimed here, unconditionally, because the release in dispose() is
    // unconditional. A claim taken later than its release is how the music
    // bed on the next screen used to get given away.
    unawaited(_sfx!.startMusicBed(widget.musicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _ShellPhase.intro && widget.introBuilder == null) {
        _speakIntro();
      }
    });
  }

  CpaLayer _layerFor(int round) => ref
      .read(kidProgressProvider.notifier)
      .getOrCreate(widget.conceptIdFor(round))
      .currentLayer;

  @override
  void dispose() {
    _beat?.cancel();
    _sfx?.releaseMusicBed();
    super.dispose();
  }

  void _speakIntro() {
    ref.narration.say(
      widget.introLine,
      cueId: '${widget.activityId}:intro',
      speaker: kKeeperSpeaker,
      caption: false,
    );
  }

  void _start() {
    ref.narration.clear();
    setState(() => _phase = _ShellPhase.playing);
  }

  void _say(String line, {bool replay = true, bool queue = false}) {
    if (!mounted) return;
    if (replay && line != _prompt) setState(() => _prompt = line);
    final narration = ref.narration;
    final l = NarrationLine(
      text: line,
      cueId: '${widget.activityId}:r$_round:${line.hashCode}',
    );
    if (queue) {
      narration.enqueue(l);
    } else {
      narration.speak(l);
    }
  }

  void _finish(RoundResult result) {
    if (!mounted || _finishedThisRound || _phase != _ShellPhase.playing) {
      return;
    }
    _finishedThisRound = true;
    _grade(widget.conceptIdFor(_round), result);
    setState(() {
      _completed += 1;
      _phase = _ShellPhase.celebrating;
    });
    final feedback = ref.read(feedbackEngineProvider);
    if (_isLastRound) {
      feedback.celebrate();
    } else {
      feedback.roundPass();
    }
    // A beat to see the finished board, and for the round's own last line -
    // "Seven!" - to land before the keeper speaks over it.
    _beat = Timer(widget.celebrationHold, () {
      if (!mounted) return;
      if (_isLastRound) {
        setState(() => _phase = _ShellPhase.finale);
        widget.onFinale?.call();
        ref.narration.say(
          widget.finalLine,
          cueId: '${widget.activityId}:finale',
          speaker: kKeeperSpeaker,
          caption: false,
          queue: true,
        );
        return;
      }
      setState(() {
        _phase = _ShellPhase.transition;
        _asideToken += 1;
      });
      ref.narration.say(
        widget.keeperLineFor(_round),
        cueId: '${widget.activityId}:r$_round:aside',
        speaker: kKeeperSpeaker,
        caption: false,
        queue: true,
      );
    });
  }

  void _grade(String conceptId, RoundResult result) {
    if (!mounted || !widget.gradeRounds) return;
    ref.read(roundCoordinatorProvider).resolveRound(
          activityId: widget.activityId,
          conceptId: conceptId,
          result: result,
        );
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _nextRound() {
    if (!mounted || _phase != _ShellPhase.transition) return;
    setState(() {
      _round += 1;
      _layer = _layerFor(_round);
      _finishedThisRound = false;
      _prompt = '';
      _phase = _ShellPhase.playing;
    });
    ref.read(feedbackEngineProvider).resetRound();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    switch (_phase) {
      case _ShellPhase.intro when widget.introBuilder != null:
        content = widget.introBuilder!(context, _start);
      case _ShellPhase.finale when widget.finaleBuilder != null:
        content = widget.finaleBuilder!(context, widget.onSequenceComplete);
      case _ShellPhase.intro:
        content = KeeperIntroOverlay(
          dialog: widget.introLine,
          startLabel: widget.startLabel,
          startButtonKey: ValueKey('${widget.activityId}-start-button'),
          onStart: _start,
        );
      case _ShellPhase.finale:
        content = KeeperIntroOverlay(
          dialog: widget.finalLine,
          startLabel: kLabelContinue,
          startButtonKey: ValueKey('${widget.activityId}-finale-next'),
          onStart: widget.onSequenceComplete,
        );
      case _ShellPhase.playing:
      case _ShellPhase.celebrating:
      case _ShellPhase.transition:
        content = SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                kReplayDemoShelf(
                  child: _prompt.isEmpty
                      ? null
                      : ReplayDemoButton(
                          label: _prompt,
                          cueId: '${widget.activityId}:replay-r$_round',
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('${widget.activityId}-round-$_round'),
                    child: Builder(
                      builder: (context) => widget.roundBuilder(
                        context,
                        RoundContext(
                          index: _round,
                          count: widget.roundCount,
                          locked: _phase != _ShellPhase.playing,
                          showDemo: _round == 0 && !widget.skipIntro,
                          say: _say,
                          finish: _finish,
                          grade: _grade,
                          layer: _layer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
        );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.background,
        PlayfieldScaffold(
          progress: _completed / widget.roundCount,
          celebrate:
              _phase == _ShellPhase.celebrating || _phase == _ShellPhase.finale,
          child: content,
        ),
        if (widget.showBuddy &&
            _phase != _ShellPhase.intro &&
            _phase != _ShellPhase.finale)
          BuddyCompanionCorner(facing: widget.buddyFacing),
        if (_phase == _ShellPhase.transition)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KeeperAside(
              text: widget.keeperLineFor(_round),
              token: _asideToken,
              onDismissed: _nextRound,
            ),
          ),
      ],
    );
  }
}
