// Per-sub-mode metadata for the Sanctuary node picker — the symbol sprite
// and short label shown in the bottom sheet when the kid taps an activity
// node that has more than one available sub-mode.
//
// Challenge sub-modes share the same metadata block as regular ones; the
// picker decides whether to surface them. The convention going forward
// is: challenge sub-modes live at the end of an activity's chain and only
// appear in the picker once every regular sub-mode is complete, marked
// with a "Challenge!" chip so the kid knows it's optional.

import 'asset_paths.dart';

class SubModePickerOption {
  const SubModePickerOption({
    required this.label,
    required this.symbolAsset,
  });

  /// Short button label shown beneath the symbol.
  final String label;

  /// Sprite shown as the picker option's icon. Same size + treatment for
  /// every option so the kid can compare shapes at a glance.
  final String symbolAsset;
}

/// Picker metadata keyed by `(activityId, subModeId)`. A missing entry
/// means we draw a generic placeholder — keeps the picker forgiving of
/// sub-modes whose runtime hasn't shipped yet.
final Map<String, Map<String, SubModePickerOption>> kSubModePickerData =
    <String, Map<String, SubModePickerOption>>{
  'shape-garden': <String, SubModePickerOption>{
    'find-shape': SubModePickerOption(
      label: 'Find the shape',
      symbolAsset:
          AssetPaths.shapeGarden2dSprite('triangle', 'yellow'),
    ),
    'flat-or-solid': SubModePickerOption(
      label: 'Flat or solid',
      symbolAsset:
          AssetPaths.shapeGarden3dCreature('sphere', 'jellyfish'),
    ),
    'sort-by-attribute': SubModePickerOption(
      label: 'Sort by attribute',
      symbolAsset:
          AssetPaths.shapeGarden2dSprite('hexagon', 'honeycomb'),
    ),
    'two-attribute-hunt': SubModePickerOption(
      label: 'Two-attribute hunt',
      symbolAsset:
          AssetPaths.shapeGarden2dSprite('pentagon', 'starfruit'),
    ),
  },
  'counting-parade': <String, SubModePickerOption>{
    'count-the-parade': const SubModePickerOption(
      label: 'Count the parade',
      symbolAsset: AssetPaths.countingParadeFawn,
    ),
    'count-forward-from-n': const SubModePickerOption(
      label: 'Counting on',
      symbolAsset: AssetPaths.countingParadeBabyGryphon,
    ),
    'count-out-n': const SubModePickerOption(
      label: 'Count out',
      symbolAsset: AssetPaths.countingParadeGoldenEgg,
    ),
    'count-on-by-ones': const SubModePickerOption(
      label: 'Count by ones',
      symbolAsset: AssetPaths.countingParadeBabyPhoenix,
    ),
    'long-parade': const SubModePickerOption(
      label: 'Big parade',
      symbolAsset: AssetPaths.countingParadeBabyUnicorn,
    ),
    'tens-parade': const SubModePickerOption(
      label: 'Count to 100',
      symbolAsset: AssetPaths.countingParadeBabyDragon,
    ),
  },
  'wheres-buddy': <String, SubModePickerOption>{
    // K.G.1 — find the hiding Buddy / place the Buddy at a relative
    // position. Icons reuse the parade-Toucan + parade-Phoenix sprites
    // as a stop-gap until a dedicated Buddy silhouette ships.
    'find-mode': const SubModePickerOption(
      label: 'Hide and seek',
      symbolAsset: AssetPaths.countingParadeBabyToucan,
    ),
    'place-mode': const SubModePickerOption(
      label: 'Put Buddy there',
      symbolAsset: AssetPaths.countingParadeBabyPhoenix,
    ),
    'relational-mode': const SubModePickerOption(
      label: 'Two friends',
      symbolAsset: AssetPaths.countingParadeBabyUnicorn,
    ),
  },
  'build-a-habitat': <String, SubModePickerOption>{
    // K.G.5 + K.G.6 — build a frame with clay and sticks, then raise
    // the habitat with 3D pieces. Icons reuse the existing 3D outline
    // sprites to telegraph "this is about making shapes."
    'simple-shelter': SubModePickerOption(
      label: 'Simple shelter',
      symbolAsset: AssetPaths.shapeGarden3dOutline('cube'),
    ),
    'creature-home': SubModePickerOption(
      label: 'Creature home',
      symbolAsset: AssetPaths.shapeGarden3dOutline('cylinder'),
    ),
    'grand-habitat': SubModePickerOption(
      label: 'Grand habitat',
      symbolAsset: AssetPaths.shapeGarden3dOutline('sphere'),
    ),
  },
};

SubModePickerOption? pickerOptionFor({
  required String activityId,
  required String subModeId,
}) {
  return kSubModePickerData[activityId]?[subModeId];
}
