// Concept model — what the MasteryEngine and ScaffoldEngine reason about.
// Sprint 1 only consumes the fields the vertical slice needs; the registry has
// more (prerequisites, sibling-credit rules, etc.) that later sprints will use.
//
// Source: data/concept-registry/kindergarten.json
// Schema: schemas/concept-registry.schema.json

class Concept {
  const Concept({
    required this.id,
    required this.standardCode,
    required this.description,
    required this.gradeLevel,
    required this.strand,
    required this.requiresLesson,
    required this.granularity,
    this.lessonId,
    this.introducedBy,
    this.exercisedBy = const [],
    this.instanceKeys = const [],
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    return Concept(
      id: json['id'] as String,
      standardCode: json['standardCode'] as String,
      description: json['description'] as String,
      gradeLevel: json['gradeLevel'] as String,
      strand: json['strand'] as String,
      requiresLesson: json['requiresLesson'] as bool? ?? false,
      granularity: json['granularity'] as String? ?? 'concept-wide',
      lessonId: json['lessonId'] as String?,
      introducedBy: json['introducedBy'] as String?,
      exercisedBy: (json['exercisedBy'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
      instanceKeys: (json['instanceKeys'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(growable: false),
    );
  }

  final String id;
  final String standardCode;
  final String description;
  final String gradeLevel;
  final String strand;
  final bool requiresLesson;
  final String granularity;
  final String? lessonId;
  final String? introducedBy;
  final List<String> exercisedBy;
  final List<String> instanceKeys;

  bool get isPerInstance => granularity == 'per-instance';
}
