// SettingsScreen — parent / older-kid controls for the global app behaviour.
// Lives at `/settings`, reachable from the home map's AppBar gear icon.
//
// Keep this screen flat and obvious: kids may stumble in and we don't want
// them flipping settings they don't understand. Every toggle has a one-line
// subtitle explaining who the setting is for. New settings should follow
// the same structure.
//
// The "Developer tools" section at the bottom is for the project owner's
// testing workflow. It currently holds the "Jump to lesson" picker —
// fast-forwards save state so a later lesson can be opened without
// playing through every preceding Sanctuary node.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dev_advance.dart';
import '../../providers/read_aloud_settings_provider.dart';
import '../../providers/save_provider.dart';
import '../../providers/tts_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readAloud = ref.watch(readAloudGateEnabledProvider);
    final tts = ref.watch(ttsEnabledProvider);

    void persist() => ref.read(saveCoordinatorProvider).persist();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to the island',
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            SwitchListTile(
              title: const Text('Read text aloud when tapped'),
              subtitle: const Text(
                'For younger kids who can\'t read button labels yet — '
                'first tap reads, second tap acts.',
              ),
              value: readAloud,
              onChanged: (v) {
                ref.read(readAloudGateEnabledProvider.notifier).set(v);
                persist();
              },
            ),
            SwitchListTile(
              title: const Text('Narration voice'),
              subtitle: const Text(
                'Speak keeper dialogue and counting prompts aloud through '
                'the device voice.',
              ),
              value: tts,
              onChanged: (v) {
                ref.read(ttsEnabledProvider.notifier).set(v);
                persist();
              },
            ),
            const Divider(height: 32),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Developer tools',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fast_forward),
              title: const Text('Jump to a lesson'),
              subtitle: const Text(
                'Fast-forward save state so every lesson before the one you '
                'pick is treated as completed. Grants the matching coins + '
                'reward stage. Useful for testing later lessons without '
                'playing through the whole sequence.',
              ),
              onTap: () => _openJumpPicker(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Launch a specific lesson'),
              subtitle: const Text(
                'Skip the Sanctuary map and open one lesson directly. Useful '
                'for testing lessons that aren\'t yet reachable through the '
                'normal scaffold (K.G.3 / K.G.4 etc. — the shape-garden node '
                'only routes to K.G.2 today).',
              ),
              onTap: () => _openLessonLauncher(context),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset all lesson progress'),
              subtitle: const Text(
                'Clears exploration, reward stage, and coin balance back to '
                'a fresh boot. Other settings (TTS, read-aloud) are kept.',
              ),
              onTap: () => _confirmReset(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Inventory of available lesson ids — what shows up in the launcher
  /// picker. Mirrors the files in `assets/data/lesson-runtime/`. Kept as
  /// a hard-coded list (rather than scanning the bundle) so the picker
  /// doesn't need to wait on async asset enumeration.
  static const List<({String id, String label})> _kLessonLauncherEntries =
      <({String id, String label})>[
    (id: 'lesson-k-cc-4a-one-to-one', label: 'K.CC.4a — Counting Parade (one-to-one)'),
    (id: 'lesson-k-g-2-shape-recognition', label: 'K.G.2 — Shape Garden (find the shape)'),
    (id: 'lesson-k-g-3-flat-or-solid', label: 'K.G.3 — Shape Garden (flat or solid)'),
  ];

  Future<void> _openLessonLauncher(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Launch which lesson?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Opens the lesson directly. Save state and prior progress '
                  'are untouched.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const Divider(height: 1),
              for (final entry in _kLessonLauncherEntries)
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(entry.label),
                  subtitle: Text(
                    entry.id,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(sheetCtx).pop(entry.id),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (!context.mounted) return;
    context.go('/lesson/$picked');
  }

  Future<void> _openJumpPicker(BuildContext context, WidgetRef ref) async {
    final options = devAdvanceOptions();
    final picked = await showModalBottomSheet<DevAdvanceOption>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Jump to which Sanctuary lesson?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Everything before the chosen lesson is marked completed. '
                  "The chosen lesson itself is left untouched so you'll see "
                  'it cold the first time you tap its map node.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const Divider(height: 1),
              for (final opt in options)
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.amber.shade100,
                    child: Text(
                      '${opt.sequenceIndex}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  title: Text(opt.displayName),
                  subtitle: Text(
                    'Activity: ${opt.activityId}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(sheetCtx).pop(opt),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    if (!context.mounted) return;
    final result = await applyDevAdvance(ref, picked);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Jumped to ${picked.displayName} '
          '(${result.precedingActivitiesCompleted} activities completed, '
          '+${result.coinsGranted} coins).',
        ),
      ),
    );
    context.go('/sanctuary');
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Reset all lesson progress?'),
          content: const Text(
            'This wipes exploration, reward stage, and coins back to a '
            'fresh boot. TTS / read-aloud preferences are kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await resetDevAdvance(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson progress reset.')),
    );
  }
}
