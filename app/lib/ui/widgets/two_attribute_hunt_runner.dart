// TwoAttributeHuntRunner — the Shape Garden's K.G.4 challenge variant.
//
// Each round shows a board of shapes plus a two-attribute prompt; the
// kid taps every shape that matches both attributes at once
// ("4 sides AND blue", "round AND big"). Wrong taps are gently
// corrected; correct taps light up + tick a counter; when every match
// is found the round resolves.
//
// Three rounds (escalating attribute combinations). Lives at the end
// of the Shape Garden chain as the activity's optional challenge —
// surfaced from the Sanctuary picker only after every regular sub-mode
// has been completed.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/asset_paths.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../providers/wallet_provider.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_choice_overlay.dart';
import 'keeper_intro_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'next_arrow_button.dart';
import 'progress_bar_to_reward.dart';

enum _Phase { intro, demo, hunting, celebrating, interstitial, reward }

class _Shape {
  const _Shape({
    required this.id,
    required this.kind,
    required this.variant,
    required this.color,
    required this.isLarge,
    required this.position,
  });

  final String id;
  final String kind;

  /// File-name variant (the artist-named suffix like `green`, `sand`,
  /// `petal`). Doubles as the colour family for the colour attribute
  /// when the variant name is itself a colour word.
  final String variant;

  /// Coarse colour bucket used for the colour predicate.
  final String color;

  final bool isLarge;
  final Offset position;
}

class _Round {
  const _Round({
    required this.title,
    required this.prompt,
    required this.matches,
    required this.shapes,
    required this.keeperLine,
  });

  /// Short pill text shown on screen ("Blue AND 4 sides").
  final String title;

  /// Full narration ("Find every shape that is blue and has four
  /// sides.").
  final String prompt;

  /// IDs of the shapes that satisfy both attributes.
  final Set<String> matches;

  final List<_Shape> shapes;
  final String keeperLine;
}

const List<_Round> _kRounds = <_Round>[
  // Round 1 — "Blue AND 4 sides."
  _Round(
    title: 'Blue AND 4 sides',
    prompt:
        'Find every shape that is blue and has four sides. Tap each one!',
    matches: <String>{'b-sq', 'b-rect'},
    shapes: <_Shape>[
      _Shape(
        id: 'b-sq',
        kind: 'square',
        variant: 'gray',
        color: 'blue',
        isLarge: false,
        position: Offset(0.18, 0.20),
      ),
      _Shape(
        id: 'b-rect',
        kind: 'rectangle',
        variant: 'stone',
        color: 'blue',
        isLarge: false,
        position: Offset(0.72, 0.66),
      ),
      _Shape(
        id: 'b-circle',
        kind: 'circle',
        variant: 'sunflower',
        color: 'blue',
        isLarge: false,
        position: Offset(0.50, 0.30),
      ),
      _Shape(
        id: 'y-sq',
        kind: 'square',
        variant: 'green',
        color: 'green',
        isLarge: false,
        position: Offset(0.80, 0.22),
      ),
      _Shape(
        id: 'y-tri',
        kind: 'triangle',
        variant: 'yellow',
        color: 'yellow',
        isLarge: false,
        position: Offset(0.30, 0.66),
      ),
      _Shape(
        id: 'r-pent',
        kind: 'pentagon',
        variant: 'starfruit',
        color: 'yellow',
        isLarge: false,
        position: Offset(0.55, 0.80),
      ),
    ],
    keeperLine:
        'Two blue shapes with four sides — you spotted both!',
  ),
  // Round 2 — "Round AND big."
  _Round(
    title: 'Round AND big',
    prompt: 'Find every shape that is round and big.',
    matches: <String>{'big-circle-1', 'big-circle-2'},
    shapes: <_Shape>[
      _Shape(
        id: 'big-circle-1',
        kind: 'circle',
        variant: 'daisy',
        color: 'white',
        isLarge: true,
        position: Offset(0.25, 0.30),
      ),
      _Shape(
        id: 'big-circle-2',
        kind: 'circle',
        variant: 'sunflower',
        color: 'yellow',
        isLarge: true,
        position: Offset(0.72, 0.30),
      ),
      _Shape(
        id: 'small-circle',
        kind: 'circle',
        variant: 'violet',
        color: 'purple',
        isLarge: false,
        position: Offset(0.50, 0.16),
      ),
      _Shape(
        id: 'big-tri',
        kind: 'triangle',
        variant: 'leaf',
        color: 'green',
        isLarge: true,
        position: Offset(0.20, 0.72),
      ),
      _Shape(
        id: 'big-rect',
        kind: 'rectangle',
        variant: 'wood',
        color: 'brown',
        isLarge: true,
        position: Offset(0.75, 0.72),
      ),
      _Shape(
        id: 'small-semi',
        kind: 'semicircle_half',
        variant: 'green',
        color: 'green',
        isLarge: false,
        position: Offset(0.50, 0.66),
      ),
    ],
    keeperLine: 'Two big round things — both found!',
  ),
  // Round 3 — "Pointy AND yellow."
  _Round(
    title: 'Pointy AND yellow',
    prompt: 'Find every shape that has corners and is yellow.',
    matches: <String>{'y-tri-1', 'y-pent'},
    shapes: <_Shape>[
      _Shape(
        id: 'y-tri-1',
        kind: 'triangle',
        variant: 'yellow',
        color: 'yellow',
        isLarge: false,
        position: Offset(0.22, 0.24),
      ),
      _Shape(
        id: 'y-pent',
        kind: 'pentagon',
        variant: 'orange',
        color: 'yellow',
        isLarge: false,
        position: Offset(0.78, 0.66),
      ),
      _Shape(
        id: 'y-circle',
        kind: 'circle',
        variant: 'sunflower',
        color: 'yellow',
        isLarge: false,
        position: Offset(0.50, 0.20),
      ),
      _Shape(
        id: 'g-tri',
        kind: 'triangle',
        variant: 'leaf',
        color: 'green',
        isLarge: false,
        position: Offset(0.72, 0.24),
      ),
      _Shape(
        id: 'b-rect',
        kind: 'rectangle',
        variant: 'stone',
        color: 'blue',
        isLarge: false,
        position: Offset(0.22, 0.70),
      ),
      _Shape(
        id: 'p-hex',
        kind: 'hexagon',
        variant: 'terracotta',
        color: 'brown',
        isLarge: false,
        position: Offset(0.50, 0.74),
      ),
    ],
    keeperLine: 'Yellow with corners — sharp eye!',
  ),
];

