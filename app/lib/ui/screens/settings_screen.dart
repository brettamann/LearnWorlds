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
//
// The screen claims the music bed (MusicBedScope) for one concrete reason:
// the music slider below is unusable in silence. Everything else about the
// claim is a bonus — walking in here from a map no longer drops the track.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dev_advance.dart';
import '../../data/sfx_catalog.dart';
import '../../engines/narration/narration_cue_log.dart';
import '../../engines/narration/narration_export.dart';
import '../../platform/narration_audio.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/audio_settings_provider.dart';
import '../../providers/read_aloud_settings_provider.dart';
import '../../providers/save_provider.dart';
import '../../providers/tts_settings_provider.dart';
import '../widgets/music_bed_scope.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readAloud = ref.watch(readAloudGateEnabledProvider);
    final tts = ref.watch(ttsEnabledProvider);
    final musicOn = ref.watch(musicEnabledProvider);
    final sfxOn = ref.watch(sfxEnabledProvider);

    void persist() => ref.read(saveCoordinatorProvider).persist();

    return MusicBedScope(
      child: Scaffold(
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
              // Sound first. Both levels have lived only in Dart constants
              // until now, so the one thing anyone actually opened this screen
              // wanting to change was the one thing it could not do.
              SwitchListTile(
                title: const Text('Music'),
                subtitle: const Text(
                  'The background music bed. Plays under everything and never '
                  'restarts between rounds.',
                ),
                value: musicOn,
                onChanged: (v) {
                  ref.read(musicEnabledProvider.notifier).set(v);
                  persist();
                },
              ),
              if (musicOn)
                _VolumeRow(
                  key: const ValueKey('music-volume'),
                  icon: Icons.music_note,
                  value: ref.watch(musicVolumeProvider),
                  // Live on every frame of the drag: SfxEngine.setMusicVolume
                  // reaches the playing bed, so the level you hear while
                  // dragging is the level you are choosing.
                  onChanged: (v) =>
                      ref.read(musicVolumeProvider.notifier).set(v),
                  // Persisted only on release. A slider fires per frame and
                  // SharedPreferences is a whole-blob write.
                  onSettled: (_) => persist(),
                ),
              SwitchListTile(
                title: const Text('Sound effects'),
                subtitle: const Text(
                  'Taps, the counting notes, coins, and the reward fanfare.',
                ),
                value: sfxOn,
                onChanged: (v) {
                  ref.read(sfxEnabledProvider.notifier).set(v);
                  persist();
                },
              ),
              if (sfxOn)
                _VolumeRow(
                  key: const ValueKey('sfx-volume'),
                  icon: Icons.graphic_eq,
                  value: ref.watch(sfxVolumeProvider),
                  onChanged: (v) => ref.read(sfxVolumeProvider.notifier).set(v),
                  onSettled: (_) {
                    // Effects are one-shots, so unlike the music bed there is
                    // nothing already playing to hear the change in. Play one
                    // on release — on release rather than per frame, or a drag
                    // becomes a machine gun.
                    ref.read(sfxEngineProvider).play(Sfx.coin);
                    persist();
                  },
                ),
              const Divider(height: 32),
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
                leading: const Icon(Icons.mic),
                title: const Text('Copy recording script'),
                subtitle: Text(_scriptSubtitle(ref)),
                onTap: () => _copyRecordingScript(context, ref),
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
      ),
    );
  }

  static String _scriptSubtitle(WidgetRef ref) {
    final clipKeys = ref.watch(narrationAudioProvider).clipKeys;
    final coverage = narrationCoverage(
      observed: ref.watch(narrationCueLogProvider).values,
      clipKeys: clipKeys,
    );

    // Total clips found is the first thing to look at when the game is still
    // speaking in the browser voice: zero here means the bundle was not
    // rebuilt after rendering, and no amount of staring at the script will
    // show that.
    final found = clipKeys.length;

    // Deliberately NOT called orphans any more. This screen only knows the
    // lines narration_script.dart can enumerate - the counting words, the warm
    // lines and Counting Parade. The lesson I-Show/We-Try narration is
    // authored in data/lesson-runtime/*.json and reaches the app through
    // LessonRuntime, so its clips legitimately match nothing here. Calling
    // those "reworded, need re-cutting" sent the owner hunting for a problem
    // that did not exist. tools/tts/kokoro/render.mjs owns orphan detection;
    // it reads the full script and can tell the difference.
    final extra = coverage.orphaned == 0
        ? ''
        : ' ${coverage.orphaned} more cover lesson narration and lines heard '
            'while playing.';

    return 'The full script as JSON for the harness at tools/tts/record/. '
        'Most of it is enumerated from the catalogs, so you can record '
        'without playing first. $found voice clip(s) in this build; '
        '${coverage.recorded} of ${coverage.scripted} enumerated lines '
        'covered.$extra';
  }

  /// Dump the recording script to the clipboard.
  ///
  /// Enumerated lines plus anything heard while playing that the enumerator
  /// does not cover -- see narration_export.dart. Keyed by the words rather
  /// than by cueId, so one take of "Seven." serves every counting activity.
  Future<void> _copyRecordingScript(BuildContext context, WidgetRef ref) async {
    final observed = ref.read(narrationCueLogProvider).values;
    final clipKeys = ref.read(narrationAudioProvider).clipKeys;
    final json = narrationExportJson(observed: observed, clipKeys: clipKeys);
    final coverage = narrationCoverage(observed: observed, clipKeys: clipKeys);
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied the script. ${coverage.remaining} line(s) still to record. '
          'Paste into tools/tts/record/index.html.',
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
    (
      id: 'lesson-k-cc-4a-one-to-one',
      label: 'K.CC.4a — Counting Parade (one-to-one)'
    ),
    (
      id: 'lesson-k-g-2-shape-recognition',
      label: 'K.G.2 — Shape Garden (find the shape)'
    ),
    (
      id: 'lesson-k-g-3-flat-or-solid',
      label: 'K.G.3 — Shape Garden (flat or solid)'
    ),
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

/// One level slider, indented under the switch that owns it so the pairing
/// reads without needing a heading.
///
/// [onChanged] fires on every frame of the drag and [onSettled] once on
/// release. That split is the whole point of this widget: the audible effect
/// has to be immediate, and the disk write must not be — SharedPreferences
/// stores the save as one blob, so a per-frame persist would rewrite the
/// entire save state sixty times a second.
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    super.key,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.onSettled,
  });

  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onSettled;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Icon(icon, size: 20, color: Colors.black54),
          Expanded(
            child: Slider(
              // Twenty steps rather than a continuous value: the difference
              // between 0.33 and 0.34 is inaudible, and a divided slider is
              // far easier to land on a remembered number a second time.
              divisions: 20,
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              onChangeEnd: onSettled,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
