// LessonRuntime — Sprint 1 subset of data/lesson-runtime/<id>.json.
// Only the fields the M6 caption-based runner uses: iShow narration script,
// weTry narration cues, and youDo handoff parameters. Animation choreography
// is loaded into a flexible map so later sprints can render scenes without
// the loader changing.
//
// `weTry` used to stop at its narration map: the lines were parsed, and the
// `choreography` that says when to speak them was skipped. That is why the
// phase was authored in all 22 lessons and ran in none of them.

import 'we_try_script.dart';

class NarrationCue {
  const NarrationCue({required this.at, required this.text});

  factory NarrationCue.fromJson(Map<String, dynamic> json) {
    return NarrationCue(
      at: json['at'] as String,
      text: json['text'] as String,
    );
  }

  /// Either a duration string like "5s" / "11s" (iShow) or a cueId
  /// like "we-try-after-tap-1" (weTry). Caller knows which one to expect.
  final String at;
  final String text;
}

class AnimationStep {
  const AnimationStep({
    required this.at,
    required this.action,
    required this.params,
  });

  factory AnimationStep.fromJson(Map<String, dynamic> json) {
    return AnimationStep(
      at: json['at'] as String,
      action: json['action'] as String,
      params: json['params'] is Map
          ? Map<String, dynamic>.from(json['params'] as Map)
          : const <String, dynamic>{},
    );
  }

  final String at;
  final String action;
  final Map<String, dynamic> params;
}

/// One scene entry from `phases.iShow.scene.shapes` (K.G.2-style lessons).
/// We don't try to model every field every lesson family will use — just
/// the ones the renderer reads to draw a sprite and animate it. Unknown
/// extra keys ride along in `raw` for later sprints.
class SceneShape {
  const SceneShape({
    required this.id,
    required this.kind,
    this.variant,
    this.role,
    this.raw = const <String, dynamic>{},
  });

  factory SceneShape.fromJson(Map<String, dynamic> json) {
    return SceneShape(
      id: json['id'] as String,
      kind: json['kind'] as String,
      variant: json['variant'] as String?,
      role: json['role'] as String?,
      raw: json,
    );
  }

  /// Stable id used in animationSteps targets (e.g. `tri-1`, `dis-2`).
  final String id;

  /// Shape family (`triangle`, `circle`, `square`, `hexagon`, etc.).
  final String kind;

  /// Author-supplied pose / variant (`upright-small`, `point-down`,
  /// `rotated-45`). The renderer translates these to rotation + scale.
  final String? variant;

  /// `distractor` for non-target shapes; null for targets.
  final String? role;

  final Map<String, dynamic> raw;
}

class IShowPhase {
  const IShowPhase({
    required this.durationSec,
    required this.narrationScript,
    required this.animationSteps,
    required this.skipAvailableAfterSec,
    required this.shapes,
    required this.landmarkIds,
    required this.creatureCount,
    this.framePrebuilt = false,
    this.showsRoof = false,
    this.background,
    this.musicBed,
  });

