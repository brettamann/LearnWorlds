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

  /// The simplest sub-mode of this activity — where staggered demotion puts
  /// a kid who is struggling (specs/shared/adaptive-scaffolding.md).
  ///
  /// Read the flag carefully before filtering on it. "Simplest" is usually
  /// the same sub-mode as `isDefault`: Shape Garden, Where's Buddy,
  /// Ten-Frame Pond, Scribe's Tower and Storyteller's Pond all mark their
  /// first step both default and floor, because the easiest thing they teach
  /// is also where a first-time kid starts. Build-a-Habitat is the one
  /// activity with a rung *below* its entry point — `frame-only` builds the
  /// frame and stops, and it is not default and not part of the chain.
  final bool isDemotionFloor;

  /// Whether this sub-mode is a step in the chain a kid works forward
  /// through — what the Sanctuary picker offers, what auto-advance moves on
  /// to, and what "this activity is finished" is measured against.
  ///
  /// The entry point is always a step, whatever else it is marked. Past it,
  /// two kinds sit outside the chain for opposite reasons: a challenge comes
  /// *after* it (offered once every step is done, and skippable forever) and
  /// a floor sits *below* it.
  ///
  /// This was read by nothing at all until recently, so `frame-only` was in
  /// Build-a-Habitat's chain as an ordinary step, with three consequences.
  /// It has no picker artwork, so the sheet drew it as a grey question mark
  /// captioned `frame-only` in front of a child who cannot read. It comes
  /// last in registry order, so the easiest build in the activity was the one
  /// she played last — the ramp running backwards on the culminating round.
  /// And the activity could not be marked complete without it, which on this
  /// map is what lifts the fog on Where's Buddy.
  bool get isChainStep => isDefault || (!isChallenge && !isDemotionFloor);

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

  /// The sub-mode with [id], or null if this activity has none.
  SubMode? subModeById(String id) =>
      subModes.where((m) => m.id == id).firstOrNull;

  /// The concept a round of [subMode] teaches first: its own first primary
  /// concept, else the activity's first.
  String entryConceptIdFor(SubMode? subMode) =>
      subMode != null && subMode.primaryConcepts.isNotEmpty
          ? subMode.primaryConcepts.first
          : concepts.first.conceptId;

  /// The sub-mode one step simpler than [subModeId], for a child who is
  /// struggling at the simplest layer of it - step two of the staggered
  /// demotion in specs/shared/adaptive-scaffolding.md, once there is no CPA
  /// layer left to drop.
  ///
  /// Within the chain that is the step before. From the entry point it is the
  /// floor below the entry, where an activity has one (Build-a-Habitat's
  /// frame-only, Care Pantry's categorize-only): the only way either is ever
  /// reached. A challenge, or the floor itself, has nothing simpler - a
  /// challenge is opt-in, and a hard time in it is not a signal to send her
  /// backwards through the activity.
  SubMode? simplerThan(String subModeId) {
    final chain = subModes.where((m) => m.isChainStep).toList();
    final i = chain.indexWhere((m) => m.id == subModeId);
    if (i > 0) return chain[i - 1];
    if (i < 0) return null;
    for (final m in subModes) {
      if (m.isDemotionFloor && !m.isChainStep) return m;
    }
    return null;
  }
}
