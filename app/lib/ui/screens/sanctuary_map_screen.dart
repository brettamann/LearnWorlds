// SanctuaryMapScreen — anchor-driven layout. The map PNG embeds magenta
// pixel markers (#FF00F0..#FF00FB) at the painter's chosen positions; the
// scanner finds them at boot and this screen renders nodes, banners, a
// dotted path between them, and a fog-of-war cloud layer over unexplored
// regions on top of the same image.
//
// Anchor → role mapping:
//   #FF00F0  →  story-kickoff cutscene ("Welcome", no lesson number)
//   #FF00F1  →  lesson 1   (Counting Parade)
//   #FF00F2  →  lesson 2   (Shape Garden)
//   #FF00F3  →  lesson 3   (Ten-Frame Pond)
//   #FF00F4  →  lesson 4   (Build-a-Habitat)
//   #FF00F5  →  lesson 5   (Care Pantry)
//   #FF00F6  →  lesson 6   (Scribe's Tower)
//   #FF00F7  →  lesson 7   (Storyteller's Pond)
//   #FF00F8  →  lesson 8   (Where's Buddy?)
//   #FF00F9  →  lesson 9   (Caretaker's Bench)
//   #FF00FA  →  lesson 10  (Picnic Baskets)
//   #FF00FB  →  lesson 11  (Fluency Within 5)
//
// Edit `kSanctuarySequence` below if the magenta order in the art changes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/activity_registry.dart';
import '../../data/asset_paths.dart';
import '../../data/button_labels.dart';
import '../../data/concept_registry.dart';
import '../../data/map_labels.dart';
import '../../data/playable_activities.dart';
import '../../data/sanctuary_decor_catalog.dart';
import '../../data/sanctuary_sequence.dart';
import '../../engines/feedback/feedback_engine.dart';
import '../../engines/narration/narration_line.dart';
import '../../engines/narration/narration_player.dart';
import '../../models/activity.dart';
import '../../models/decor_placement.dart';
import '../../models/reward_track.dart';
import '../../navigation/routes.dart';
import '../../navigation/sub_mode_launcher.dart';
import '../../providers/app_providers.dart';
import '../../providers/exploration_provider.dart';
import '../../providers/map_anchors_provider.dart';
import '../../providers/sanctuary_decor_provider.dart';
import '../../providers/save_provider.dart';
import '../../providers/sub_mode_progress_provider.dart';
import '../../providers/wallet_provider.dart';
import '../widgets/coin_hud.dart';
import '../widgets/decor_tray.dart';
import '../widgets/map_dotted_path_painter.dart';
import '../widgets/map_fog_layer.dart';
import '../widgets/map_node_with_banner.dart';
import '../widgets/map_side_rail.dart';
import '../widgets/music_bed_scope.dart';
import '../widgets/reward_overlay.dart' show RewardOverlay;
import '../widgets/sanctuary_decor_layer.dart';
import '../widgets/sub_mode_picker_sheet.dart';

/// Per-node banner side. Chosen by hand to avoid overlaps with the dotted
/// path on the current Sanctuary map; flip a side here if a new arrangement
/// causes a banner to collide with a node, line, or another banner.
const Map<int, BannerSide> _bannerSideByCode = {
  0xF0: BannerSide.below,
  // Above, not right: its right-hand banner ran straight over Shape Garden's
  // node and banner, which only mattered once every place could be on the
  // map at once. `sanctuary_banners_test.dart` measures it.
  0xF1: BannerSide.above,
  0xF2: BannerSide.right,
  0xF3: BannerSide.right,
  0xF4: BannerSide.below,
  0xF5: BannerSide.left,
  0xF6: BannerSide.left,
  // Right: on a larger window its left-hand banner ran off the screen.
  0xF7: BannerSide.right,
  0xF8: BannerSide.below,
  0xF9: BannerSide.right,
  0xFA: BannerSide.left,
  0xFB: BannerSide.right,
};

class SanctuaryMapScreen extends ConsumerStatefulWidget {
  const SanctuaryMapScreen({super.key});

  @override
  ConsumerState<SanctuaryMapScreen> createState() => _SanctuaryMapScreenState();
}

class _SanctuaryMapScreenState extends ConsumerState<SanctuaryMapScreen> {
  /// True while the decorate tray is open. Deliberately not persisted: she
  /// should land on her sanctuary, not on a workbench.
  bool _decorating = false;

