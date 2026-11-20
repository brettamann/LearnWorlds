// Ten-Frame Pond - K.OA.3, K.OA.4, K.NBT.1.
//
// Ten lily pads float in two rows of five. Frogs wait on the bank; she taps a
// frog and it hops onto the next free pad. The pads fill the top row first,
// left to right, then the bottom row - the order a ten-frame is always read in
// - so seven is always "a full row and two more", on every round, and she
// never has to be told that.
//
// Decisions made for the person playing it:
//
// - **Tap, not drag.** The spec draws frogs being dragged onto pads. Dragging
//   is a motor skill a five-year-old is still acquiring and it is not what
//   this standard is about; a tap that makes a frog hop is one gesture she
//   already has, and the hop itself is the fun.
// - **Tapping the pad works too.** A lot of children will tap where the frog
//   should *go*. In a one-colour round that calls the next frog over, into the
//   next pad in order - the pad she touched is not always the one it lands
//   on, because the reading order is the lesson.
// - **Nothing she touches is ignored.** A frog already sitting wiggles when it
//   is poked; a two-colour round answers a tap on an empty pad by lighting the
//   two banks, since which colour to send is her choice to make.
// - **The fifth and the tenth frog say something different.** "Five! The top
//   row is full" and "Ten! The whole pond is full" replace the plain count at
//   exactly the moments the structure appears.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../activities/sub_mode_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/number_words.dart';
import '../../data/round_pick.dart';
import '../../data/sfx_catalog.dart';
import '../../data/ten_frame_words.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../common/timer_scope.dart';
import 'lesson_hand_pointer.dart';
import 'number_choice.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class TenFramePondRunner extends ConsumerStatefulWidget {
  const TenFramePondRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = TenFramePondModes.fillToTarget,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  ConsumerState<TenFramePondRunner> createState() => _TenFramePondRunnerState();
}

class _TenFramePondRunnerState extends ConsumerState<TenFramePondRunner> {
  late final List<PondRound> _rounds = pondRoundsFor(
    widget.subMode,
    seed: roundSeed(ref.read(sessionIdProvider), widget.subMode),
  );

  /// The green count of the last accepted split at each target, so the
  /// "different way" round can tell a new way from the same one again.
  final Map<int, int> _lastGreen = <int, int>{};

  String get _concept => switch (widget.subMode) {
        TenFramePondModes.makeTen => 'K.OA.4',
        TenFramePondModes.tenPlusN ||
        TenFramePondModes.threeFrames =>
          'K.NBT.1',
        _ => 'K.OA.3',
      };

  @override
  Widget build(BuildContext context) {
    return SanctuaryRoundShell(
      activityId: ActivityIds.tenFramePond,
      roundCount: _rounds.length,
      conceptIdFor: (_) => _concept,
      introLine: kPondIntro,
      keeperLineFor: pondKeeperLine,
      finalLine: kPondFinal,
      skipIntro: widget.skipIntro,
      musicBed: widget.subMode == TenFramePondModes.threeFrames
          ? kChallengeMusicBed
          : kDefaultMusicBed,
      onSequenceComplete: widget.onSequenceComplete,
      background: Image.asset(
        AssetPaths.tenFramePondBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) {
        final round = _rounds[c.index];
        return PondRoundBody(
          round: round,
          c: c,
          previousGreen: round.differentWay ? _lastGreen[round.target] : null,
          onSplit: (green) => _lastGreen[round.target] = green,
        );
      },
    );
  }
}

/// One frog, wherever it is.
class _Frog {
  _Frog({required this.id, required this.orange, required this.slot});

  final int id;
  final bool orange;

  /// Its place on the bank while it waits.
  int slot;

  /// The pad it is sitting on, or null while it waits.
  int? pad;

  /// Bumped each time it jumps, which plays the hop.
  int hop = 0;

  /// Bumped when she pokes it on its pad.
  int wiggle = 0;

  /// Dived into the pond - on its way out of the scene.
  bool gone = false;
}

/// Where everything goes, for one board size.
class _PondGeometry {
  _PondGeometry(this.size, this.round) {
    final w = size.width;
    final h = size.height;
    bankH = round.askHowMany ? 200 : 118;
    const top = 6.0;
    final availH = h - bankH - top - 14;
    final frames = round.frames;
    final byWidth = w * 0.9 / 5.76;
    final byHeight = availH / (2.4 * frames + 0.34 * (frames - 1));
    pad = math.min(118, math.min(byWidth, byHeight));
    gap = pad * 0.12;
    border = pad * 0.14;
    frameW = 5 * pad + 4 * gap + 2 * border;
    frameH = 2 * pad + gap + 2 * border;
    final framesH = frames * frameH + (frames - 1) * pad * 0.34;
    frameTop = top + math.max(0, (availH - framesH) / 2);
    frameLeft = (w - frameW) / 2;
    frog = pad * 0.84;
    bankFrog = math.min(104, math.max(84, pad * 0.95));
    bankY = h - bankH / 2 - 4;
  }

