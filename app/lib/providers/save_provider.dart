// SaveCoordinator — persists the kid's progress + wallet to disk and
// rehydrates them at boot. Backed by shared_preferences (cross-platform:
// localStorage on web, native prefs on iOS/Android). Sprint 1 implements the
// minimum needed for the vertical slice; multi-kid storage and the full save
// schema arrive in later sprints.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engines/mastery/concept_state.dart';
import 'exploration_provider.dart';
import 'progress_provider.dart';
import 'read_aloud_settings_provider.dart';
import 'reward_progress_provider.dart';
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
    final subModesJson =
        json['subModes'] as Map<String, dynamic>? ?? const {};
    final subModes = <String, Set<String>>{};
    subModesJson.forEach((activityId, value) {
      subModes[activityId] = ((value as List<dynamic>?) ?? const [])
          .map((e) => e as String)
          .toSet();
    });
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
    );
  }

  final Map<String, ConceptState> progress;
  final int coins;
  final bool ttsEnabled;
  final Set<int> exploration;
  final bool readAloudGateEnabled;
  final Map<String, RewardTrackState> rewards;
  final Map<String, Set<String>> subModes;

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
    };
  }
}

Map<String, dynamic> _rewardStateToJson(RewardTrackState s) => {
      'completed': s.completedActivities.toList()..sort(),
      'lastSeenStage': s.lastSeenStage,
      'graduated': s.graduated,
    };

RewardTrackState _rewardStateFromJson(Map<String, dynamic> json) =>
    RewardTrackState(
      completedActivities: ((json['completed'] as List<dynamic>?) ?? const [])
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
      currentLayer: CpaLayer.values
          .byName(json['currentLayer'] as String? ?? 'concrete'),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
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
      final blob = _SaveBlob(
        progress: progress,
        coins: coins,
        ttsEnabled: ttsEnabled,
        exploration: exploration,
        readAloudGateEnabled: readAloudGateEnabled,
        rewards: rewards,
        subModes: subModes,
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

final saveCoordinatorProvider =
    Provider<SaveCoordinator>(SaveCoordinator.new);
