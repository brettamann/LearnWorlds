// TwoAttributeHuntRunner — the Shape Garden's K.G.4 challenge variant.
//
// Each round shows a board of shapes plus a two-attribute prompt; the
// kid taps every shape that matches both attributes at once
// ("4 sides AND green", "round AND big"). Wrong taps are gently
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
import '../../data/button_labels.dart';
import '../../data/sfx_catalog.dart';
import '../../data/shape_colors.dart';
import '../../data/warm_lines.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../engines/scaffolding/hint_ladder.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/wallet_provider.dart';
import 'answer_feedback.dart';
import 'buddy_companion.dart';
import 'continue_arrow_shelf.dart';
import 'glitter_burst.dart';
import 'keeper_aside.dart';
import 'keeper_choice_overlay.dart';
import 'keeper_intro_overlay.dart';
import 'lesson_hand_pointer.dart';
import 'next_arrow_button.dart';
import 'playfield_scaffold.dart';
import 'touch_here_halo.dart';

enum _Phase {
  intro,
  demo,
  hunting,

  /// Keeper speaks over the live board and advances the round herself.
  transition,

  celebrating,

  /// Final beat only.
  interstitial,
  reward,
}

class HuntShape {
  const HuntShape({
    required this.id,
    required this.kind,
    required this.variant,
    required this.isLarge,
    required this.position,
  });

  final String id;
  final String kind;

  /// File-name variant - the artist's material name (`stone`, `stem`,
  /// `starfruit`).
  final String variant;

  /// The colour word a child would use, read off the sprite rather than
  /// restated here. It used to be a field, and it was wrong: three shapes
  /// declared `blue` and were painted grey and gold. See `shape_colors.dart`.
  String get color => shapeVariantColor(variant);

  final bool isLarge;
  final Offset position;
}

