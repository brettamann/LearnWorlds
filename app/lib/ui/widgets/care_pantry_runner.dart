// Care Pantry - K.MD.3: classify, count, and compare the counts.
//
// The supply hut floor is a muddle of food. Crates stand along the back wall,
// each with a picture of what goes in it pinned above it - a picture, because
// the person sorting cannot read a label.
//
// The spec has her drag each item to its crate. That is two skills at once,
// and only one of them is the standard: dragging to a target is motor control,
// deciding what belongs with what is classification. So each round is a hunt
// instead - "Put away the apples! Tap every apple" - and every apple she finds
// flies into its crate while the count climbs. The classifying is all hers
// (she has to find the apples among the carrots, and a carrot she taps during
// the apple hunt gives a gentle shake), and the crate she is filling is lit so
// she always knows which one it is.
//
// Then the other half of K.MD.3: "Which crate has the most?" The crates show
// what is inside them, so the answer is something she can see as well as
// count. The full pantry asks for the fewest too.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activities/activity_ids.dart';
import '../../data/asset_paths.dart';
import '../../data/care_pantry_words.dart';
import '../../data/number_words.dart';
import '../../data/round_pick.dart';
import '../../data/sfx_catalog.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/mastery/round_outcome.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../common/timer_scope.dart';
import 'answer_feedback.dart';
import 'glitter_burst.dart';
import 'lesson_hand_pointer.dart';
import 'sanctuary_round_shell.dart';
import 'touch_here_halo.dart';

class CarePantryRunner extends ConsumerWidget {
  const CarePantryRunner({
    super.key,
    required this.onSequenceComplete,
    this.subMode = kPantrySubSimple,
    this.skipIntro = false,
  });

  final VoidCallback onSequenceComplete;
  final String subMode;
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = pantryRoundsFor(
      subMode,
      seed: roundSeed(ref.watch(sessionIdProvider), subMode),
    );
    return SanctuaryRoundShell(
      activityId: ActivityIds.carePantry,
      roundCount: rounds.length,
      conceptIdFor: (_) => 'K.MD.3',
      introLine: kPantryIntro,
      keeperLineFor: pantryKeeperLine,
      finalLine: kPantryFinal,
      skipIntro: skipIntro,
      musicBed:
          subMode == kPantrySubColour ? kChallengeMusicBed : kDefaultMusicBed,
      onSequenceComplete: onSequenceComplete,
      background: Image.asset(
        AssetPaths.carePantryBackground,
        fit: BoxFit.cover,
      ),
      roundBuilder: (context, c) =>
          PantryRoundBody(round: rounds[c.index], c: c),
    );
  }
}

class _Item {
  _Item({required this.id, required this.kind, required this.spot});
  final int id;
  final PantryKind kind;

  /// Index into the floor layout.
  final int spot;

  /// Which crate it went into, once it did.
  int? crate;

  /// In the air on its way to a crate - drawn over the crate, not in it yet.
  bool flying = false;
  int wrong = 0;
}

enum _Stage { sorting, askMost, askFewest, done }

class PantryRoundBody extends ConsumerStatefulWidget {
  const PantryRoundBody({super.key, required this.round, required this.c});

  final PantryRound round;
  final RoundContext c;

  @override
  ConsumerState<PantryRoundBody> createState() => _PantryRoundBodyState();
}

