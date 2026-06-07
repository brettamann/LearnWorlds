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

class IShowPhase {
  const IShowPhase({
    required this.durationSec,
    required this.narrationScript,
    required this.animationSteps,
    required this.skipAvailableAfterSec,
  });

  factory IShowPhase.fromJson(Map<String, dynamic> json) {
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
    );
  }

  final int durationSec;
  final List<NarrationCue> narrationScript;
  final List<AnimationStep> animationSteps;
  final int skipAvailableAfterSec;
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
