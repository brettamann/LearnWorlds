// Asset path constants. All bundled data (registries, lessons, strings) lives
// under app/assets/, so every rootBundle key starts with assets/.

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

  /// Not a parade species. This is the Tens Parade challenge reward, and it
  /// is deliberately absent from every round sequence so the only place a kid
  /// ever sees it is the card she earns by counting to a hundred.
  // The fifteen cards that complete sanctuary-creature-cards-set. Card art
  // only: unlike the eight above, these creatures never walk in the parade,
  // so nothing outside creature_card_catalog.dart reaches for them.
  static const String countingParadeMossBunny =
      'assets/activities/counting-parade/sprites/moss_bunny.png';
  static const String countingParadeAcornSquirrel =
      'assets/activities/counting-parade/sprites/acorn_squirrel.png';
  static const String countingParadeBerryHedgehog =
      'assets/activities/counting-parade/sprites/berry_hedgehog.png';
  static const String countingParadeMeadowFrog =
      'assets/activities/counting-parade/sprites/meadow_frog.png';
  static const String countingParadeStarTurtle =
      'assets/activities/counting-parade/sprites/star_turtle.png';
  static const String countingParadeHoneyCub =
      'assets/activities/counting-parade/sprites/honey_cub.png';
  static const String countingParadePebbleMouse =
      'assets/activities/counting-parade/sprites/pebble_mouse.png';
  static const String countingParadeFireflySprite =
      'assets/activities/counting-parade/sprites/firefly_sprite.png';
  static const String countingParadeBabyPegasus =
      'assets/activities/counting-parade/sprites/baby_pegasus.png';
  static const String countingParadeCrystalDeer =
      'assets/activities/counting-parade/sprites/crystal_deer.png';
  static const String countingParadeLanternMoth =
      'assets/activities/counting-parade/sprites/lantern_moth.png';
  static const String countingParadeSnowFox =
      'assets/activities/counting-parade/sprites/snow_fox.png';
  static const String countingParadeRainbowChameleon =
      'assets/activities/counting-parade/sprites/rainbow_chameleon.png';
  static const String countingParadeMoonlightOwl =
      'assets/activities/counting-parade/sprites/moonlight_owl.png';
  static const String countingParadeSunbeamStag =
      'assets/activities/counting-parade/sprites/sunbeam_stag.png';

  static const String countingParadeCloudUnicorn =
      'assets/activities/counting-parade/sprites/cloud_unicorn.png';
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
  static const String mysticSanctuaryMap =
      'assets/maps/mystic_sanctuary_map.png';

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
  /// creature sprites. Reused by the K.G.4 sort-by-attribute sub-mode
  /// with an attribute-icon overlay rendered on top in code.
  static const String shapeGardenBin2d =
      'assets/activities/shape-garden/bin_2d.png';
  static const String shapeGardenBin3d =
      'assets/activities/shape-garden/bin_3d.png';

  // ------- Build-a-Habitat (K.G.5 + K.G.6) -------
  // Background is shared with Shape Garden — same Sanctuary clearing
  // aesthetic, no separate illustration needed yet.
  static const String buildAHabitatBackground = shapeGardenBackground;

  /// Stick sprite — horizontal wooden stick used at the edges of a
  /// K.G.5 frame. Rotated in code to line up with each edge.
  static const String buildAHabitatStick =
      'assets/activities/shape-garden/shape_2d_stick.png';

  /// Clay ball — placed at each corner of a K.G.5 frame.
  static const String buildAHabitatClayBall =
      'assets/activities/shape-garden/shape_3d_sphere-clay.png';

  // ------- Where's Buddy? (K.G.1) -------

  /// The clearing the six landmarks stand on.
  ///
  /// It borrowed the Shape Garden courtyard for a long time, which is the
  /// right aesthetic and the wrong shape: two thirds of that frame is sky and
  /// treeline and the ground is a strip across the bottom. That was invisible
  /// while the landmarks were pills of text, which float anywhere. It stopped
  /// being invisible the moment they became a pond and a cottage - at the
  /// positions this activity has always used, half of them stood in the sky.
  ///
  /// Pushing every landmark down into the band of ground that courtyard has
  /// does not work: the band that is both on grass and still leaves room for
  /// the above/below vectors is about 0.16 of the playfield, and six landmarks
  /// inside it cannot satisfy the two rules "between" depends on - a pair more
  /// than 0.4 apart, and a midpoint that does not land on a third landmark.
  /// So the geometry was right and the ground was wrong. This one is grass
  /// from a high horizon down, and deliberately empty in the middle.
  static const String wheresBuddyBackground =
      'assets/activities/wheres-buddy/clearing-background.png';

  /// Sprite for each of the six named places on the clearing, by landmark id.
  ///
  /// The activity teaches position words *relative to a landmark* - above the
  /// hollow tree, behind the cottage - and until now it drew no landmarks at
  /// all. `wheres_buddy_landmarks.dart` had a position and a name for each
  /// place and the runner rendered the name: six identical white pills of text
  /// over a courtyard illustration containing no fountain, no tree and no
  /// cottage. For a child who cannot read there was nothing on screen to be
  /// above or behind, which makes the whole activity a guess.
  ///
  /// Three reuse the decor sprites rather than paying for near-duplicates.
  /// That is not only thrift: those are the same objects she can buy and place
  /// on her own Sanctuary map, so the pond in the clearing is *her* pond, and
  /// one visual vocabulary across two screens is worth more than two.
  static const Map<String, String> wheresBuddyLandmarks = <String, String>{
    'fountain': 'assets/sanctuary/decor/star-fountain.png',
    'pond': 'assets/sanctuary/decor/lily-pond.png',
    'mushroom': 'assets/sanctuary/decor/toadstool-cluster.png',
    'hollow-tree': 'assets/activities/wheres-buddy/landmark-hollow-tree.png',
    'cottage': 'assets/activities/wheres-buddy/landmark-cottage.png',
    'rock-cluster': 'assets/activities/wheres-buddy/landmark-rock-cluster.png',
  };

  // ------- The Sanctuary, woken up (2026-09-24) -------
  // Generated through tools/artgen - see the "Waking the Sanctuary" block in
  // catalog.mjs for the prompts, and why every background's middle is empty.

  // Ten-Frame Pond
  static const String tenFramePondBackground =
      'assets/activities/ten-frame-pond/backgrounds/pond.png';
  static const String tenFrameLilyPad =
      'assets/activities/ten-frame-pond/sprites/lily-pad.png';
  static const String tenFrameFrogGreen =
      'assets/activities/ten-frame-pond/sprites/frog-green.png';
  static const String tenFrameFrogOrange =
      'assets/activities/ten-frame-pond/sprites/frog-orange.png';
  static const String tenFrameFrogWaving =
      'assets/activities/ten-frame-pond/sprites/frog.png';

  // Care Pantry
  static const String carePantryBackground =
      'assets/activities/care-pantry/backgrounds/pantry.png';
  static const String carePantryCrate =
      'assets/activities/care-pantry/sprites/crate.png';
  static const String carePantryAcorn =
      'assets/activities/care-pantry/sprites/acorn.png';
  static const String carePantryBerries =
      'assets/activities/care-pantry/sprites/berries.png';
  static const String carePantryCarrot =
      'assets/activities/care-pantry/sprites/carrot.png';
  static const String carePantryApple =
      'assets/activities/care-pantry/sprites/apple.png';

  // Scribe's Tower
  static const String scribesTowerBackground =
      'assets/activities/scribes-tower/backgrounds/tower.png';

  // Storyteller's Pond
  static const String storytellersPondBackground =
      'assets/activities/storytellers-pond/backgrounds/pond-dusk.png';
  static const String storytellersDuckling =
      'assets/activities/storytellers-pond/sprites/duckling.png';

  // Caretaker's Bench
  static const String caretakersBenchBackground =
      'assets/activities/caretakers-bench/backgrounds/bench.png';
  static const String caretakersScaleStand =
      'assets/activities/caretakers-bench/sprites/scale-stand.png';
  static const String caretakersPumpkin =
      'assets/activities/caretakers-bench/sprites/pumpkin.png';
  static const String caretakersWatermelon =
      'assets/activities/caretakers-bench/sprites/watermelon.png';
  static const String caretakersRock =
      'assets/activities/caretakers-bench/sprites/rock.png';
  static const String caretakersLeaf =
      'assets/activities/caretakers-bench/sprites/leaf.png';

  // Picnic Baskets
  static const String picnicBackground =
      'assets/activities/picnic-baskets/backgrounds/picnic.png';
  static const String picnicBasket =
      'assets/activities/picnic-baskets/sprites/basket.png';

  // ------- General reward icons -------
  static const String rewardFeather =
      'assets/rewards/general/reward-feather.png';
  static const String rewardGem = 'assets/rewards/general/reward-gem.png';

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