class _PantryRoundBodyState extends ConsumerState<PantryRoundBody>
    with TimerScope<PantryRoundBody> {
  final List<_Item> _items = <_Item>[];
  HintLadder? _hints;
  _Stage _stage = _Stage.sorting;
  int _active = 0;
  bool _busy = false;
  int _misses = 0;
  int _missRotation = 0;
  int? _ringedItem;
  int? _ringedCrate;
  int? _rightCrate;
  final Map<int, int> _crateWrong = <int, int>{};
  final Map<int, int> _crateBurst = <int, int>{};

  bool _handVisible = false;
  Offset _handAt = Offset.zero;
  int _poke = 0;

  PantryRound get _r => widget.round;
  bool get _open => !_busy && !widget.c.locked && _stage != _Stage.done;

  @override
  void initState() {
    super.initState();
    final kinds = <PantryKind>[];
    if (_r.items.isNotEmpty) {
      kinds.addAll(_r.items);
    } else {
      for (final crate in _r.crates) {
        for (var i = 0; i < crate.count; i++) {
          kinds.add(crate.kind!);
        }
      }
    }
    // Mixed up the same way every time this round is built: a board that
    // reshuffled on a rebuild would move an apple out from under her finger.
    final order = List<int>.generate(kinds.length, (i) => i)
      ..shuffle(math.Random(widget.c.index * 131 + kinds.length));
    for (var i = 0; i < kinds.length; i++) {
      _items.add(_Item(id: i, kind: kinds[order[i]], spot: i));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.c.showDemo) {
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

  PantryCrate get _activeCrate => _r.crates[_active];

  int _inCrate(int crate) => _items.where((i) => i.crate == crate).length;

  _Item? _nextBelonging() {
    for (final it in _items) {
      if (it.crate == null && pantryBelongs(it.kind, _activeCrate)) return it;
    }
    return null;
  }

  void _begin() {
    widget.c.say(pantryPutAway(_activeCrate));
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHint)..start();
  }

  void _runDemo() {
    final it = _nextBelonging();
    final geo = _geo;
    if (it == null || geo == null) return _begin();
    setState(() {
      _busy = true;
      _handVisible = true;
      _handAt = geo.itemCenter(it.spot);
    });
    widget.c.say(kPantryDemo, replay: false);
    after(const Duration(milliseconds: 900), () => setState(() => _poke++));
    after(const Duration(milliseconds: 1100), () {
      setState(() {
        it
          ..crate = _active
          ..flying = true;
        _handVisible = false;
      });
      ref.read(feedbackEngineProvider).drop();
    });
    // And back out again - the first one is hers to find.
    after(const Duration(milliseconds: 2600), () {
      widget.c.say(kPantryDemoBack, replay: false, queue: true);
      setState(() {
        it
          ..crate = null
          ..flying = false;
      });
    });
    after(const Duration(milliseconds: 4600), () {
      setState(() => _busy = false);
      _begin();
    });
  }

  void _onItemTap(_Item it, {bool fromHint = false}) {
    if (!_open || _stage != _Stage.sorting || it.crate != null) return;
    if (!fromHint) _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    if (!pantryBelongs(it.kind, _activeCrate)) {
      setState(() {
        it.wrong += 1;
        _misses += 1;
      });
      feedback.wrong();
      widget.c.say(
        pantryMissKind(_missRotation++, _activeCrate),
        replay: false,
      );
      return;
    }
    setState(() {
      it
        ..crate = _active
        ..flying = true;
      _ringedItem = null;
    });
    final n = _inCrate(_active);
    feedback
      ..drop()
      ..countStep(n);
    after(const Duration(milliseconds: 480), () {
      setState(() => it.flying = false);
    });
    final crateDone = n >= _activeCrate.count;
    if (!crateDone) {
      widget.c.say('${spellCount(n)}.', replay: false, queue: fromHint);
      return;
    }
    // The last one in: say how many that kind came to.
    widget.c.say(pantryCounted(_activeCrate), replay: false, queue: true);
    if (_active < _r.crates.length - 1) {
      setState(() => _active += 1);
      widget.c.say(pantryPutAway(_activeCrate), queue: true);
      _hints?.start();
      return;
    }
    if (_r.askMost) {
      setState(() => _stage = _Stage.askMost);
      widget.c.say(kPantryAskMost, queue: true);
      _hints?.start();
      return;
    }
    _finish();
  }

  int _extremeCrate({required bool most}) {
    var best = 0;
    for (var i = 1; i < _r.crates.length; i++) {
      final a = _r.crates[i].count;
      final b = _r.crates[best].count;
      if (most ? a > b : a < b) best = i;
    }
    return best;
  }

  void _onCrateTap(int crate) {
    if (!_open) return;
    if (_stage == _Stage.sorting) {
      // Not a question yet, but she touched it - say what this crate is
      // waiting for, which is the thing she most likely wanted to know.
      ref.read(feedbackEngineProvider).sparkle();
      widget.c.say(pantryPutAway(_activeCrate), replay: false);
      return;
    }
    if (_stage != _Stage.askMost && _stage != _Stage.askFewest) return;
    _hints?.poke();
    final feedback = ref.read(feedbackEngineProvider);
    final most = _stage == _Stage.askMost;
    final right = _extremeCrate(most: most);
    if (crate != right) {
      setState(() {
        _crateWrong[crate] = (_crateWrong[crate] ?? 0) + 1;
        _misses += 1;
      });
      feedback.wrong();
      widget.c.say(pantryMissCrate(_missRotation++), replay: false);
      return;
    }
    feedback.correct();
    setState(() {
      _rightCrate = crate;
      _ringedCrate = null;
      _crateBurst[crate] = (_crateBurst[crate] ?? 0) + 1;
    });
    final c = _r.crates[crate];
    widget.c.say(
      most ? pantryRightMost(c) : pantryRightFewest(c),
      replay: false,
    );
    if (most && _r.askFewest) {
      setState(() {
        _stage = _Stage.askFewest;
        _busy = true;
      });
      after(const Duration(milliseconds: 1600), () {
        setState(() {
          _rightCrate = null;
          _busy = false;
        });
        widget.c.say(kPantryAskFewest, queue: true);
        _hints?.start();
      });
      return;
    }
    _finish();
  }

  void _finish() {
    _stage = _Stage.done;
    _hints?.pause();
    final helped = (_hints?.hintsUsed ?? 0) > 0;
    widget.c.finish(
      gradeRound(misses: _misses, helped: helped),
    );
  }

  void _onHint(HintLevel level) {
    if (!mounted || !_open) return;
    final feedback = ref.read(feedbackEngineProvider);
    if (_stage == _Stage.sorting) {
      final it = _nextBelonging();
      if (it == null) return;
      switch (level) {
        case HintLevel.none:
          return;
        case HintLevel.highlight:
          setState(() => _ringedItem = it.id);
        case HintLevel.point:
          setState(() => _ringedItem = it.id);
          feedback.hint();
          widget.c.say(warmHintLine(2), replay: false);
        case HintLevel.demonstrate:
          feedback.hint();
          widget.c.say(warmHintLine(3), replay: false);
          _onItemTap(it, fromHint: true);
      }
      return;
    }
    switch (level) {
      case HintLevel.none:
      case HintLevel.highlight:
        return;
      case HintLevel.point:
        feedback.hint();
        widget.c.say(kPantryLookFull, replay: false);
      case HintLevel.demonstrate:
        feedback.hint();
        setState(
          () => _ringedCrate = _extremeCrate(most: _stage == _Stage.askMost),
        );
        widget.c.say(warmHintLine(3), replay: false);
    }
  }

  _PantryGeometry? _geo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geo = _PantryGeometry(
          constraints.biggest,
          crates: _r.crates.length,
          items: _items.length,
        );
        _geo = geo;
        final asking = _stage == _Stage.askMost || _stage == _Stage.askFewest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _r.crates.length; i++)
              Positioned.fromRect(
                rect: geo.crateRect(i),
                child: GestureDetector(
                  key: ValueKey('pantry-crate-$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onCrateTap(i),
                  child: AnswerFeedback(
                    wrongToken: _crateWrong[i] ?? 0,
                    child: _CrateView(
                      crate: _r.crates[i],
                      contents: _items
                          .where((it) => it.crate == i && !it.flying)
                          .map((it) => it.kind.asset)
                          .toList(),
                      lit: (_stage == _Stage.sorting && i == _active) ||
                          _rightCrate == i,
                      askable: asking,
                      ringed: _ringedCrate == i,
                      burst: _crateBurst[i] ?? 0,
                    ),
                  ),
                ),
              ),
            for (final it in _items) _floorItem(geo, it),
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

  Widget _floorItem(_PantryGeometry geo, _Item it) {
    final inCrate = it.crate != null;
    final Rect rect;
    if (inCrate) {
      final c = geo.crateRect(it.crate!).center;
      rect = Rect.fromCenter(
        center: c,
        width: geo.item * 0.4,
        height: geo.item * 0.4,
      );
    } else {
      rect = Rect.fromCenter(
        center: geo.itemCenter(it.spot),
        width: geo.item,
        height: geo.item,
      );
    }
    return AnimatedPositioned.fromRect(
      key: ValueKey('pantry-item-${it.id}'),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
      rect: rect,
      child: IgnorePointer(
        ignoring: inCrate,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: inCrate && !it.flying ? 0 : 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onItemTap(it),
            child: AnswerFeedback(
              wrongToken: it.wrong,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(it.kind.asset, fit: BoxFit.contain),
                  ),
                  if (_ringedItem == it.id)
                    TouchHereRingOutside(around: Size.square(geo.item)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PantryGeometry {
  _PantryGeometry(this.size, {required this.crates, required this.items}) {
    final w = size.width;
    crateW = math.min(200, (w - 40) / crates - 24);
    crateH = crateW * 0.95;
    item = math.min(100, math.max(78, w / 11));
    cols = math.min(
      items,
      math.max(4, ((w - kBuddyCornerReserve) / (item * 1.35)).floor()),
    );
    rows = (items / cols).ceil();
  }

  final Size size;
  final int crates;
  final int items;
  late final double crateW;
  late final double crateH;
  late final double item;
  late final int cols;
  late final int rows;

  Rect crateRect(int i) {
    const gap = 28.0;
    final total = crates * crateW + (crates - 1) * gap;
    final left = (size.width - total) / 2 + i * (crateW + gap);
    return Rect.fromLTWH(left, 8, crateW, crateH);
  }

  /// The floor: a loose grid below the crates, nudged about so it reads as a
  /// muddle rather than a display, and kept clear of Buddy's corner.
  Offset itemCenter(int spot) {
    final top = 8 + crateH + 30;
    final bottom = size.height - 16;
    const left = kBuddyCornerReserve * 0.6;
    final right = size.width - 20;
    final cx = spot % cols;
    final cy = spot ~/ cols;
    final cellW = (right - left) / cols;
    final cellH = (bottom - top) / math.max(rows, 2);
    final jitter = math.Random(spot * 977);
    final dx = (jitter.nextDouble() - 0.5) * cellW * 0.25;
    final dy = (jitter.nextDouble() - 0.5) * cellH * 0.2;
    return Offset(
      left + (cx + 0.5) * cellW + dx,
      top + (cy + 0.5) * cellH + dy,
    );
  }
}

class _CrateView extends StatelessWidget {
  const _CrateView({
    required this.crate,
    required this.contents,
    required this.lit,
    required this.askable,
    required this.ringed,
    required this.burst,
  });

  final PantryCrate crate;
  final List<String> contents;
  final bool lit;
  final bool askable;
  final bool ringed;
  final int burst;

  static const Map<String, Color> _colours = <String, Color>{
    'red': Color(0xFFE53935),
    'orange': Color(0xFFFB8C00),
    'green': Color(0xFF43A047),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final badge = w * 0.36;
        final mini = w * 0.25;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: box.maxHeight - badge * 0.6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: lit
                      ? const [
                          BoxShadow(
                            color: Color(0x99FFD54F),
                            blurRadius: 22,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Image.asset(
                  AssetPaths.carePantryCrate,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            // What is inside, drawn in front of the crate so it reads as
            // piled in it - and so "which has the most" is something she can
            // see, not only something she can count. It was behind the crate
            // at first, which hid every item she had put away.
            Positioned(
              left: w * 0.06,
              right: w * 0.06,
              top: badge * 0.62,
              bottom: 4,
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 0,
                  runSpacing: -mini * 0.3,
                  children: [
                    for (final a in contents)
                      SizedBox(
                        width: mini,
                        height: mini,
                        child: Image.asset(a, fit: BoxFit.contain),
                      ),
                  ],
                ),
              ),
            ),
            // The label: a picture of what goes in, or a splash of colour.
            Positioned(
              left: (w - badge) / 2,
              top: 0,
              width: badge,
              height: badge,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: crate.byColour
                      ? _colours[pantryCrateColour(crate)]
                      : const Color(0xFFFFFBF0),
                  border: Border.all(
                    color: lit ? AppColors.hintGlow : AppColors.wood,
                    width: lit ? 5 : 3,
                  ),
                ),
                padding: EdgeInsets.all(badge * 0.14),
                child: crate.byColour
                    ? null
                    : Image.asset(crate.kind!.asset, fit: BoxFit.contain),
              ),
            ),
            if (ringed) TouchHereRingOutside(around: box.biggest),
            if (burst > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: GlitterBurst(
                    key: ValueKey('crate-burst-$burst'),
                    maxRadius: w * 0.7,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
