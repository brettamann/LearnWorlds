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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/activity_registry.dart';
import '../../data/asset_paths.dart';
import '../../data/concept_registry.dart';
import '../../data/sanctuary_sequence.dart';
import '../../engines/scaffolding/scaffold_decision.dart';
import '../../engines/scaffolding/scaffold_engine.dart';
import '../../models/activity.dart';
import '../../models/reward_track.dart';
import '../../providers/app_providers.dart';
import '../../providers/exploration_provider.dart';
import '../../providers/map_anchors_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/sub_mode_progress_provider.dart';
import '../widgets/map_dotted_path_painter.dart';
import '../widgets/map_fog_layer.dart';
import '../widgets/map_node_with_banner.dart';
import '../widgets/reward_overlay.dart' show RewardOverlay;
import '../widgets/sub_mode_picker_sheet.dart';

/// Per-node banner side. Chosen by hand to avoid overlaps with the dotted
/// path on the current Sanctuary map; flip a side here if a new arrangement
/// causes a banner to collide with a node, line, or another banner.
const Map<int, BannerSide> _bannerSideByCode = {
  0xF0: BannerSide.below,
  0xF1: BannerSide.right,
  0xF2: BannerSide.right,
  0xF3: BannerSide.right,
  0xF4: BannerSide.below,
  0xF5: BannerSide.left,
  0xF6: BannerSide.left,
  0xF7: BannerSide.left,
  0xF8: BannerSide.below,
  0xF9: BannerSide.right,
  0xFA: BannerSide.left,
  0xFB: BannerSide.right,
};

