// SaveCoordinator — persists the kid's progress, wallet and settings to disk
// and rehydrates them at boot. Backed by shared_preferences (localStorage on
// web, native prefs on iOS/Android).
//
// What is saved is the list [kSaveSlots]: one entry per field, naming its
// JSON key, the provider it watches, how to write it and how to read it back
// (including what an older save that predates the field means). Adding a
// saved field is one entry there. It used to be six edits to a hand-written
// blob class, and a screen that forgot to call persist() after changing
// something lost it.
//
// Saving is automatic once [startAutosave] has run (main.dart does, after
// hydrating): any change to a slot's provider schedules a write
// [kAutosaveDelay] later, so a burst of changes - a volume slider dragged for
// a second, a round paying coins and a card together - is one write. [persist]
// writes now and is still there for the few callers that must wait for disk.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sfx_catalog.dart';
import '../engines/mastery/concept_state.dart';
import '../models/buddy_appearance.dart';
import '../models/decor_placement.dart';
import 'audio_settings_provider.dart';
import 'buddy_appearance_provider.dart';
import 'buddy_wardrobe_provider.dart';
import 'collection_provider.dart';
import 'exploration_provider.dart';
import 'progress_provider.dart';
import 'read_aloud_settings_provider.dart';
import 'reward_progress_provider.dart';
import 'sanctuary_decor_provider.dart';
import 'sub_mode_progress_provider.dart';
import 'tts_settings_provider.dart';
import 'wallet_provider.dart';

const _saveKey = 'critmath.save.v1';

/// How long autosave waits after a change for more changes to arrive.
const Duration kAutosaveDelay = Duration(milliseconds: 250);

/// One saved field.
class SaveSlot {
  const SaveSlot({
    required this.key,
    required this.watch,
    required this.write,
    required this.read,
  });

  /// The field's name in the saved JSON. Never rename one: an old save would
  /// silently lose it.
  final String key;

  /// The provider whose changes should trigger a save.
  final ProviderListenable<Object?> watch;

  /// The field's current value, as JSON.
  final Object? Function(Ref ref) write;

  /// Restores the field from [save], the whole decoded save. The key may be
  /// absent (a save older than the field); each slot says what that means.
  final void Function(Ref ref, Map<String, dynamic> save) read;
}

Set<String> _stringSet(Object? json) =>
    ((json as List<dynamic>?) ?? const []).map((e) => e as String).toSet();

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

BuddyAppearance _buddyFrom(Map<String, dynamic> save) {
  final json = save['buddy'] as Map<String, dynamic>?;
  return json != null
      ? BuddyAppearance.fromJson(json)
      : BuddyAppearance.defaults();
}

