// What she owns, and where she put it.
//
// Two notifiers rather than one, matching the split the collection already
// uses: ownership is a purchase record and changes rarely, placements change
// on every drag. Keeping them apart means dragging a mushroom around does not
// rebuild the shop tray.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sanctuary_decor_catalog.dart';
import '../models/decor_placement.dart';

/// Decor she has bought. The starter set in `kDecorFreeItems` is deliberately
/// not stored here — `owns` checks it separately, so changing the free set
/// later re-prices existing saves instead of leaving stale grants behind. This
/// is the same rule `BuddyWardrobe` follows, for the same reason.
class DecorOwnership extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  bool owns(String id) => kDecorFreeItems.contains(id) || state.contains(id);

  /// Idempotent, so a double-tap on a tray tile cannot charge twice — the
  /// caller checks `owns` before spending.
  void grant(String id) {
    if (state.contains(id)) return;
    state = <String>{...state, id};
  }

  void hydrate(Set<String> owned) =>
      state = <String>{...owned}..removeWhere(kDecorFreeItems.contains);
}

final decorOwnershipProvider = NotifierProvider<DecorOwnership, Set<String>>(
  DecorOwnership.new,
);

/// Where each decoration sits, in map order — later placements draw on top,
/// which is the behaviour anyone dragging things around expects.
class SanctuaryDecor extends Notifier<List<DecorPlacement>> {
  @override
  List<DecorPlacement> build() => const <DecorPlacement>[];

  /// Never reused, so a placement's identity survives a delete of the one
  /// before it. Recomputed on hydrate from the highest id in the save.
  int _nextInstanceId = 1;

  /// How many of one item can be on the map at once.
  ///
  /// Not a rule she is meant to feel — it is high enough that a five-year-old
  /// filling the meadow with mushrooms succeeds. It exists so a stuck finger
  /// on a touchscreen cannot write a save with ten thousand rows in it.
  static const int kMaxPerItem = 12;

  /// The total across all items, for the same reason.
  static const int kMaxTotal = 60;

  int countOf(String decorId) =>
      state.where((p) => p.decorId == decorId).length;

  bool get isFull => state.length >= kMaxTotal;

  /// Adds a copy of [decorId] at normalised ([x], [y]).
  ///
  /// Returns the new placement, or null if a cap was hit. The caller decides
  /// what to say about that; this layer never speaks.
  DecorPlacement? place(String decorId, double x, double y) {
    if (isFull || countOf(decorId) >= kMaxPerItem) return null;
    final placement = DecorPlacement(
      instanceId: _nextInstanceId++,
      decorId: decorId,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
    );
    state = <DecorPlacement>[...state, placement];
    return placement;
  }

  /// Moves an existing placement, and lifts it to the top of the draw order —
  /// the thing she just touched should not end up behind something else.
  void move(int instanceId, double x, double y) {
    final found = state.where((p) => p.instanceId == instanceId).firstOrNull;
    if (found == null) return;
    state = <DecorPlacement>[
      ...state.where((p) => p.instanceId != instanceId),
      found.moveTo(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0)),
    ];
  }

  void remove(int instanceId) {
    state = state.where((p) => p.instanceId != instanceId).toList();
  }

  /// Drops rows whose item is no longer in the catalog, so removing a decor
  /// item from the catalog cannot crash the map on an old save.
  void hydrate(List<DecorPlacement> placements) {
    final kept = placements
        .where((p) => decorItemById(p.decorId) != null)
        .take(kMaxTotal)
        .toList();
    state = kept;
    _nextInstanceId = kept.isEmpty
        ? 1
        : kept.map((p) => p.instanceId).reduce((a, b) => a > b ? a : b) + 1;
  }
}

final sanctuaryDecorProvider =
    NotifierProvider<SanctuaryDecor, List<DecorPlacement>>(SanctuaryDecor.new);
