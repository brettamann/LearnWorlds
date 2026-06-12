// LessonScreen — plays a lesson as a captioned + animated preview that
// mirrors the activity round the kid is about to play.
//
// Two top-level shapes:
//   - **Fawn / iShow lessons** (K.CC.4a-style): keeper intro → iShow scene
//     scheduled from runtime.iShow narration + animation steps → Continue
//     hands off to /activity.
//   - **Shape lessons** (K.G.2): keeper intro → fixed 9-step per-shape
//     sequence (circle, triangle, right-triangle, square, rectangle,
//     pentagon, hexagon, half-circle, quarter-circle). Each step is a
//     ShapeIntroLayer beat (sprite + count its sides) followed by a
//     ShapeFindRound beat (tap all the X). After the last shape, a
//     Continue arrow hands off to /activity.
//
// Detection: `runtime.iShow.shapes.isNotEmpty` picks the shape branch.
// K.CC.4a-style lessons skip the per-shape sequence entirely and run the
// existing iShow scheduler (badge, fawns, hand pointer pre-glide).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/asset_paths.dart';
import '../../data/lesson_loader.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/lesson_runtime.dart';
import '../widgets/animated_fawn.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/glitter_burst.dart';
import '../widgets/keeper_intro_overlay.dart';
import '../widgets/kg3_flat_or_solid_lesson_layer.dart';
import '../widgets/lesson_hand_pointer.dart';
import '../widgets/next_arrow_button.dart';
import '../widgets/shape_find_demo.dart';
import '../widgets/shape_find_round.dart';
import '../widgets/shape_intro_layer.dart';

