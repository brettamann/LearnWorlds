// The scenes LessonScreen draws under its narration: three fawns in a
// meadow (the counting lessons), clusters of ten (K.CC.1), counting on from a
// number (K.CC.2), and the shapes-done celebration. Moved out of
// lesson_screen.dart so the screen is the phase machine and nothing else.

import 'package:flutter/material.dart';

import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../theme/app_decor.dart';
import '../characters/animated_fawn.dart';
import '../common/count_badge.dart';
import '../common/glitter_burst.dart';
import '../common/read_aloud_gate.dart';
import 'lesson_hand_pointer.dart';
import 'lesson_target_registry.dart';

// ============================================================================
// Fawn stage (K.CC.4a)
// ============================================================================

class LessonFawnStage extends StatelessWidget {
  const LessonFawnStage({
    super.key,
    required this.sparkled,
    required this.badgeValue,
    required this.pointerVisible,
    required this.pointerTargetId,
    required this.handAtTarget,
    required this.pokeCounter,
    required this.burstCounters,
    required this.count,
    required this.targets,
  });

  final Set<String> sparkled;
  final int? badgeValue;
  final bool pointerVisible;
  final String? pointerTargetId;
  final bool handAtTarget;
  final int pokeCounter;
  final Map<String, int> burstCounters;

  /// From the scene, not from here. The We-Try asks for four where the I-Show
  /// showed three.
  final int count;

  /// Where each fawn ended up, so the We-Try can put a halo on the one it is
  /// asking about and tell a touch on it from a touch beside it.
  final LessonTargetRegistry targets;
  static const double _fawnWidth = 120;
  static const double _fawnHeight = 150;
  static const double _handSize = 96;

  int? _indexFor(String id) {
    final m = RegExp(r'fawn-(\d+)$').firstMatch(id);
    if (m == null) return null;
    final n = int.tryParse(m.group(1)!);
    if (n == null || n < 1 || n > count) return null;
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
              child: CountBadge(value: badgeValue ?? 0, target: count),
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
        final slotW = constraints.maxWidth / count;
        final fawnTop = constraints.maxHeight - _fawnHeight;
        final fawnCenters = List<double>.generate(
          count,
          (i) => (i + 0.5) * slotW,
        );

        final targetIdx = pointerTargetId == null
            ? null
            : _indexFor(pointerTargetId!);
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
            for (var i = 0; i < count; i++)
              Positioned(
                left: fawnCenters[i] - _fawnWidth / 2,
                top: fawnTop,
                width: _fawnWidth,
                height: _fawnHeight,
                child: AnimatedFawn(
                  key: targets.keyFor('fawn-${i + 1}'),
                  active: sparkled.contains('fawn-${i + 1}'),
                  pointed: pointerVisible && targetIdx == i,
                  width: _fawnWidth,
                  height: _fawnHeight,
                ),
              ),
            for (var i = 0; i < count; i++)
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
class ShapesDoneCelebration extends StatelessWidget {
  const ShapesDoneCelebration({super.key});

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

/// Small chunky back arrow pinned to the top-left of the lesson.

/// Tucked-corner "skip" affordance — small on purpose so the kid doesn't
/// confuse it with the big glowing Continue arrow.
class LessonPillButton extends StatelessWidget {
  const LessonPillButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Gated inside the widget rather than at the call site, per the authoring
    // rule in read_aloud_gate.dart. It was not gated at all: a white pill of
    // text on the lesson screen, silent, whose effect is to skip the teaching.
    return ReadAloudGate(
      label: label,
      cueId: 'lesson:skip',
      onTap: onPressed,
      child: Container(
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
      ),
    );
  }
}

// ============================================================================
// K.CC.1 cluster stage — 3 columns of 10 baby gryphons, count badge above
// ============================================================================

class LessonClusterStage extends StatelessWidget {
  const LessonClusterStage({
    super.key,
    required this.badgeValue,
    required this.targets,
  });

  final int? badgeValue;

  /// Registered as `cluster-1`..`cluster-3`, the ids the K.CC.1 We-Try names.
  final LessonTargetRegistry targets;

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
                            key: targets.keyFor('cluster-${c + 1}'),
                            label: decadeLabel(c),
                            spriteAsset: AssetPaths.countingParadeBabyGryphon,
                            highlight:
                                badgeValue != null &&
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
    super.key,
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
            width: LessonClusterStage._spriteSize * 2 + 12,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < LessonClusterStage._perCluster; i++)
                  Image.asset(
                    spriteAsset,
                    width: LessonClusterStage._spriteSize,
                    height: LessonClusterStage._spriteSize,
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

class LessonCountOnStage extends StatelessWidget {
  const LessonCountOnStage({
    super.key,
    required this.badgeValue,
    required this.targets,
  });

  final int? badgeValue;

  /// The K.CC.2 We-Try names the already-counted fawns `fawn-N` and the ones
  /// that walk in `new-fawn-N`.
  final LessonTargetRegistry targets;

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
                                key: targets.keyFor('fawn-${i + 1}'),
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
                                key: targets.keyFor('new-fawn-${i + 1}'),
                                duration: const Duration(milliseconds: 350),
                                scale: value >= _preCount + i + 1 ? 1.15 : 1.0,
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
      decoration: AppDecor.card(radius: 22),
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