  /// Identifies the map box so a global drop point can be turned into a
  /// normalised position inside it.
  final GlobalKey _mapKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final anchors = ref.watch(sanctuaryAnchorsProvider);
    final activityRegistry = ref.watch(activityRegistryProvider);
    final conceptRegistry = ref.watch(conceptRegistryProvider);
    final exploration = ref.watch(explorationProvider);
    final owned = ref.watch(decorOwnershipProvider);

    return MusicBedScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mystic Sanctuary'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to the island',
            onPressed: () => context.go(Routes.home),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: anchors.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Center(
                              child: Text('Map load failed: $e'),
                            ),
                            data: (data) => _MapStack(
                              key: _mapKey,
                              anchors: data.anchors,
                              exploration: exploration,
                              activityRegistry: activityRegistry,
                              conceptRegistry: conceptRegistry,
                              decorating: _decorating,
                              placements: ref.watch(sanctuaryDecorProvider),
                              onCutsceneTap: () =>
                                  context.go(Routes.sanctuaryCutscene),
                              onDecorMoved: _onDecorMoved,
                              onDecorTapped: (p) {
                                final item = decorItemById(p.decorId);
                                if (item != null) _say(decorNameLine(item));
                              },
                              onLessonTap: (activity) =>
                                  _onLessonTap(context, ref, activity),
                              onAsleepTap: (line) =>
                                  _say(line, cueId: 'sanctuary:asleep'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The map draws as a centred square, so on any landscape
                    // screen there is a column of unused space beside it. The
                    // controls live there rather than in the app bar: four
                    // 24px icons in the top-right corner is the least
                    // reachable place on the screen for the person this game
                    // is for.
                    MapSideRail(
                      children: [
                        // Directly above the shop, and a fresh balance is
                        // most worth showing on the map she lands on straight
                        // after a sub-mode.
                        const CoinHud(),
                        MapRailButton(
                          key: const ValueKey('sanctuary-decorate'),
                          icon: _decorating ? Icons.check : Icons.park,
                          caption:
                              _decorating ? kLabelDone : kRailDecorateLabel,
                          active: _decorating,
                          onPressed: _toggleDecorating,
                        ),
                        MapRailButton(
                          icon: Icons.style,
                          caption: kRailCardsLabel,
                          onPressed: () => context.go(Routes.collection),
                        ),
                        MapRailButton(
                          icon: Icons.storefront,
                          caption: kRailShopLabel,
                          onPressed: () => context.go(Routes.buddyShop),
                        ),
                        MapRailButton(
                          icon: Icons.settings,
                          caption: kRailSettingsLabel,
                          onPressed: () => context.go(Routes.settings),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_decorating)
                DecorTray(
                  // Watched, not read: a purchase changes this set, and the
                  // tile has to stop being a price chip the instant it does.
                  owns: (id) =>
                      kDecorFreeItems.contains(id) || owned.contains(id),
                  coins: ref.watch(walletProvider),
                  onBuy: _onBuy,
                  onTapOwned: (item) => _say(decorNameLine(item)),
                  onPlace: _onPlace,
                  onRemove: _onRemove,
                  onDone: _toggleDecorating,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Speaks a line on the map.
  ///
  /// The cueId names the slot for the cue log, not the clip — clips are keyed
  /// by the words themselves — so it costs nothing to be accurate about which
  /// surface is talking, and an export that lumps a sleeping-node answer in
  /// with the decor names is an export nobody can read.
  void _say(String text, {String cueId = 'sanctuary:decor'}) {
    // The only other voice on this screen is a banner tap, and a banner tap
    // either navigates away or is this same call, so these can never cut a
    // line off mid-word the way a reveal sharing a beat with the keeper would.
    ref.narration.say(text, cueId: cueId, speaker: kKeeperSpeaker);
  }

  void _toggleDecorating() {
    final opening = !_decorating;
    setState(() => _decorating = opening);
    if (opening) _say(kDecorInviteLine);
  }

  /// Turns a global release point into a normalised position on the map, or
  /// null if she let go outside it — over the tray, or off the edge.
  ({double x, double y})? _normalise(Offset global) {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    final x = local.dx / box.size.width;
    final y = local.dy / box.size.height;
    if (x < 0 || x > 1 || y < 0 || y > 1) return null;
    return (x: x, y: y);
  }

  void _onPlace(DecorItem item, Offset global) {
    final at = _normalise(global);
    // Dropped outside the map: nothing happens, and nothing is said. She
    // still has the item; there is no mistake here to report.
    if (at == null) return;
    final placed =
        ref.read(sanctuaryDecorProvider.notifier).place(item.id, at.x, at.y);
    if (placed == null) return;
    ref.read(feedbackEngineProvider).correct();
    unawaited(ref.read(saveCoordinatorProvider).persist());
  }

  void _onDecorMoved(int instanceId, Offset global) {
    final at = _normalise(global);
    // Released off the map but not on the tray: leave it where it was rather
    // than deleting it. Deleting is the tray, and only the tray.
    if (at == null) return;
    ref.read(sanctuaryDecorProvider.notifier).move(instanceId, at.x, at.y);
    unawaited(ref.read(saveCoordinatorProvider).persist());
  }

  void _onRemove(int instanceId) {
    ref.read(sanctuaryDecorProvider.notifier).remove(instanceId);
    ref.read(feedbackEngineProvider).wrong();
    unawaited(ref.read(saveCoordinatorProvider).persist());
  }

  /// Buying, and the soft refusal when she cannot afford it yet.
  void _onBuy(DecorItem item) {
    final ownership = ref.read(decorOwnershipProvider.notifier);
    if (ownership.owns(item.id)) return;
    final price = decorPrice(item.id);
    if (!ref.read(walletProvider.notifier).spend(price)) {
      // Reuses the wrong-answer beat rather than an error: a shop she cannot
      // afford yet must stay a nice place to look at.
      ref.read(feedbackEngineProvider).wrong();
      _say(kDecorTooExpensiveLine);
      return;
    }
    ownership.grant(item.id);
    ref.read(feedbackEngineProvider).roundPass();
    _say(decorNameLine(item));
    unawaited(ref.read(saveCoordinatorProvider).persist());
  }

  Future<void> _onLessonTap(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final concepts = ref.read(conceptRegistryProvider).valueOrNull;
    if (concepts == null) {
      context.goActivity(activity.id);
      return;
    }

    // Build the picker entry set: every chain sub-mode in registry order.
    // `next` is the first that hasn't been completed yet — there can be at
    // most one `next` per visit. Sub-modes after `next` are hidden so the
    // kid can't skip ahead.
    //
    // A demotion floor below the entry point is not a chain step and never
    // appears here — Build-a-Habitat's `frame-only` is the only one in the
    // grade. A floor is somewhere the scaffolding puts a kid who is
    // struggling, so offering it as a thing to choose is offering her the
    // remedial drill, and this one had no artwork or label of its own, so it
    // drew as a grey question mark over the words `frame-only`. (Most
    // activities mark their *default* sub-mode as the floor too; that one is
    // the first thing she plays and stays. See SubMode.isChainStep.)
    final completed =
        ref.read(subModeProgressProvider.notifier).completedFor(activity.id);
    final regular =
        activity.subModes.where((m) => m.isChainStep).toList(growable: false);
    final entries = <SubModePickerEntry>[];
    var nextAssigned = false;
    for (final subMode in regular) {
      final isCompleted = completed.contains(subMode.id);
      final isNext = !isCompleted && !nextAssigned;
      // Later un-completed sub-modes aren't offered yet — the kid works
      // through the chain in order.
      if (!isCompleted && !isNext) break;
      entries.add(
        SubModePickerEntry(
          subMode: subMode,
          isCompleted: isCompleted,
          isNext: isNext,
        ),
      );
      if (isNext) nextAssigned = true;
    }
    // Once every regular sub-mode is done, the challenge sub-modes unlock
    // as optional final checks. They sit at the end of the picker with a
    // "Challenge!" chip and the kid can ignore them forever — the activity
    // is considered fully complete by `_allNonChallengeSubModesDone`
    // regardless of whether they're ever played.
    final allRegularDone = regular.every((m) => completed.contains(m.id));
    if (allRegularDone) {
      for (final subMode in activity.subModes.where((m) => m.isChallenge)) {
        entries.add(
          SubModePickerEntry(
            subMode: subMode,
            isCompleted: completed.contains(subMode.id),
            isNext: false,
            isChallenge: true,
          ),
        );
      }
    }
    if (entries.isEmpty) {
      // No registered sub-modes — fall back to the activity tile.
      context.goActivity(activity.id);
      return;
    }

    SubMode chosenSubMode;
    if (entries.length == 1) {
      // One option — skip the picker and route directly.
      chosenSubMode = entries.first.subMode;
    } else {
      final pickedId = await showSubModePicker(
        context,
        activityId: activity.id,
        activityDisplayName: activity.displayName,
        entries: entries,
      );
      if (pickedId == null) return; // dismissed
      if (!context.mounted) return;
      chosenSubMode =
          entries.firstWhere((e) => e.subMode.id == pickedId).subMode;
    }

    launchSubMode(context, ref, activity: activity, subMode: chosenSubMode);
  }
}

class _MapStack extends StatelessWidget {
  const _MapStack({
    super.key,
    required this.anchors,
    required this.exploration,
    required this.activityRegistry,
    required this.conceptRegistry,
    required this.decorating,
    required this.placements,
    required this.onCutsceneTap,
    required this.onDecorMoved,
    required this.onDecorTapped,
    required this.onLessonTap,
    required this.onAsleepTap,
  });

  final Map<int, Offset> anchors;
  final Set<int> exploration;
  final AsyncValue<ActivityRegistry> activityRegistry;
  final AsyncValue<ConceptRegistry> conceptRegistry;
  final bool decorating;
  final List<DecorPlacement> placements;
  final VoidCallback onCutsceneTap;
  final DecorMoved onDecorMoved;
  final void Function(DecorPlacement placement) onDecorTapped;
  final ValueChanged<Activity> onLessonTap;

  /// Says why a place that isn't built yet did nothing. Silence here reads as
  /// a frozen app, which is the single failure this whole project set out to
  /// stop being possible.
  final ValueChanged<String> onAsleepTap;

  /// A node is visible when it's been explored, or when it's the next node
  /// after the last explored one — so the kid can see what's next to go to.
  ///
  /// The rule lives in sanctuary_sequence.dart rather than here: it is
  /// curriculum sequencing, not layout, and it has one subtlety worth reading
  /// before changing anything (a node with no runner can never be completed,
  /// so it must not be allowed to gate the node after it).
  bool _isVisible(int code) => isSanctuaryNodeVisible(code, exploration);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final shortest = w < h ? w : h;
        // Node sizing: ~7% of the shortest map side scales well across screens.
        final nodeDiameter = shortest * 0.07;

        // Pixel positions of every anchor.
        final centres = <int, Offset>{};
        for (final code in kSanctuarySequence) {
          final norm = anchors[code];
          if (norm == null) continue;
          centres[code] = Offset(norm.dx * w, norm.dy * h);
        }

        // Two segment lists, both keyed by which endpoints are revealed:
        //   - `pathSegments` are drawn (both endpoints visible) — so we
        //     never paint a dotted line wandering into the fog.
        //   - `clearedSegments` clear fog (start endpoint explored) so the
        //     air around the path opens up as the kid progresses.
        final pathSegments = <(Offset, Offset)>[];
        final clearedSegments = <(Offset, Offset)>[];
        for (var i = 0; i < kSanctuarySequence.length - 1; i++) {
          final aCode = kSanctuarySequence[i];
          final bCode = kSanctuarySequence[i + 1];
          final a = centres[aCode];
          final b = centres[bCode];
          if (a == null || b == null) continue;
          if (_isVisible(aCode) && _isVisible(bCode)) {
            pathSegments.add((a, b));
          }
          if (exploration.contains(aCode)) {
            clearedSegments.add((a, b));
          }
        }

        final revealedNodeCentres = <Offset>[
          for (final code in kSanctuarySequence)
            if (_isVisible(code) && centres[code] != null) centres[code]!,
        ];

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AssetPaths.mysticSanctuaryMap,
                fit: BoxFit.fill,
              ),
            ),
            // Dotted path between revealed nodes only — segments to nodes
            // the kid hasn't discovered stay invisible until they arrive.
            Positioned.fill(
              child: CustomPaint(
                painter: MapDottedPathPainter(
                  segments: pathSegments,
                  nodeDiameter: nodeDiameter,
                ),
              ),
            ),
            // Pass 1 — node discs *below* the fog. Clouds drift over
            // un-revealed nodes naturally; revealed discs still get a
            // halo punched by the fog painter so they stay visible.
            for (final code in kSanctuarySequence)
              if (_isVisible(code) && centres[code] != null)
                _buildNode(
                  context,
                  code: code,
                  centre: centres[code]!,
                  nodeDiameter: nodeDiameter,
                  renderMode: MapNodeRenderMode.nodeOnly,
                ),
            // Fog layer between the node discs and the banner labels.
            MapFogLayer(
              size: Size(w, h),
              revealedNodes: revealedNodeCentres,
              revealedSegments: clearedSegments,
              nodeDiameter: nodeDiameter,
              cloudWidth: shortest * 0.18,
              cloudHeight: shortest * 0.18 * (559 / 830),
            ),
            // Decor above the fog so nothing she places can disappear into a
            // cloud, and below the banner pass so it can never swallow the
            // tap target that starts a lesson. See sanctuary_decor_layer.dart.
            SanctuaryDecorLayer(
              placements: placements,
              size: Size(w, h),
              editing: decorating,
              onMoved: onDecorMoved,
              onTapped: onDecorTapped,
            ),
            // Pass 2 — parchment banners *above* the fog so a cloud
            // can never park on top of a label and hide the lesson
            // name. Tap targets remain consistent because the banner
            // half is the tappable one in both passes.
            for (final code in kSanctuarySequence)
              if (_isVisible(code) && centres[code] != null)
                _buildNode(
                  context,
                  code: code,
                  centre: centres[code]!,
                  nodeDiameter: nodeDiameter,
                  renderMode: MapNodeRenderMode.bannerOnly,
                ),
            // Reward overlay sits above everything else so the advancement
            // animation can take over the whole map area when it plays.
            // See specs/shared/reward-tracks.md.
            Positioned.fill(
              child: RewardOverlay(track: kMysteryEggTrack),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNode(
    BuildContext context, {
    required int code,
    required Offset centre,
    required double nodeDiameter,
    MapNodeRenderMode renderMode = MapNodeRenderMode.both,
  }) {
    final sequenceIdx = kSanctuarySequence.indexOf(code);
    // The banner pass keeps the canonical `node-<id>` key because the
    // banner is the primary tap target (wrapped in ReadAloudGate, used
    // by tests + external integration). The node-disc pass gets a
    // suffix so Flutter doesn't reparent the same widget across the
    // fog layer.
    final isBannerPass = renderMode != MapNodeRenderMode.nodeOnly;
    if (code == kSanctuarySequence.first) {
      return MapNodeWithBanner(
        key: ValueKey(
          isBannerPass ? 'node-cutscene' : 'node-cutscene-disc',
        ),
        center: centre,
        nodeDiameter: nodeDiameter,
        label: kSanctuaryCutsceneLabel,
        // Renders a play arrow inside the yellow node instead of a number,
        // signalling "watch me" rather than "math here." Future cutscene
        // anchors (mid-region story beats, region-finale celebrations) use
        // the same flag.
        isCutscene: true,
        bannerSide: _bannerSideByCode[code] ?? BannerSide.below,
        renderMode: renderMode,
        onTap: onCutsceneTap,
      );
    }
    final activityId = kSanctuaryActivityByCode[code];
    if (activityId == null) return const SizedBox.shrink();
    final activity = activityRegistry.valueOrNull?.byIdOrNull(activityId);
    // Four of the eleven nodes are not in the registry at all, and the map
    // used to put the raw id on their parchment.
    final label = activity?.displayName ?? placeholderActivityName(activityId);
    // Registered is not the same as playable: three more are in the registry
    // with no runner behind them, and routing to one of those lands a
    // pre-reader on a sentence in English on a blank screen.
    final awake = activity != null &&
        conceptRegistry.valueOrNull != null &&
        isActivityPlayable(activityId);
    return MapNodeWithBanner(
      key: ValueKey(
        isBannerPass ? 'node-$activityId' : 'node-$activityId-disc',
      ),
      center: centre,
      nodeDiameter: nodeDiameter,
      label: label,
      // A sleeping node carries a moon rather than its place in the order.
      // The number is a promise that there is something to do there.
      numberInside: awake ? sequenceIdx : null, // F1 → idx 1, F2 → idx 2, ...
      asleep: !awake,
      bannerSide: _bannerSideByCode[code] ?? BannerSide.right,
      renderMode: renderMode,
      onTap: awake
          ? () => onLessonTap(activity)
          : () => onAsleepTap(kAsleepPlaceLine),
    );
  }
}
