// Activity model — mirrors the runtime fields used by the Hub and ActivityRunner.
// Sprint 1 keeps this plain Dart (no freezed) to keep velocity up; promote to
// freezed once a second consumer needs the same model.
//
// Source of truth: data/activity-registry/kindergarten.json
// Schema: schemas/activity-registry.schema.json

class ConceptRef {
  const ConceptRef({
    required this.conceptId,
    required this.role,
  });

  factory ConceptRef.fromJson(Map<String, dynamic> json) {
    return ConceptRef(
      conceptId: json['conceptId'] as String,
      role: json['role'] as String,
    );
  }

  final String conceptId;
  final String role;
}

class SubMode {
  const SubMode({
    required this.id,
    required this.primaryConcepts,
    this.isDefault = false,
    this.isChallenge = false,
    this.isDemotionFloor = false,
    this.ownsIntro = false,
  });

  factory SubMode.fromJson(Map<String, dynamic> json) {
    return SubMode(
      id: json['id'] as String,
      primaryConcepts: (json['primaryConcepts'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false),
      isDefault: json['isDefault'] as bool? ?? false,
      isChallenge: json['isChallenge'] as bool? ?? false,
      isDemotionFloor: json['isDemotionFloor'] as bool? ?? false,
      ownsIntro: json['ownsIntro'] as bool? ?? false,
    );
  }

  final String id;
  final List<String> primaryConcepts;
  final bool isDefault;
  final bool isChallenge;
  final bool isDemotionFloor;

  /// When true, the sub-mode's runner plays its own animated demo/lesson
  /// at intro time. The Sanctuary picker and the activity-screen
  /// auto-advance both skip ScaffoldEngine for these sub-modes — they
  /// route straight into the activity so the runner's intro is the only
  /// thing the kid sees. Challenge sub-modes get the same routing
  /// treatment but for a different reason (they're optional final
  /// checks), which is why this flag is separate from `isChallenge`.
  final bool ownsIntro;
}

class Activity {
  const Activity({
    required this.id,
    required this.displayName,
    required this.region,
    required this.grade,
    required this.status,
    required this.concepts,
    required this.subModes,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      region: json['region'] as String,
      grade: json['grade'] as String,
      status: json['status'] as String,
      concepts: (json['concepts'] as List<dynamic>)
          .map((e) => ConceptRef.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      subModes: (json['subModes'] as List<dynamic>)
          .map((e) => SubMode.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final String id;
  final String displayName;
  final String region;
  final String grade;
  final String status;
  final List<ConceptRef> concepts;
  final List<SubMode> subModes;

  SubMode get defaultSubMode =>
      subModes.firstWhere((m) => m.isDefault, orElse: () => subModes.first);
}
