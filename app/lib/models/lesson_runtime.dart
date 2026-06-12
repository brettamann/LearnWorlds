// LessonRuntime — Sprint 1 subset of data/lesson-runtime/<id>.json.
// Only the fields the M6 caption-based runner uses: iShow narration script,
// weTry narration cues, and youDo handoff parameters. Animation choreography
// is loaded into a flexible map so later sprints can render scenes without
// the loader changing.

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
    this.background,
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
      background: scene['background'] as String?,
    );
  }

  final int durationSec;
  final List<NarrationCue> narrationScript;
  final List<AnimationStep> animationSteps;
  final int skipAvailableAfterSec;

  /// Shapes the renderer should draw in the scene. Empty for fawn-style
  /// lessons (K.CC.4a) — those use `scene.creatures` which we don't model
  /// yet because the existing renderer hard-codes "3 fawns."
  final List<SceneShape> shapes;

  /// Logical background key from the JSON (e.g. `shape-garden-enchanted-path`).
  /// Renderer maps this to an actual asset.
  final String? background;
}

class WeTryPhase {
  const WeTryPhase({
    required this.durationSec,
    required this.narrationByCueId,
  });

  factory WeTryPhase.fromJson(Map<String, dynamic> json) {
    final byCue = <String, String>{};
    for (final cue in json['narrationScript'] as List<dynamic>) {
      final map = cue as Map<String, dynamic>;
      byCue[map['at'] as String] = map['text'] as String;
    }
    return WeTryPhase(
      durationSec: (json['durationSec'] as num).toInt(),
      narrationByCueId: byCue,
    );
  }

  final int durationSec;
  final Map<String, String> narrationByCueId;

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
  });

  factory LessonRuntime.fromJson(Map<String, dynamic> json) {
    final phases = json['phases'] as Map<String, dynamic>;
    return LessonRuntime(
      id: json['id'] as String,
      conceptId: json['conceptId'] as String,
      iShow: IShowPhase.fromJson(phases['iShow'] as Map<String, dynamic>),
      weTry: WeTryPhase.fromJson(phases['weTry'] as Map<String, dynamic>),
      youDo: YouDoPhase.fromJson(phases['youDo'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String conceptId;
  final IShowPhase iShow;
  final WeTryPhase weTry;
  final YouDoPhase youDo;
}