/// Every saved field. Order matters only on read: the wardrobe reads after
/// the Buddy it dresses.
final List<SaveSlot> kSaveSlots = <SaveSlot>[
  SaveSlot(
    key: 'progress',
    watch: kidProgressProvider,
    write: (ref) => {
      for (final e in ref.read(kidProgressProvider).entries)
        e.key: _conceptStateToJson(e.value),
    },
    read: (ref, save) {
      final json = save['progress'] as Map<String, dynamic>? ?? const {};
      ref.read(kidProgressProvider.notifier).replaceAll({
        for (final e in json.entries)
          e.key: _conceptStateFromJson(e.value as Map<String, dynamic>),
      });
    },
  ),
  SaveSlot(
    key: 'coins',
    watch: walletProvider,
    write: (ref) => ref.read(walletProvider),
    read: (ref, save) => ref
        .read(walletProvider.notifier)
        .set((save['coins'] as num?)?.toInt() ?? 0),
  ),
  SaveSlot(
    key: 'exploration',
    watch: explorationProvider,
    write: (ref) => ref.read(explorationProvider).toList()..sort(),
    read: (ref, save) => ref
        .read(explorationProvider.notifier)
        .replaceAll(
          ((save['exploration'] as List<dynamic>?) ?? const [])
              .map((e) => (e as num).toInt())
              .toSet(),
        ),
  ),
  SaveSlot(
    key: 'rewards',
    watch: rewardProgressProvider,
    write: (ref) => {
      for (final e in ref.read(rewardProgressProvider).entries)
        e.key: _rewardStateToJson(e.value),
    },
    read: (ref, save) {
      final json = save['rewards'] as Map<String, dynamic>? ?? const {};
      ref.read(rewardProgressProvider.notifier).replaceAll({
        for (final e in json.entries)
          e.key: _rewardStateFromJson(e.value as Map<String, dynamic>),
      });
    },
  ),
  SaveSlot(
    key: 'subModes',
    watch: subModeProgressProvider,
    write: (ref) => {
      for (final e in ref.read(subModeProgressProvider).entries)
        e.key: _sorted(e.value),
    },
    read: (ref, save) {
      final json = save['subModes'] as Map<String, dynamic>? ?? const {};
      ref.read(subModeProgressProvider.notifier).replaceAll({
        for (final e in json.entries) e.key: _stringSet(e.value),
      });
    },
  ),
  SaveSlot(
    key: 'buddy',
    watch: buddyAppearanceProvider,
    write: (ref) => ref.read(buddyAppearanceProvider).toJson(),
    read: (ref, save) =>
        ref.read(buddyAppearanceProvider.notifier).hydrate(_buddyFrom(save)),
  ),
  SaveSlot(
    key: 'owned',
    watch: buddyWardrobeProvider,
    write: (ref) => _sorted(ref.read(buddyWardrobeProvider)),
    // Absent before the Buddy shop existed. An empty set is correct: the
    // wardrobe folds in whatever the saved Buddy is already wearing, so a kid
    // who picked a now-priced part keeps it.
    read: (ref, save) => ref
        .read(buddyWardrobeProvider.notifier)
        .hydrate(_stringSet(save['owned']), appearance: _buddyFrom(save)),
  ),
  SaveSlot(
    key: 'cards',
    watch: cardCollectionProvider,
    write: (ref) => _sorted(ref.read(cardCollectionProvider)),
    // Absent before creature cards were implemented. An empty collection is
    // the honest migration — nobody could have found one.
    read: (ref, save) => ref
        .read(cardCollectionProvider.notifier)
        .hydrate(_stringSet(save['cards'])),
  ),
  SaveSlot(
    key: 'decorOwned',
    watch: decorOwnershipProvider,
    write: (ref) => _sorted(ref.read(decorOwnershipProvider)),
    // Absent before the sanctuary could be decorated: nothing was bought.
    read: (ref, save) => ref
        .read(decorOwnershipProvider.notifier)
        .hydrate(_stringSet(save['decorOwned'])),
  ),
  SaveSlot(
    key: 'decorPlacements',
    watch: sanctuaryDecorProvider,
    write: (ref) => [
      for (final p in ref.read(sanctuaryDecorProvider)) p.toJson(),
    ],
    // Malformed rows are dropped, not thrown on. A save is the one file that
    // must never fail to load, and losing the whole sanctuary over one bad
    // decoration row would be far worse than losing one mushroom.
    read: (ref, save) => ref.read(sanctuaryDecorProvider.notifier).hydrate([
      for (final raw in (save['decorPlacements'] as List<dynamic>?) ?? const [])
        if (DecorPlacement.fromJson(raw) case final p?) p,
    ]),
  ),
  // Settings. Saves written before a setting existed default it ON: sound is
  // the primary feedback channel for a pre-reader, and silence is the bug.
  SaveSlot(
    key: 'ttsEnabled',
    watch: ttsEnabledProvider,
    write: (ref) => ref.read(ttsEnabledProvider),
    read: (ref, save) => ref
        .read(ttsEnabledProvider.notifier)
        .set(save['ttsEnabled'] as bool? ?? true),
  ),
  SaveSlot(
    key: 'readAloudGateEnabled',
    watch: readAloudGateEnabledProvider,
    write: (ref) => ref.read(readAloudGateEnabledProvider),
    read: (ref, save) => ref
        .read(readAloudGateEnabledProvider.notifier)
        .set(save['readAloudGateEnabled'] as bool? ?? true),
  ),
  SaveSlot(
    key: 'sfxEnabled',
    watch: sfxEnabledProvider,
    write: (ref) => ref.read(sfxEnabledProvider),
    read: (ref, save) => ref
        .read(sfxEnabledProvider.notifier)
        .set(save['sfxEnabled'] as bool? ?? true),
  ),
  SaveSlot(
    key: 'musicEnabled',
    watch: musicEnabledProvider,
    write: (ref) => ref.read(musicEnabledProvider),
    read: (ref, save) => ref
        .read(musicEnabledProvider.notifier)
        .set(save['musicEnabled'] as bool? ?? true),
  ),
  SaveSlot(
    key: 'sfxVolume',
    watch: sfxVolumeProvider,
    write: (ref) => ref.read(sfxVolumeProvider),
    read: (ref, save) => ref
        .read(sfxVolumeProvider.notifier)
        .set((save['sfxVolume'] as num?)?.toDouble() ?? kDefaultSfxVolume),
  ),
  SaveSlot(
    key: 'musicVolume',
    watch: musicVolumeProvider,
    write: (ref) => ref.read(musicVolumeProvider),
    read: (ref, save) => ref
        .read(musicVolumeProvider.notifier)
        .set(hydrateMusicVolume((save['musicVolume'] as num?)?.toDouble())),
  ),
];

/// Music levels that were once the shipped default.
///
/// Every save carries a musicVolume whether or not anyone ever touched the
/// slider, because the whole settings block is persisted on the first save.
/// So a stored value identical to an old default is almost certainly nobody's
/// choice — it is the old default, written down. Retuning the bed would
/// otherwise reach only players who have never played.
///
/// A value that is not on this list is treated as deliberate and left alone,
/// which is why the list is exact rather than a range.
const List<double> kSupersededMusicVolumes = <double>[0.35];

double hydrateMusicVolume(double? stored) {
  if (stored == null) return kDefaultMusicVolume;
  for (final superseded in kSupersededMusicVolumes) {
    if ((stored - superseded).abs() < 0.0005) return kDefaultMusicVolume;
  }
  return stored;
}

