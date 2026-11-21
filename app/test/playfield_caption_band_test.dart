// Nothing she has to touch may sit under the caption band.
//
// Every runner is mounted full-bleed by `activity_screen`, which also mounts
// `CaptionOverlay` - an opaque strip across the bottom of the screen. So the
// box a runner lays out in is taller than the space it can put things in, and
// a runner that positions anything by a fraction of its own height, or that
// lets an `Expanded` fill to the bottom, will put something underneath it.
//
// That has now happened three times, none of which looked broken:
//
//   1. Counting Parade's companion stood at the bottom of the meadow with the
//      band across it. Fixed locally, by that runner, with a new constant.
//   2. Where's Buddy parked the Buddy she has to *pick up* at 0.92 of the
//      clearing - so he waited every round, and returned after every miss,
//      with a subtitle across his body. "Below the mushroom", an answer,
//      landed in the same strip.
//   3. Shape Garden scattered its shapes on a 4x3 grid over the full height,
//      so in a round whose instruction is "tap all the circles" two of the
//      three circles had their lower third behind the band; and its three
//      sorting baskets each had eighty pixels of drop target under it.
//
// Each was found by rendering a screen and looking at it, which is not a
// process that scales to ten playfields and every future one. This is that
// check, done by measurement: mount each playfield the way the activity
// screen does, find everything that takes a touch, and fail if any of it
// reaches into the band.
//
// It deliberately does not check that anyone uses `PlayfieldArea`. There is
// more than one right way to keep clear of the band - a fractional layout
// wants the inset area, a Column wants bottom padding - and what matters is
// the child being able to reach the thing, not which of the two was used.

import 'package:critmath/activities/build_a_habitat/build_a_habitat_runner.dart';
import 'package:critmath/activities/care_pantry/care_pantry_runner.dart';
import 'package:critmath/activities/caretakers_bench/caretakers_bench_runner.dart';
import 'package:critmath/activities/counting_parade/count_forward_from_n_runner.dart';
import 'package:critmath/activities/counting_parade/count_on_by_ones_runner.dart';
import 'package:critmath/activities/counting_parade/count_out_n_runner.dart';
import 'package:critmath/activities/counting_parade/counting_parade_runner.dart';
import 'package:critmath/activities/counting_parade/long_parade_runner.dart';
import 'package:critmath/activities/counting_parade/tens_parade_runner.dart';
import 'package:critmath/activities/fluency/fluency_runner.dart';
import 'package:critmath/activities/picnic_baskets/picnic_baskets_runner.dart';
import 'package:critmath/activities/scribes_tower/scribes_tower_runner.dart';
import 'package:critmath/activities/shape_garden/shape_garden_runner.dart';
import 'package:critmath/activities/shape_garden/shape_garden_sort_by_attribute_runner.dart';
import 'package:critmath/activities/shape_garden/two_attribute_hunt_runner.dart';
import 'package:critmath/activities/storytellers_pond/storytellers_pond_runner.dart';
import 'package:critmath/activities/ten_frame_pond/ten_frame_pond_runner.dart';
import 'package:critmath/activities/wheres_buddy/wheres_buddy_runner.dart';
import 'package:critmath/providers/session_provider.dart';
import 'package:critmath/ui/common/caption_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/harness.dart';

/// Every playfield a child can reach, built the way the activity screen
/// builds it.
///
/// A function rather than a const map because a widget cannot be reused
/// across two `pumpWidget` calls with different sizes.
Map<String, Widget> playfields() => <String, Widget>{
  'counting-parade': CountingParadeRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'long-parade': LongParadeRunner(onSequenceComplete: () {}, skipIntro: true),
  'count-out-n': CountOutNRunner(onSequenceComplete: () {}, skipIntro: true),
  'count-forward-from-n': CountForwardFromNRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'count-on-by-ones': CountOnByOnesRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'shape-garden-find': ShapeGardenRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'tens-parade': TensParadeRunner(onSequenceComplete: () {}, skipIntro: true),
  'shape-garden-flat-or-solid': ShapeGardenSortingRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'shape-garden-sort': ShapeGardenSortByAttributeRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'two-attribute-hunt': TwoAttributeHuntRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'build-a-habitat': BuildAHabitatRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'wheres-buddy': WheresBuddyRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'place-mode',
  ),
  'ten-frame-fill': TenFramePondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'ten-frame-two-ways': TenFramePondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'two-ways',
  ),
  'ten-frame-teens': TenFramePondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'ten-plus-n',
  ),
  'ten-frame-challenge': TenFramePondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'three-frames',
  ),
  'pantry-simple': CarePantryRunner(onSequenceComplete: () {}, skipIntro: true),
  'pantry-full': CarePantryRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'full-pantry',
  ),
  'pantry-colour': CarePantryRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'unfamiliar-rules',
  ),
  'scribe-trace': ScribesTowerRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'scribe-cue': ScribesTowerRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'write-from-cue',
  ),
  'scribe-match': ScribesTowerRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'match-numeral',
  ),
  'story-add': StorytellersPondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'story-take': StorytellersPondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'take-from',
  ),
  'story-together': StorytellersPondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'put-together',
  ),
  'story-apart': StorytellersPondRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'take-apart',
  ),
  'bench-describe': CaretakersBenchRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'bench-weigh': CaretakersBenchRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'compare-two',
  ),
  'bench-order': CaretakersBenchRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'order-three-by-length',
  ),
  'picnic-match': PicnicBasketsRunner(
    onSequenceComplete: () {},
    skipIntro: true,
  ),
  'picnic-count': PicnicBasketsRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'count-and-compare',
  ),
  'picnic-numerals': PicnicBasketsRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'numeral-compare',
  ),
  'picnic-three': PicnicBasketsRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'three-way-compare',
  ),
  'fluency-casual': FluencyRunner(onSequenceComplete: () {}, skipIntro: true),
  'fluency-speed': FluencyRunner(
    onSequenceComplete: () {},
    skipIntro: true,
    subMode: 'speed-run',
  ),
};