/// Coins awarded once the kid clears every challenge round. Same
/// generosity tier as the counting `tens-parade` challenge.
const int _kRewardCoins = 50;

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
  late _Phase _phase = widget.skipIntro ? _Phase.hunting : _Phase.intro;
  int _roundIndex = 0;
  int _completedRounds = 0;
  Set<String> _foundIds = <String>{};
  int _burstKey = 0;
  Timer? _celebrationTimer;

  /// Demo-phase hand-pointer state. Drives a quick I-Show that taps
  /// one matching shape ("Both!") and one near-miss ("Only blue —
  /// not both") on the actual round-1 board before the kid starts.
  final List<Timer> _demoTimers = <Timer>[];
  Offset _handTarget = const Offset(0.5, 0.5);
  bool _handVisible = false;
  int _pokeKey = 0;
  String? _demoHaloShapeId;
  String? _demoHaloKind; // 'match' / 'miss'

  _Round get _currentRound => _kRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == _kRounds.length - 1;
  double get _progress => _completedRounds / _kRounds.length;
  bool get _allFound =>
      _foundIds.length == _currentRound.matches.length &&
      _foundIds.containsAll(_currentRound.matches);

  String get _introDialog =>
      'Ready for the big sort? Each round names TWO things at once — '
      'tap every shape that matches BOTH. Get them all and earn '
      '$_kRewardCoins bonus coins!';

  String get _rewardDialog =>
      'All three rounds cleared! Two-attribute hunt is no match for you. '
      'Here are $_kRewardCoins bonus coins.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_phase == _Phase.hunting) _speakPrompt();
    });
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _cancelDemoTimers();
    super.dispose();
  }

  void _cancelDemoTimers() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    _demoTimers.clear();
  }

  void _speakPrompt() {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: _currentRound.prompt,
            cueId: '2attr:r$_roundIndex:prompt',
          ),
        );
  }

  void _speakDemo(String text, String cueId) {
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(text: text, cueId: cueId),
        );
  }

  /// Tap → start the animated demo. Plays out on the actual round-1
  /// board so the kid is looking at the real challenge by the time
  /// the prompt narration kicks in.
  void _onStartFromIntro() {
    setState(() => _phase = _Phase.demo);
    _scheduleDemo();
  }

  /// Two-beat I-Show on the round-1 board:
  ///   1. Hand glides to a TRUE match → poke → "Both!" narration +
  ///      gold halo.
  ///   2. Hand glides to a NEAR-miss (matches one attribute, not
  ///      both) → poke → "Only blue — not both." narration + red
  ///      halo.
  /// Then a closer line and the kid takes over.
  void _scheduleDemo() {
    final round = _kRounds.first;
    // Pick demo targets out of the round's shape pool. The first
    // match-id is the "yes" example; we want a near-miss for the
    // "no" — a blue *circle* is blue but has no sides.
    const matchId = 'b-sq'; // blue + 4 sides ✓
    const missId = 'b-circle'; // blue but no sides ✗
    final matchShape = round.shapes.firstWhere((s) => s.id == matchId);
    final missShape = round.shapes.firstWhere((s) => s.id == missId);

    _demoTimers.add(
      Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _speakDemo(
          'Watch me. Each round needs both things at the same time.',
          '2attr:demo:intro',
        );
        setState(() {
          _handVisible = true;
          _handTarget = matchShape.position;
        });
      }),
    );
    _demoTimers.add(
      Timer(const Duration(milliseconds: 2100), () {
        if (!mounted) return;
        setState(() {
          _pokeKey += 1;
          _demoHaloShapeId = matchShape.id;
          _demoHaloKind = 'match';
          _burstKey += 1;
        });
        _speakDemo(
          'This square is blue AND has four sides — both. Yes!',
          '2attr:demo:match',
        );
      }),
    );
    _demoTimers.add(
      Timer(const Duration(milliseconds: 5200), () {
        if (!mounted) return;
        setState(() {
          _demoHaloShapeId = null;
          _handTarget = missShape.position;
        });
      }),
    );
    _demoTimers.add(
      Timer(const Duration(milliseconds: 6400), () {
        if (!mounted) return;
        setState(() {
          _pokeKey += 1;
          _demoHaloShapeId = missShape.id;
          _demoHaloKind = 'miss';
        });
        _speakDemo(
          'This circle is blue, but it has no sides — only one match. '
          'Not both.',
          '2attr:demo:miss',
        );
      }),
    );
    _demoTimers.add(
      Timer(const Duration(milliseconds: 9800), () {
        if (!mounted) return;
        setState(() {
          _demoHaloShapeId = null;
          _demoHaloKind = null;
          _handVisible = false;
        });
        _speakDemo(
          'Your turn. Find every shape that matches BOTH!',
          '2attr:demo:handoff',
        );
      }),
    );
    _demoTimers.add(
      Timer(const Duration(milliseconds: 11600), () {
        if (!mounted) return;
        setState(() => _phase = _Phase.hunting);
        _speakPrompt();
      }),
    );
  }

  void _onShapeTap(_Shape shape) {
    if (_phase != _Phase.hunting) return;
    if (_foundIds.contains(shape.id)) return;
    final isMatch = _currentRound.matches.contains(shape.id);
    if (!isMatch) {
      ref.read(narrationPlayerProvider.notifier).speak(
            NarrationLine(
              text: "That's not both. Try another!",
              cueId: '2attr:r$_roundIndex:miss-${shape.id}',
            ),
          );
      return;
    }
    setState(() {
      _foundIds = <String>{..._foundIds, shape.id};
      _burstKey += 1;
    });
    ref.read(narrationPlayerProvider.notifier).speak(
          NarrationLine(
            text: 'Yes! Both.',
            cueId: '2attr:r$_roundIndex:hit-${shape.id}',
          ),
        );
    if (_allFound) _finishRound();
  }

  void _finishRound() {
    setState(() {
      _completedRounds += 1;
      _phase = _Phase.celebrating;
    });
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.interstitial);
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: _currentRound.keeperLine,
              cueId: '2attr:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  void _advanceFromInterstitial() {
    if (_isLastRound) {
      ref.read(walletProvider.notifier).award(_kRewardCoins);
      setState(() => _phase = _Phase.reward);
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: _rewardDialog,
              cueId: '2attr:reward',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
      return;
    }
    setState(() {
      _roundIndex += 1;
      _foundIds = <String>{};
      _phase = _Phase.hunting;
    });
    _speakPrompt();
  }

  void _repeat() {
    setState(() {
      _roundIndex = 0;
      _completedRounds = 0;
      _foundIds = <String>{};
      _phase = _Phase.hunting;
    });
    _speakPrompt();
  }

  @override
  Widget build(BuildContext context) {
    final phaseContent = switch (_phase) {
      _Phase.intro => KeeperIntroOverlay(
          dialog: _introDialog,
          startLabel: 'Challenge!',
          startButtonKey: const ValueKey('2attr-start-button'),
          onStart: _onStartFromIntro,
        ),
      _Phase.demo ||
      _Phase.hunting ||
      _Phase.celebrating =>
        _HuntLayer(
          round: _phase == _Phase.demo ? _kRounds.first : _currentRound,
          foundIds: _foundIds,
          burstKey: _burstKey,
          inputLocked:
              _phase == _Phase.celebrating || _phase == _Phase.demo,
          onShapeTap: _onShapeTap,
          allDone: _phase == _Phase.celebrating,
          demoHandVisible: _phase == _Phase.demo && _handVisible,
          demoHandTarget: _handTarget,
          demoPokeKey: _pokeKey,
          demoHaloShapeId: _demoHaloShapeId,
          demoHaloKind: _demoHaloKind,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _currentRound.keeperLine,
          startLabel: _isLastRound ? 'Continue' : 'Next round!',
          startButtonKey: const ValueKey('2attr-interstitial-next'),
          onStart: _advanceFromInterstitial,
        ),
      _Phase.reward => KeeperChoiceOverlay(
          dialog: _rewardDialog,
          secondaryLabel: 'Continue',
          primaryLabel: 'Again!',
          onSecondary: widget.onSequenceComplete,
          onPrimary: _repeat,
          secondaryButtonKey: const ValueKey('2attr-finish'),
          primaryButtonKey: const ValueKey('2attr-repeat'),
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.shapeGardenBackground, fit: BoxFit.cover),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: ProgressBarToReward(
                  progress: _progress,
                  celebrate: _phase == _Phase.celebrating ||
                      _phase == _Phase.reward,
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

class _HuntLayer extends StatelessWidget {
  const _HuntLayer({
    required this.round,
    required this.foundIds,
    required this.burstKey,
    required this.inputLocked,
    required this.onShapeTap,
    required this.allDone,
    this.demoHandVisible = false,
    this.demoHandTarget = const Offset(0.5, 0.5),
    this.demoPokeKey = 0,
    this.demoHaloShapeId,
    this.demoHaloKind,
  });

  final _Round round;
  final Set<String> foundIds;
  final int burstKey;
  final bool inputLocked;
  final ValueChanged<_Shape> onShapeTap;
  final bool allDone;

  /// Demo-phase overlay state. When `demoHandVisible` is true the
  /// hand pointer glides to `demoHandTarget` (normalized) and pokes
  /// each time `demoPokeKey` changes. `demoHaloShapeId` + `demoHaloKind`
  /// (`'match'` / `'miss'`) light up the shape under the hand so the
  /// kid sees "this is the kind of answer that counts" and "this is
  /// the kind that doesn't."
  final bool demoHandVisible;
  final Offset demoHandTarget;
  final int demoPokeKey;
  final String? demoHaloShapeId;
  final String? demoHaloKind;

  static const double _kSmallSize = 72;
  static const double _kLargeSize = 124;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            // Attribute pill across the top — visible so a kid mid-
            // round can re-check the conditions without re-tapping
            // anything for narration.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.deepPurple.shade200,
                  width: 2,
                ),
              ),
              child: Text(
                round.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return Stack(
                          children: [
                            for (final s in round.shapes)
                              _HuntShape(
                                key: ValueKey('2attr-${s.id}'),
                                shape: s,
                                size: s.isLarge ? _kLargeSize : _kSmallSize,
                                found: foundIds.contains(s.id),
                                burstKey: burstKey,
                                inputLocked: inputLocked,
                                canvasW: w,
                                canvasH: h,
                                onTap: () => onShapeTap(s),
                                demoHaloKind: demoHaloShapeId == s.id
                                    ? demoHaloKind
                                    : null,
                              ),
                            if (demoHandVisible)
                              LessonHandPointer(
                                visible: true,
                                target: Offset(
                                  demoHandTarget.dx * w - 48,
                                  demoHandTarget.dy * h - 48,
                                ),
                                pokeKey: demoPokeKey,
                                size: 96,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  kContinueArrowShelf(
                    child: allDone
                        ? const NextArrowButton(
                            key: ValueKey('2attr-done-arrow'),
                            idleHintEnabled: true,
                            onPressed: _noop,
                            label: 'Nice!',
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _HuntShape extends StatelessWidget {
  const _HuntShape({
    super.key,
    required this.shape,
    required this.size,
    required this.found,
    required this.burstKey,
    required this.inputLocked,
    required this.canvasW,
    required this.canvasH,
    required this.onTap,
    this.demoHaloKind,
  });

  final _Shape shape;
  final double size;
  final bool found;
  final int burstKey;
  final bool inputLocked;
  final double canvasW;
  final double canvasH;
  final VoidCallback onTap;

  /// Demo-phase highlight. `'match'` paints a gold halo ("yes — both
  /// of these things") and `'miss'` paints a red one ("only one of
  /// the things"). Null = no demo halo, normal hunt rendering.
  final String? demoHaloKind;

  @override
  Widget build(BuildContext context) {
    final cx = shape.position.dx * canvasW;
    final cy = shape.position.dy * canvasH;
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
                        color: Colors.amber.shade400
                            .withValues(alpha: 0.6),
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
          ],
        ),
      ),
    );
  }
}
