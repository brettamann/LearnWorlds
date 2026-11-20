// Storyteller's Pond - K.OA.2 (and K.OA.1): word problems within ten.
//
// The Star Turtle tells a short story and she acts it out with the animals in
// front of her: ducklings waiting on the grass swim over when she taps them,
// frogs going home hop away when she waves goodbye. Only then does the turtle
// ask the question - "How many ducklings are there now?" - and she answers on
// a number card that carries its dots.
//
// Acting it out is the teaching, not a warm-up to it. A five-year-old solving
// "three and two more" by holding two numbers in her head is being asked for
// the abstraction before she has the thing it abstracts; moving the two
// ducklings over and then counting what is there is K.OA.1's "represent with
// objects", and it makes the answer something she can see.
//
// The take-apart story has no single answer: five ducklings, some into the
// water and some on the grass, however she likes - she can tap one back if
// she changes her mind - and the turtle says what she made.
//
// The acting-out never goes away; it is the point. What fades as she gets
// surer is the help on the answer cards: at the pictorial layer they are bare
// numerals and she counts the animals to find hers, and a miss puts the dots
// back. At the abstract layer the story is also written down once she has
// answered it - "3 + 2 = 5" floating over the pond while the turtle says
// "three and two more make five" - so the first number sentences she meets
// are ones she has just acted out.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/number_words.dart';
import '../../data/round_pick.dart';
import '../../data/sfx_catalog.dart';
import '../../data/storytellers_pond_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/concept_state.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import 'answer_feedback.dart';
import 'lesson_hand_pointer.dart';
import 'next_arrow_button.dart';
import 'number_choice.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class StorytellersPondRunner extends ConsumerWidget {
  const StorytellersPondRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = kStorySubAddTo,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = storiesFor(
      subMode,
      seed: roundSeed(ref.watch(sessionIdProvider), subMode),
    );
    return SanctuaryRoundShell(
      activityId: 'storytellers-pond',
      roundCount: stories.length,
      conceptIdFor: (_) => 'K.OA.2',
      introLine: kStoryIntro,
      keeperLineFor: storyKeeperLine,
      finalLine: kStoryFinal,
      skipIntro: skipIntro,
      musicBed:
          subMode == kStorySubTwoStep ? kChallengeMusicBed : kDefaultMusicBed,
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.storytellersPondBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) =>
          StoryRoundBody(story: stories[c.index], c: c),
    );
  }
}

enum _Zone { water, grass, gone }

class _Critter {
  _Critter(this.id, this.asset, this.zone, {this.group = 0});
  final int id;
  final String asset;
  _Zone zone;

  /// Put-together: which of the two kinds it is, for left/right grouping.
  final int group;
  bool counted = false;
  int hop = 0;
  int wrong = 0;
}

enum _Step { act, second, ask, done }

class StoryRoundBody extends ConsumerStatefulWidget {
  const StoryRoundBody({super.key, required this.story, required this.c});

  final Story story;
  final RoundContext c;

  @override
  ConsumerState<StoryRoundBody> createState() => _StoryRoundBodyState();
}

class _StoryRoundBodyState extends ConsumerState<StoryRoundBody> {
  final List<_Critter> _critters = <_Critter>[];
  final List<Timer> _timers = <Timer>[];
  HintLadder? _hints;
  _Step _step = _Step.act;
  int _arrived = 0;
  int _left = 0;
  int _misses = 0;
  int? _ringed;
  bool _ringCheck = false;

  late final List<int> _choices =
      numberChoicesFor(widget.story.answer, seed: widget.c.index + 5);
  int? _answered;
  int? _hintedCard;
  final Map<int, int> _wrongCards = <int, int>{};

  /// The hint ladder has helped with the question itself.
  bool _askHelped = false;

  /// Dots on the cards at concrete, and for the rest of the question once
  /// she has missed or been helped.
  bool get _cardDots =>
      supportLayer(
        widget.c.layer,
        misses: _misses > 0 || _askHelped ? 1 : 0,
      ) ==
      CpaLayer.concrete;

  /// The number sentence, once the story is solved, at the abstract layer.
  String? get _sentence {
    if (widget.c.layer != CpaLayer.abstract || _step != _Step.done) {
      return null;
    }
    if (_s.kind == StoryKind.takeApart) {
      final w = _inWater;
      return w < 1 || w >= _s.a ? null : storySentence(_s, inWater: w);
    }
    if (_answered == null) return null;
    return storySentence(_s);
  }

