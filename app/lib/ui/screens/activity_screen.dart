// ActivityScreen — hosts an ActivityRunner for the requested activity.
// Sprint 1 only knows Counting Parade; other activities fall back to the
// "coming soon" placeholder. M8 wires round resolution through the
// MasteryEngine + reward engine.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/counting_parade_runner.dart';
import '../widgets/next_arrow_button.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({
    super.key,
    required this.activityId,
    this.launchExtra,
  });

  final String activityId;

  /// Optional payload from the LessonScreen handoff: subMode + round params.
  /// Null when the kid taps the activity tile directly (no lesson needed).
  final Map<String, dynamic>? launchExtra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(activityRegistryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          registry.maybeWhen(
            data: (r) => r.byId(activityId).displayName,
            orElse: () => activityId,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to the Sanctuary',
          onPressed: () => context.go('/sanctuary'),
        ),
      ),
      body: Stack(
        children: [
          registry.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (data) {
              if (activityId == 'counting-parade') {
                return CountingParadeRunner(
                  // The lesson screen already played the keeper intro before
                  // the iShow; don't replay it on the round.
                  skipIntro: launchExtra?['fromLesson'] != null,
                  onSequenceComplete: () =>
                      _showRoundCompleteSheet(context, true),
                );
              }
              return Center(
                child: Text('Activity "$activityId" lands in a later sprint.'),
              );
            },
          ),
          const CaptionOverlay(),
        ],
      ),
    );
  }

  void _showRoundCompleteSheet(BuildContext context, bool success) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.celebration : Icons.refresh,
                size: 72,
                color: success ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'Nicely counted!' : 'Try again.',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              NextArrowButton(
                key: const ValueKey('round-complete-next'),
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  GoRouter.of(sheetCtx).go('/sanctuary');
                },
                label: 'Sanctuary',
              ),
            ],
          ),
        );
      },
    );
  }
}
