// TwoAttributeHuntRunner — the Shape Garden's K.G.4 challenge variant.
//
// Each round shows a board of shapes plus a two-attribute prompt; the kid
// taps every shape that matches both attributes at once ("4 sides AND
// green", "round AND big"). Wrong taps are gently corrected; correct taps
// light up; when every match is found the round is done.
//
// Three rounds, no per-round grading or coins: the challenge pays one bonus
// at the end, once per visit, and offers "Again!" or "Continue". Lives at
// the end of the Shape Garden chain, surfaced from the Sanctuary picker only
// after every regular sub-mode has been completed. The boards and every line
// are in data/two_attribute_hunt_rounds.dart.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/sfx_catalog.dart';
import '../../data/two_attribute_hunt_rounds.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/wallet_provider.dart';
import '../common/target_hint.dart';
import '../common/timer_scope.dart';
import 'answer_feedback.dart';
import 'glitter_burst.dart';
import 'keeper_choice_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class TwoAttributeHuntRunner extends ConsumerStatefulWidget {
  const TwoAttributeHuntRunner({
    super.key,
    required this.onSequenceComplete,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final bool skipIntro;

  @override
  ConsumerState<TwoAttributeHuntRunner> createState() =>
      _TwoAttributeHuntRunnerState();
}

class _TwoAttributeHuntRunnerState
    extends ConsumerState<TwoAttributeHuntRunner> {
  /// Bumped by "Again!", which plays the three rounds again on a fresh shell.
  int _play = 0;

  /// The play that paid the bonus, if one has. "Again!" used to pay it on
  /// every replay; it is paid once per visit, and a replay's finale says the
  /// keeper's last line instead of promising coins it is not giving.
  int? _paidOnPlay;

  bool get _paysThisPlay => _paidOnPlay == null || _paidOnPlay == _play;

  void _payBonus() {
    if (_paidOnPlay != null) return;
    // Not setState: nothing on screen changes, and the finale already built
    // for this play keeps its words.
    _paidOnPlay = _play;
    ref.read(walletProvider.notifier).award(kTwoAttributeHuntBonus);
  }

  void _again() => setState(() => _play += 1);

  @override
  Widget build(BuildContext context) {
    final finalLine = _paysThisPlay
        ? kTwoAttributeHuntReward
        : kTwoAttributeHuntRounds.last.keeperLine;
    return SanctuaryRoundShell(
      key: ValueKey('2attr-play-$_play'),
      activityId: ActivityIds.shapeGarden,
      roundCount: kTwoAttributeHuntRounds.length,
      conceptIdFor: (_) => 'K.G.4',
      gradeRounds: false,
      introLine: kTwoAttributeHuntIntro,
      startLabel: kTwoAttributeHuntStartLabel,
      keeperLineFor: (i) => kTwoAttributeHuntRounds[i].keeperLine,
      finalLine: finalLine,
      // A replay goes straight back to the first board, without the intro or
      // the demonstration.
      skipIntro: widget.skipIntro || _play > 0,
      // The higher-energy bed: this is the opt-in challenge, and it should
      // feel different from the regular garden the moment it opens.
      musicBed: kChallengeMusicBed,
      celebrationHold: const Duration(seconds: 1),
      onSequenceComplete: widget.onSequenceComplete,
      onFinale: _payBonus,
      finaleBuilder: (context, done) => KeeperChoiceOverlay(
        dialog: finalLine,
        secondaryLabel: kLabelContinue,
        primaryLabel: kLabelAgain,
        onSecondary: done,
        onPrimary: _again,
        secondaryButtonKey: const ValueKey('2attr-finish'),
        primaryButtonKey: const ValueKey('2attr-repeat'),
      ),
      background: Image.asset(
        AssetPaths.shapeGardenBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) => TwoAttributeRoundBody(c: c),
    );
  }
}

/// One board: tap every shape that matches both attributes.
class TwoAttributeRoundBody extends ConsumerStatefulWidget {
  const TwoAttributeRoundBody({super.key, required this.c});

  final RoundContext c;

  @override
  ConsumerState<TwoAttributeRoundBody> createState() =>
      _TwoAttributeRoundBodyState();
}

class _TwoAttributeRoundBodyState extends ConsumerState<TwoAttributeRoundBody>
    with TimerScope<TwoAttributeRoundBody> {
  late final HuntRound _round = kTwoAttributeHuntRounds[widget.c.index];

  final Set<String> _found = <String>{};
  int _burstKey = 0;

  /// Shape id -> wrong taps on it, driving the shake.
  final Map<String, int> _wrongTokens = <String, int>{};
  int _misses = 0;

  /// The shape the ladder is ringing, if any.
  String? _hintedId;
  HintLadder? _hints;
  bool _done = false;

  /// The round-one demonstration is playing: the hand, its halos, and no
  /// input.
  bool _demoing = false;
  bool _handVisible = false;
  double _handX = 0.5;
  double _handY = 0.5;
  int _pokeKey = 0;
  String? _haloId;

  /// `match` (gold: "yes, both") or `miss` (red: "only one of them").
  String? _haloKind;

  bool get _open => !_done && !_demoing && !widget.c.locked;

  HuntShape? get _nextMatch => _round.shapes
      .where((s) => _round.matches.contains(s.id) && !_found.contains(s.id))
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    _demoing = widget.c.showDemo;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_demoing) {
        _playDemo();
      } else {
        _begin();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    super.dispose();
  }

  void _begin() {
    widget.c.say(_round.prompt);
    _hints = HintLadder(onLevel: _onHint)..start();
  }

  /// Two-beat I-Show on the real round-one board: the hand taps a true match
  /// ("both", gold halo), then a near-miss that matches on colour alone
  /// ("not both", red halo), and hands over.
  void _playDemo() {
    HuntShape shape(String id) => _round.shapes.firstWhere((s) => s.id == id);
    final match = shape(kTwoAttributeDemoMatchId);
    final miss = shape(kTwoAttributeDemoMissId);
    void say(String line) => widget.c.say(line, replay: false);

    afterMs(200, () {
      say(kTwoAttributeDemoIntro);
      setState(() {
        _handVisible = true;
        _handX = match.x;
        _handY = match.y;
      });
    });
    afterMs(2100, () {
      setState(() {
        _pokeKey += 1;
        _haloId = match.id;
        _haloKind = 'match';
        _burstKey += 1;
      });
      say(kTwoAttributeDemoMatch);
    });
    afterMs(5200, () {
      setState(() {
        _haloId = null;
        _handX = miss.x;
        _handY = miss.y;
      });
    });
    afterMs(6400, () {
      setState(() {
        _pokeKey += 1;
        _haloId = miss.id;
        _haloKind = 'miss';
      });
      say(kTwoAttributeDemoMiss);
    });
    afterMs(9800, () {
      setState(() {
        _haloId = null;
        _haloKind = null;
        _handVisible = false;
      });
      say(kTwoAttributeDemoHandoff);
    });
    afterMs(11600, () {
      setState(() => _demoing = false);
      _begin();
    });
  }

  /// Points at a match she has not found rather than restating the prompt:
  /// the prompt is already on the replay button, and hearing the same
  /// sentence a third time is not help.
  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final next = _nextMatch;
    if (next == null) return;
    answerTargetHint(
      level,
      ring: () => setState(() => _hintedId = next.id),
      chime: ref.read(feedbackEngineProvider).hint,
      say: (line) => widget.c.say(line, replay: false),
      demonstrate: () => _onTap(next, fromHint: true),
    );
  }

  void _onTap(HuntShape shape, {bool fromHint = false}) {
    if (!_open || _found.contains(shape.id)) return;
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (!_round.matches.contains(shape.id)) {
      setState(() {
        _wrongTokens[shape.id] = (_wrongTokens[shape.id] ?? 0) + 1;
      });
      feedback.wrong();
      widget.c.say(twoAttributeMissLine(_misses++), replay: false);
      return;
    }
    setState(() {
      _found.add(shape.id);
      _burstKey += 1;
      _hintedId = null;
    });
    // Steps up the scale as matches accumulate, so the second one sounds
    // like progress rather than like the first one again.
    feedback.countStep(_found.length);
    // Queued when the ladder made this tap, so it does not cut off the hint
    // line it follows.
    widget.c.say(kTwoAttributeHitLine, replay: false, queue: fromHint);
    if (_nextMatch != null) return;
    _done = true;
    _hints?.pause();
    // Not graded (the shell's gradeRounds is off); reported for the
    // celebration and the round count.
    widget.c.finish(
      gradeRound(misses: _misses, helped: (_hints?.hintsUsed ?? 0) > 0),
    );
  }

  static const double _kSmallSize = 72;
  static const double _kLargeSize = 124;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Attribute pill across the top, so she can re-check the conditions
        // without asking for the narration again.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.deepPurple.shade200, width: 2),
          ),
          child: Text(
            _round.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  for (final s in _round.shapes)
                    _HuntShapeSprite(
                      key: ValueKey('2attr-shape-${s.id}'),
                      shape: s,
                      size: s.isLarge ? _kLargeSize : _kSmallSize,
                      found: _found.contains(s.id),
                      burstKey: _burstKey,
                      wrongToken: _wrongTokens[s.id] ?? 0,
                      inputLocked: !_open,
                      canvasW: w,
                      canvasH: h,
                      onTap: () => _onTap(s),
                      hinted: _hintedId == s.id,
                      demoHaloKind: _haloId == s.id ? _haloKind : null,
                    ),
                  if (_demoing && _handVisible)
                    LessonHandPointer(
                      visible: true,
                      target: Offset(_handX * w - 48, _handY * h - 48),
                      pokeKey: _pokeKey,
                      size: 96,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HuntShapeSprite extends StatelessWidget {
  const _HuntShapeSprite({
    super.key,
    required this.shape,
    required this.size,
    required this.found,
    required this.burstKey,
    required this.wrongToken,
    required this.inputLocked,
    required this.canvasW,
    required this.canvasH,
    required this.onTap,
    this.demoHaloKind,
    this.hinted = false,
  });

  final HuntShape shape;
  final double size;
  final bool found;
  final int burstKey;

  /// Bumped on each wrong tap of this shape. Drives the shake.
  final int wrongToken;

  final bool inputLocked;
  final double canvasW;
  final double canvasH;
  final VoidCallback onTap;

  /// Demo-phase highlight. `'match'` paints a gold halo ("yes — both
  /// of these things") and `'miss'` paints a red one ("only one of
  /// the things"). Null = no demo halo, normal hunt rendering.
  final String? demoHaloKind;

  /// Ringed by the hint ladder.
  final bool hinted;

  @override
  Widget build(BuildContext context) {
    final cx = shape.x * canvasW;
    final cy = shape.y * canvasH;
    final sprite = AssetPaths.shapeGarden2dSprite(
      shape.kind,
      shape.variant,
    );
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (inputLocked || found) ? null : onTap,
        child: AnswerFeedback(
          wrongToken: wrongToken,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Demo halo behind the sprite so the colour reads
              // through. Gold for "match", red for "near-miss".
              if (demoHaloKind != null)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (demoHaloKind == 'match'
                                  ? Colors.amber.shade400
                                  : Colors.redAccent.shade200)
                              .withValues(alpha: 0.7),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              Opacity(
                opacity: found ? 1.0 : 0.95,
                child: Image.asset(sprite, fit: BoxFit.contain),
              ),
              if (found)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade400.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              if (found)
                Positioned.fill(
                  child: IgnorePointer(
                    child: GlitterBurst(
                      key: ValueKey('2attr-burst-${shape.id}-$burstKey'),
                      maxRadius: math.max(80, size * 0.9),
                    ),
                  ),
                ),
              if (hinted) TouchHereRingOutside(around: Size.square(size)),
            ],
          ),
        ),
      ),
    );
  }
}
