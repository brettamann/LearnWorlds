// Asset path constants. The repo-root data/ and content/ trees are mirrored
// under app/assets/ via scripts/sync-assets.ps1, so rootBundle keys live
// under assets/. (Direct `../` paths bundle fine but break Flutter web's URL
// normalization at runtime.)

class AssetPaths {
  AssetPaths._();

  // Registries
  static const String kindergartenActivityRegistry =
      'assets/data/activity-registry/kindergarten.json';
  static const String kindergartenConceptRegistry =
      'assets/data/concept-registry/kindergarten.json';

  // Lesson runtime JSON. Files are named without the registry's "lesson-"
  // prefix (e.g. lessonId "lesson-k-cc-4a-one-to-one" → file
  // "k-cc-4a-one-to-one.json"). Centralise that translation here.
  static String lessonRuntime(String lessonId) {
    const prefix = 'lesson-';
    final stem = lessonId.startsWith(prefix)
        ? lessonId.substring(prefix.length)
        : lessonId;
    return 'assets/data/lesson-runtime/$stem.json';
  }

  // Activity content strings (en-US for now)
  static String activityStrings(String activityId) =>
      'assets/content/strings/en-US/activities/$activityId.json';

  // Art assets (placeholder until specs/shared/art-direction.md ships
  // official versions; paths follow specs/shared/asset-paths.md).
  static const String countingParadeMeadow =
      'assets/activities/counting-parade/backgrounds/meadow.jpg';
  // Counting Parade creature sprites. The parade sequence in
  // CountingParadeRunner uses the magical ones; kitten/puppy ship but stay
  // off the K parade for now (Sanctuary theme is mythical creatures).
  static const String countingParadeFawn =
      'assets/activities/counting-parade/sprites/fawn.png';
  static const String countingParadeBabyGryphon =
      'assets/activities/counting-parade/sprites/baby_gryphon.png';
  static const String countingParadeBabyDragon =
      'assets/activities/counting-parade/sprites/dragon_baby.png';
  static const String countingParadeBabyUnicorn =
      'assets/activities/counting-parade/sprites/unicorn_baby.png';
  static const String countingParadeBabyPhoenix =
      'assets/activities/counting-parade/sprites/pheonix_baby.png';
  static const String countingParadeBabyCentaur =
      'assets/activities/counting-parade/sprites/centaur_baby.png';
  static const String countingParadeBabyToucan =
      'assets/activities/counting-parade/sprites/toucan_baby.png';
  static const String countingParadeGoldenEgg =
      'assets/activities/counting-parade/sprites/golden_egg.png';
  static const String sanctuaryKeeperMystic =
      'assets/shared/region-characters/sanctuary/keeper-mystic.png';

  // Demonstration UI — used by LessonScreen iShow phases to show "the system
  // is touching this thing for you." See specs/shared/lesson-demonstration.md.
  static const String demoHandPointer = 'assets/shared/ui/hand_pointer.png';

  // Map UI — yellow lesson nodes (121x120), banner parchment (202x116,
  // text-area at 35,28 / 143x63), cloud (830x559 — drawn smaller, see
  // FogLayer). Placeholder until art direction ships the real sprites.
  static const String mapNodeYellow = 'assets/shared/ui/node-yellow.png';
  static const String mapBannerParchment =
      'assets/shared/ui/banner_parchment.png';
  static const String mapCloud = 'assets/shared/ui/cloud.png';

  // World maps — the navigation grammar of the island. Placeholder art; see
  // specs/shared/map-screens.md for the clickable-region pattern.
  static const String homeScreenMap = 'assets/maps/home_screen_map.png';
  static const String mysticSanctuaryMap = 'assets/maps/mystic_sanctuary_map.png';

  // Ten-Frame Pond placeholder sprite (Sprint 2+ activity).
  static const String tenFramePondFrog =
      'assets/activities/ten-frame-pond/sprites/frog.png';

  // ------- Shape Garden (K.G.2-4) -------
  // Background that fills the body of both the K.G.2 lesson scene and the
  // Shape Garden activity rounds.
  static const String shapeGardenBackground =
      'assets/activities/shape-garden/shape_garden_background.png';

  /// 2D shape sprite. `shape` is the canonical key (`triangle`,
  /// `triangle-right`, `circle`, `square`, `rectangle`, `pentagon`, `hexagon`,
  /// `semicircle_half`, `semicircle_quarter`); `variant` is whatever the
  /// artist named the material/colour suffix (e.g. `leaf`, `petal`, `stone`,
  /// `honeycomb`). File names mix `-` and `_` separators per artist
  /// convention — semicircle_half/quarter use underscores throughout;
  /// everything else uses hyphens. The presence of `_` in the shape key
  /// flips the separator.
  static String shapeGarden2dSprite(String shape, String variant) {
    final compound = shape.contains('_'); // semicircle_half / quarter
    final separator = compound ? '_' : '-';
    return 'assets/activities/shape-garden/shape_2d_$shape$separator$variant.png';
  }

  /// The `*-example` variant for a 2D shape — same file family as
  /// `shapeGarden2dSprite`, but the sprite carries magenta side-locator dots
  /// (#FF00F0) that the ExampleDotScanner reads at lesson load to position
  /// the hand pointer on each side's midpoint.
  static String shapeGarden2dExample(String shape) =>
      shapeGarden2dSprite(shape, 'example');

  /// 3D shape sprite — each shape has a themed creature (`gnome`, `turtle`,
  /// `golem`, `fish`, `jellyfish`) and a matching 2D outline used in the
  /// K.G.3 "flat vs solid" lesson to show what the cross-section looks like.
  static String shapeGarden3dCreature(String shape, String creatureName) =>
      'assets/activities/shape-garden/shape_3d_${shape}_$creatureName.png';

  static String shapeGarden3dOutline(String shape) =>
      'assets/activities/shape-garden/shape_3d_${shape}_outline.png';

  /// Decor sprites — butterflies and frogs in multiple colours, plus the
  /// watering can. Used as in-round wrong-tap targets that teach the kid
  /// "this is alive but it's not a shape — find the shapes."
  static String shapeGardenButterfly(String colour) =>
      'assets/activities/shape-garden/butterfly-decor-$colour.png';

  static String shapeGardenFrog(String colour) =>
      'assets/activities/shape-garden/frog-decor-$colour.png';

  static const String shapeGardenWateringCan =
      'assets/activities/shape-garden/watering-can-decor.png';

  /// Bins used by the K.G.3 "Flat or Solid" sub-mode — left bin (`bin_2d`)
  /// holds the painted-flat shapes, right bin (`bin_3d`) holds the solid
  /// creature sprites.
  static const String shapeGardenBin2d =
      'assets/activities/shape-garden/bin_2d.png';
  static const String shapeGardenBin3d =
      'assets/activities/shape-garden/bin_3d.png';

  // Reward track sprites — see specs/shared/reward-tracks.md.
  // K mystery egg, 8 progressive stages + 1 "hatched" complete state.
  static String kMysteryEggStage(int stage) {
    if (stage < 1 || stage > 8) {
      throw ArgumentError(
        'K mystery egg has stages 1..8; got $stage',
      );
    }
    return 'assets/rewards/k-mystery-egg/egg-reward-stage-$stage.png';
  }

  static const String kMysteryEggComplete =
      'assets/rewards/k-mystery-egg/egg-reward-stage-complete.png';
}
