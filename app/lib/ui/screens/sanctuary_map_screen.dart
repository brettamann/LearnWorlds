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
// Edit `_sequence` below if the magenta order in the art changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/activity_registry.dart';
import '../../data/asset_paths.dart';
import '../../data/concept_registry.dart';
import '../../engines/scaffolding/scaffold_decision.dart';
import '../../engines/scaffolding/scaffold_engine.dart';
import '../../models/activity.dart';
import '../../providers/app_providers.dart';
import '../../providers/exploration_provider.dart';
import '../../providers/map_anchors_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/save_provider.dart';
import '../../providers/tts_settings_provider.dart';
import '../widgets/map_dotted_path_painter.dart';
import '../widgets/map_fog_layer.dart';
import '../widgets/map_node_with_banner.dart';

/// Sequence of magenta-anchor codes from start (F0 cutscene) to last
/// lesson. Drives both the dotted-path order and the reveal-the-next-node
/// logic.
const List<int> _sequence = [
  0xF0,
  0xF1,
  0xF2,
  0xF3,
  0xF4,
  0xF5,
  0xF6,
  0xF7,
  0xF8,
  0xF9,
  0xFA,
  0xFB,
];

/// Activity id per non-cutscene code. F0 doesn't have one.
const Map<int, String> _activityByCode = {
  0xF1: 'counting-parade',
  0xF2: 'shape-garden',
  0xF3: 'ten-frame-pond',
  0xF4: 'build-a-habitat',
  0xF5: 'care-pantry',
  0xF6: 'scribes-tower',
  0xF7: 'storytellers-pond',
  0xF8: 'wheres-buddy',
  0xF9: 'caretakers-bench',
  0xFA: 'picnic-baskets',
  0xFB: 'fluency-within-5',
};

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
    final ttsOn = ref.watch(ttsEnabledProvider);

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
            tooltip: ttsOn
                ? 'Narration voice on (tap to silence)'
                : 'Narration voice off (tap to enable)',
            icon: Icon(ttsOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              ref.read(ttsEnabledProvider.notifier).toggle();
              ref.read(saveCoordinatorProvider).persist();
            },
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

  void _onLessonTap(BuildContext context, WidgetRef ref, Activity activity) {
    final concepts = ref.read(conceptRegistryProvider).valueOrNull;
    if (concepts == null) {
      context.go('/activity/${activity.id}');
      return;
    }
    const engine = ScaffoldEngine();
    final defaultMode = activity.defaultSubMode;
    final entryConceptId = defaultMode.primaryConcepts.isNotEmpty
        ? defaultMode.primaryConcepts.first
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
        context.go('/lesson/$lessonId');
      case ProceedAtLayer():
        context.go('/activity/${activity.id}');
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
    if (code == _sequence.first) return true;
    final idx = _sequence.indexOf(code);
    if (idx <= 0) return false;
    return exploration.contains(_sequence[idx - 1]);
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
        for (final code in _sequence) {
          final norm = anchors[code];
          if (norm == null) continue;
          centres[code] = Offset(norm.dx * w, norm.dy * h);
        }

        // Dotted path segments — only the ones whose start node is explored
        // are "revealed" for fog purposes.
        final revealedSegments = <(Offset, Offset)>[];
        for (var i = 0; i < _sequence.length - 1; i++) {
          final a = centres[_sequence[i]];
          final b = centres[_sequence[i + 1]];
          if (a == null || b == null) continue;
          if (exploration.contains(_sequence[i])) {
            revealedSegments.add((a, b));
          }
        }

        final revealedNodeCentres = <Offset>[
          for (final code in _sequence)
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
            // Dotted path across the full sequence. The fog hides the
            // unexplored parts of the line; we draw the whole path so the
            // intended journey is consistent under the clouds.
            Positioned.fill(
              child: CustomPaint(
                painter: MapDottedPathPainter(
                  points: [
                    for (final code in _sequence)
                      if (centres[code] != null) centres[code]!,
                  ],
                  nodeDiameter: nodeDiameter,
                ),
              ),
            ),
            // Nodes + banners — only those that are visible.
            for (final code in _sequence)
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
              revealedSegments: revealedSegments,
              nodeDiameter: nodeDiameter,
              cloudWidth: shortest * 0.18,
              cloudHeight: shortest * 0.18 * (559 / 830),
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
    final sequenceIdx = _sequence.indexOf(code);
    if (code == _sequence.first) {
      return MapNodeWithBanner(
        key: const ValueKey('node-cutscene'),
        center: centre,
        nodeDiameter: nodeDiameter,
        label: 'Welcome',
        bannerSide: _bannerSideByCode[code] ?? BannerSide.below,
        onTap: onCutsceneTap,
      );
    }
    final activityId = _activityByCode[code];
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
