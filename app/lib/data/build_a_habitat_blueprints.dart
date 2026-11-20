// Build-a-Habitat blueprints (K.G.5 + K.G.6).
//
// One blueprint per round. Phase 1 (K.G.5) walks the kid through
// placing clay balls at each corner and sticks along each side of a 2D
// frame. Phase 2 (K.G.6) adds 3D shapes on top to compose the habitat.
//
// Blueprints are pure data: a list of normalized corner positions
// (defines the polygon), a list of edges (pairs of corner indices), and
// a list of K.G.6 "roof shapes" placed at positions on top of the
// frame. The runner does the rendering.

import 'package:flutter/material.dart';

import 'asset_paths.dart';
import 'habitat_words.dart';

/// One 3D shape placement for Phase 2 (K.G.6). The shape sits on top
/// of the assembled frame and contributes to the resident creature's
/// shelter.
class HabitatRoofPiece {
  const HabitatRoofPiece({
    required this.kind,
    required this.position,
    required this.size,
  });

  /// Sprite kind — must match a creature asset in the 3D pool. We
  /// currently use the themed `cube-turtle` / `cone-gnome` /
  /// `cylinder-golem` / `sphere-jellyfish` / `pyramid-fish` sprites.
  final String kind;

  /// Normalized centre of the piece on the build canvas.
  final Offset position;

  /// Diameter as a fraction of the shortest canvas side.
  final double size;

  /// The sprite this piece shows once it has been placed.
  ///
  /// The mapping used to be a private const inside `build_a_habitat_runner`,
  /// which was fine while the runner was the only thing that drew a habitat.
  /// The picker card draws one too, from this same blueprint - and a card
  /// showing a turtle where the round puts a gnome is exactly the kind of
  /// quiet drift a five-year-old learning "which picture is which game"
  /// cannot afford. One mapping, both callers.
  String get placedAsset => AssetPaths.shapeGarden3dCreature(
        kind,
        _kCreatureByKind[kind] ?? 'turtle',
      );

  /// Unplaced, the piece shows its hollow outline instead.
  String get outlineAsset => AssetPaths.shapeGarden3dOutline(kind);
}

/// Kind -> creature theming, so the roof reuses the Shape Garden 3D pool
/// rather than needing art of its own.
const Map<String, String> _kCreatureByKind = <String, String>{
  'cube': 'turtle',
  'sphere': 'jellyfish',
  'cylinder': 'golem',
  'cone': 'gnome',
  'pyramid': 'fish',
};

class HabitatBlueprint {
  const HabitatBlueprint({
    required this.id,
    required this.residentSpecies,
    required this.corners,
    required this.edges,
    required this.roof,
    required this.keeperLine,
    required this.rewardAsset,
  });

  /// Stable id used in cue ids and reward telemetry.
  final String id;

  /// Title shown in narration ("a fawn shelter", "a unicorn gazebo").
  ///
  /// Read back out of habitat_words.dart rather than stored, so the recording
  /// script and the game name the habitat with the same string. See that
  /// file for why the words cannot live here.
  String get displayName => habitatDisplayName(id);

  /// Resident creature kind — used to pick the thank-you collectible
  /// theming (feather / gem) at round end.
  final String residentSpecies;

  /// Normalized vertex positions defining the polygon frame.
  final List<Offset> corners;

  /// Edges between corners (each pair maps to a stick).
  final List<List<int>> edges;

  /// 3D pieces to place on top in Phase 2 (K.G.6).
  final List<HabitatRoofPiece> roof;

  /// Short keeper line after this habitat is finished.
  final String keeperLine;

  /// Reward sprite asset path (feather, gem, etc.).
  final String rewardAsset;
}

/// Three rounds: triangle → square → pentagon. Difficulty climbs in
/// both corner count and roof piece count, mirroring K.G.5's "build
/// the frame" + K.G.6's "compose on top" arc.
const List<HabitatBlueprint> kHabitatBlueprints = <HabitatBlueprint>[
  HabitatBlueprint(
    id: 'fawn-triangle-shelter',
    residentSpecies: 'fawn',
    corners: <Offset>[
      Offset(0.5, 0.20),
      Offset(0.22, 0.72),
      Offset(0.78, 0.72),
    ],
    edges: <List<int>>[
      <int>[0, 1],
      <int>[1, 2],
      <int>[2, 0],
    ],
    roof: <HabitatRoofPiece>[
      HabitatRoofPiece(
        kind: 'cube',
        position: Offset(0.5, 0.40),
        size: 0.22,
      ),
    ],
    keeperLine: 'A fawn shelter! Beautifully built.',
    rewardAsset: 'assets/rewards/general/reward-feather.png',
  ),
  HabitatBlueprint(
    id: 'gryphon-square-roost',
    residentSpecies: 'gryphon',
    corners: <Offset>[
      Offset(0.25, 0.25),
      Offset(0.75, 0.25),
      Offset(0.75, 0.75),
      Offset(0.25, 0.75),
    ],
    edges: <List<int>>[
      <int>[0, 1],
      <int>[1, 2],
      <int>[2, 3],
      <int>[3, 0],
    ],
    roof: <HabitatRoofPiece>[
      HabitatRoofPiece(
        kind: 'cone',
        position: Offset(0.32, 0.36),
        size: 0.20,
      ),
      HabitatRoofPiece(
        kind: 'cone',
        position: Offset(0.68, 0.36),
        size: 0.20,
      ),
      HabitatRoofPiece(
        kind: 'cube',
        position: Offset(0.5, 0.50),
        size: 0.24,
      ),
    ],
    keeperLine: 'A gryphon roost — four sides and a peaked roof!',
    rewardAsset: 'assets/rewards/general/reward-gem.png',
  ),
  HabitatBlueprint(
    id: 'unicorn-pentagon-gazebo',
    residentSpecies: 'unicorn',
    corners: <Offset>[
      Offset(0.50, 0.18),
      Offset(0.80, 0.40),
      Offset(0.70, 0.78),
      Offset(0.30, 0.78),
      Offset(0.20, 0.40),
    ],
    edges: <List<int>>[
      <int>[0, 1],
      <int>[1, 2],
      <int>[2, 3],
      <int>[3, 4],
      <int>[4, 0],
    ],
    roof: <HabitatRoofPiece>[
      HabitatRoofPiece(
        kind: 'sphere',
        position: Offset(0.5, 0.38),
        size: 0.22,
      ),
      HabitatRoofPiece(
        kind: 'cylinder',
        position: Offset(0.32, 0.56),
        size: 0.18,
      ),
      HabitatRoofPiece(
        kind: 'cylinder',
        position: Offset(0.68, 0.56),
        size: 0.18,
      ),
    ],
    keeperLine: 'A unicorn gazebo — five sides and a starlit dome on top!',
    rewardAsset: 'assets/rewards/general/reward-gem.png',
  ),
];
