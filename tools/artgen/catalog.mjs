// What art we actually need, and how to ask for it.
//
// Deliberately short. The rule is that an entry earns its place by being art
// the shipped code already reaches for and cannot get — not art that would be
// nice to have. Two things follow from that:
//
//   - Colour and pose variants are NOT entries. Buddy has twelve body colours
//     from one silhouette; a thirteenth is a local recolour, not a generation.
//     Facing left is `Transform.scale(scaleX: -1)` in buddy_widget.dart, not a
//     mirrored asset.
//   - Art for unbuilt features is NOT an entry. The reward catalog authors 24
//     creature cards, but `creature_card_catalog.dart` runs Counting Parade
//     only, so the pond cards (Blue Koi, Pearl-Fin) would be sprites for a
//     screen that cannot show them. They go in when the pond drops do.
//
// `reference` is the strong lever. Editing against an existing asset holds the
// line weight and palette far better than any prompt can, so a new part is
// asked for as a variation of the part it must sit beside.
//
// EFFORT IS NOT JUST QUALITY. Measured on this deployment:
//
//   draft    gpt-image-1-mini  1.1c  returns real alpha (67-74% transparent)
//   standard gpt-image-2       4.1c  returns fully opaque images, 0% alpha
//
// gpt-image-2 follows instructions better but hands back a background no
// matter how the prompt is worded - white for simple subjects, and for busy
// ones a *drawn* transparency checkerboard, which no background remover can
// safely strip because it is real pixels. So cutout sprites default to draft.
// Use standard only where the subject is simple enough that the flood fill can
// take the background off cleanly, and check the result before trusting it.

/** Shared tail: what every cutout sprite must and must not have. */
const CUTOUT =
  'Flat vector cartoon, clean even line weight, no gradients, no texture. ' +
  'Centred, front view, generous even margin on all four sides, nothing touching the edge of the frame. ' +
  'Fully transparent background. No drop shadow, no outer glow, no background shapes, no text, no watermark.';

/**
 * Shared tail for Buddy's limbs.
 *
 * Stricter than CUTOUT about flatness. The limb sprites are the simplest art
 * in the game - one green shape, one black line - and anything the model adds
 * (a highlight, a second tone, a seam) reads at Buddy's size as a smudge
 * rather than as detail.
 */
const LIMB =
  'Flat vector cartoon, one single flat colour fill and one clean heavy black outline of even ' +
  'weight, exactly like the reference. No gradients, no shading, no texture, no inner detail ' +
  'lines beyond the one or two the shape needs. ' +
  'Bright grass green fill, the same green as the reference. ' +
  'Centred with an even margin, nothing touching the edge of the frame. ' +
  'Fully transparent background. No drop shadow, no outer glow, no background shapes, no text.';