Map<String, dynamic> _rewardStateToJson(RewardTrackState s) => {
  'completed': _sorted(s.completedActivities),
  'events': _sorted(s.completionEvents),
  'lastSeenStage': s.lastSeenStage,
  'graduated': s.graduated,
};

RewardTrackState _rewardStateFromJson(Map<String, dynamic> json) =>
    RewardTrackState(
      completedActivities: _stringSet(json['completed']),
      // Absent in saves written before per-sub-mode advancement existed. An
      // empty set just means the stageGrants floor decides the stage, which
      // is exactly what those saves already did.
      completionEvents: _stringSet(json['events']),
      lastSeenStage: (json['lastSeenStage'] as num?)?.toInt() ?? 0,
      graduated: json['graduated'] as bool? ?? false,
    );

Map<String, dynamic> _conceptStateToJson(ConceptState s) => {
  'conceptId': s.conceptId,
  'instanceKey': s.instanceKey,
  'status': s.status.name,
  'currentLayer': s.currentLayer.name,
  'currentStreak': s.currentStreak,
  'consecutiveFailures': s.consecutiveFailures,
  'abstractSuccessCount': s.abstractSuccessCount,
  'sessionIds': s.sessionIds.toList(),
  'daysTouched': s.daysTouched.toList(),
  'firstTouchedAt': s.firstTouchedAt?.toIso8601String(),
  'lastTouchedAt': s.lastTouchedAt?.toIso8601String(),
};

ConceptState _conceptStateFromJson(Map<String, dynamic> json) => ConceptState(
  conceptId: json['conceptId'] as String,
  instanceKey: json['instanceKey'] as String?,
  status: MasteryStatus.values.byName(
    json['status'] as String? ?? 'notStarted',
  ),
  currentLayer: CpaLayer.values.byName(
    json['currentLayer'] as String? ?? 'concrete',
  ),
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  // Absent in saves written before demotion existed; 0 is the correct
  // migration value (nobody was mid-struggle under the old engine).
  consecutiveFailures: (json['consecutiveFailures'] as num?)?.toInt() ?? 0,
  abstractSuccessCount: (json['abstractSuccessCount'] as num?)?.toInt() ?? 0,
  sessionIds: _stringSet(json['sessionIds']),
  daysTouched: _stringSet(json['daysTouched']),
  firstTouchedAt: json['firstTouchedAt'] != null
      ? DateTime.parse(json['firstTouchedAt'] as String)
      : null,
  lastTouchedAt: json['lastTouchedAt'] != null
      ? DateTime.parse(json['lastTouchedAt'] as String)
      : null,
);

class SaveCoordinator {
  SaveCoordinator(this._ref, {List<SaveSlot>? slots})
    : _slots = slots ?? kSaveSlots;

  final Ref _ref;
  final List<SaveSlot> _slots;

  Future<void>? _writing;
  bool _writeAgain = false;
  Timer? _pending;
  bool _autosaving = false;

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return;
    final Map<String, dynamic> save;
    try {
      save = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Corrupt save: start fresh rather than crash the kid's session.
      return;
    }
    for (final slot in _slots) {
      // One field at a time, so a bad field costs that field and not the
      // whole save.
      try {
        slot.read(_ref, save);
      } catch (_) {}
    }
  }

  /// From now on, save whenever any slot changes. Called once, after
  /// [hydrate], so restoring the save does not immediately write it back.
  void startAutosave() {
    if (_autosaving) return;
    _autosaving = true;
    _ref.onDispose(() => _pending?.cancel());
    for (final slot in _slots) {
      _ref.listen<Object?>(slot.watch, (_, __) => _scheduleSave());
    }
  }

  void _scheduleSave() {
    _pending?.cancel();
    _pending = Timer(kAutosaveDelay, () => unawaited(persist()));
  }

  /// Writes now; completes when what was current at the call is on disk.
  ///
  /// A call while a write is in flight does not get handed that write: the
  /// in-flight one took its snapshot before this call's change, so another
  /// write follows it, and the future completes after that one.
  Future<void> persist() {
    final writing = _writing;
    if (writing != null) {
      _writeAgain = true;
      return writing;
    }
    // Marked as writing before the write starts, so a persist() that lands
    // while the snapshot is being taken queues behind it rather than
    // starting a second, concurrent write.
    final done = Completer<void>();
    _writing = done.future;
    _writeUntilCurrent().then(done.complete, onError: done.completeError);
    return done.future;
  }

  Future<void> _writeUntilCurrent() async {
    try {
      do {
        _writeAgain = false;
        // Snapshot before awaiting anything, so the write is of this moment.
        final json = <String, Object?>{
          for (final slot in _slots) slot.key: slot.write(_ref),
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_saveKey, jsonEncode(json));
      } while (_writeAgain);
    } finally {
      _writing = null;
    }
  }
}

final saveCoordinatorProvider = Provider<SaveCoordinator>(SaveCoordinator.new);