/// Order the K.G.2 lesson introduces shapes in. Simple → complex; circles
/// first (no sides, easiest), then the polygon ladder, then the imperfect
/// circles which depend on understanding "side" already. 3D shapes land in
/// a later sprint per the lesson spec.
const List<String> kShapeIntroSequence = <String>[
  'circle',
  'triangle',
  'triangle-right',
  'square',
  'rectangle',
  'pentagon',
  'hexagon',
  'semicircle_half',
  'semicircle_quarter',
];

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    this.subModeOverride,
  });

  final String lessonId;

  /// When set, overrides the lesson runtime's `youDo.subMode` on the
  /// hand-off to the activity. Used by the Sanctuary node picker so a
  /// kid who picked one sub-mode but a lesson covering a different
  /// sub-mode is required (e.g. the K.CC.1 lesson is shared across the
  /// long-parade and count-on-by-ones chain entries) doesn't get
  /// dropped into the wrong activity body. Null = use the lesson's own
  /// youDo.subMode.
  final String? subModeOverride;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _LessonPhase {
  keeperIntro,
  shapeIntro,
  shapeFindDemo,
  shapeFindRound,
  shapesDone,
  flatOrSolidLesson,
  iShow,
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Future<LessonRuntime>? _future;
  final List<Timer> _timers = [];
  bool _continueEnabled = false;
  bool _skipEnabled = false;
  LessonRuntime? _runtime;
  _LessonPhase _phase = _LessonPhase.keeperIntro;

  // Per-shape sequence cursor (K.G.2 only). Indexes kShapeIntroSequence.
  int _currentShapeIdx = 0;

  // Generic iShow scene state — used by the K.CC.4a fawn stage. Untouched
  // by the shape sequence.
  final Set<String> _sparkled = <String>{};
  int? _badgeValue; // null = hidden
  bool _pointerVisible = false;
  String? _pointerTargetId;
  bool _handAtTarget = false;
  int _pokeCounter = 0;
  final Map<String, int> _burstCounters = <String, int>{};

  /// Concept-specific keeper dialogue. Kept here so every introducing
  /// activity's keeper line lives in one place. The fawns line is the
  /// K.CC.4a default — every other concept that uses LessonScreen needs
  /// its own case so the kid doesn't hear "the fawns wander off" before
  /// a lesson about clusters or counting on.
  String _keeperIntroDialog(LessonRuntime? runtime) {
    switch (runtime?.conceptId) {
      case 'K.G.2':
        return 'Look — some plants in the garden have grown into shapes! '
            "Help me find them all, won't you?";
      case 'K.G.3':
        return 'Some shapes are flat — like drawings on a page. Others are '
            'solid — you can hold them in your hand. Help me sort them into '
            'the right baskets!';
      case 'K.CC.1':
        return "Today the parade is HUGE. Don't worry — we can count by "
            'tens! Watch how a big group of ten becomes one easy count.';
      case 'K.CC.2':
        return "We don't always start at one. When some are already counted, "
            'we can keep going from there. Let me show you.';
      default:
        return "Oh, thank goodness you're here. The fawns wander off every "
            'time I blink. Can you help me make sure all three are still '
            'in the meadow?';
    }
  }

  String _keeperIntroStartLabel(LessonRuntime? runtime) {
    switch (runtime?.conceptId) {
      case 'K.G.2':
        return "Let's look!";
      case 'K.G.3':
        return "Let's sort!";
      case 'K.CC.1':
      case 'K.CC.2':
        return "Let's count!";
      default:
        return "Let's count!";
    }
  }

  /// Idempotent keeper-intro narration. The post-frame callback in the
  /// FutureBuilder calls this on every rebuild; the flag makes it a no-op
  /// after the first fire.
  bool _keeperIntroSpoken = false;

  @override
  void initState() {
    super.initState();
    _future = const LessonLoader().load(widget.lessonId);
  }

  void _speakKeeperIntroOnce(LessonRuntime runtime) {
    if (_keeperIntroSpoken) return;
    _keeperIntroSpoken = true;
    ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
          NarrationLine(
            text: _keeperIntroDialog(runtime),
            cueId: 'lesson:keeper-intro',
            speaker: 'sanctuary-keeper-mystic',
          ),
        );
  }

  /// True for lessons whose iShow scene includes painted shapes (K.G.2).
  /// We use this rather than the conceptId switch so adjacent shape-recog
  /// lessons get the same treatment without touching this file.
  bool _isShapeLesson(LessonRuntime runtime) =>
      runtime.iShow.shapes.isNotEmpty;

  void _onKeeperStartPressed() {
    final runtime = _runtime;
    if (runtime == null) return;
    if (runtime.conceptId == 'K.G.3') {
      setState(() => _phase = _LessonPhase.flatOrSolidLesson);
      return;
    }
    if (_isShapeLesson(runtime)) {
      setState(() {
        _currentShapeIdx = 0;
        _phase = _LessonPhase.shapeIntro;
      });
      return;
    }
    setState(() => _phase = _LessonPhase.iShow);
    _scheduleIShow(runtime);
  }

  void _onFlatOrSolidLessonComplete() {
    if (!mounted) return;
    _goToYouDo();
  }

  void _onShapeIntroComplete() {
    if (!mounted) return;
    // Show the auto-walk demo only before the *first* find round of the
    // whole sequence (index 0 — circles). After that the kid already
    // knows the mechanic; subsequent shapes go straight to interactive
    // play.
    final nextPhase = _currentShapeIdx == 0
        ? _LessonPhase.shapeFindDemo
        : _LessonPhase.shapeFindRound;
    setState(() => _phase = nextPhase);
  }

  void _onShapeFindDemoComplete() {
    if (!mounted) return;
    setState(() => _phase = _LessonPhase.shapeFindRound);
  }

  void _onShapeFindRoundComplete() {
    if (!mounted) return;
    final next = _currentShapeIdx + 1;
    if (next >= kShapeIntroSequence.length) {
      // All 9 shapes done — celebratory beat, then hand off via the
      // Continue arrow.
      ref.read(narrationPlayerProvider.notifier).speak(
            const NarrationLine(
              text: 'Wow! You learned every shape in the garden.',
              cueId: 'lesson:shapes-done',
            ),
          );
      setState(() {
        _phase = _LessonPhase.shapesDone;
        _continueEnabled = true;
      });
      return;
    }
    setState(() {
      _currentShapeIdx = next;
      _phase = _LessonPhase.shapeIntro;
    });
  }

  void _scheduleIShow(LessonRuntime runtime) {
    final player = ref.read(narrationPlayerProvider.notifier);

    // Narration cues.
    for (final cue in runtime.iShow.narrationScript) {
      final at = _parseSeconds(cue.at);
      _timers.add(
        Timer(Duration(seconds: at), () {
          if (!mounted) return;
          player.speak(
            NarrationLine(text: cue.text, cueId: 'ishow:${cue.at}'),
          );
        }),
      );
    }

    // Animation steps.
    for (final step in runtime.iShow.animationSteps) {
      final at = _parseSeconds(step.at);
      _timers.add(
        Timer(Duration(seconds: at), () {
          if (!mounted) return;
          _applyAnimationStep(step);
        }),
      );
    }

    // Pre-glide the hand to each `pointer-touch` target so the poke +
    // sparkle + narration land in sync at the touch moment. The first
    // touch is arranged by the upstream `pointer-appear` step (or starts
    // mid-screen if there isn't one); we only need 2nd onward.
    final touches = runtime.iShow.animationSteps
        .where((s) => s.action == 'pointer-touch')
        .toList();
    for (var i = 1; i < touches.length; i++) {
      final touch = touches[i];
      final targetId = _resolveTargetId(touch.params['target']);
      if (targetId == null) continue;
      final touchAtMs = _parseSeconds(touch.at) * 1000;
      final preGlideAtMs = touchAtMs - handPointerGlideDuration.inMilliseconds;
      if (preGlideAtMs <= 0) continue;
      _timers.add(
        Timer(Duration(milliseconds: preGlideAtMs), () {
          if (!mounted) return;
          setState(() {
            _pointerTargetId = targetId;
            _handAtTarget = true;
          });
        }),
      );
    }

    final skipAt = runtime.iShow.skipAvailableAfterSec;
    if (skipAt > 0) {
      _timers.add(
        Timer(Duration(seconds: skipAt), () {
          if (!mounted) return;
          setState(() => _skipEnabled = true);
        }),
      );
    }
    _timers.add(
      Timer(Duration(seconds: runtime.iShow.durationSec), () {
        if (!mounted) return;
        setState(() => _continueEnabled = true);
      }),
    );
  }

  /// Resolves a JSON `target` / `position` value into a scene target id.
  /// Strips the `left-of-` prefix that some `pointer-appear` steps use.
  String? _resolveTargetId(Object? raw) {
    if (raw is! String) return null;
    final stripped = raw.startsWith('left-of-') ? raw.substring(8) : raw;
    return stripped.isEmpty ? null : stripped;
  }

  void _applyAnimationStep(AnimationStep step) {
    setState(() {
      switch (step.action) {
        case 'pointer-appear':
          _pointerVisible = true;
          _handAtTarget = false;
          final t = _resolveTargetId(step.params['position']) ??
              _resolveTargetId(step.params['target']);
          if (t != null) _pointerTargetId = t;
        case 'pointer-touch':
          _pointerVisible = true;
          _handAtTarget = true;
          final t = _resolveTargetId(step.params['target']);
          if (t != null) _pointerTargetId = t;
          _pokeCounter++;
        case 'pointer-fade-out':
          _pointerVisible = false;
          _handAtTarget = false;
          _pointerTargetId = null;
        case 'sparkle':
          final t = _resolveTargetId(step.params['target']);
          if (t != null) {
            _sparkled.add(t);
            _burstCounters[t] = (_burstCounters[t] ?? 0) + 1;
          }
        case 'count-badge-show':
        case 'count-badge-update':
          final v = step.params['value'];
          if (v is num) _badgeValue = v.toInt();
        default:
          break;
      }
    });
  }

  int _parseSeconds(String at) {
    final trimmed = at.endsWith('s') ? at.substring(0, at.length - 1) : at;
    return int.tryParse(trimmed) ?? 0;
  }

  void _goToYouDo() {
    final runtime = _runtime;
    if (runtime == null) return;
    ref.read(narrationPlayerProvider.notifier).clear();
    final subMode = widget.subModeOverride ?? runtime.youDo.subMode;
    context.go(
      '/activity/${runtime.youDo.activityId}',
      extra: {
        'fromLesson': widget.lessonId,
        'subMode': subMode,
        'roundParameters': runtime.youDo.roundParameters,
      },
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  /// Background asset chosen per concept. Shape Garden gets the garden art;
  /// Counting Parade (default) keeps the meadow.
  String _backgroundAsset(LessonRuntime? runtime) {
    switch (runtime?.conceptId) {
      case 'K.G.2':
        return AssetPaths.shapeGardenBackground;
      default:
        return AssetPaths.countingParadeMeadow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAsset(_runtime),
            fit: BoxFit.cover,
          ),
          FutureBuilder<LessonRuntime>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white70,
                    child: Text('Lesson load failed: ${snap.error}'),
                  ),
                );
              }
              final runtime = snap.requireData;
              _runtime ??= runtime;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _speakKeeperIntroOnce(runtime);
              });

              if (_phase == _LessonPhase.keeperIntro) {
                return KeeperIntroOverlay(
                  dialog: _keeperIntroDialog(runtime),
                  startLabel: _keeperIntroStartLabel(runtime),
                  startButtonKey:
                      const ValueKey('lesson-keeper-start-button'),
                  onStart: _onKeeperStartPressed,
                );
              }

              if (_phase == _LessonPhase.shapeIntro &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                return ShapeIntroLayer(
                  key: ValueKey('shape-intro-$kind'),
                  shapeKind: kind,
                  onComplete: _onShapeIntroComplete,
                );
              }

              if (_phase == _LessonPhase.shapeFindDemo &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                return ShapeFindDemo(
                  key: ValueKey('shape-find-demo-$kind'),
                  targetKind: kind,
                  onComplete: _onShapeFindDemoComplete,
                );
              }

              if (_phase == _LessonPhase.shapeFindRound &&
                  _currentShapeIdx < kShapeIntroSequence.length) {
                final kind = kShapeIntroSequence[_currentShapeIdx];
                final previousKinds =
                    kShapeIntroSequence.sublist(0, _currentShapeIdx);
                return ShapeFindRound(
                  key: ValueKey('shape-find-$kind'),
                  targetKind: kind,
                  previousKinds: previousKinds,
                  onComplete: _onShapeFindRoundComplete,
                );
              }

              if (_phase == _LessonPhase.shapesDone) {
                return const _ShapesDoneCelebration();
              }

              if (_phase == _LessonPhase.flatOrSolidLesson) {
                return Kg3FlatOrSolidLessonLayer(
                  key: const ValueKey('kg3-flat-or-solid-layer'),
                  onComplete: _onFlatOrSolidLessonComplete,
                );
              }

              // Fawn / iShow path — K.CC.4a-style lessons.
              switch (runtime.conceptId) {
                case 'K.CC.1':
                  return _ClusterStage(badgeValue: _badgeValue);
                case 'K.CC.2':
                  return _CountOnStage(badgeValue: _badgeValue);
              }
              return _FawnStage(
                sparkled: _sparkled,
                badgeValue: _badgeValue,
                pointerVisible: _pointerVisible,
                pointerTargetId: _pointerTargetId,
                handAtTarget: _handAtTarget,
                pokeCounter: _pokeCounter,
                burstCounters: _burstCounters,
              );
            },
          ),
          const CaptionOverlay(),
          // Persistent back-to-Sanctuary affordance — kids can bail from
          // any phase.
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: _BackToSanctuaryButton(
                onPressed: () {
                  ref.read(narrationPlayerProvider.notifier).clear();
                  context.go('/sanctuary');
                },
              ),
            ),
          ),
          if (_phase == _LessonPhase.iShow &&
              _skipEnabled &&
              !_continueEnabled)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: _PillButton(
                  onPressed: _goToYouDo,
                  label: "I've got this",
                ),
              ),
            ),
          if ((_phase == _LessonPhase.iShow ||
                  _phase == _LessonPhase.shapesDone) &&
              _continueEnabled)
            Positioned(
              right: 32,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: NextArrowButton(
                    key: const ValueKey('lesson-continue-arrow'),
                    idleHintEnabled: true,
                    onPressed: _goToYouDo,
                    label: 'Continue',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Fawn stage (K.CC.4a)
// ============================================================================

class _FawnStage extends StatelessWidget {
  const _FawnStage({
    required this.sparkled,
    required this.badgeValue,
    required this.pointerVisible,
    required this.pointerTargetId,
    required this.handAtTarget,
    required this.pokeCounter,
    required this.burstCounters,
  });

  final Set<String> sparkled;
  final int? badgeValue;
  final bool pointerVisible;
  final String? pointerTargetId;
  final bool handAtTarget;
  final int pokeCounter;
  final Map<String, int> burstCounters;

  static const int _fawnCount = 3;
  static const double _fawnWidth = 120;
  static const double _fawnHeight = 150;
  static const double _handSize = 96;

  int? _indexFor(String id) {
    final m = RegExp(r'fawn-(\d+)$').firstMatch(id);
    if (m == null) return null;
    final n = int.tryParse(m.group(1)!);
    if (n == null || n < 1 || n > _fawnCount) return null;
    return n - 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: badgeValue == null ? 0.0 : 1.0,
              child: _CountBadge(value: badgeValue ?? 0, target: _fawnCount),
            ),
            const Spacer(),
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    AssetPaths.sanctuaryKeeperMystic,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStack()),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotW = constraints.maxWidth / _fawnCount;
        final fawnTop = constraints.maxHeight - _fawnHeight;
        final fawnCenters = List<double>.generate(
          _fawnCount,
          (i) => (i + 0.5) * slotW,
        );

        final targetIdx =
            pointerTargetId == null ? null : _indexFor(pointerTargetId!);
        Offset handTarget;
        if (targetIdx == null) {
          handTarget = Offset(-_handSize - 20, fawnTop - 40);
        } else {
          final centerX = fawnCenters[targetIdx];
          final dx = handAtTarget ? -_handSize / 2 + 6 : -_handSize / 2 - 50;
          handTarget = Offset(centerX + dx, fawnTop - 50);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _fawnCount; i++)
              Positioned(
                left: fawnCenters[i] - _fawnWidth / 2,
                top: fawnTop,
                width: _fawnWidth,
                height: _fawnHeight,
                child: AnimatedFawn(
                  key: ValueKey('lesson-fawn-$i'),
                  active: sparkled.contains('fawn-${i + 1}'),
                  pointed: pointerVisible && targetIdx == i,
                  width: _fawnWidth,
                  height: _fawnHeight,
                ),
              ),
            for (var i = 0; i < _fawnCount; i++)
              if ((burstCounters['fawn-${i + 1}'] ?? 0) > 0)
                Positioned(
                  left: fawnCenters[i] - 70,
                  top: fawnTop + _fawnHeight / 2 - 70,
                  width: 140,
                  height: 140,
                  child: GlitterBurst(
                    key: ValueKey(
                      'burst-fawn-$i-${burstCounters['fawn-${i + 1}']}',
                    ),
                  ),
                ),
            LessonHandPointer(
              visible: pointerVisible,
              target: handTarget,
              pokeKey: pokeCounter,
              size: _handSize,
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Shapes-done celebration
// ============================================================================

/// Shown after every shape in the K.G.2 sequence has been introduced + found.
/// A static congratulatory card; the Continue arrow drawn at the LessonScreen
/// level handles the hand-off to the activity.
class _ShapesDoneCelebration extends StatelessWidget {
  const _ShapesDoneCelebration();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 72, color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'You learned every shape in the garden!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Tap Continue when you're ready to play.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.35,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Shared sub-widgets
// ============================================================================

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

/// Small chunky back arrow pinned to the top-left of the lesson.
class _BackToSanctuaryButton extends StatelessWidget {
  const _BackToSanctuaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white.withValues(alpha: 0.88),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.black87,
            semanticLabel: 'Back to the Sanctuary',
          ),
        ),
      ),
    );
  }
}