  bool _handVisible = false;
  Offset _handAt = Offset.zero;
  int _poke = 0;

  Story get _s => widget.story;
  bool get _open => !widget.c.locked && _step != _Step.done;
  int get _inWater => _critters.where((c) => c.zone == _Zone.water).length;

  @override
  void initState() {
    super.initState();
    var id = 0;
    final asset = _s.creature.asset;
    switch (_s.kind) {
      case StoryKind.addTo:
      case StoryKind.twoStep:
        for (var i = 0; i < _s.a; i++) {
          _critters.add(_Critter(id++, asset, _Zone.water));
        }
        for (var i = 0; i < _s.b; i++) {
          _critters.add(_Critter(id++, asset, _Zone.grass));
        }
      case StoryKind.takeFrom:
      case StoryKind.takeApart:
        for (var i = 0; i < _s.a; i++) {
          _critters.add(_Critter(id++, asset, _Zone.grass));
        }
      case StoryKind.putTogether:
        for (var i = 0; i < _s.a; i++) {
          _critters.add(_Critter(id++, asset, _Zone.water));
        }
        for (var i = 0; i < _s.b; i++) {
          _critters.add(
            _Critter(id++, _s.other!.asset, _Zone.water, group: 1),
          );
        }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.c.say(storyOpening(_s));
      if (widget.c.showDemo) _pointAtFirst();
      _hints = HintLadder(onLevel: _onHint)..start();
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _after(Duration d, VoidCallback f) =>
      _timers.add(Timer(d, () => mounted ? f() : null));

  /// The first visit's "watch me": the hand points at the first thing to tap
  /// and taps it, and the animal wiggles - nothing moves. The story is hers
  /// to act out; the hand only shows her where her finger goes.
  void _pointAtFirst() {
    final target = _nextTarget();
    final geo = _geo;
    if (target == null || geo == null) return;
    setState(() {
      _handVisible = true;
      _handAt = geo.centerOf(target, _critters);
    });
    _after(const Duration(milliseconds: 1200), () {
      setState(() {
        _poke++;
        target.wrong++;
      });
    });
    _after(const Duration(milliseconds: 2200), () {
      setState(() => _handVisible = false);
    });
  }

  /// What the story wants her to tap next, for the hints.
  _Critter? _nextTarget() {
    switch (_s.kind) {
      case StoryKind.addTo:
        return _firstIn(_Zone.grass);
      case StoryKind.twoStep:
        return _step == _Step.act
            ? _firstIn(_Zone.grass)
            : _firstIn(_Zone.water);
      case StoryKind.takeFrom:
        return _firstIn(_Zone.grass);
      case StoryKind.putTogether:
        for (final c in _critters) {
          if (!c.counted) return c;
        }
        return null;
      case StoryKind.takeApart:
        // Nothing in the water: send one in. Everything in the water: bring
        // one back - the check only appears with some in each place, so a
        // hint that pointed at the check here pointed at nothing.
        if (_inWater == 0) return _firstIn(_Zone.grass);
        if (_inWater >= _s.a) return _firstIn(_Zone.water);
        return null;
    }
  }

  _Critter? _firstIn(_Zone z) {
    for (final c in _critters) {
      if (c.zone == z) return c;
    }
    return null;
  }

  void _onCritter(_Critter c, {bool fromHint = false}) {
    if (!_open || (_step != _Step.act && _step != _Step.second)) return;
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    setState(() => _ringed = null);
    switch (_s.kind) {
      case StoryKind.addTo:
      case StoryKind.twoStep:
        if (_step == _Step.act) {
          if (c.zone != _Zone.grass) return _wiggle(c);
          setState(() {
            c
              ..zone = _Zone.water
              ..hop += 1;
          });
          _arrived += 1;
          feedback.countStep(_s.a + _arrived);
          widget.c.say(
            '${spellCount(_s.a + _arrived)}.',
            replay: false,
            queue: fromHint,
          );
          if (_arrived >= _s.b) {
            if (_s.kind == StoryKind.twoStep) {
              setState(() => _step = _Step.second);
              widget.c.say(storySecondPart(_s), queue: true);
              _hints?.start();
            } else {
              _ask();
            }
          }
          return;
        }
        // Two-step, the second part: some go home.
        if (c.zone != _Zone.water) return _wiggle(c);
        _goHome(c, _s.c, fromHint: fromHint);
      case StoryKind.takeFrom:
        if (c.zone != _Zone.grass) return;
        _goHome(c, _s.b, fromHint: fromHint);
      case StoryKind.putTogether:
        if (c.counted) return _wiggle(c);
        setState(() {
          c
            ..counted = true
            ..hop += 1;
        });
        final n = _critters.where((x) => x.counted).length;
        feedback.countStep(n);
        widget.c.say('${spellCount(n)}.', replay: false, queue: fromHint);
        if (n >= _critters.length) _ask();
      case StoryKind.takeApart:
        // Back and forth as she likes; the check appears once there is some
        // in each place.
        setState(() {
          c
            ..zone = c.zone == _Zone.grass ? _Zone.water : _Zone.grass
            ..hop += 1;
          _ringCheck = false;
        });
        feedback.drop();
    }
  }

  void _goHome(_Critter c, int leaving, {required bool fromHint}) {
    final feedback = ref.read(feedbackEngineProvider);
    if (_left >= leaving) {
      // She is waving at one who is staying. Not a wrong answer - the story
      // just does not have that one leaving.
      setState(() => c.wrong++);
      feedback.bubble();
      widget.c.say(storyJustThat(leaving), replay: false);
      return;
    }
    setState(() {
      c
        ..zone = _Zone.gone
        ..hop += 1;
    });
    _left += 1;
    feedback.whoosh();
    widget.c.say(kStoryBye, replay: false, queue: fromHint);
    if (_left >= leaving) _ask();
  }

  void _wiggle(_Critter c) {
    setState(() => c.wrong++);
    ref.read(feedbackEngineProvider).sparkle();
  }

  void _ask() {
    setState(() => _step = _Step.ask);
    widget.c.say(storyQuestion(_s), queue: true);
    _hints?.start();
  }

  void _onPick(int n) {
    if (!_open || _step != _Step.ask) return;
    _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (n != _s.answer) {
      setState(() {
        _wrongCards[n] = (_wrongCards[n] ?? 0) + 1;
        _misses += 1;
        if (_misses >= 2) _hintedCard = _s.answer;
      });
      feedback.wrong();
      widget.c.say(storyMiss(_misses), replay: false);
      return;
    }
    setState(() {
      _answered = n;
      _hintedCard = null;
    });
    feedback.correct();
    widget.c.say(storyDone(_s), replay: false);
    _finish();
  }

  void _onCheck() {
    if (!_open || _s.kind != StoryKind.takeApart) return;
    final w = _inWater;
    if (w < 1 || w >= _s.a) return;
    ref.read(feedbackEngineProvider).correct();
    widget.c.say(storyDone(_s, inWater: w), replay: false);
    _finish();
  }

  void _finish() {
    setState(() => _step = _Step.done);
    _hints?.pause();
    final helped = (_hints?.hintsUsed ?? 0) > 0;
    widget.c.finish(
      _misses >= 3
          ? RoundResult.failure
          : (_misses == 0 && !helped
              ? RoundResult.success
              : RoundResult.softSuccess),
    );
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final feedback = ref.read(feedbackEngineProvider);
    if (_step == _Step.ask) {
      switch (level) {
        case HintLevel.none:
        case HintLevel.highlight:
          return;
        case HintLevel.point:
          feedback.hint();
          setState(() => _askHelped = true);
          widget.c.say(kStoryCountAgain, replay: false);
        case HintLevel.demonstrate:
          feedback.hint();
          setState(() => _hintedCard = _s.answer);
          widget.c.say(warmHintLine(3), replay: false);
      }
      return;
    }
    final target = _nextTarget();
    if (target == null) {
      // Take-apart with ducklings in the water already: the thing she has not
      // found is the check.
      if (level == HintLevel.none) return;
      setState(() => _ringCheck = true);
      if (level != HintLevel.highlight) {
        feedback.hint();
        widget.c.say(kStoryDoneSplit, replay: false);
      }
      return;
    }
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _ringed = target.id);
      case HintLevel.point:
        setState(() => _ringed = target.id);
        feedback.hint();
        widget.c.say(warmHintLine(2), replay: false);
      case HintLevel.demonstrate:
        feedback.hint();
        widget.c.say(warmHintLine(3), replay: false);
        _onCritter(target, fromHint: true);
    }
  }

