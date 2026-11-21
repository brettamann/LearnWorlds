// Where the things a lesson can name actually are on screen.
//
// The We-Try phase needs two facts about a target like `fawn-2` or
// `above-well`: where to draw the halo that tells her where to touch, and
// whether her touch landed on it. Those are the same fact, and answering them
// twice — once in the halo's layout, once in a hit test — is how a halo ends
// up glowing somewhere the tap doesn't count. So both come from one place: the
// stage attaches a key to whatever it drew for that id, and this reads the
// rect back off it.
//
// A target the stage never registered resolves to no rect, and the caller
// treats a touch as a hit. That is not a fallback papering over a gap — it is
// what the content asks for. The lessons that name a gesture and no target
// ("drag-fish-to-pad") are exactly the ones whose passCondition says any drag
// passes, so a screen that cannot place the target must not be able to call
// her wrong about it.

import 'package:flutter/widgets.dart';

class LessonTargetRegistry {
  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};

  /// The key a stage should attach to whatever it draws for [id].
  ///
  /// Stable across rebuilds — a fresh GlobalKey each frame would detach and
  /// re-attach every target element on every tick, which is both expensive and
  /// enough to lose the rect at the moment of a tap.
  GlobalKey keyFor(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'lesson-target:$id'));

  /// The on-screen rect of [id], or null if nothing has been drawn for it.
  Rect? rectOf(String id) {
    final context = _keys[id]?.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Whether [position] (global) is on any of [ids].
  ///
  /// True when none of them can be placed, for the reason in the file comment.
  /// [slop] widens each rect: these are five-year-old fingers on sprites drawn
  /// at their natural size, and a touch two pixels off a fawn's flank is a
  /// touch on the fawn.
  bool hits(Iterable<String> ids, Offset position, {double slop = 24}) {
    var placed = false;
    for (final id in ids) {
      final rect = rectOf(id);
      if (rect == null) continue;
      placed = true;
      if (rect.inflate(slop).contains(position)) return true;
    }
    return !placed;
  }
}
