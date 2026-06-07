// ConceptState — per-(kid, concept[, instanceKey]) record the MasteryEngine
// reads and writes. Persistence shape lives in save-recovery.md; this is the
// in-memory runtime shape that engines manipulate.
//
// Sprint 1 implements the subset used by the vertical slice
// (Counting Parade → K.CC.4a). Hint/tile-fallback triggers and the
// "no failures in last 3 Abstract attempts" tail check arrive in later sprints.

enum MasteryStatus { notStarted, introduced, practicing, mastered }

enum CpaLayer { concrete, pictorial, abstract }

class ConceptState {
  const ConceptState({
    required this.conceptId,
    this.instanceKey,
    this.status = MasteryStatus.notStarted,
    this.currentLayer = CpaLayer.concrete,
    this.currentStreak = 0,
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
      abstractSuccessCount: abstractSuccessCount ?? this.abstractSuccessCount,
      sessionIds: sessionIds ?? this.sessionIds,
      daysTouched: daysTouched ?? this.daysTouched,
      firstTouchedAt: firstTouchedAt ?? this.firstTouchedAt,
      lastTouchedAt: lastTouchedAt ?? this.lastTouchedAt,
    );
  }
}