/// Tucked-corner "skip" affordance — small on purpose so the kid doesn't
/// confuse it with the big glowing Continue arrow.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: Text(label),
      ),
    );
  }
}

// ============================================================================
// K.CC.1 cluster stage — 3 columns of 10 baby gryphons, count badge above
// ============================================================================

class _ClusterStage extends StatelessWidget {
  const _ClusterStage({required this.badgeValue});

  final int? badgeValue;

  static const int _clusters = 3;
  static const int _perCluster = 10;
  static const double _spriteSize = 38;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: badgeValue == null ? 0.0 : 1.0,
              child: _RunningBadge(value: badgeValue ?? 0, target: 30),
            ),
            const Spacer(),
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    AssetPaths.sanctuaryKeeperMystic,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var c = 0; c < _clusters; c++)
                          _Cluster(
                            label: '${(c + 1) * 10}',
                            spriteAsset: AssetPaths.countingParadeBabyGryphon,
                            highlight: badgeValue != null &&
                                badgeValue! >= (c + 1) * 10,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Cluster extends StatelessWidget {
  const _Cluster({
    required this.label,
    required this.spriteAsset,
    required this.highlight,
  });

  final String label;
  final String spriteAsset;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.65 : 0.3),
        borderRadius: BorderRadius.circular(18),
        boxShadow: highlight
            ? const [
                BoxShadow(
                  color: Colors.amberAccent,
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: highlight ? Colors.black87 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: _ClusterStage._spriteSize * 2 + 12,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _ClusterStage._perCluster; i++)
                  Image.asset(
                    spriteAsset,
                    width: _ClusterStage._spriteSize,
                    height: _ClusterStage._spriteSize,
                    fit: BoxFit.contain,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// K.CC.2 count-on stage — 4 pre-counted fawns + 3 new arrivals
// ============================================================================

class _CountOnStage extends StatelessWidget {
  const _CountOnStage({required this.badgeValue});

  final int? badgeValue;

  static const int _preCount = 4;
  static const int _arrivalsCount = 3;
  static const double _spriteSize = 84;

  @override
  Widget build(BuildContext context) {
    final value = badgeValue ?? _preCount;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: badgeValue == null ? 0.0 : 1.0,
              child: _RunningBadge(value: value, target: 7),
            ),
            const Spacer(),
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(
                    AssetPaths.sanctuaryKeeperMystic,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: [
                            for (var i = 0; i < _preCount; i++)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.55,
                                    child: Image.asset(
                                      AssetPaths.countingParadeFawn,
                                      width: _spriteSize,
                                      height: _spriteSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '— new arrivals —',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          children: [
                            for (var i = 0; i < _arrivalsCount; i++)
                              AnimatedScale(
                                duration:
                                    const Duration(milliseconds: 350),
                                scale: value >= _preCount + i + 1
                                    ? 1.15
                                    : 1.0,
                                child: Image.asset(
                                  AssetPaths.countingParadeFawn,
                                  width: _spriteSize,
                                  height: _spriteSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RunningBadge extends StatelessWidget {
  const _RunningBadge({required this.value, required this.target});

  final int value;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
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
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }
}