  factory IShowPhase.fromJson(Map<String, dynamic> json) {
    final scene = json['scene'] as Map<String, dynamic>? ?? const {};
    return IShowPhase(
      durationSec: (json['durationSec'] as num).toInt(),
      narrationScript: (json['narrationScript'] as List<dynamic>)
          .map((e) => NarrationCue.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      animationSteps:
          (json['animationSteps'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => AnimationStep.fromJson(e as Map<String, dynamic>))
              .toList(growable: false),
      skipAvailableAfterSec:
          (json['skipToYouDoAvailableAfterSec'] as num?)?.toInt() ?? 0,
      shapes: (scene['shapes'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => SceneShape.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      landmarkIds: <String>[
        for (final id in scene['landmarks'] as List<dynamic>? ?? const [])
          if (id is String) id,
      ],
      creatureCount: _creatureCount(scene),
      framePrebuilt: (scene['buildSite'] as Map?)?['completedFrame'] != null,
      showsRoof: (scene['buildSite'] as Map?)?['phase2GhostOutline'] != null,
      background: scene['background'] as String?,
      musicBed: scene['musicBed'] as String?,
    );
  }

  final int durationSec;
  final List<NarrationCue> narrationScript;

  /// The habitat frame is already standing when the demonstration opens
  /// (K.G.6 builds on top of the frame she laid in K.G.5).
  final bool framePrebuilt;

  /// The roof ghost is drawn: this demonstration adds a shape on top.
  final bool showsRoof;
  final List<AnimationStep> animationSteps;
  final int skipAvailableAfterSec;

  /// Shapes the renderer should draw in the scene. Empty for fawn-style
  /// lessons (K.CC.4a) — those use `scene.creatures` which we don't model
  /// yet because the existing renderer hard-codes "3 fawns."
  final List<SceneShape> shapes;

  /// Places standing in the clearing, for the K.G.1 position lessons. Ids
  /// match `kWheresBuddyLandmarks`, so the lesson stands the kid in front of
  /// the same tree the round will ask her about.
  ///
  /// The scene block has carried these since the lesson was written; nothing
  /// read them, which is why K.G.1 rendered three fawns.
  final List<String> landmarkIds;

  /// How many creatures stand in the scene.
  ///
  /// Read rather than assumed because the We-Try scenes deliberately hold one
  /// more than the I-Show did - the demonstration counts three fawns, her turn
  /// counts four, so the phase asks for a new quantity instead of replaying
  /// the one she just watched. A renderer that keeps its own count draws three
  /// while the narrator says "Three. Four."
  final int creatureCount;

  /// Logical background key from the JSON (e.g. `shape-garden-enchanted-path`).
  /// Renderer maps this to an actual asset.
  final String? background;

  /// Music bed the scene asks for, resolved against [kMusicBeds]. Authored in
  /// every lesson since the content was written and read by nobody until the
  /// bed became continuous — the lesson screen used to play in silence
  /// between two rounds that had music.
  final String? musicBed;
}

class WeTryPhase {
  const WeTryPhase({
    required this.durationSec,
    required this.narrationByCueId,
    required this.script,
    required this.initialGlowTarget,
    required this.landmarkIds,
    required this.creatureCount,
    required this.framePrebuilt,
    required this.showsRoof,
    this.musicBed,
  });

  factory WeTryPhase.fromJson(Map<String, dynamic> json) {
    final byCue = <String, String>{};
    for (final cue in json['narrationScript'] as List<dynamic>) {
      final map = cue as Map<String, dynamic>;
      byCue[map['at'] as String] = map['text'] as String;
    }
    final scene = json['scene'] as Map<String, dynamic>? ?? const {};
    return WeTryPhase(
      durationSec: (json['durationSec'] as num).toInt(),
      narrationByCueId: byCue,
      script: WeTryScript.compile(
        choreography: <Map<String, dynamic>>[
          for (final step in json['choreography'] as List<dynamic>? ?? const [])
            if (step is Map) Map<String, dynamic>.from(step),
        ],
        narrationByCueId: byCue,
        hesitationRule: json['hesitationRule'] as Map<String, dynamic>?,
      ),
      initialGlowTarget: scene['initialGlowTarget'] as String?,
      landmarkIds: <String>[
        for (final id in scene['landmarks'] as List<dynamic>? ?? const [])
          if (id is String) id,
      ],
      creatureCount: _creatureCount(scene),
      framePrebuilt: (scene['buildSite'] as Map?)?['completedFrame'] != null,
      showsRoof: (scene['buildSite'] as Map?)?['phase2GhostOutline'] != null,
      musicBed: scene['musicBed'] as String?,
    );
  }

  final int durationSec;
  final Map<String, String> narrationByCueId;

  /// The authored choreography, compiled into beats the lesson screen can run.
  /// Every lesson has had one of these since the content was written; until
  /// now nothing read the `choreography` key at all, so the phase existed on
  /// disk and nowhere else.
  final WeTryScript script;

  /// What lights up before she is asked to do anything, so the first thing on
  /// screen already says where to look.
  final String? initialGlowTarget;

  /// Places in the clearing, same vocabulary as the I-Show scene.
  final List<String> landmarkIds;

  /// See [IShowPhase.creatureCount] - this is the one that is usually four.
  final int creatureCount;

  /// Whether the shelter frame is already standing when her turn begins.
  ///
  /// The two Build-a-Habitat lessons want opposite things and both say so:
  /// K.G.5's We-Try scene declares `ghostOutline: bright-triangle` with vertex
  /// and edge indicators - an empty site she fills in - while K.G.6's declares
  /// `completedFrame: triangle-solid`, because its subject is what goes on top
  /// of a frame that already exists. Inheriting whatever the I-Show left
  /// behind gets K.G.5 wrong in the way that matters most: she is asked to
  /// place a corner on a triangle that is already finished.
  final bool framePrebuilt;

  /// Whether the phase-2 shapes are part of this scene.
  final bool showsRoof;

  final String? musicBed;

  String? line(String cueId) => narrationByCueId[cueId];
}

class YouDoPhase {
  const YouDoPhase({
    required this.activityId,
    required this.subMode,
    required this.roundParameters,
  });

  factory YouDoPhase.fromJson(Map<String, dynamic> json) {
    return YouDoPhase(
      activityId: json['activityId'] as String,
      subMode: json['subMode'] as String,
      roundParameters:
          Map<String, dynamic>.from(json['roundParameters'] as Map),
    );
  }

  final String activityId;
  final String subMode;
  final Map<String, dynamic> roundParameters;
}

class LessonRuntime {
  const LessonRuntime({
    required this.id,
    required this.conceptId,
    required this.iShow,
    required this.weTry,
    required this.youDo,
    required this.presentation,
  });

  factory LessonRuntime.fromJson(Map<String, dynamic> json) {
    final phases = json['phases'] as Map<String, dynamic>;
    return LessonRuntime(
      id: json['id'] as String,
      conceptId: json['conceptId'] as String,
      presentation: LessonPresentation.fromJson(
        json['presentation'] as Map<String, dynamic>,
      ),
      iShow: IShowPhase.fromJson(phases['iShow'] as Map<String, dynamic>),
      weTry: WeTryPhase.fromJson(phases['weTry'] as Map<String, dynamic>),
      youDo: YouDoPhase.fromJson(phases['youDo'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String conceptId;

  /// How LessonScreen shows this lesson: which stage, on which backdrop,
  /// opened with which keeper line.
  final LessonPresentation presentation;

  final IShowPhase iShow;
  final WeTryPhase weTry;
  final YouDoPhase youDo;
}

/// Creatures in a scene block, however that lesson counts them.
///
/// `count` in the one-to-one lessons, `clusterCount` where the unit is a
/// cluster of ten, `preCountedCount` where some are already numbered. Falls
/// back to 3, which is what the fawn stage drew before it read anything.
int _creatureCount(Map<String, dynamic> scene) {
  final creatures = scene['creatures'];
  if (creatures is! Map) return 3;
  for (final key in const ['count', 'clusterCount', 'preCountedCount']) {
    final value = creatures[key];
    if (value is num) return value.toInt();
  }
  return 3;
}

/// The stage a lesson is played on.
enum LessonStage {
  /// Creatures in a meadow, counted (the default counting lessons).
  fawns('fawns'),

  /// Groups of ten (K.CC.1).
  clusters('clusters'),

  /// Counting on from a number already counted (K.CC.2).
  countOn('count-on'),

  /// The habitat build site (K.G.5, K.G.6).
  habitat('habitat'),

  /// Buddy and the landmarks of the clearing (K.G.1).
  clearing('clearing'),

  /// Nine shapes, each introduced then found (K.G.2).
  shapeSequence('shape-sequence'),

  /// Flat-or-solid pairings and a sort (K.G.3).
  flatOrSolid('flat-or-solid'),

  /// Sorting by number of sides (K.G.4).
  sortByAttribute('sort-by-attribute');

  const LessonStage(this.id);

  /// The value authored in the lesson JSON.
  final String id;

  static LessonStage fromId(String id) => values.firstWhere(
        (s) => s.id == id,
        orElse: () => throw FormatException('Unknown lesson stage "$id"'),
      );

  /// Stages that are their own guided practice, and so must not also run
  /// the generic We-Try: asking her to do the same thing twice in a row.
  bool get ownsPractice =>
      this == shapeSequence || this == flatOrSolid || this == sortByAttribute;
}

/// The painted backdrop behind a lesson.
enum LessonBackdrop {
  meadow('meadow'),
  garden('garden');

  const LessonBackdrop(this.id);
  final String id;

  static LessonBackdrop fromId(String id) => values.firstWhere(
        (b) => b.id == id,
        orElse: () => throw FormatException('Unknown lesson backdrop "$id"'),
      );
}

/// How a lesson is presented. Authored in the lesson JSON; it used to be
/// four switches on the concept id inside LessonScreen.
class LessonPresentation {
  const LessonPresentation({
    required this.stage,
    required this.backdrop,
    required this.keeperIntro,
    required this.startLabel,
  });

  factory LessonPresentation.fromJson(Map<String, dynamic> json) {
    final keeper = json['keeperIntro'] as Map<String, dynamic>;
    return LessonPresentation(
      stage: LessonStage.fromId(json['stage'] as String),
      backdrop: LessonBackdrop.fromId(json['backdrop'] as String),
      keeperIntro: keeper['text'] as String,
      startLabel: keeper['startLabel'] as String,
    );
  }

  final LessonStage stage;
  final LessonBackdrop backdrop;

  /// What the keeper says before the lesson starts.
  final String keeperIntro;

  /// The button under it.
  final String startLabel;
}