class HuntRound {
  const HuntRound({
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

  final List<HuntShape> shapes;
  final String keeperLine;
}

const List<HuntRound> kTwoAttributeHuntRounds = <HuntRound>[
  // Round 1 — "Green AND 4 sides."
  //
  // It asked for blue until 2026-09-08, and there is no blue four-sided
  // sprite in the game - the two it lit as the answer are a near-black square
  // and a grey brick. Green is the one colour the set has enough of: a green
  // square and a green rectangle to find, and a green triangle to pass over.
  // The board keeps its shape - one near-miss on each attribute - and the
  // positions are unchanged.
  HuntRound(
    title: 'Green AND 4 sides',
    prompt: 'Find every shape that is green and has four sides. Tap each one!',
    matches: <String>{'g-sq', 'g-rect'},
    shapes: <HuntShape>[
      HuntShape(
        id: 'g-sq',
        kind: 'square',
        variant: 'green',
        isLarge: false,
        position: Offset(0.18, 0.20),
      ),
      HuntShape(
        id: 'g-rect',
        kind: 'rectangle',
        variant: 'stem',
        isLarge: false,
        position: Offset(0.72, 0.66),
      ),
      // Green, and not four sides.
      HuntShape(
        id: 'g-tri',
        kind: 'triangle',
        variant: 'leaf',
        isLarge: false,
        position: Offset(0.30, 0.66),
      ),
      // Four sides, and not green.
      HuntShape(
        id: 'br-sq',
        kind: 'square',
        variant: 'brown',
        isLarge: false,
        position: Offset(0.80, 0.22),
      ),
      HuntShape(
        id: 'p-circle',
        kind: 'circle',
        variant: 'violet',
        isLarge: false,
        position: Offset(0.50, 0.30),
      ),
      HuntShape(
        id: 'y-pent',
        kind: 'pentagon',
        variant: 'starfruit',
        isLarge: false,
        position: Offset(0.55, 0.80),
      ),
    ],
    keeperLine: 'Two green shapes with four sides — you spotted both!',
  ),
  // Round 2 — "Round AND big."
  HuntRound(
    title: 'Round AND big',
    prompt: 'Find every shape that is round and big.',
    matches: <String>{'big-circle-1', 'big-circle-2'},
    shapes: <HuntShape>[
      HuntShape(
        id: 'big-circle-1',
        kind: 'circle',
        variant: 'daisy',
        isLarge: true,
        position: Offset(0.25, 0.30),
      ),
      HuntShape(
        id: 'big-circle-2',
        kind: 'circle',
        variant: 'sunflower',
        isLarge: true,
        position: Offset(0.72, 0.30),
      ),
      HuntShape(
        id: 'small-circle',
        kind: 'circle',
        variant: 'violet',
        isLarge: false,
        position: Offset(0.50, 0.16),
      ),
      HuntShape(
        id: 'big-tri',
        kind: 'triangle',
        variant: 'leaf',
        isLarge: true,
        position: Offset(0.20, 0.72),
      ),
      HuntShape(
        id: 'big-rect',
        kind: 'rectangle',
        variant: 'wood',
        isLarge: true,
        position: Offset(0.75, 0.72),
      ),
      HuntShape(
        id: 'small-semi',
        kind: 'semicircle_half',
        variant: 'green',
        isLarge: false,
        position: Offset(0.50, 0.66),
      ),
    ],
    keeperLine: 'Two big round things — both found!',
  ),
  // Round 3 — "Pointy AND yellow."
  HuntRound(
    title: 'Pointy AND yellow',
    prompt: 'Find every shape that has corners and is yellow.',
    matches: <String>{'y-tri-1', 'y-pent'},
    shapes: <HuntShape>[
      HuntShape(
        id: 'y-tri-1',
        kind: 'triangle',
        variant: 'yellow',
        isLarge: false,
        position: Offset(0.22, 0.24),
      ),
      // `pentagon-orange` until 2026-09-08, in the round that asks for
      // yellow. `starfruit` is the yellow one.
      HuntShape(
        id: 'y-pent',
        kind: 'pentagon',
        variant: 'starfruit',
        isLarge: false,
        position: Offset(0.78, 0.66),
      ),
      HuntShape(
        id: 'y-circle',
        kind: 'circle',
        variant: 'sunflower',
        isLarge: false,
        position: Offset(0.50, 0.20),
      ),
      HuntShape(
        id: 'g-tri',
        kind: 'triangle',
        variant: 'leaf',
        isLarge: false,
        position: Offset(0.72, 0.24),
      ),
      HuntShape(
        id: 'b-rect',
        kind: 'rectangle',
        variant: 'stone',
        isLarge: false,
        position: Offset(0.22, 0.70),
      ),
      HuntShape(
        id: 'p-hex',
        kind: 'hexagon',
        variant: 'terracotta',
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

  /// Bumped to (re)present the between-round keeper aside.
  int _asideToken = 0;

  /// Shape id -> wrong taps on it, driving the shake.
  Map<String, int> _wrongTokens = <String, int>{};
  int _missRotation = 0;

  /// The shape the ladder is currently pointing at, if any.
  String? _hintedId;

  HintLadder? _hints;

  /// Read eagerly - `ref.read` is illegal once dispose() has begun.
  SfxEngine? _sfxForDispose;

  /// Demo-phase hand-pointer state. Drives a quick I-Show that taps
  /// one matching shape ("Both!") and one near-miss ("Only blue —
  /// not both") on the actual round-1 board before the kid starts.
  final List<Timer> _demoTimers = <Timer>[];
  Offset _handTarget = const Offset(0.5, 0.5);
  bool _handVisible = false;
  int _pokeKey = 0;
  String? _demoHaloShapeId;
  String? _demoHaloKind; // 'match' / 'miss'

  HuntRound get _currentRound => kTwoAttributeHuntRounds[_roundIndex];
  bool get _isLastRound => _roundIndex == kTwoAttributeHuntRounds.length - 1;
  double get _progress => _completedRounds / kTwoAttributeHuntRounds.length;
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
    _sfxForDispose = ref.read(sfxEngineProvider);
    // Claimed here, not in the post-frame callback below: the release in
    // dispose() is unconditional, so the claim has to be too, or a teardown
    // before the first frame gives back a claim it never took. See
    // SfxEngine.releaseMusicBed for what that costs.
    // The higher-energy bed: this is the opt-in challenge, and it should
    // feel different from the regular garden the moment it opens.
    unawaited(_sfxForDispose!.startMusicBed(kChallengeMusicBed));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(feedbackEngineProvider).resetRound();
      if (_phase == _Phase.hunting) {
        _speakPrompt();
        _startHints();
      }
    });
  }

  @override
  void dispose() {
    _hints?.dispose();
    _celebrationTimer?.cancel();
    _cancelDemoTimers();
    final sfx = _sfxForDispose;
    if (sfx != null) sfx.releaseMusicBed();
    super.dispose();
  }

  void _cancelDemoTimers() {
    for (final t in _demoTimers) {
      t.cancel();
    }
    _demoTimers.clear();
  }

  void _startHints() {
    _hints?.dispose();
    _hints = HintLadder(onLevel: _onHintLevel)..start();
  }

  /// Escalating help. This round asks for two things at once, which is the
  /// hardest thing the Shape Garden ever asks, and it was one of four
  /// playfields where a child who did not know the answer could sit in front
  /// of it indefinitely and nothing would happen at all.
  ///
  /// The rungs point at a shape she has not found rather than restating the
  /// prompt: the prompt is already on the replay button, and hearing the same
  /// sentence a third time is not help.
  void _onHintLevel(HintLevel level) {
    if (!mounted || _phase != _Phase.hunting) return;
    final next = _nextUnfoundMatch();
    if (next == null) return;
    final feedback = ref.read(feedbackEngineProvider);
    switch (level) {
      case HintLevel.none:
        return;
      case HintLevel.highlight:
        setState(() => _hintedId = next.id);
      case HintLevel.point:
        setState(() => _hintedId = next.id);
        feedback.hint();
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: warmHintLine(2),
                cueId: '2attr:r$_roundIndex:hint-point',
              ),
            );
      case HintLevel.demonstrate:
        feedback.hint();
        ref.read(narrationPlayerProvider.notifier).speak(
              NarrationLine(
                text: warmHintLine(3),
                cueId: '2attr:r$_roundIndex:hint-demo',
              ),
            );
        _onShapeTap(next, fromHint: true);
    }
  }

