// SaveCoordinator — persists the kid's progress + wallet to disk and
// rehydrates them at boot. Backed by shared_preferences (cross-platform:
// localStorage on web, native prefs on iOS/Android). Sprint 1 implements the
// minimum needed for the vertical slice; multi-kid storage and the full save
// schema arrive in later sprints.

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

class _SaveBlob {
  const _SaveBlob({
    required this.progress,
    required this.coins,
    required this.ttsEnabled,
    required this.exploration,
    required this.readAloudGateEnabled,
    required this.rewards,
    required this.subModes,
    required this.buddy,
    required this.owned,
    required this.cards,
    required this.decorOwned,
    required this.decorPlacements,
    required this.sfxEnabled,
    required this.musicEnabled,
    required this.sfxVolume,
    required this.musicVolume,
  });

  factory _SaveBlob.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'] as Map<String, dynamic>? ?? const {};
    final progress = <String, ConceptState>{};
    progressJson.forEach((key, value) {
      progress[key] = _conceptStateFromJson(value as Map<String, dynamic>);
    });
    final rewardsJson = json['rewards'] as Map<String, dynamic>? ?? const {};
    final rewards = <String, RewardTrackState>{};
    rewardsJson.forEach((key, value) {
      rewards[key] = _rewardStateFromJson(value as Map<String, dynamic>);
    });
    final subModesJson = json['subModes'] as Map<String, dynamic>? ?? const {};
    final subModes = <String, Set<String>>{};
    subModesJson.forEach((activityId, value) {
      subModes[activityId] = ((value as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet();
    });
    final buddyJson = json['buddy'] as Map<String, dynamic>?;
    final buddy = buddyJson != null
        ? BuddyAppearance.fromJson(buddyJson)
        : BuddyAppearance.defaults();
    return _SaveBlob(
      progress: progress,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      ttsEnabled: json['ttsEnabled'] as bool? ?? true,
      exploration: ((json['exploration'] as List<dynamic>?) ?? const [])
          .map((e) => (e as num).toInt())
          .toSet(),
      readAloudGateEnabled: json['readAloudGateEnabled'] as bool? ?? true,
      rewards: rewards,
      subModes: subModes,
      buddy: buddy,
      // Absent before the Buddy shop existed. An empty set is correct: the
      // wardrobe folds in whatever the saved Buddy is already wearing, so a
      // kid who picked a now-priced part keeps it.
      owned: ((json['owned'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      // Absent before creature cards were implemented. An empty collection is
      // the honest migration — nobody could have found one.
      cards: ((json['cards'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      // Absent before the sanctuary could be decorated. Empty is correct in
      // both cases: nothing was bought, and nothing was placed.
      decorOwned: ((json['decorOwned'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      // Malformed rows are dropped, not thrown on. A save is the one file that
      // must never fail to load, and losing the whole sanctuary over one bad
      // decoration row would be far worse than losing one mushroom.
      decorPlacements: <DecorPlacement>[
        for (final raw
            in (json['decorPlacements'] as List<dynamic>?) ?? const [])
          if (DecorPlacement.fromJson(raw) case final p?) p,
      ],
      // Saves written before the audio layer existed have none of these keys.
      // Default to ON so an upgrading player gets sound without visiting
      // settings — silence is the bug we're fixing.
      sfxEnabled: json['sfxEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? kDefaultSfxVolume,
      musicVolume:
          _hydrateMusicVolume((json['musicVolume'] as num?)?.toDouble()),
    );
  }

  /// Music levels that were once the shipped default.
  ///
  /// Every save carries a musicVolume whether or not anyone ever touched the
  /// slider, because the whole settings block is persisted on the first round
  /// that resolves. So a stored value identical to an old default is almost
  /// certainly nobody's choice — it is the old default, written down. Retuning
  /// the bed would otherwise reach only players who have never played.
  ///
  /// A value that is not on this list is treated as deliberate and left alone,
  /// which is why the list is exact rather than a range.
  static const List<double> kSupersededMusicVolumes = <double>[0.35];

  static double _hydrateMusicVolume(double? stored) {
    if (stored == null) return kDefaultMusicVolume;
    for (final superseded in kSupersededMusicVolumes) {
      if ((stored - superseded).abs() < 0.0005) return kDefaultMusicVolume;
    }
    return stored;
  }

  final Map<String, ConceptState> progress;
  final int coins;
  final bool ttsEnabled;
  final Set<int> exploration;
  final bool readAloudGateEnabled;
  final Map<String, RewardTrackState> rewards;
  final Map<String, Set<String>> subModes;
  final BuddyAppearance buddy;
  final Set<String> owned;
  final Set<String> cards;
  final Set<String> decorOwned;
  final List<DecorPlacement> decorPlacements;
  final bool sfxEnabled;
  final bool musicEnabled;
  final double sfxVolume;
  final double musicVolume;

  Map<String, dynamic> toJson() {
    final progressJson = <String, dynamic>{};
    progress.forEach((key, value) {
      progressJson[key] = _conceptStateToJson(value);
    });
    final rewardsJson = <String, dynamic>{};
    rewards.forEach((key, value) {
      rewardsJson[key] = _rewardStateToJson(value);
    });
    final subModesJson = <String, dynamic>{};
    subModes.forEach((activityId, ids) {
      subModesJson[activityId] = ids.toList()..sort();
    });
    return {
      'progress': progressJson,
      'coins': coins,
      'ttsEnabled': ttsEnabled,
      'exploration': exploration.toList()..sort(),
      'readAloudGateEnabled': readAloudGateEnabled,
      'rewards': rewardsJson,
      'subModes': subModesJson,
      'buddy': buddy.toJson(),
      'owned': owned.toList()..sort(),
      'cards': cards.toList()..sort(),
      'decorOwned': decorOwned.toList()..sort(),
      'decorPlacements': [for (final p in decorPlacements) p.toJson()],
      'sfxEnabled': sfxEnabled,
      'musicEnabled': musicEnabled,
      'sfxVolume': sfxVolume,
      'musicVolume': musicVolume,
    };
  }
}

Map<String, dynamic> _rewardStateToJson(RewardTrackState s) => {
      'completed': s.completedActivities.toList()..sort(),
      'events': s.completionEvents.toList()..sort(),
      'lastSeenStage': s.lastSeenStage,
      'graduated': s.graduated,
    };

RewardTrackState _rewardStateFromJson(Map<String, dynamic> json) =>
    RewardTrackState(
      completedActivities: ((json['completed'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      // Absent in saves written before per-sub-mode advancement existed. An
      // empty set just means the stageGrants floor decides the stage, which
      // is exactly what those saves already did.
      completionEvents: ((json['events'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
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
      status: MasteryStatus.values
          .byName(json['status'] as String? ?? 'notStarted'),
      currentLayer:
          CpaLayer.values.byName(json['currentLayer'] as String? ?? 'concrete'),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      // Absent in saves written before demotion existed; 0 is the correct
      // migration value (nobody was mid-struggle under the old engine).
      consecutiveFailures: (json['consecutiveFailures'] as num?)?.toInt() ?? 0,
      abstractSuccessCount:
          (json['abstractSuccessCount'] as num?)?.toInt() ?? 0,
      sessionIds: ((json['sessionIds'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      daysTouched: ((json['daysTouched'] as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet(),
      firstTouchedAt: json['firstTouchedAt'] != null
          ? DateTime.parse(json['firstTouchedAt'] as String)
          : null,
      lastTouchedAt: json['lastTouchedAt'] != null
          ? DateTime.parse(json['lastTouchedAt'] as String)
          : null,
    );

class SaveCoordinator {
  SaveCoordinator(this._ref);

  final Ref _ref;
  Completer<void>? _inflight;

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return;
    try {
      final blob = _SaveBlob.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _ref.read(kidProgressProvider.notifier).replaceAll(blob.progress);
      _ref.read(walletProvider.notifier).set(blob.coins);
      _ref.read(ttsEnabledProvider.notifier).set(blob.ttsEnabled);
      _ref.read(explorationProvider.notifier).replaceAll(blob.exploration);
      _ref
          .read(readAloudGateEnabledProvider.notifier)
          .set(blob.readAloudGateEnabled);
      _ref.read(rewardProgressProvider.notifier).replaceAll(blob.rewards);
      _ref.read(subModeProgressProvider.notifier).replaceAll(blob.subModes);
      _ref.read(buddyAppearanceProvider.notifier).hydrate(blob.buddy);
      _ref
          .read(buddyWardrobeProvider.notifier)
          .hydrate(blob.owned, appearance: blob.buddy);
      _ref.read(cardCollectionProvider.notifier).hydrate(blob.cards);
      _ref.read(decorOwnershipProvider.notifier).hydrate(blob.decorOwned);
      _ref.read(sanctuaryDecorProvider.notifier).hydrate(blob.decorPlacements);
      _ref.read(sfxEnabledProvider.notifier).set(blob.sfxEnabled);
      _ref.read(musicEnabledProvider.notifier).set(blob.musicEnabled);
      _ref.read(sfxVolumeProvider.notifier).set(blob.sfxVolume);
      _ref.read(musicVolumeProvider.notifier).set(blob.musicVolume);
    } catch (_) {
      // Corrupt save: start fresh rather than crash the kid's session.
    }
  }

  Future<void> persist() async {
    // Coalesce overlapping calls: if one save is in flight, return the same
    // future. Stops round resolution + boot hydration from racing.
    final inflight = _inflight;
    if (inflight != null) return inflight.future;
    final completer = Completer<void>();
    _inflight = completer;
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = _ref.read(kidProgressProvider);
      final coins = _ref.read(walletProvider);
      final ttsEnabled = _ref.read(ttsEnabledProvider);
      final exploration = _ref.read(explorationProvider);
      final readAloudGateEnabled = _ref.read(readAloudGateEnabledProvider);
      final rewards = _ref.read(rewardProgressProvider);
      final subModes = _ref.read(subModeProgressProvider);
      final buddy = _ref.read(buddyAppearanceProvider);
      final blob = _SaveBlob(
        progress: progress,
        coins: coins,
        ttsEnabled: ttsEnabled,
        exploration: exploration,
        readAloudGateEnabled: readAloudGateEnabled,
        rewards: rewards,
        subModes: subModes,
        buddy: buddy,
        owned: _ref.read(buddyWardrobeProvider),
        cards: _ref.read(cardCollectionProvider),
        decorOwned: _ref.read(decorOwnershipProvider),
        decorPlacements: _ref.read(sanctuaryDecorProvider),
        sfxEnabled: _ref.read(sfxEnabledProvider),
        musicEnabled: _ref.read(musicEnabledProvider),
        sfxVolume: _ref.read(sfxVolumeProvider),
        musicVolume: _ref.read(musicVolumeProvider),
      );
      await prefs.setString(_saveKey, jsonEncode(blob.toJson()));
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      _inflight = null;
    }
    return completer.future;
  }
}

final saveCoordinatorProvider = Provider<SaveCoordinator>(SaveCoordinator.new);
