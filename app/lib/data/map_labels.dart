// The words a tap on a map says out loud.
//
// These are here rather than inline in the two map screens for one reason:
// the narration script has to be able to enumerate them, and nothing else
// could reach them.
//
//   - `narration_script.dart` is Flutter-free by test, so it can never import
//     a screen.
//   - The literal sweep in `tool/narration_sources.dart` rejects them on
//     purpose. Its strongest filter is "ends like a sentence", which is what
//     stops every semantic label, tooltip and button caption in `lib/` from
//     becoming a voice clip. 'Mystic Sanctuary' does not end in a full stop,
//     so it never had a chance.
//
// The result was that the first two words a five-year-old hears in a session -
// the region she taps to get in, and the story node she taps first once she is
// there - were still speaking in the browser synth voice long after the rest
// of the game had been rendered in the narrator's. That is worse than silence:
// it is a jarring switch of voice at the front door.
//
// The Sanctuary's lesson banners say `activity.displayName`, which comes from
// `data/activity-registry/*.json` and so cannot live here either. Those are
// enumerated by `activityDisplayNames()` in `tool/dump_narration_script.dart`,
// next to the lesson lines it reads from the same mirror.

/// Regions on the Mystical Island map, in the order they are declared.
///
/// Foundry and Portals are `enabled: false` today. A disabled region does not
/// speak its own name - it says [kAsleepPlaceLine] instead, the same sentence
/// the Sanctuary's sleeping nodes say - so those two are enumerated against
/// the day they wake up rather than for today. Two short clips are a few
/// kilobytes, and the alternative is that opening a region silently drops it
/// back to the synth voice, which is the failure this file exists to fix.
const String kHomeRegionLabel = 'Home';
const String kFoundryRegionLabel = 'Foundry';
const String kPortalsRegionLabel = 'Portals';
const String kMysticSanctuaryRegionLabel = 'Mystic Sanctuary';

/// The story-kickoff node at the head of the Sanctuary sequence — the one
/// drawn with a play arrow instead of a lesson number.
const String kSanctuaryCutsceneLabel = 'Welcome';

/// What a tap on a place that has nothing behind it yet says.
///
/// Used by both maps. It was written for the Sanctuary's sleeping nodes and
/// named for them, and then the island's two dark regions turned out to have
/// the identical problem and no answer to it at all: `enabled: false` gave
/// them `onTap: null` under an *opaque* hit test, so a tap on the Foundry was
/// swallowed and returned nothing - no sound, no voice, no movement - on the
/// first screen of every session. One sentence covers both maps, and reusing
/// it means reusing the clip.
///
/// Four of the eleven nodes are not in the activity registry at all and three
/// more are registered with no runner, so seven of eleven places on the map
/// open nothing. They stay drawn — specs/shared/map-screens.md wants the
/// region to have a shape from the start — but a tap used to do one of two
/// things, and both were bad: nothing whatsoever, which to a child is
/// indistinguishable from the app having frozen, or a route to a screen
/// carrying the sentence `Activity "ten-frame-pond" lands in a later sprint.`
/// in front of someone who cannot read.
///
/// So it says something instead. It names no place, deliberately: one clip
/// covers all seven, and the child already knows which one she touched. What
/// she does not know is that nothing is broken and where to go instead, and
/// "bright" is the difference she can see — awake nodes are yellow, sleeping
/// ones are drained of colour.
const String kAsleepPlaceLine =
    'That one is still asleep. Try one of the bright ones!';

/// Captions on the side-rail buttons of both maps.
///
/// The rail exists because four 24-pixel icons in an app bar is the least
/// reachable place on the screen for the person this game is for. Having
/// moved them somewhere she can hit, nobody gave them a voice: `MapRailButton`
/// was a bare `InkWell`, so all five - the shop, the card album, decorate
/// mode, and both Settings - made no sound when pressed and said nothing,
/// under captions she cannot read. Two of those five are the game's entire
/// reward economy and a third is the only open-ended play in it.
///
/// Decorate mode's exit reuses `kLabelDone` from button_labels.dart rather
/// than adding a second 'Done' here: clips are keyed by their words, so a
/// duplicate is one clip with two names waiting to drift apart.
const String kRailDecorateLabel = 'Decorate';
const String kRailCardsLabel = 'Cards';
const String kRailShopLabel = 'Shop';
const String kRailSettingsLabel = 'Settings';

/// Every label above, for the recording script.
const List<String> kSpokenMapLabels = <String>[
  kHomeRegionLabel,
  kFoundryRegionLabel,
  kPortalsRegionLabel,
  kMysticSanctuaryRegionLabel,
  kSanctuaryCutsceneLabel,
  kRailDecorateLabel,
  kRailCardsLabel,
  kRailShopLabel,
  kRailSettingsLabel,
];
