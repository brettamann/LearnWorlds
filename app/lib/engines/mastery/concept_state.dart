// ConceptState — per-(kid, concept[, instanceKey]) record the MasteryEngine
// reads and writes. Persistence shape lives in save-recovery.md; this is the
// in-memory runtime shape that engines manipulate.
//
// The "no failures in last 3 Abstract attempts" tail check is still deferred;
// CPA promotion, demotion, and the soft-success path are implemented.

enum MasteryStatus { notStarted, introduced, practicing, mastered }

enum CpaLayer { concrete, pictorial, abstract }

class ConceptState {
  const ConceptState({
    required this.conceptId,
    this.instanceKey,
    this.status = MasteryStatus.notStarted,
    this.currentLayer = CpaLayer.concrete,
    this.currentStreak = 0,
    this.consecutiveFailures = 0,
    this.abstractSuccessCount = 0,
    this.sessionIds = const <String>{},
    this.daysTouched = const <String>{},
    this.firstTouchedAt,
    this.lastTouchedAt,
  });

  final String conceptId;
  final String? instanceKey;
  final MasteryStatus status;
  final CpaLayer currentLayer;
  final int currentStreak;

  /// Failures in a row at the current layer. Demotion fires at 2, against 3
  /// successes to promote — deliberately asymmetric, because
  /// specs/shared/adaptive-scaffolding.md wants us "generous on the way down,
  /// conservative on the way up". Reset by any success, soft or otherwise.
  final int consecutiveFailures;

  final int abstractSuccessCount;
  final Set<String> sessionIds;
  final Set<String> daysTouched;
  final DateTime? firstTouchedAt;
  final DateTime? lastTouchedAt;

  bool get isFirstEncounter => status == MasteryStatus.notStarted;

  /// Stable key for indexing; includes the instance suffix for per-instance
  /// concepts so K.CC.3 / 5 and K.CC.3 / 13 don't collide.
  String get key => instanceKey == null ? conceptId : '$conceptId/$instanceKey';

  ConceptState copyWith({
    MasteryStatus? status,
    CpaLayer? currentLayer,
    int? currentStreak,
    int? consecutiveFailures,
    int? abstractSuccessCount,
    Set<String>? sessionIds,
    Set<String>? daysTouched,
    DateTime? firstTouchedAt,
    DateTime? lastTouchedAt,
  }) {
    return ConceptState(
      conceptId: conceptId,
      instanceKey: instanceKey,
      status: status ?? this.status,
      currentLayer: currentLayer ?? this.currentLayer,
      currentStreak: currentStreak ?? this.currentStreak,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      abstractSuccessCount: abstractSuccessCount ?? this.abstractSuccessCount,
      sessionIds: sessionIds ?? this.sessionIds,
      daysTouched: daysTouched ?? this.daysTouched,
      firstTouchedAt: firstTouchedAt ?? this.firstTouchedAt,
      lastTouchedAt: lastTouchedAt ?? this.lastTouchedAt,
    );
  }
}