  final Size size;
  final PondRound round;
  late final double bankH;
  late final double pad;
  late final double gap;
  late final double border;
  late final double frameW;
  late final double frameH;
  late final double frameTop;
  late final double frameLeft;
  late final double frog;
  late final double bankFrog;
  late final double bankY;

  Rect frameRect(int frame) => Rect.fromLTWH(
        frameLeft,
        frameTop + frame * (frameH + pad * 0.34),
        frameW,
        frameH,
      );

  Rect padRect(int i) {
    final frame = frameRect(i ~/ 10);
    final cell = i % 10;
    return Rect.fromLTWH(
      frame.left + border + (cell % 5) * (pad + gap),
      frame.top + border + (cell ~/ 5) * (pad + gap),
      pad,
      pad,
    );
  }

  /// Bank positions. One colour: five across the middle. Two colours: green
  /// on the left, orange on the right, with water between them so the two
  /// read as two groups.
  Offset bankCenter({required bool orange, required int slot}) {
    final mid = size.width / 2;
    if (!round.twoColors) {
      // Clamped like the two-colour bank below: on a narrow board the end
      // frog of five would otherwise stand under Buddy.
      final step = math.min(
        bankFrog * 1.2,
        (mid - kBuddyCornerReserve - bankFrog / 2) / 2,
      );
      return Offset(mid + (slot - 2) * step, bankY);
    }
    // The outermost frog has to stay clear of Buddy, who stands in the
    // bottom-left corner in front of everything: a frog under him cannot be
    // tapped at all, because the touch lands on Buddy.
    final reach = (mid - kBuddyCornerReserve - bankFrog / 2) / 3.9;
    final step = math.min(bankFrog * 1.2, reach);
    final dir = orange ? 1 : -1;
    return Offset(mid + dir * (step * 0.9 + slot * step), bankY);
  }
}

class PondRoundBody extends ConsumerStatefulWidget {
  const PondRoundBody({
    super.key,
    required this.round,
    required this.c,
    required this.previousGreen,
    required this.onSplit,
  });

  final PondRound round;
  final RoundContext c;
  final int? previousGreen;
  final ValueChanged<int> onSplit;

  @override
  ConsumerState<PondRoundBody> createState() => _PondRoundBodyState();
}