/// Window shapes to check.
///
/// The reference size first - `README.md` names 1180x820, iPad Air logical
/// resolution, and the rest of the suite pins the same. Then the same width
/// at a shorter height, because the band is a fixed 96 pixels and so eats a
/// larger share of a shorter window. Height is the only thing varied on
/// purpose: playfields are fixed logical pixels by design, so squeezing the
/// width produces overflow that says nothing about the caption band.
const List<Size> _sizes = <Size>[Size(1180, 820), Size(1180, 700)];

/// The on-screen rect of the nearest enclosing scroll viewport, if any.
Rect? _viewportOf(Element element) {
  Rect? found;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is Scrollable) {
      final box = ancestor.renderObject;
      if (box is RenderBox && box.hasSize) {
        found = box.localToGlobal(Offset.zero) & box.size;
      }
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in playfields().entries) {
    testWidgets('${entry.key} keeps everything touchable above the band', (
      tester,
    ) async {
      for (final size in _sizes) {
        useViewSize(tester, size);

        await tester.pumpWidget(
          ProviderScope(
            // Pinned so the seeded scatter is the same layout every run; an
            // intermittently-failing layout guard gets muted rather than
            // fixed.
            overrides: [sessionIdProvider.overrideWithValue('band-guard')],
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(child: playfields()[entry.key]!),
                    const CaptionOverlay(),
                  ],
                ),
              ),
            ),
          ),
        );
        // Explicit frames: BuddyWidget breathes on a repeating controller, so
        // pumpAndSettle never returns on a playfield.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        final bandTop = size.height - kCaptionBandClearance;
        final screenArea = size.width * size.height;
        final offenders = <String>[];

        for (final type in <Type>[
          GestureDetector,
          Draggable<Object>,
          DragTarget<Object>,
          InkWell,
        ]) {
          for (final element in find.byType(type).evaluate()) {
            final box = element.renderObject;
            if (box is! RenderBox || !box.hasSize) continue;
            var rect = box.localToGlobal(Offset.zero) & box.size;
            // Full-bleed layers are not actors. Several runners wrap the
            // whole playfield in a gesture surface - the miss reaction in
            // Where's Buddy is the clearing itself - and those legitimately
            // extend behind the band.
            if (rect.width * rect.height > screenArea * 0.35) continue;
            // Inside a scroll view, a child's own rect is not a claim about
            // the screen: it is clipped to the viewport, and content past the
            // bottom is scrolled-away rather than hidden behind the band.
            // Measuring the intersection asks the right question - what can
            // she see and reach right now.
            final viewport = _viewportOf(element);
            if (viewport != null) {
              rect = rect.intersect(viewport);
              if (rect.isEmpty) continue;
            }
            if (rect.bottom <= bandTop + 0.5) continue;
            offenders.add(
              '$type at (${rect.left.toStringAsFixed(0)}, '
              '${rect.top.toStringAsFixed(0)}) '
              '${rect.width.toStringAsFixed(0)}x'
              '${rect.height.toStringAsFixed(0)}, bottom '
              '${rect.bottom.toStringAsFixed(0)} vs band top '
              '${bandTop.toStringAsFixed(0)}',
            );
          }
        }

        expect(
          offenders.toSet().toList(),
          isEmpty,
          reason:
              '${entry.key} at ${size.width.toInt()}x'
              '${size.height.toInt()} puts something she has to touch under '
              'the caption band',
        );

        // Round timers keep running; unmount before the next size so they do
        // not fail teardown.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });
  }
}