class SanctuaryMapScreen extends ConsumerWidget {
  const SanctuaryMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchors = ref.watch(sanctuaryAnchorsProvider);
    final activityRegistry = ref.watch(activityRegistryProvider);
    final conceptRegistry = ref.watch(conceptRegistryProvider);
    final exploration = ref.watch(explorationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mystic Sanctuary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to the island',
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: anchors.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Map load failed: $e')),
              data: (data) => _MapStack(
                anchors: data.anchors,
                exploration: exploration,
                activityRegistry: activityRegistry,
                conceptRegistry: conceptRegistry,
                onCutsceneTap: () => context.go('/sanctuary/cutscene'),
                onLessonTap: (activity) => _onLessonTap(context, ref, activity),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLessonTap(
    BuildContext context,
    WidgetRef ref,
    Activity activity,
  ) async {
    final concepts = ref.read(conceptRegistryProvider).valueOrNull;
    if (concepts == null) {
      context.go('/activity/${activity.id}');
      return;
    }

    // Build the picker entry set: every non-challenge sub-mode in registry
    // order. `next` is the first that hasn't been completed yet — there
    // can be at most one `next` per visit. Sub-modes after `next` are
    // hidden so the kid can't skip ahead.
    final completed =
        ref.read(subModeProgressProvider.notifier).completedFor(activity.id);
    final regular =
        activity.subModes.where((m) => !m.isChallenge).toList(growable: false);
    final entries = <SubModePickerEntry>[];
    var nextAssigned = false;
    for (final subMode in regular) {
      final isCompleted = completed.contains(subMode.id);
      final isNext = !isCompleted && !nextAssigned;
      if (!isCompleted && !isNext) break; // later un-completed → not yet offered
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
    final allRegularDone =
        regular.every((m) => completed.contains(m.id));
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
      context.go('/activity/${activity.id}');
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
      chosenSubMode = entries
          .firstWhere((e) => e.subMode.id == pickedId)
          .subMode;
    }

    _routeForSubMode(
      context,
      ref,
      activity: activity,
      subMode: chosenSubMode,
    );
  }

  /// Dispatches the chosen sub-mode through ScaffoldEngine — first-time
  /// taps land on the lesson, subsequent taps proceed straight to the
  /// activity round with the right `subMode` in `launchExtra`.
  void _routeForSubMode(
    BuildContext context,
    WidgetRef ref, {
    required Activity activity,
    required SubMode subMode,
  }) {
    // Two cases never play the introducing-concept lesson:
    //   - `isChallenge` — optional final check after every regular
    //     sub-mode is done; the runner has its own brief demo.
    //   - `ownsIntro` — the sub-mode's runner plays its own animated
    //     lesson at intro time (e.g. count-on-by-ones decade demo), so
    //     letting ScaffoldEngine fire the concept's lesson on top would
    //     stack the wrong demo in front of it.
    if (subMode.isChallenge || subMode.ownsIntro) {
      context.go(
        '/activity/${activity.id}',
        extra: <String, dynamic>{'subMode': subMode.id},
      );
      return;
    }
    final concepts = ref.read(conceptRegistryProvider).valueOrNull;
    if (concepts == null) {
      context.go(
        '/activity/${activity.id}',
        extra: <String, dynamic>{'subMode': subMode.id},
      );
      return;
    }
    const engine = ScaffoldEngine();
    final entryConceptId = subMode.primaryConcepts.isNotEmpty
        ? subMode.primaryConcepts.first
        : activity.concepts.first.conceptId;
    final concept = concepts.byId(entryConceptId);
    final state =
        ref.read(kidProgressProvider.notifier).getOrCreate(concept.id);
    final decision = engine.decide(
      activity: activity,
      concept: concept,
      state: state,
    );
    switch (decision) {
      case PlayLesson(:final lessonId):
        // Pass the picked sub-mode through so the lesson hands off into
        // the activity at that sub-mode rather than the lesson's own
        // youDo.subMode (which can differ — e.g. the K.CC.1 lesson is
        // shared across long-parade and count-on-by-ones in the chain).
        context.go(
          '/lesson/$lessonId',
          extra: <String, dynamic>{'subMode': subMode.id},
        );
      case ProceedAtLayer():
        context.go(
          '/activity/${activity.id}',
          extra: <String, dynamic>{'subMode': subMode.id},
        );
    }
  }
}

class _MapStack extends StatelessWidget {
  const _MapStack({
    required this.anchors,
    required this.exploration,
    required this.activityRegistry,
    required this.conceptRegistry,
    required this.onCutsceneTap,
    required this.onLessonTap,
  });

  final Map<int, Offset> anchors;
  final Set<int> exploration;
  final AsyncValue<ActivityRegistry> activityRegistry;
  final AsyncValue<ConceptRegistry> conceptRegistry;
  final VoidCallback onCutsceneTap;
  final ValueChanged<Activity> onLessonTap;

  /// A node is visible when it's been explored, or when it's the next node
  /// after the last explored one — so the kid can see what's next to go to.
  bool _isVisible(int code) {
    if (exploration.contains(code)) return true;
    if (code == kSanctuarySequence.first) return true;
    final idx = kSanctuarySequence.indexOf(code);
    if (idx <= 0) return false;
    return exploration.contains(kSanctuarySequence[idx - 1]);
  }

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
            // Nodes + banners — only those that are visible.
            for (final code in kSanctuarySequence)
              if (_isVisible(code) && centres[code] != null)
                _buildNode(
                  context,
                  code: code,
                  centre: centres[code]!,
                  nodeDiameter: nodeDiameter,
                ),
            // Fog layer on top of nodes/path; punches holes around revealed
            // nodes + segments.
            MapFogLayer(
              size: Size(w, h),
              revealedNodes: revealedNodeCentres,
              revealedSegments: clearedSegments,
              nodeDiameter: nodeDiameter,
              cloudWidth: shortest * 0.18,
              cloudHeight: shortest * 0.18 * (559 / 830),
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
  }) {
    final sequenceIdx = kSanctuarySequence.indexOf(code);
    if (code == kSanctuarySequence.first) {
      return MapNodeWithBanner(
        key: const ValueKey('node-cutscene'),
        center: centre,
        nodeDiameter: nodeDiameter,
        label: 'Welcome',
        // Renders a play arrow inside the yellow node instead of a number,
        // signalling "watch me" rather than "math here." Future cutscene
        // anchors (mid-region story beats, region-finale celebrations) use
        // the same flag.
        isCutscene: true,
        bannerSide: _bannerSideByCode[code] ?? BannerSide.below,
        onTap: onCutsceneTap,
      );
    }
    final activityId = kSanctuaryActivityByCode[code];
    if (activityId == null) return const SizedBox.shrink();
    final activity = activityRegistry.valueOrNull?.byIdOrNull(activityId);
    final label = activity?.displayName ?? activityId;
    final hasContent =
        activity != null && conceptRegistry.valueOrNull != null;
    return MapNodeWithBanner(
      key: ValueKey('node-$activityId'),
      center: centre,
      nodeDiameter: nodeDiameter,
      label: label,
      numberInside: sequenceIdx, // F1 → idx 1, F2 → idx 2, ...
      bannerSide: _bannerSideByCode[code] ?? BannerSide.right,
      onTap: hasContent ? () => onLessonTap(activity) : () {},
    );
  }
}