  HuntShape? _nextUnfoundMatch() {
    for (final s in _currentRound.shapes) {
      if (_currentRound.matches.contains(s.id) && !_foundIds.contains(s.id)) {
        return s;
      }
    }
    return null;
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
    final round = kTwoAttributeHuntRounds.first;
    // Pick demo targets out of the round's shape pool: one that matches on
    // both attributes, and one that matches on colour alone.
    //
    // These are ids typed by hand against a const board, so the two have to
    // move together - when the round was re-authored these still named the
    // old shapes, and `firstWhere` threw before the demo drew a frame.
    // `every_sub_mode_opens_test` is what said so.
    const matchId = 'g-sq'; // green + 4 sides ✓
    const missId = 'g-tri'; // green, but three sides ✗
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
          'This square is green AND has four sides — both. Yes!',
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
          'This triangle is green, but it has three sides — only one '
              'match. Not both.',
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
        _startHints();
      }),
    );
  }

  void _onShapeTap(HuntShape shape, {bool fromHint = false}) {
    if (_phase != _Phase.hunting) return;
    if (_foundIds.contains(shape.id)) return;
    if (!fromHint) _hints?.poke();
    final isMatch = _currentRound.matches.contains(shape.id);
    if (!isMatch) {
      setState(() {
        _wrongTokens = <String, int>{
          ..._wrongTokens,
          shape.id: (_wrongTokens[shape.id] ?? 0) + 1,
        };
      });
      ref.read(feedbackEngineProvider).wrong();
      ref.read(narrationPlayerProvider.notifier).speak(
            NarrationLine(
              text: "That's not both. ${warmMissLine(_missRotation++)}",
              cueId: '2attr:r$_roundIndex:miss-${shape.id}-$_missRotation',
            ),
          );
      return;
    }
    setState(() {
      _foundIds = <String>{..._foundIds, shape.id};
      _burstKey += 1;
      _hintedId = null;
    });
    // Steps up the scale as matches accumulate, so finding the third one
    // sounds like progress rather than like the first one again.
    ref.read(feedbackEngineProvider).countStep(_foundIds.length);
    // Queued, not spoken, when the ladder did this tap. See HintLadder.
    final say = ref.read(narrationPlayerProvider.notifier);
    final line = NarrationLine(
      text: 'Yes! Both.',
      cueId: '2attr:r$_roundIndex:hit-${shape.id}',
    );
    if (fromHint) {
      say.enqueue(line);
    } else {
      say.speak(line);
    }
    if (_allFound) _finishRound();
  }

  void _finishRound() {
    _hints?.pause();
    setState(() {
      _completedRounds += 1;
      _hintedId = null;
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
                text: _currentRound.keeperLine,
                cueId: '2attr:r$_roundIndex:interstitial',
                speaker: 'sanctuary-keeper-mystic',
              ),
            );
      });
      return;
    }
    // No coin sound between rounds: this challenge pays out once, at the
    // end, so a per-round clink would promise money that isn't coming.
    feedback.roundPass(payout: false);
    _celebrationTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.transition;
        _asideToken += 1;
      });
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            NarrationLine(
              text: _currentRound.keeperLine,
              cueId: '2attr:r$_roundIndex:interstitial',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  /// The final beat's Continue. Awards the challenge bonus.
  void _claimReward() {
    ref.read(walletProvider.notifier).award(_kRewardCoins);
    setState(() => _phase = _Phase.reward);
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _rewardDialog,
            cueId: '2attr:reward',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  /// Fired by the keeper aside retiring itself, not by a button.
  void _advanceToNextRound() {
    if (!mounted || _phase != _Phase.transition) return;
    setState(() {
      _roundIndex += 1;
      _foundIds = <String>{};
      _wrongTokens = <String, int>{};
      _missRotation = 0;
      _hintedId = null;
      _phase = _Phase.hunting;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _speakPrompt();
    _startHints();
  }

  void _repeat() {
    setState(() {
      _roundIndex = 0;
      _completedRounds = 0;
      _foundIds = <String>{};
      _wrongTokens = <String, int>{};
      _missRotation = 0;
      _hintedId = null;
      _phase = _Phase.hunting;
    });
    ref.read(feedbackEngineProvider).resetRound();
    _speakPrompt();
    _startHints();
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
      _Phase.celebrating ||
      _Phase.transition =>
        _HuntLayer(
          round: _phase == _Phase.demo
              ? kTwoAttributeHuntRounds.first
              : _currentRound,
          foundIds: _foundIds,
          burstKey: _burstKey,
          wrongTokens: _wrongTokens,
          inputLocked: _phase != _Phase.hunting,
          onShapeTap: _onShapeTap,
          allDone: _phase == _Phase.celebrating,
          demoHandVisible: _phase == _Phase.demo && _handVisible,
          demoHandTarget: _handTarget,
          demoPokeKey: _pokeKey,
          demoHaloShapeId: _demoHaloShapeId,
          demoHaloKind: _demoHaloKind,
          hintedId: _hintedId,
        ),
      _Phase.interstitial => KeeperIntroOverlay(
          dialog: _currentRound.keeperLine,
          startLabel: 'Continue',
          startButtonKey: const ValueKey('2attr-interstitial-next'),
          onStart: _claimReward,
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
        PlayfieldScaffold(
          progress: _progress,
          celebrate: _phase == _Phase.celebrating || _phase == _Phase.reward,
          child: phaseContent,
        ),
        if (_phase == _Phase.hunting ||
            _phase == _Phase.celebrating ||
            _phase == _Phase.transition)
          const BuddyCompanionCorner(),
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

class _HuntLayer extends StatelessWidget {
  const _HuntLayer({
    required this.round,
    required this.foundIds,
    required this.burstKey,
    required this.wrongTokens,
    required this.inputLocked,
    required this.onShapeTap,
    required this.allDone,
    this.demoHandVisible = false,
    this.demoHandTarget = const Offset(0.5, 0.5),
    this.demoPokeKey = 0,
    this.demoHaloShapeId,
    this.demoHaloKind,
    this.hintedId,
  });

  final HuntRound round;
  final Set<String> foundIds;
  final int burstKey;

  /// Shape id -> wrong taps on it. Drives the shake.
  final Map<String, int> wrongTokens;

  final bool inputLocked;
  final ValueChanged<HuntShape> onShapeTap;
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

  /// The shape the hint ladder is ringing. A different affordance from the
  /// demo halo above and deliberately so: the halo is a blurred disc drawn
  /// behind the sprite, which against the sky reads as a drop shadow, and the
  /// ring is the one thing in the game that means "touch here".
  final String? hintedId;

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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
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
                              _HuntShapeSprite(
                                key: ValueKey('2attr-${s.id}'),
                                shape: s,
                                size: s.isLarge ? _kLargeSize : _kSmallSize,
                                found: foundIds.contains(s.id),
                                burstKey: burstKey,
                                wrongToken: wrongTokens[s.id] ?? 0,
                                inputLocked: inputLocked,
                                canvasW: w,
                                canvasH: h,
                                onTap: () => onShapeTap(s),
                                hinted: hintedId == s.id,
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
                            label: kLabelNice,
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
