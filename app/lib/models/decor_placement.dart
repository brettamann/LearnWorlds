// One decoration, somewhere on the Sanctuary map.
//
// Position is normalised (0..1) against the map's square box rather than
// stored in pixels, for the same reason the magenta anchors are: the map is
// rendered inside an `AspectRatio(1)` that is whatever size the window allows,
// so a pixel position saved on a touchscreen monitor would land somewhere else
// entirely on an iPad. Normalised, a placement means the same thing on both.
//
// Placements are a list, not a set or a map keyed by item: putting three
// toadstools in three places is an obviously reasonable thing for a
// five-year-old to want, and the first design that keys on `decorId` quietly
// makes that impossible.

class DecorPlacement {
  const DecorPlacement({
    required this.instanceId,
    required this.decorId,
    required this.x,
    required this.y,
  });

  /// Identifies this placement as distinct from another copy of the same item.
  /// Monotonic per save; see `SanctuaryDecor._nextInstanceId`.
  final int instanceId;

  /// Which `DecorItem` this is a copy of.
  final String decorId;

  /// Centre of the sprite, as a fraction of the map's width and height.
  final double x;
  final double y;

  DecorPlacement moveTo(double newX, double newY) => DecorPlacement(
    instanceId: instanceId,
    decorId: decorId,
    x: newX,
    y: newY,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'instanceId': instanceId,
    'decorId': decorId,
    'x': x,
    'y': y,
  };

  /// Returns null for a row that cannot be read rather than throwing.
  ///
  /// A save is the one file in the game that must never fail to load: losing
  /// the whole sanctuary because one decoration row is malformed would be a
  /// far worse bug than losing one mushroom.
  static DecorPlacement? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final decorId = raw['decorId'];
    final instanceId = raw['instanceId'];
    final x = raw['x'];
    final y = raw['y'];
    if (decorId is! String || instanceId is! int) return null;
    if (x is! num || y is! num) return null;
    return DecorPlacement(
      instanceId: instanceId,
      decorId: decorId,
      x: x.toDouble().clamp(0.0, 1.0),
      y: y.toDouble().clamp(0.0, 1.0),
    );
  }
}
