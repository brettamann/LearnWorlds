// The We-Try gate's halo layer.
//
// The ring itself is `TouchHereHalo`, which lives next door because the
// runners' idle-help wants the same one. What is here is the part that is
// specific to a lesson: which targets are lit, where the stage put them, and
// taking the touch that answers the gate.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'lesson_target_registry.dart';
import 'touch_here_halo.dart';

/// Draws a halo over every currently-lit target, and takes her touch.
///
/// Sits above the stage rather than inside it so that all five stage families
/// get the same affordance from one widget. The rects come from the registry
/// the stage filled in, which means the ring is drawn in exactly the place a
/// touch is tested against - the alternative, laying the halo out here and
/// hit-testing there, is how a halo ends up glowing somewhere that taps do not
/// count.
class WeTryHaloLayer extends StatefulWidget {
  const WeTryHaloLayer({
    super.key,
    required this.registry,
    required this.targets,
    required this.urgent,
    required this.onTouch,
  });

  final LessonTargetRegistry registry;

  /// Scene ids currently lit.
  final Set<String> targets;

  /// Whether she has been waiting past the lesson's hesitation threshold.
  final bool urgent;

  /// Global position of her touch. Null while no gate is open, in which case
  /// the layer lets pointers through to whatever is underneath.
  final ValueChanged<Offset>? onTouch;

  @override
  State<WeTryHaloLayer> createState() => _WeTryHaloLayerState();
}

class _WeTryHaloLayerState extends State<WeTryHaloLayer>
    with SingleTickerProviderStateMixin {
  Map<String, Rect> _rects = const <String, Rect>{};

  /// Re-measures every frame rather than once on mount.
  ///
  /// A single measurement is wrong more often than it looks. The stage moves
  /// under the halo for two ordinary reasons: sprites are `Image.asset`, which
  /// has no size until its PNG decodes, so the first layout after mount is not
  /// the layout the child sees; and the stages animate - Buddy glides between
  /// spots, creatures walk in. Measuring once put the first ring on the
  /// keeper's staff instead of the fawn beside him, because the keeper's own
  /// image had not decoded yet when the rect was taken and everything to its
  /// right shifted when it did.
  ///
  /// The cost is a handful of `localToGlobal` calls per frame, and `setState`
  /// only fires when a rect actually moves.
  /// Created eagerly rather than `late final`: a lazy field that is first
  /// touched in `dispose()` gets *built* there, and `createTicker` reaches for
  /// an ancestor that is already gone by then.
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _measure())..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final measured = <String, Rect>{};
    for (final id in widget.targets) {
      final global = widget.registry.rectOf(id);
      if (global == null) continue;
      measured[id] = box.globalToLocal(global.topLeft) & global.size;
    }
    if (!mapEquals(measured, _rects)) setState(() => _rects = measured);
  }

  @override
  Widget build(BuildContext context) {
    final onTouch = widget.onTouch;
    return Listener(
      behavior: onTouch == null
          ? HitTestBehavior.translucent
          : HitTestBehavior.opaque,
      onPointerDown: onTouch == null ? null : (e) => onTouch(e.position),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: SizedBox()),
          // A marker for "this layer is currently taking her touch", which is
          // otherwise invisible: the halo is up both while she is being told
          // what to do and while she is being waited for, so a test that
          // guesses when the gate opened guesses wrong and then reports a
          // silent beat that is really a beat that had not started.
          if (onTouch != null)
            const Positioned(
              key: ValueKey('we-try-gate-open'),
              width: 0,
              height: 0,
              child: SizedBox(),
            ),
          for (final entry in _rects.entries)
            TouchHereHalo(
              key: ValueKey('we-try-halo-${entry.key}'),
              rect: entry.value,
              urgent: widget.urgent,
            ),
        ],
      ),
    );
  }
}