export const ASSETS = [
  // ---- Buddy mouths -------------------------------------------------
  // buddy_widget.dart:52 already asks for v2/v3/v4 by id per mood, and
  // buddyMouthAsset() falls back to v1 when they are absent — so the moods are
  // wired and simply have nothing to show. All three edit against v1 so they
  // read as the same mouth in different shapes rather than three cartoons.
  {
    id: 'mouth-v2',
    title: 'Buddy mouth — open smile (happy)',
    out: 'app/assets/buddy/mouths/v2.png',
    reference: 'app/assets/buddy/mouths/v1.png',
    // Was standard. gpt-image-2 drew it well but on an opaque white card, and
    // flood-filling that off left a scatter of speckles around the mouth that
    // was plainly visible composited on Buddy. Real alpha beats a better
    // drawing that has to be cut out afterwards.
    effort: 'draft',
    prompt:
      'Redraw this cartoon mouth in the identical art style — same black outline weight, same flat colour fill — ' +
      'but as a warm happy open smile: a broad upward crescent, upper row of square white teeth, ' +
      'dark red inner mouth, soft pink tongue resting at the bottom. Friendly and delighted, not laughing. ' +
      'Just the mouth shape — no lips, no skin, no face. ' + CUTOUT,
    reframe: { widthScale: 1.0 },
  },
  {
    id: 'mouth-v3',
    title: 'Buddy mouth — small o (curious)',
    out: 'app/assets/buddy/mouths/v3.png',
    reference: 'app/assets/buddy/mouths/v1.png',
    effort: 'draft',
    // Narrower on purpose: a curious "oh" is a small mouth. widthScale is what
    // keeps that an art decision instead of an accident of canvas padding.
    prompt:
      'Redraw this cartoon mouth in the identical art style — same black outline weight, same flat colour fill — ' +
      'but as a small round open "o", a gentle surprised curious expression. ' +
      'It MUST have the same thick bold black outline as the reference — a heavy black ring ' +
      'all the way around the opening, exactly the line weight of the original. ' +
      'The inside of the mouth MUST be filled solid dark red all the way across — it is a ' +
      'closed filled shape, NOT a ring, NOT a hollow donut, NOT transparent in the middle. ' +
      'A small soft pink tongue sits at the bottom of the red area. No teeth. ' +
      'Just the mouth shape — no lips, no skin, no face. ' + CUTOUT,
    // Half of v1 read as a dot on the face; an "oh" is smaller than a laugh
    // but still has to be visible at 0.14 of Buddy's height.
    reframe: { widthScale: 0.62 },
  },
  {
    id: 'mouth-v4',
    title: 'Buddy mouth — flat (thinking)',
    out: 'app/assets/buddy/mouths/v4.png',
    reference: 'app/assets/buddy/mouths/v1.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon mouth in the identical art style — same black outline weight, same flat colour fill — ' +
      'but as a closed thoughtful mouth: a single LEVEL horizontal line, running straight across ' +
      'left to right with only the faintest wave in it. It must NOT curve upward into a smile and ' +
      'must NOT curve downward into a frown — it is flat, neutral, pensive. ' +
      'The line MUST be thick and bold — the same heavy black line weight as the outline in the ' +
      'reference image, not a thin stroke — with rounded ends. Mouth completely closed. ' +
      'No teeth, no tongue, no red fill, no open area at all. ' +
      'Just the line — no lips, no skin, no face. ' + CUTOUT,
    reframe: { widthScale: 0.78 },
  },

  // ---- Creature cards -----------------------------------------------
  // The ninth card in sanctuary-creature-cards-set. The other eight reuse
  // Counting Parade sprites; this one is the set's rare and has no sprite, so
  // the set cannot be completed and `sanctuary-atlas` cannot unlock.
  {
    id: 'card-cloud-unicorn',
    title: 'Cloud Unicorn — rare creature card',
    out: 'app/assets/activities/counting-parade/sprites/cloud_unicorn.png',
    reference: 'app/assets/activities/counting-parade/sprites/unicorn_baby.png',
    // Was standard; gpt-image-2 returned a drawn checkerboard background,
    // which is unremovable because it is real pixels rather than alpha.
    effort: 'draft',
    prompt:
      'Redraw this baby unicorn in the identical art style, line weight and proportions, ' +
      'but as a Cloud Unicorn: coat of soft white cloud-fluff, pale sky-blue shading, ' +
      'a mane and tail like wisps of cloud tinted warm sunrise gold, small pearl-white horn. ' +
      'Same friendly baby proportions, same pose, same standing three-quarter view. ' +
      'Gentle and dreamlike, still clearly the same creature family. ' + CUTOUT,
    // Sits beside the other parade sprites at their size, so match the
    // reference's framing exactly rather than rescaling it.
    reframe: { widthScale: 1.0 },
  },

  // ---- The rest of the Sanctuary Creature Cards ---------------------
  // `sanctuary-creature-cards-set` is authored as 24 cards. Eight reuse the
  // Counting Parade cast, the Cloud Unicorn is the challenge grant, and these
  // fifteen are the remainder. They are entries now because the drop machinery
  // is built and running: RoundCoordinator rolls over kCreatureCards filtered
  // by activityId, Counting Parade is complete, so each of these is a card the
  // shipped code will hand a child the moment the art and the catalog row
  // exist. (Contrast the pond cards above, which are still art for a screen
  // that cannot show them.)
  //
  // Two anchors rather than one. The decor set proved that a single fixed
  // reference keeps a set consistent with the game rather than with whichever
  // item happened to be generated first - but a moth edited against a fawn is
  // asking the model to fight the reference's whole silhouette. So: the fawn
  // for anything that stands on the ground, the toucan for anything with
  // wings. Both are parade cast, so both carry the same line weight and
  // palette.
  //
  // No reframe. These never stand beside a parade sprite the way the Cloud
  // Unicorn does; each is alone on a card face and in one album tile, sized by
  // BoxFit.contain. Matching every content box to the fawn's would push a wide
  // moth off the sides for no gain - the same reasoning as the decor set.
  {
    id: 'card-moss-bunny',
    title: 'Moss Bunny — creature card',
    out: 'app/assets/activities/counting-parade/sprites/moss_bunny.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a small round baby rabbit with soft moss-green fur, a cream belly, long gently drooping ears with pale pink inners, tiny sprigs of clover growing along its back, and big friendly dark eyes. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-acorn-squirrel',
    title: 'Acorn Squirrel — creature card',
    out: 'app/assets/activities/counting-parade/sprites/acorn_squirrel.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a plump baby squirrel with warm russet-brown fur, a huge bushy tail curled up behind it, a pale cream chest, and a single golden acorn held in both front paws. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-berry-hedgehog',
    title: 'Berry Hedgehog — creature card',
    out: 'app/assets/activities/counting-parade/sprites/berry_hedgehog.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a small round baby hedgehog with soft tan face and paws, a rounded cap of blunt friendly spines in dusty plum, and three little red berries balanced among the spines. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-meadow-frog',
    title: 'Meadow Frog — creature card',
    out: 'app/assets/activities/counting-parade/sprites/meadow_frog.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a cheerful round baby frog with bright spring-green skin, a pale yellow belly, big round eyes with golden irises, and a tiny white daisy tucked behind one eye. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-star-turtle',
    title: 'Star Turtle — creature card',
    out: 'app/assets/activities/counting-parade/sprites/star_turtle.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a small baby tortoise with a gentle teal-blue shell patterned with pale cream stars, soft sandy-yellow legs and head, and a sleepy contented smile. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-honey-cub',
    title: 'Honey Cub — creature card',
    out: 'app/assets/activities/counting-parade/sprites/honey_cub.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a chubby baby bear cub with warm honey-gold fur, a paler muzzle, small round ears, and a little pot of honey hugged against its chest. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-pebble-mouse',
    title: 'Pebble Mouse — creature card',
    out: 'app/assets/activities/counting-parade/sprites/pebble_mouse.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a tiny baby mouse with soft dove-grey fur, very large round pale-pink ears, a cream belly, a long thin curling tail, and a smooth speckled pebble held in its paws. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-firefly-sprite',
    title: 'Firefly Sprite — creature card',
    out: 'app/assets/activities/counting-parade/sprites/firefly_sprite.png',
    reference: 'app/assets/activities/counting-parade/sprites/toucan_baby.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook bird proportions with a large head and big gentle eyes. '
      + 'The creature is a tiny friendly firefly: a small round bug with a soft moss-green head and chest, two large clear rounded insect wings held open at its sides, and two curled antennae. Its whole rear half is a big round lantern that GLOWS bright warm amber-gold, clearly lit from within with a soft golden halo around it - the glow is the most important part of the drawing. Gentle dot eyes and a little smile. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-baby-pegasus',
    title: 'Baby Pegasus — creature card',
    out: 'app/assets/activities/counting-parade/sprites/baby_pegasus.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a baby winged horse with a soft cream-white coat, a pale lavender mane and tail, and two small feathered wings folded neatly at its sides. Stubby foal legs, big gentle eyes. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-crystal-deer',
    title: 'Crystal Deer — creature card',
    out: 'app/assets/activities/counting-parade/sprites/crystal_deer.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a baby deer with a pale ice-blue coat, a soft white belly, and small branching antlers made of translucent pale-violet crystal that catch the light. Same friendly fawn proportions. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-lantern-moth',
    title: 'Lantern Moth — creature card',
    out: 'app/assets/activities/counting-parade/sprites/lantern_moth.png',
    reference: 'app/assets/activities/counting-parade/sprites/toucan_baby.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook bird proportions with a large head and big gentle eyes. '
      + 'The creature is a gentle storybook moth with a plump dusty-violet furry body, broad rounded wings in warm cream and soft amber patterned with round glowing spots, and two curled feathery antennae. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-snow-fox',
    title: 'Snow Fox — creature card',
    out: 'app/assets/activities/counting-parade/sprites/snow_fox.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a baby arctic fox cub with soft snow-white fur, faint pale-blue shading, large pointed ears, a very fluffy tail with a silver-grey tip, and bright dark eyes. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-rainbow-chameleon',
    title: 'Rainbow Chameleon — creature card',
    out: 'app/assets/activities/counting-parade/sprites/rainbow_chameleon.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a small friendly baby chameleon with a body banded in soft rainbow pastels from mint to peach to lilac, a curled spiral tail, round independently swivelling eyes, and little gripping feet on a short twig. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-moonlight-owl',
    title: 'Moonlight Owl — creature card',
    out: 'app/assets/activities/counting-parade/sprites/moonlight_owl.png',
    reference: 'app/assets/activities/counting-parade/sprites/toucan_baby.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook bird proportions with a large head and big gentle eyes. '
      + 'The creature is a small round baby owl with plumage in deep midnight blue flecked with tiny silver stars, a pale moon-white heart-shaped face, huge amber eyes, and soft tufted ears. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },
  {
    id: 'card-sunbeam-stag',
    title: 'Sunbeam Stag — creature card',
    out: 'app/assets/activities/counting-parade/sprites/sunbeam_stag.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image — same flat vector '
      + 'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly '
      + 'storybook baby animal proportions with a large head and big gentle eyes. '
      + 'The creature is a young stag with a coat of warm sunlit gold, a cream underside, and tall elegant antlers that glow like soft sunbeams with small warm-white light motes drifting near their tips. Noble and calm, still a young animal. '
      + 'Standing three-quarter view, calm and friendly, the kind of creature a small child would want to meet. '
      + CUTOUT,
    // Shown on a reveal card face and in one album tile, both a few hundred
    // logical pixels. 512 covers the larger of the two on a retina iPad.
    maxSize: 512,
  },

  // ---- Sanctuary decor ----------------------------------------------
  // The eight items `data/sanctuary_decor_catalog.dart` sells. Decorating is
  // the game's only surface with no correct answer, so these are the one place
  // in the art budget where "nice to have" IS the requirement - the whole
  // feature is that she chose them and put them where she wanted.
  //
  // All eight edit against the shape-garden watering can rather than each
  // other. It is the closest thing the repo has to a neutral prop in the house
  // style, and referencing one fixed anchor keeps the set consistent with the
  // game instead of consistent with whichever item happened to be generated
  // first.
  {
    id: 'decor-toadstool-cluster',
    title: 'Sanctuary decor — toadstool cluster',
    out: 'app/assets/sanctuary/decor/toadstool-cluster.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a cluster of three plump storybook toadstools of different heights, warm red caps with soft cream spots, thick pale stalks, a little moss at the base. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-flower-patch',
    title: 'Sanctuary decor — flower patch',
    out: 'app/assets/sanctuary/decor/flower-patch.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a small patch of five simple garden flowers on green stems — pink, gold and pale violet blooms with round friendly petals and two broad leaves. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-garden-lantern',
    title: 'Sanctuary decor — garden lantern',
    out: 'app/assets/sanctuary/decor/garden-lantern.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is an old-fashioned garden lamp post standing upright on the ground. From bottom to top: a small round dark base resting on the grass, then a slim dark-grey iron post, then at the very TOP a square lantern box with four clear glass panes glowing warm yellow from the candle inside, capped by a small pointed roof. The complete lamp post from base to roof must be inside the frame, standing the right way up. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-standing-stone',
    title: 'Sanctuary decor — standing stone',
    out: 'app/assets/sanctuary/decor/standing-stone.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one single upright standing stone, like a small menhir: a tall rounded-top slab of soft grey-blue rock, wider at the bottom and narrowing to a smooth domed top, standing on a patch of green grass with a little moss at its foot. Three simple pale-teal spiral runes are carved into the front face. The whole stone, its domed top and its grassy base must all be inside the frame. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-lily-pond',
    title: 'Sanctuary decor — lily pond',
    out: 'app/assets/sanctuary/decor/lily-pond.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a small oval pond seen from a low three-quarter angle: calm blue water with two flat green lily pads and one pink water lily, ringed by smooth grey stones. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-topiary-tree',
    title: 'Sanctuary decor — topiary tree',
    out: 'app/assets/sanctuary/decor/topiary-tree.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a small potted topiary tree with three clearly separate parts stacked vertically: at the BOTTOM a terracotta flower pot, ABOVE it a slim bare brown trunk, and on the trunk TWO round balls of neat green foliage, one above the other with a visible gap of bare trunk between them. The pot, the trunk and both foliage balls must all be visible inside the frame. IMPORTANT: this object is tall and narrow, so draw it SMALL in the frame - leave a wide band of empty space above the top foliage ball and below the bottom of the pot. Nothing may touch the top or bottom edge. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-star-fountain',
    title: 'Sanctuary decor — star fountain',
    out: 'app/assets/sanctuary/decor/star-fountain.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a small ornate stone fountain seen from a low three-quarter angle: a wide five-pointed star-shaped basin of pale cream stone holding shallow blue water, with a short carved pillar rising from its centre and a gentle low arc of pale blue water curving out of the pillar and falling back into the basin. A few small gold sparkle stars float near the water. The entire fountain including the top of the water arc must be inside the frame. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  {
    id: 'decor-rainbow-arch',
    title: 'Sanctuary decor — rainbow arch',
    out: 'app/assets/sanctuary/decor/rainbow-arch.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image — same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a freestanding decorative garden arch shaped like a rainbow, six soft bands of colour from red through violet, its two feet planted in small tufts of grass. ' +
      'It is a small decorative garden object that will be placed on a storybook map. ' + CUTOUT,
    // Rendered between 0.06 and 0.17 of the map's shortest side, so a
    // 1024px source is roughly five times more pixels than the largest
    // item can ever show. 400 covers the biggest at 2x for a retina iPad.
    maxSize: 400,
    // No reframe. Reframing scales a sprite so its content box matches the
    // reference's, which is exactly right for a mouth that must register
    // against Buddy's face and exactly wrong here: these are free-standing
    // objects with their own proportions, and matching a wide short watering
    // can pushed every tall one off the top and bottom of the frame. On-screen
    // size is `DecorItem.widthFraction`, under BoxFit.contain.
  },
  // ---- Where's Buddy landmarks ---------------------------------------
  // The clearing has six named places - the fountain, the hollow tree, the
  // giant mushroom, the rock cluster, the cottage and the pond - and it had
  // pictures of none of them. `wheres_buddy_landmarks.dart` carries a
  // normalised position and a name for each, and the runner drew the name: six
  // identical white pills of text over the Shape Garden courtyard, which has no
  // fountain, no tree and no cottage in it. The activity teaches position
  // words *relative to a landmark*, so for a child who cannot read there was
  // nothing on screen to be above or behind. She could only guess.
  //
  // Three of the six are already drawn. `sanctuary/decor` sells a lily pond, a
  // toadstool cluster and a star fountain, all from one batch in this style, so
  // the pond, the mushroom and the fountain reuse those rather than paying for
  // near-duplicates - see the note on AssetPaths.wheresBuddyLandmarks. These
  // three are what is genuinely missing, and they edit against the same
  // watering can the decor set did so all six read as one place.
  {
    id: 'landmark-hollow-tree',
    title: "Where's Buddy landmark - the hollow tree",
    out: 'app/assets/activities/wheres-buddy/landmark-hollow-tree.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a friendly storybook hollow tree: a stout brown trunk with a large dark rounded ' +
      'hollow opening in the front big enough for a small animal to hide inside, a round leafy green ' +
      'canopy on top, two thick roots at the base with a little grass. The hollow opening is the ' +
      'most important feature and must read clearly. ' + CUTOUT,
    // Same reasoning as the decor set: rendered at a fraction of the clearing,
    // so a 1024px source is far more pixels than it can ever show.
    maxSize: 400,
  },
  {
    id: 'landmark-cottage',
    title: "Where's Buddy landmark - the cottage",
    out: 'app/assets/activities/wheres-buddy/landmark-cottage.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a tiny storybook cottage: cream walls, a steep shingled roof in warm ' +
      'terracotta, one round-topped wooden door, one square window with a cross frame, a small ' +
      'chimney. Cosy and simple, seen straight on from the front. ' + CUTOUT,
    maxSize: 400,
  },
  {
    id: 'landmark-rock-cluster',
    title: "Where's Buddy landmark - the rock cluster",
    out: 'app/assets/activities/wheres-buddy/landmark-rock-cluster.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    // A cluster, not the single carved standing stone the decor set already
    // has: the name the narrator speaks is "the rock cluster", and a landmark
    // whose picture argues with its name is worse than no picture.
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a cluster of four or five smooth grey boulders of different sizes heaped ' +
      'together, the largest at the back, a little green moss and grass at the base. Plainly several ' +
      'separate rocks piled together, not one big stone. ' + CUTOUT,
    maxSize: 400,
  },
  // ---- Where's Buddy clearing ----------------------------------------
  // The only background in the catalog, and the only entry with
  // `cutout: false`.
  //
  // Where's Buddy borrowed the Shape Garden courtyard, which is the right
  // aesthetic and the wrong *shape*: two thirds of the frame is sky and
  // treeline, and the ground is a narrow band across the bottom. That did not
  // matter while the six landmarks were pills of text, which can float
  // anywhere. It matters the moment they are a pond, a cottage and a rock
  // pile: at the positions the activity has always used, half of them stood in
  // the clouds.
  //
  // The alternative was to push every landmark down into the band of ground
  // there is, and it does not fit. The vertical band that is both on grass and
  // still leaves room for the "above"/"below" vectors is about 0.16 of the
  // playfield, and six landmarks squeezed into it break two rules the activity
  // depends on: the relational pairs have to be more than 0.4 apart for
  // "between" to mean anything, and the midpoint of a pair must not land on a
  // third landmark. So the geometry is right and the ground was wrong.
  //
  // Painted, not flat vector - it sits behind the sprites rather than beside
  // them, and it edits against the courtyard so the two rooms of the Sanctuary
  // look like the same world.
  {
    id: 'wheres-buddy-clearing',
    title: "Where's Buddy - the Sanctuary clearing",
    out: 'app/assets/activities/wheres-buddy/clearing-background.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    // Backgrounds want the opaque image gpt-image-2 insists on returning, and
    // the better instruction-following matters here: the whole ask is a
    // composition constraint rather than a subject.
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same warm daylight palette, same gentle cartoon shapes. ' +
      'It is a wide sunny clearing in a magical sanctuary, seen from slightly above. ' +
      'IMPORTANT COMPOSITION: the horizon sits high, about one quarter of the way down the image. ' +
      'Above it, a thin strip of soft blue sky with a few clouds and a distant treeline. ' +
      'Below it, the remaining three quarters is one broad open expanse of sunlit green grass ' +
      'running all the way to the bottom edge. ' +
      'Small wildflowers and low bushes only along the far left and far right edges. ' +
      'The whole centre of the grass is completely EMPTY - no buildings, no trees, no ponds, ' +
      'no rocks, no animals, no paths, no objects of any kind. It is an empty meadow that ' +
      'other artwork will be placed on top of. ' +
      'No characters, no text, no watermark, no border, no vignette, no frame.',
    // A background keeps far more of its pixels than a sprite does - it is
    // drawn full-bleed under a whole screen rather than at a fraction of one.
    // 860 is not arbitrary: it is exactly the width of the courtyard this
    // replaces, so the two backgrounds cost the web build the same and are
    // upscaled by the same amount on a large window. At 1024 it was 1.98MB
    // against the courtyard's 1.03MB for no visible difference on a soft
    // painted image.
    maxSize: 860,
  },
  // ---- Buddy arms and legs -------------------------------------------
  // Buddy has twelve bodies, twelve eyes, two hats - and exactly one arm and
  // one leg. `buddy_shop_catalog.dart` already prices arms and legs at 30
  // coins each and its comment says the single options are free "because they
  // are currently the *only* options; when more land they price themselves off
  // kBuddyPartPrices with no edit here". So the shop has had two categories
  // that show one already-owned tile each since it was built.
  //
  // Only the RIGHT sprite is generated. The left is `mirror`ed from it at
  // install time, because the pair has to agree about how many fingers Buddy
  // has and two independent generations do not - the existing arm-1-l is
  // itself a mirror of arm-1-r.
  //
  // Everything stays the same grass green. The limbs are green against all
  // twelve body colours today, so a differently coloured limb is not a variant
  // of this sprite, it is a variant of the whole scheme - and it would look
  // wrong against at least half the bodies she can pick. The shape carries the
  // difference.
  //
  // ORIENTATION is the thing to check by eye. buddy_widget.dart rotates each
  // arm about its shoulder - `alignment: Alignment.topLeft` for the right arm,
  // topRight for the left - so a sprite whose shoulder ends up at the wrong
  // corner swings from the hand instead.
  {
    id: 'arm-2',
    title: "Buddy arm - soft paw",
    out: 'app/assets/buddy/arms/arm-2-r.png',
    mirror: 'app/assets/buddy/arms/arm-2-l.png',
    reference: 'app/assets/buddy/arms/arm-1-r.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon limb in the identical art style, as a different shape: a rounded animal paw with three plump toe pads at the end, one small thumb pad at the wrist side. ' +
      'ORIENTATION MATTERS: this is a RIGHT arm seen from the front. The shoulder end is the ' +
      'narrow stump at the TOP LEFT of the frame, and the limb extends down and to the right, ' +
      'exactly like the reference. Keep the same overall length and thickness as the reference. ' +
      'No body, no shoulder joint, no torso - just the arm. ' + LIMB,
    reframe: { widthScale: 1.0 },
  },
  {
    id: 'arm-3',
    title: "Buddy arm - round mitten",
    out: 'app/assets/buddy/arms/arm-3-r.png',
    mirror: 'app/assets/buddy/arms/arm-3-l.png',
    reference: 'app/assets/buddy/arms/arm-1-r.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon limb in the identical art style, as a different shape: a simple round mitten with no fingers at all, just a soft ball of a hand with one small thumb bump. ' +
      'ORIENTATION MATTERS: this is a RIGHT arm seen from the front. The shoulder end is the ' +
      'narrow stump at the TOP LEFT of the frame, and the limb extends down and to the right, ' +
      'exactly like the reference. Keep the same overall length and thickness as the reference. ' +
      'No body, no shoulder joint, no torso - just the arm. ' + LIMB,
    reframe: { widthScale: 1.0 },
  },
  {
    id: 'arm-4',
    title: "Buddy arm - little wing",
    out: 'app/assets/buddy/arms/arm-4-r.png',
    mirror: 'app/assets/buddy/arms/arm-4-l.png',
    reference: 'app/assets/buddy/arms/arm-1-r.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon limb in the identical art style, as a different shape: a small rounded wing instead of a hand, with three broad feather shapes fanning out at the end. ' +
      'ORIENTATION MATTERS: this is a RIGHT arm seen from the front. The shoulder end is the ' +
      'narrow stump at the TOP LEFT of the frame, and the limb extends down and to the right, ' +
      'exactly like the reference. Keep the same overall length and thickness as the reference. ' +
      'No body, no shoulder joint, no torso - just the arm. ' + LIMB,
    reframe: { widthScale: 1.0 },
  },
  {
    id: 'leg-2',
    title: "Buddy leg - paw foot",
    out: 'app/assets/buddy/legs/leg-2-r.png',
    mirror: 'app/assets/buddy/legs/leg-2-l.png',
    reference: 'app/assets/buddy/legs/leg-1-r.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon limb in the identical art style, as a different shape: the foot is a rounded animal paw with three plump toes across the front. ' +
      'THE OUTLINE IS THE MOST IMPORTANT PART: the whole shape must be surrounded by a thick, solid, ' +
      'pure BLACK outline of even weight, exactly like the reference. The first attempt came back with ' +
      'no outline at all and pale mint fill, which is unusable. Bold black line, bright saturated green fill. ' +
      'ORIENTATION MATTERS: this is a RIGHT leg seen from the front. The hip end is the rounded ' +
      'top LEFT of the frame and the foot points down and to the right, exactly like the ' +
      'reference. Keep the same overall length and thickness as the reference. ' +
      'No body, no hip joint, no torso - just the leg and its foot. ' + LIMB,
    reframe: { widthScale: 1.0 },
  },
  {
    id: 'leg-3',
    title: "Buddy leg - boot",
    out: 'app/assets/buddy/legs/leg-3-r.png',
    mirror: 'app/assets/buddy/legs/leg-3-l.png',
    reference: 'app/assets/buddy/legs/leg-1-r.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon limb in the identical art style, as a different shape: the foot is a chunky rounded ankle boot with a turned-over cuff at the top of it and a flat sole. ' +
      'ORIENTATION MATTERS: this is a RIGHT leg seen from the front. The hip end is the rounded ' +
      'top LEFT of the frame and the foot points down and to the right, exactly like the ' +
      'reference. Keep the same overall length and thickness as the reference. ' +
      'No body, no hip joint, no torso - just the leg and its foot. ' + LIMB,
    reframe: { widthScale: 1.0 },
  },
  {
    id: 'leg-4',
    title: "Buddy leg - bird foot",
    out: 'app/assets/buddy/legs/leg-4-r.png',
    mirror: 'app/assets/buddy/legs/leg-4-l.png',
    reference: 'app/assets/buddy/legs/leg-1-r.png',
    effort: 'draft',
    prompt:
      'Redraw this cartoon limb in the identical art style, as a different shape: the foot has three long splayed toes like a bird foot, spread wide and flat on the ground. ' +
      'ORIENTATION MATTERS: this is a RIGHT leg seen from the front. The hip end is the rounded ' +
      'top LEFT of the frame and the foot points down and to the right, exactly like the ' +
      'reference. Keep the same overall length and thickness as the reference. ' +
      'No body, no hip joint, no torso - just the leg and its foot. ' + LIMB,
    reframe: { widthScale: 1.0 },
  },
  // ---- Waking the Sanctuary (2026-09-24) ------------------------------
  // Seven Sanctuary nodes were asleep because nothing had been built behind
  // them. These are the scenes and objects their runners draw.
  //
  // Backgrounds follow the rule the Where's Buddy clearing had to learn: the
  // whole middle must be EMPTY, because gameplay art is laid over it and a
  // painted pond with lily pads already in it would argue with the lily pads
  // she is filling.
  {
    id: 'pond-background',
    title: 'Ten-Frame Pond - the lily pond',
    out: 'app/assets/activities/ten-frame-pond/backgrounds/pond.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same warm daylight palette, same gentle cartoon shapes. ' +
      'It is a calm magical pond in a sunny sanctuary, seen from slightly above. ' +
      'IMPORTANT COMPOSITION: the horizon sits high, about one fifth of the way down the image. ' +
      'Above it, a thin strip of soft blue sky and a distant soft green treeline. ' +
      'Below it, the whole rest of the image is one broad calm clear blue-green pond surface ' +
      'running all the way to the bottom edge. ' +
      'Reeds, cattails and two or three pink water lilies only along the far left and far right edges. ' +
      'The whole centre of the water is completely EMPTY - no lily pads, no rocks, no animals, ' +
      'no logs, no objects of any kind. It is empty water that other artwork will be placed on top of. ' +
      'No characters, no text, no watermark, no border, no vignette, no frame.',
    maxSize: 860,
  },
  {
    id: 'lily-pad',
    title: 'Ten-Frame Pond - one lily pad',
    out: 'app/assets/activities/ten-frame-pond/sprites/lily-pad.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is a single round green lily pad seen from directly above: a wide flat circle of ' +
      'fresh leaf green with one narrow wedge-shaped notch cut in from the edge, and a few soft ' +
      'slightly darker green vein lines radiating from the centre. Simple, flat, perfectly round. ' +
      CUTOUT,
    maxSize: 320,
  },
  {
    id: 'frog-green',
    title: 'Ten-Frame Pond - green frog',
    out: 'app/assets/activities/ten-frame-pond/sprites/frog-green.png',
    reference: 'app/assets/activities/ten-frame-pond/sprites/frog.png',
    effort: 'draft',
    prompt:
      'Redraw this frog in the identical art style to the reference - same flat cartoon look, same ' +
      'clean black outline, same big friendly eyes and rosy cheeks, same chunky baby proportions - ' +
      'but SITTING calmly and facing straight forward with both front feet down on the ground and ' +
      'no waving arm, with a small happy smile. Bright grass-green body with a pale yellow-green belly. ' +
      CUTOUT,
    maxSize: 320,
  },
  {
    id: 'frog-orange',
    title: 'Ten-Frame Pond - orange frog',
    out: 'app/assets/activities/ten-frame-pond/sprites/frog-orange.png',
    reference: 'app/assets/activities/ten-frame-pond/sprites/frog.png',
    effort: 'draft',
    // Has to be told apart from the green one by a five-year-old at a glance,
    // on a pad the size of a thumb, because "three green and two orange make
    // five" is the whole lesson. So a different colour all over, not spots.
    prompt:
      'Redraw this frog in the identical art style to the reference - same flat cartoon look, same ' +
      'clean black outline, same big friendly eyes and rosy cheeks, same chunky baby proportions - ' +
      'but SITTING calmly and facing straight forward with both front feet down on the ground and ' +
      'no waving arm, with a small happy smile. Its whole body is a warm bright ORANGE, like a ' +
      'tangerine, with a pale cream belly and a few small darker orange spots on its head. It must ' +
      'not look green anywhere. ' +
      CUTOUT,
    maxSize: 320,
  },

  // ---- Care Pantry ----
  {
    id: 'pantry-background',
    title: 'Care Pantry - the supply hut',
    out: 'app/assets/activities/care-pantry/backgrounds/pantry.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same warm palette, same gentle cartoon shapes. ' +
      'It is the inside of a cosy wooden supply hut in a magical sanctuary. ' +
      'IMPORTANT COMPOSITION: a warm wooden plank wall fills the top third, with two plain empty ' +
      'wooden shelves and a few small bundles of dried herbs hanging near the very top edge, and a ' +
      'small sunny window at the top left. The lower two thirds is one broad plain empty floor of ' +
      'warm honey-coloured wooden planks running to the bottom edge. ' +
      'The whole centre and bottom of the image is completely EMPTY - no crates, no barrels, no ' +
      'baskets, no tables, no food, no objects of any kind. ' +
      'No characters, no text, no watermark, no border, no vignette, no frame.',
    maxSize: 860,
  },
  {
    id: 'pantry-acorn',
    title: 'Care Pantry - acorn',
    out: 'app/assets/activities/care-pantry/sprites/acorn.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one single plump acorn standing upright: a shiny warm brown nut with a ' +
      'bumpy darker brown cap on top and a tiny stem. ' + CUTOUT,
    maxSize: 256,
  },
  {
    id: 'pantry-berries',
    title: 'Care Pantry - berries',
    out: 'app/assets/activities/care-pantry/sprites/berries.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one small bunch of exactly three round shiny bright red berries joined to one ' +
      'short green stem with a single small green leaf. ' + CUTOUT,
    maxSize: 256,
  },
  {
    id: 'pantry-carrot',
    title: 'Care Pantry - carrot',
    out: 'app/assets/activities/care-pantry/sprites/carrot.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one single fresh bright orange carrot, standing upright with its pointed end ' +
      'down, with a short bushy tuft of bright green leaves on top. ' + CUTOUT,
    maxSize: 256,
  },
  {
    id: 'pantry-apple',
    title: 'Care Pantry - apple',
    out: 'app/assets/activities/care-pantry/sprites/apple.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one single shiny round red apple with a short brown stem and one green leaf. ' +
      CUTOUT,
    maxSize: 256,
  },
  {
    id: 'pantry-crate',
    title: 'Care Pantry - an empty crate',
    out: 'app/assets/activities/care-pantry/sprites/crate.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one open EMPTY wooden crate seen from the front and slightly above, made of ' +
      'warm light-brown planks with small nail dots, the open top showing the empty inside. Wider ' +
      'than it is tall. Absolutely nothing inside it. ' + CUTOUT,
    maxSize: 400,
  },

  // ---- Scribe's Tower ----
  {
    id: 'tower-background',
    title: "Scribe's Tower - the writing room",
    out: 'app/assets/activities/scribes-tower/backgrounds/tower.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same warm palette, same gentle cartoon shapes. ' +
      'It is the inside of a small round stone writing tower in a magical sanctuary, warm and ' +
      'golden. IMPORTANT COMPOSITION: a curved pale stone wall with two tall arched stained-glass ' +
      'windows and a few shelves of rolled scrolls fills only the top quarter of the image and a ' +
      'narrow strip down the far left and far right edges. The whole centre and bottom of the ' +
      'image is one broad, plain, softly lit empty space of warm cream stone floor and soft golden ' +
      'light - no desk, no furniture, no scrolls, no objects. A few tiny floating gold sparkles. ' +
      'No characters, no text, no letters, no numbers, no watermark, no border, no frame.',
    maxSize: 860,
  },

  // ---- Storyteller's Pond ----
  {
    id: 'storyteller-background',
    title: "Storyteller's Pond - the pond at sunset",
    out: 'app/assets/activities/storytellers-pond/backgrounds/pond-dusk.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same gentle cartoon shapes, but in warm golden sunset light. ' +
      'It is a reedy pond in a magical sanctuary at golden hour. ' +
      'IMPORTANT COMPOSITION: a warm peach and pink sunset sky with soft clouds and a distant ' +
      'treeline across the top fifth. Below it, a broad calm pond with golden reflections fills ' +
      'the middle of the image, and a soft grassy bank runs across the bottom third to the bottom ' +
      'edge. Tall reeds and cattails only at the far left and far right edges. The centre of the ' +
      'water and the centre of the grassy bank are completely EMPTY - no animals, no rocks, no ' +
      'logs, no objects. ' +
      'No characters, no text, no watermark, no border, no vignette, no frame.',
    maxSize: 860,
  },
  {
    id: 'duckling',
    title: "Storyteller's Pond - duckling",
    out: 'app/assets/activities/storytellers-pond/sprites/duckling.png',
    reference: 'app/assets/activities/counting-parade/sprites/fawn.png',
    effort: 'draft',
    prompt:
      'Draw a new creature in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill, same friendly ' +
      'storybook baby animal proportions with a large head and big gentle eyes. ' +
      'The creature is a fluffy round baby duckling, sunny yellow all over, with a small orange ' +
      'beak and small orange webbed feet, standing three-quarter view, cheerful. ' + CUTOUT,
    maxSize: 320,
  },

  // ---- Caretaker's Bench ----
  {
    id: 'bench-background',
    title: "Caretaker's Bench - the workbench",
    out: 'app/assets/activities/caretakers-bench/backgrounds/bench.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same warm palette, same gentle cartoon shapes. ' +
      'It is a cosy corner of a garden workshop in a magical sanctuary. ' +
      'IMPORTANT COMPOSITION: a warm wooden plank wall with a small glowing hanging lantern and ' +
      'a few garden tools on pegs fills the top third only. Below it, the entire rest of the image ' +
      'is the broad, flat, EMPTY top surface of one long light wooden workbench running edge to ' +
      'edge and all the way to the bottom of the image. The workbench surface is completely empty ' +
      '- no tools, no jars, no objects of any kind. ' +
      'No characters, no text, no watermark, no border, no vignette, no frame.',
    maxSize: 860,
  },
  {
    id: 'scale-stand',
    title: "Caretaker's Bench - balance scale stand",
    out: 'app/assets/activities/caretakers-bench/sprites/scale-stand.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    // Just the stand. The beam and pans are drawn in code, because they have
    // to tip by exactly the amount the two weights say and a picture cannot.
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is only the stand of an old-fashioned balance scale, with NO beam and NO pans: ' +
      'a heavy round golden brass base and one single tall straight golden brass post rising from ' +
      'the middle of it, ending in a small round knob at the very top. Nothing else. ' + CUTOUT,
    maxSize: 400,
  },
  {
    id: 'bench-pumpkin',
    title: "Caretaker's Bench - pumpkin",
    out: 'app/assets/activities/caretakers-bench/sprites/pumpkin.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one big round ribbed orange pumpkin with a short curly green stem. ' + CUTOUT,
    maxSize: 320,
  },
  {
    id: 'bench-watermelon',
    title: "Caretaker's Bench - watermelon",
    out: 'app/assets/activities/caretakers-bench/sprites/watermelon.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one large whole oval watermelon lying on its side, dark and light green stripes. ' +
      CUTOUT,
    maxSize: 320,
  },
  {
    id: 'bench-rock',
    title: "Caretaker's Bench - rock",
    out: 'app/assets/activities/caretakers-bench/sprites/rock.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one single chunky rounded grey boulder, smooth, solid and heavy looking. ' +
      CUTOUT,
    maxSize: 320,
  },
  {
    id: 'bench-leaf',
    title: "Caretaker's Bench - leaf",
    out: 'app/assets/activities/caretakers-bench/sprites/leaf.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one single small light green leaf with a short thin stem, gently curved. ' +
      CUTOUT,
    maxSize: 256,
  },

  // ---- Picnic Baskets ----
  {
    id: 'picnic-background',
    title: 'Picnic Baskets - the picnic glade',
    out: 'app/assets/activities/picnic-baskets/backgrounds/picnic.png',
    reference: 'app/assets/activities/shape-garden/shape_garden_background.png',
    effort: 'standard',
    cutout: false,
    prompt:
      'Paint a new background illustration in the identical art style to this reference image - ' +
      'same soft painted storybook look, same warm daylight palette, same gentle cartoon shapes. ' +
      'It is a sunny grassy glade in a magical sanctuary, set for a picnic. ' +
      'IMPORTANT COMPOSITION: soft blue sky and a gentle treeline across the top fifth. The rest ' +
      'is sunny green grass. One very large plain red-and-white gingham picnic blanket lies flat ' +
      'on the grass across the middle and lower part of the image, seen from slightly above, ' +
      'filling most of the width. The blanket is completely EMPTY - no food, no baskets, no ' +
      'plates, no cups, no animals, no objects of any kind on it. ' +
      'No characters, no text, no watermark, no border, no vignette, no frame.',
    maxSize: 860,
  },
  {
    id: 'picnic-basket',
    title: 'Picnic Baskets - a picnic basket',
    out: 'app/assets/activities/picnic-baskets/sprites/basket.png',
    reference: 'app/assets/activities/shape-garden/watering-can-decor.png',
    effort: 'draft',
    prompt:
      'Draw a new object in the identical art style to this reference image - same flat vector ' +
      'cartoon look, same clean black outline weight, same flat unshaded colour fill. ' +
      'The object is one woven wicker picnic basket with a curved handle over the top, light ' +
      'golden-brown weave, lid closed, seen from the front. ' + CUTOUT,
    maxSize: 320,
  },
];

export function assetById(id) {
  return ASSETS.find((a) => a.id === id);
}

export function resolveIds(args) {
  if (!args.length) return ASSETS.map((a) => a.id);
  const unknown = args.filter((a) => !assetById(a));
  if (unknown.length) throw new Error(`unknown asset id(s): ${unknown.join(', ')}`);
  return args;
}
