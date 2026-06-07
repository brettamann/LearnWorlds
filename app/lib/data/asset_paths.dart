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
}
