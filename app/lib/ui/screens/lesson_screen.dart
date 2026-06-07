// LessonScreen — plays a lesson's iShow phase as a captioned + animated
// preview that mirrors the Counting Parade round the kid is about to play.
// The meadow + keeper-mystic + fawn sprites are the same assets the round
// uses, so the iShow is a visual rehearsal: each tap target sparkles on cue
// and the count badge climbs in lockstep with the narration script.
//
// Lifecycle:
//   1. Load the lesson runtime.
//   2. Schedule timers for each NarrationCue + AnimationStep in iShow.
//   3. After iShow.durationSec, surface a "Continue" button.
//   4. On Continue (or Skip-after-15s), go to /activity/:id with the
//      youDo round parameters in route extras.

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
import '../widgets/lesson_hand_pointer.dart';
import '../widgets/next_arrow_button.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _LessonPhase { keeperIntro, iShow }

class _LessonScreenState extends ConsumerState<LessonScreen> {
  Future<LessonRuntime>? _future;
  final List<Timer> _timers = [];
  bool _continueEnabled = false;
  bool _skipEnabled = false;
  LessonRuntime? _runtime;
  _LessonPhase _phase = _LessonPhase.keeperIntro;

  // Scene state driven by the iShow animation timeline.
  final Set<int> _sparkled = <int>{};
  int? _badgeValue; // null = hidden
  bool _pointerVisible = false;
  int? _pointerTarget; // 0-based fawn index
  // Hand pointer state — see specs/shared/lesson-demonstration.md for the
  // glide→poke→glitter→hop pattern this drives.
  bool _handAtTarget = false; // false = hovering "left-of-fawn-N" approach pose
  int _pokeCounter = 0; // bumps each `pointer-touch` step to retrigger poke
  // One generation counter per fawn so a fresh GlitterBurst widget spawns on
  // each `sparkle` step (key change = new instance = animation restart).
  final List<int> _burstCounters = List<int>.filled(_fawnCount, 0);

  static const int _fawnCount = 3;
  static const String _keeperIntroDialog =
      "Oh, thank goodness you're here. The fawns wander off every time I "
      'blink. Can you help me make sure all three are still in the meadow?';