  _StoryGeometry? _geo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final geo = _StoryGeometry(box.biggest);
        _geo = geo;
        final canCheck = _s.kind == StoryKind.takeApart &&
            _inWater >= 1 &&
            _inWater < _s.a &&
            _step == _Step.act;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The storyteller, on the bank to the right.
            Positioned(
              right: 0,
              bottom: 0,
              width: geo.turtle,
              height: geo.turtle,
              child: const IgnorePointer(child: _BobbingTurtle()),
            ),
            for (final c in _critters) _critter(geo, c),
            if (_step == _Step.ask || _answered != null)
              Positioned(
                left: 0,
                right: 0,
                top: 4,
                child: Center(
                  child: NumberChoiceRow(
                    choices: _choices,
                    cardWidth: 132,
                    answered: _answered,
                    hinted: _hintedCard,
                    wrongTokens: _wrongCards,
                    showDots: _cardDots,
                    locked: !_open,
                    onPick: _onPick,
                  ),
                ),
              ),
            if (_sentence != null)
              Positioned(
                left: 0,
                right: geo.turtle,
                top: geo.waterY - geo.critter * 1.55,
                child: Center(
                  child: _NumberSentence(
                    key: const ValueKey('story-sentence'),
                    text: _sentence!,
                  ),
                ),
              ),
            if (canCheck)
              Positioned(
                right: geo.turtle + 8,
                top: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NextArrowButton(
                      key: const ValueKey('story-check'),
                      onPressed: _onCheck,
                      label: kLabelDone,
                    ),
                    if (_ringCheck)
                      const TouchHereRingOutside(around: Size.square(96)),
                  ],
                ),
              ),
            if (_handVisible)
              LessonHandPointer(
                visible: true,
                target: _handAt - const Offset(30, 18),
                pokeKey: _poke,
              ),
          ],
        );
      },
    );
  }

  Widget _critter(_StoryGeometry geo, _Critter c) {
    final center = geo.centerOf(c, _critters);
    final gone = c.zone == _Zone.gone;
    final size = geo.critter;
    return AnimatedPositioned(
      key: ValueKey('story-critter-${c.id}'),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      left: (gone ? geo.size.width + size : center.dx) - size / 2,
      top: center.dy - size / 2 - (gone ? size * 0.6 : 0),
      width: size,
      height: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 420),
        opacity: gone ? 0 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: gone ? null : () => _onCritter(c),
          child: AnswerFeedback(
            wrongToken: c.wrong,
            correctToken: c.counted ? 1 : 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(c.asset, fit: BoxFit.contain),
                ),
                if (_ringed == c.id)
                  TouchHereRingOutside(around: Size.square(size)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "3 + 2 = 5", written on a slate - never read out as symbols; the turtle's
/// own words for it are already being spoken.
class _NumberSentence extends StatelessWidget {
  const _NumberSentence({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xEEFFFBF0),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD8C6A0), width: 3),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 56,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4A3220),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryGeometry {
  _StoryGeometry(this.size) {
    critter = math.min(100, math.max(80, size.width / 11));
    turtle = math.min(170, size.height * 0.34);
    waterY = size.height * 0.5;
    grassY = size.height - critter / 2 - 10;
  }

  final Size size;
  late final double critter;
  late final double turtle;
  late final double waterY;
  late final double grassY;

  /// Animals sit in rows, one per place, centred between Buddy's corner on
  /// the left and the turtle on the right. Put-together keeps its two kinds
  /// apart so they read as two groups before they are counted as one.
  Offset centerOf(_Critter c, List<_Critter> all) {
    const left = kBuddyCornerReserve;
    final right = size.width - turtle;
    final mid = (left + right) / 2;
    final step = critter * 1.08;
    if (c.zone == _Zone.water) {
      final groups = all.map((x) => x.group).toSet().length;
      final same = all
          .where((x) => x.zone == _Zone.water && x.group == c.group)
          .toList();
      final i = same.indexOf(c);
      final groupMid = groups == 1
          ? mid
          : mid + (c.group == 0 ? -1 : 1) * (same.length / 2 + 0.6) * step;
      return Offset(groupMid + (i - (same.length - 1) / 2) * step, waterY);
    }
    final row = all.where((x) => x.zone == _Zone.grass).toList();
    final i = math.max(0, row.indexOf(c));
    return Offset(mid + (i - (row.length - 1) / 2) * step, grassY);
  }
}

class _BobbingTurtle extends StatefulWidget {
  const _BobbingTurtle();

  @override
  State<_BobbingTurtle> createState() => _BobbingTurtleState();
}

class _BobbingTurtleState extends State<_BobbingTurtle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Transform.flip(
        flipX: true,
        child: Image.asset(
          AssetPaths.countingParadeStarTurtle,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