class _PondRoundBodyState extends ConsumerState<PondRoundBody>
    with TimerScope<PondRoundBody> {
  static const int _bankSlots = 5;
  static const int _twoColourSlots = 4;

  final List<_Frog> _frogs = <_Frog>[];
  int _nextId = 0;
  bool _busy = false;
  bool _done = false;
  HintLadder? _hints;

  /// The one frog the hint ladder is pointing at.
  int? _ringedFrog;

  /// Both banks lit - "tap a frog" - after a pad tap in a two-colour round.
  bool _ringBanks = false;

  /// The first pond glowing - "that one is ten" - in the challenge.
  bool _ringFrame = false;

  int _sameWayTries = 0;

  // Demonstrator's hand.
  bool _handVisible = false;
  Offset _handAt = Offset.zero;
  int _poke = 0;

  // The challenge's answer cards.
  late final List<int> _choices = numberChoicesFor(
    widget.round.target,
    seed: widget.c.index + 3,
    min: 11,
    max: 19,
  );
  int? _answered;
  int? _hintedCard;
  final Map<int, int> _wrongTokens = <int, int>{};
  int _misses = 0;

  PondRound get _r => widget.round;
  int get _filled => _frogs.where((f) => f.pad != null && !f.gone).length;
  bool get _inputOpen => !_busy && !_done && !widget.c.locked;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _r.preset; i++) {
      _frogs.add(_Frog(id: _nextId++, orange: false, slot: -1)..pad = i);
    }
    if (!_r.askHowMany) _fillBank();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.c.showDemo && !_r.askHowMany) {
        _runDemo();
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

  /// Keeps each bank topped up: a frog that hops off is replaced by one that
  /// wanders in, so she can never run out and never has to wait.
  void _fillBank() {
    void top(bool orange, int slots) {
      final waiting = _frogs.where(
        (f) => f.pad == null && !f.gone && f.orange == orange,
      );
      final used = waiting.map((f) => f.slot).toSet();
      for (var s = 0; s < slots && used.length < slots; s++) {
        if (used.contains(s)) continue;
        _frogs.add(_Frog(id: _nextId++, orange: orange, slot: s));
        used.add(s);
      }
    }

    if (_r.twoColors) {
      top(false, _twoColourSlots);
      top(true, _twoColourSlots);
    } else {
      top(false, _bankSlots);
    }
  }

  _Frog? _firstWaiting({bool? orange}) {
    final waiting = _frogs
        .where(
          (f) =>
              f.pad == null &&
              !f.gone &&
              (orange == null || f.orange == orange),
        )
        .toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    return waiting.isEmpty ? null : waiting.first;
  }

  int _nextPad() {
    final taken =
        _frogs.where((f) => f.pad != null && !f.gone).map((f) => f.pad);
    for (var i = 0; i < _r.frames * 10; i++) {
      if (!taken.contains(i)) return i;
    }
    return -1;
  }

  void _begin() {
    if (!mounted) return;
    widget.c.say(pondPrompt(_r));
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHint)..start();
  }

  // ---- the demonstration --------------------------------------------------

  /// "Watch. Tap a frog, and hop!" - one frog goes on and comes back again.
  ///
  /// It comes back because the round is hers. The first real play session
  /// found a lesson that did two of her taps for her, and a demonstration
  /// that leaves its frog on the pad would be the same thing again: the first
  /// frog of every visit placed by the game.
  void _runDemo() {
    final frog = _firstWaiting(orange: false);
    if (frog == null) return _begin();
    final geo = _geometry;
    if (geo == null) return _begin();
    setState(() {
      _busy = true;
      _handVisible = true;
      _handAt = geo.bankCenter(orange: false, slot: frog.slot);
    });
    widget.c.say(kPondDemo, replay: false);
    after(const Duration(milliseconds: 900), () {
      setState(() => _poke++);
    });
    after(const Duration(milliseconds: 1100), () {
      // The next free pad, not pad 0: in make-ten seven frogs are already
      // sitting, and the demonstration used to land its frog on top of one.
      final pad = _nextPad();
      if (pad < 0) return;
      setState(() {
        frog
          ..pad = pad
          ..hop += 1;
        _handVisible = false;
      });
      ref.read(feedbackEngineProvider).countStep(_filled);
    });
    after(const Duration(milliseconds: 2500), () {
      widget.c.say(kPondDemoBack, replay: false, queue: true);
      setState(() {
        frog
          ..pad = null
          ..hop += 1;
      });
    });
    after(const Duration(milliseconds: 4700), () {
      setState(() => _busy = false);
      _begin();
    });
  }

  // ---- her turn -----------------------------------------------------------

  void _onFrogTap(_Frog frog) {
    if (!_inputOpen) return;
    if (frog.pad != null) {
      // Sitting frogs are not a target, but a poke still gets an answer.
      setState(() => frog.wiggle += 1);
      ref.read(feedbackEngineProvider).sparkle();
      return;
    }
    _hop(frog);
  }

  void _onPadTap(int pad) {
    if (!_inputOpen) return;
    if (_frogs.any((f) => f.pad == pad && !f.gone)) return;
    if (_r.twoColors) {
      // Which colour goes on is her decision, so the game will not make it
      // for her; it shows her where the frogs are instead.
      setState(() => _ringBanks = true);
      ref.read(feedbackEngineProvider).bubble();
      after(const Duration(milliseconds: 1600), () {
        setState(() => _ringBanks = false);
      });
      return;
    }
    final frog = _firstWaiting();
    if (frog != null) _hop(frog);
  }

  void _hop(_Frog frog, {bool fromHint = false}) {
    final pad = _nextPad();
    if (pad < 0 || _filled >= _r.target) return;
    if (!fromHint) _hints?.poke();
    setState(() {
      frog
        ..pad = pad
        ..hop += 1;
      _ringedFrog = null;
      _ringBanks = false;
      _fillBank();
    });
    final n = _filled;
    ref.read(feedbackEngineProvider).countStep(n);
    final String line;
    if (n == 5 && _r.target > 5) {
      line = kPondTopRowFull;
    } else if (n == 10 && _r.target > 10) {
      line = kPondFrameFull;
    } else {
      line = '${spellCount(n)}.';
    }
    // Queued when the ladder did the hop - the hint's own line is in flight
    // and this would cut it off. See HintLadder.
    widget.c.say(line, replay: false, queue: fromHint);
    if (n >= _r.target) _complete();
  }

  void _complete() {
    final green =
        _frogs.where((f) => f.pad != null && !f.gone && !f.orange).length;
    if (_r.differentWay && widget.previousGreen == green && _sameWayTries < 2) {
      _sameWayTries += 1;
      setState(() => _busy = true);
      ref.read(feedbackEngineProvider).wrong();
      widget.c.say(kPondSameWay, replay: false, queue: true);
      // They dive back in rather than hopping back: the bank is always full,
      // and a splash is a better way to say "again" than a refusal.
      after(const Duration(milliseconds: 2400), () {
        setState(() {
          for (final f in _frogs) {
            if (f.pad != null) f.gone = true;
          }
        });
        ref.read(feedbackEngineProvider).bubble();
      });
      after(const Duration(milliseconds: 3000), () {
        setState(() {
          _frogs.removeWhere((f) => f.gone);
          _fillBank();
          _busy = false;
        });
        widget.c.say(pondPrompt(_r));
        _hints?.start();
      });
      return;
    }
    _done = true;
    _hints?.pause();
    if (_r.twoColors) widget.onSplit(green);
    widget.c.say(pondDoneLine(_r, green: green), replay: false, queue: true);
    final helped = (_hints?.hintsUsed ?? 0) > 0 || _sameWayTries > 0;
    widget.c.finish(gradeRound(helped: helped));
  }

  // ---- the challenge: how many? --------------------------------------------

  void _onPick(int n) {
    if (!_inputOpen) return;
    _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (n != _r.target) {
      setState(() {
        _wrongTokens[n] = (_wrongTokens[n] ?? 0) + 1;
        _misses += 1;
        _ringFrame = true;
        if (_misses >= 2) _hintedCard = _r.target;
      });
      feedback.wrong();
      widget.c.say(pondMissLine(_misses), replay: false);
      return;
    }
    _done = true;
    _hints?.pause();
    setState(() {
      _answered = n;
      _hintedCard = null;
    });
    feedback.correct();
    widget.c.say(pondDoneLine(_r), replay: false);
    final result =
        gradeRound(misses: _misses, helped: (_hints?.hintsUsed ?? 0) > 0);
    widget.c.finish(result);
  }

  // ---- help -----------------------------------------------------------------

  void _onHint(HintLevel level) {
    if (!mounted || !_inputOpen) return;
    final feedback = ref.read(feedbackEngineProvider);
    if (_r.askHowMany) {
      switch (level) {
        case HintLevel.none:
          return;
        case HintLevel.highlight:
          setState(() => _ringFrame = true);
        case HintLevel.point:
          feedback.hint();
          widget.c.say(kPondCountOn, replay: false);
        case HintLevel.demonstrate:
          feedback.hint();
          setState(() => _hintedCard = _r.target);
          widget.c.say(warmHintLine(3), replay: false);
      }
      return;
    }
    final frog = _firstWaiting(orange: false) ?? _firstWaiting();
    if (frog == null) return;
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _ringedFrog = frog.id);
      case HintLevel.point:
        setState(() => _ringedFrog = frog.id);
        feedback.hint();
        widget.c.say(warmHintLine(2), replay: false);
      case HintLevel.demonstrate:
        feedback.hint();
        widget.c.say(warmHintLine(3), replay: false);
        _hop(frog, fromHint: true);
    }
  }

  // ---- drawing --------------------------------------------------------------

  _PondGeometry? _geometry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geo = _PondGeometry(constraints.biggest, _r);
        _geometry = geo;
        final taken = <int>{
          for (final f in _frogs)
            if (f.pad != null && !f.gone) f.pad!,
        };
        final frameFull = <bool>[
          for (var fr = 0; fr < _r.frames; fr++)
            List<int>.generate(10, (i) => fr * 10 + i).every(taken.contains),
        ];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var fr = 0; fr < _r.frames; fr++)
              Positioned.fromRect(
                rect: geo.frameRect(fr),
                child: _FrameBorder(
                  radius: geo.pad * 0.28,
                  glowing: frameFull[fr] || (_ringFrame && fr == 0),
                ),
              ),
            for (var i = 0; i < _r.frames * 10; i++)
              Positioned.fromRect(
                rect: geo.padRect(i),
                child: GestureDetector(
                  key: ValueKey('pond-pad-$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onPadTap(i),
                  child: Image.asset(
                    AssetPaths.tenFrameLilyPad,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (_ringBanks)
              for (final orange in <bool>[false, true])
                _BankRing(geo: geo, orange: orange, slots: _twoColourSlots),
            for (final f in _frogs) _positionedFrog(geo, f),
            if (_r.askHowMany)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: NumberChoiceRow(
                    choices: _choices,
                    showDots: false,
                    cardWidth: 138,
                    answered: _answered,
                    hinted: _hintedCard,
                    wrongTokens: _wrongTokens,
                    locked: !_inputOpen,
                    onPick: _onPick,
                  ),
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

  Widget _positionedFrog(_PondGeometry geo, _Frog f) {
    final onPad = f.pad != null;
    final size = onPad ? geo.frog : geo.bankFrog;
    final center = onPad
        ? geo.padRect(f.pad!).center - Offset(0, geo.pad * 0.05)
        : geo.bankCenter(orange: f.orange, slot: f.slot);
    final ringed = _ringedFrog == f.id;
    return AnimatedPositioned(
      key: ValueKey('pond-frog-${f.id}'),
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
      left: center.dx - size / 2,
      top: center.dy - size / 2 + (f.gone ? geo.pad * 0.4 : 0),
      width: size,
      height: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 380),
        opacity: f.gone ? 0 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onFrogTap(f),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _HoppingFrog(
                  asset: f.orange
                      ? AssetPaths.tenFrameFrogOrange
                      : AssetPaths.tenFrameFrogGreen,
                  hop: f.hop,
                  wiggle: f.wiggle,
                  arriving: !onPad && f.hop == 0,
                ),
              ),
              if (ringed) TouchHereRingOutside(around: Size.square(size)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ten-frame itself: a soft wooden border that holds two rows of five.
///
/// The border is what makes it a ten-frame rather than ten pads on water -
/// the edges are what she counts "full" against.
class _FrameBorder extends StatelessWidget {
  const _FrameBorder({required this.radius, required this.glowing});

  final double radius;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0x3380D8E8),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: glowing ? AppColors.coinGold : AppColors.wood,
          width: glowing ? 7 : 5,
        ),
        boxShadow: glowing
            ? const [
                BoxShadow(
                  color: Color(0x88FFD66B),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}

class _BankRing extends StatelessWidget {
  const _BankRing({
    required this.geo,
    required this.orange,
    required this.slots,
  });

  final _PondGeometry geo;
  final bool orange;
  final int slots;

  @override
  Widget build(BuildContext context) {
    final a = geo.bankCenter(orange: orange, slot: 0);
    final b = geo.bankCenter(orange: orange, slot: slots - 1);
    final half = geo.bankFrog / 2;
    return TouchHereHalo(
      rect: Rect.fromPoints(
        Offset(math.min(a.dx, b.dx) - half, a.dy - half),
        Offset(math.max(a.dx, b.dx) + half, a.dy + half),
      ),
    );
  }
}

/// A frog that hops whenever [hop] changes and wiggles when [wiggle] does.
class _HoppingFrog extends StatefulWidget {
  const _HoppingFrog({
    required this.asset,
    required this.hop,
    required this.wiggle,
    required this.arriving,
  });

  final String asset;
  final int hop;
  final int wiggle;

  /// A new frog wandering onto the bank - it pops in rather than appearing.
  final bool arriving;

  @override
  State<_HoppingFrog> createState() => _HoppingFrogState();
}

class _HoppingFrogState extends State<_HoppingFrog>
    with TickerProviderStateMixin {
  late final AnimationController _hopC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );
  late final AnimationController _wiggleC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _arriveC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    value: widget.arriving ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.arriving) _arriveC.forward();
  }

  @override
  void didUpdateWidget(_HoppingFrog old) {
    super.didUpdateWidget(old);
    if (widget.hop != old.hop) _hopC.forward(from: 0);
    if (widget.wiggle != old.wiggle) _wiggleC.forward(from: 0);
  }

  @override
  void dispose() {
    _hopC.dispose();
    _wiggleC.dispose();
    _arriveC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_hopC, _wiggleC, _arriveC]),
      builder: (context, child) {
        final t = _hopC.value;
        final lift = _hopC.isAnimating ? math.sin(math.pi * t) : 0.0;
        // A squash on take-off and landing; stretched in the air.
        final stretch = _hopC.isAnimating
            ? 1 +
                0.12 * math.sin(math.pi * t) -
                0.1 * math.sin(math.pi * 2 * t).abs() * 0.5
            : 1.0;
        final wig = _wiggleC.isAnimating
            ? math.sin(_wiggleC.value * math.pi * 4) *
                0.14 *
                (1 - _wiggleC.value)
            : 0.0;
        final arrive = Curves.easeOutBack.transform(_arriveC.value);
        return Transform.translate(
          offset: Offset(0, -lift * 46),
          child: Transform.rotate(
            angle: wig,
            child: Transform.scale(
              scaleX: arrive * (2 - stretch),
              scaleY: arrive * stretch,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(widget.asset, fit: BoxFit.contain),
    );
  }
}