  @override
  void initState() {
    super.initState();
    _future = const LessonLoader().load(widget.lessonId);
    // Speak the keeper's intro once the first frame is up. Use the no-caption
    // path: the line is already shown in the keeper's speech bubble, so
    // letting it also hit the CaptionOverlay would duplicate it on-screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(narrationPlayerProvider.notifier).speakWithoutCaption(
            const NarrationLine(
              text: _keeperIntroDialog,
              cueId: 'lesson:keeper-intro',
              speaker: 'sanctuary-keeper-mystic',
            ),
          );
    });
  }

  void _startIShow() {
    final runtime = _runtime;
    if (runtime == null) return;
    setState(() => _phase = _LessonPhase.iShow);
    _scheduleIShow(runtime);
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

    // Animation steps. Each maps to a scene-state change.
    for (final step in runtime.iShow.animationSteps) {
      final at = _parseSeconds(step.at);
      _timers.add(
        Timer(Duration(seconds: at), () {
          if (!mounted) return;
          _applyAnimationStep(step);
        }),
      );
    }

    // Pre-glide the hand to each `pointer-touch` target so the poke + sparkle
    // + narration land in sync at the touch moment instead of after the glide
    // finishes. The first touch is already accounted for by the upstream
    // `pointer-appear` step; we only need to handle the 2nd onward.
    final touches = runtime.iShow.animationSteps
        .where((s) => s.action == 'pointer-touch')
        .toList();
    for (var i = 1; i < touches.length; i++) {
      final touch = touches[i];
      final targetIdx = _indexFromTarget(touch.params['target']);
      if (targetIdx == null) continue;
      final touchAtMs = _parseSeconds(touch.at) * 1000;
      final preGlideAtMs = touchAtMs - handPointerGlideDuration.inMilliseconds;
      if (preGlideAtMs <= 0) continue;
      _timers.add(
        Timer(Duration(milliseconds: preGlideAtMs), () {
          if (!mounted) return;
          setState(() {
            _pointerTarget = targetIdx;
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

  /// Parses a string like `"fawn-3"` or `"left-of-fawn-2"` into a 0-based
  /// fawn index. Returns null for unparseable / out-of-range values so the
  /// renderer ignores actions it doesn't recognise.
  int? _indexFromTarget(Object? raw) {
    if (raw is! String) return null;
    final m = RegExp(r'fawn-(\d+)').firstMatch(raw);
    if (m == null) return null;
    final n = int.tryParse(m.group(1)!);
    if (n == null || n < 1 || n > _fawnCount) return null;
    return n - 1;
  }

  void _applyAnimationStep(AnimationStep step) {
    setState(() {
      switch (step.action) {
        case 'pointer-appear':
          _pointerVisible = true;
          _handAtTarget = false;
          final t = _indexFromTarget(step.params['position']) ??
              _indexFromTarget(step.params['target']);
          if (t != null) _pointerTarget = t;
        case 'pointer-touch':
          _pointerVisible = true;
          _handAtTarget = true;
          final t = _indexFromTarget(step.params['target']);
          if (t != null) _pointerTarget = t;
          _pokeCounter++;
        case 'pointer-fade-out':
          _pointerVisible = false;
          _handAtTarget = false;
          _pointerTarget = null;
        case 'sparkle':
          final t = _indexFromTarget(step.params['target']);
          if (t != null) {
            _sparkled.add(t);
            _burstCounters[t] = _burstCounters[t] + 1;
          }
        case 'count-badge-show':
        case 'count-badge-update':
          final v = step.params['value'];
          if (v is num) _badgeValue = v.toInt();
        default:
          // music-bed-in, scene-fade-up, narrator-begin, phase-end, etc.
          // are no-ops in this Sprint-1 scene renderer.
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
    context.go(
      '/activity/${runtime.youDo.activityId}',
      extra: {
        'fromLesson': widget.lessonId,
        'subMode': runtime.youDo.subMode,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.countingParadeMeadow,
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
              _runtime ??= snap.data;
              if (_phase == _LessonPhase.keeperIntro) {
                return KeeperIntroOverlay(
                  dialog: _keeperIntroDialog,
                  startLabel: "Let's count!",
                  startButtonKey:
                      const ValueKey('lesson-keeper-start-button'),
                  onStart: _startIShow,
                );
              }
              return _LessonStage(
                fawnCount: _fawnCount,
                sparkled: _sparkled,
                badgeValue: _badgeValue,
                pointerVisible: _pointerVisible,
                pointerTarget: _pointerTarget,
                handAtTarget: _handAtTarget,
                pokeCounter: _pokeCounter,
                burstCounters: _burstCounters,
              );
            },
          ),
          const CaptionOverlay(),
          // Persistent back-to-Sanctuary affordance — kids can bail out of a
          // lesson from any phase. Matches the AppBar back button used by
          // every other in-activity screen.
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
          if (_phase == _LessonPhase.iShow && _skipEnabled && !_continueEnabled)
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
          if (_phase == _LessonPhase.iShow && _continueEnabled)
            Positioned(
              right: 32,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Center(
                  child: NextArrowButton(
                    key: const ValueKey('lesson-continue-arrow'),
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

class _LessonStage extends StatelessWidget {
  const _LessonStage({
    required this.fawnCount,
    required this.sparkled,
    required this.badgeValue,
    required this.pointerVisible,
    required this.pointerTarget,
    required this.handAtTarget,
    required this.pokeCounter,
    required this.burstCounters,
  });

  final int fawnCount;
  final Set<int> sparkled;
  final int? badgeValue;
  final bool pointerVisible;
  final int? pointerTarget;
  final bool handAtTarget;
  final int pokeCounter;
  final List<int> burstCounters;

  // Fawn sprite size. Kept as constants so the hand-target math stays in
  // sync with how the sprites lay out.
  static const double _fawnWidth = 120;
  static const double _fawnHeight = 150;
  static const double _handSize = 96;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            // Count badge across the top — fades in once the timeline shows it.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: badgeValue == null ? 0.0 : 1.0,
              child: _CountBadge(value: badgeValue ?? 0, target: fawnCount),
            ),
            const Spacer(),
            // Keeper on the left, fawns + demo overlay on the right.
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
                  Expanded(child: _buildFawnDemoStack()),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFawnDemoStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotW = constraints.maxWidth / fawnCount;
        final fawnTop = constraints.maxHeight - _fawnHeight;
        final fawnCenters = List<double>.generate(
          fawnCount,
          (i) => (i + 0.5) * slotW,
        );

        // Where the hand should sit. Approach pose ("left-of-fawn-N") parks
        // it ~50px to the left of center; the touch pose centers it over the
        // fawn. Tweak these offsets if the pointer art changes shape.
        Offset handTarget;
        if (pointerTarget == null) {
          handTarget = Offset(-_handSize - 20, fawnTop - 40);
        } else {
          final centerX = fawnCenters[pointerTarget!];
          final dx = handAtTarget ? -_handSize / 2 + 6 : -_handSize / 2 - 50;
          handTarget = Offset(centerX + dx, fawnTop - 50);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < fawnCount; i++)
              Positioned(
                left: fawnCenters[i] - _fawnWidth / 2,
                top: fawnTop,
                width: _fawnWidth,
                height: _fawnHeight,
                child: AnimatedFawn(
                  key: ValueKey('lesson-fawn-$i'),
                  active: sparkled.contains(i),
                  pointed: pointerVisible && pointerTarget == i,
                  width: _fawnWidth,
                  height: _fawnHeight,
                ),
              ),
            for (var i = 0; i < fawnCount; i++)
              if (burstCounters[i] > 0)
                Positioned(
                  left: fawnCenters[i] - 70,
                  top: fawnTop + _fawnHeight / 2 - 70,
                  width: 140,
                  height: 140,
                  child: GlitterBurst(
                    key: ValueKey('burst-$i-${burstCounters[i]}'),
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

/// Small chunky back arrow pinned to the top-left of the lesson. The lesson
/// is full-bleed (no AppBar), so without this affordance there's no obvious
/// way out mid-iShow.
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
