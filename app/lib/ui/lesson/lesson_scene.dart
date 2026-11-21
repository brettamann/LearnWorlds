// LessonScene - everything a lesson's stage shows, and the rules for moving
// it.
//
// The I-Show and the We-Try both move the same scene: the demonstrator's
// hand, sparkles, the count badge, Buddy in the clearing, the habitat frame
// going up. These used to be seventeen fields and a dozen methods on
// LessonScreen's State, mixed in with its timers and its phase machine. Here
// they are one object the screen observes, so the choreography can be tested
// without pumping a widget.
//
// Nothing in here waits. Timing belongs to the timelines that drive it
// (IShowTimeline, WeTryRunner); this only answers "what does the scene look
// like after this step".

import 'package:flutter/widgets.dart';

import '../../activities/wheres_buddy/wheres_buddy_landmark_sprite.dart';
import '../../data/build_a_habitat_blueprints.dart';
import '../../models/lesson_runtime.dart';
import 'clearing_lesson_stage.dart';
import 'habitat_lesson_stage.dart';

class LessonScene extends ChangeNotifier {
  // ---- Generic I-Show scene (fawns, clusters, count-on) ------------------

  final Set<String> sparkled = <String>{};
  final Map<String, int> burstCounters = <String, int>{};

  /// The count badge, or null while hidden.
  int? badgeValue;

  bool pointerVisible = false;
  String? pointerTargetId;
  bool handAtTarget = false;
  int pokeCounter = 0;

  // ---- K.G.1 clearing ------------------------------------------------------

  /// The place the narrator is naming, and where Buddy stands.
  String? facingLandmarkId;
  ClearingSpot? buddySpot;

  // ---- K.G.5 / K.G.6 habitat ----------------------------------------------

  final Set<int> placedCorners = <int>{};
  final Set<int> placedEdges = <int>{};
  final Set<int> placedRoof = <int>{};
  HabitatCarry carrying = HabitatCarry.none;
  bool handVisible = false;
  Offset? handTarget;
  bool fawnHome = false;

  // ---- We-Try --------------------------------------------------------------

  /// What is lit right now, in scene-target ids. The halo is drawn over the
  /// stage at the rect the stage registered, so this is also what a touch is
  /// tested against - one source for "where to touch" and "did she".
  final Set<String> haloed = <String>{};

  static HabitatBlueprint get _blueprint => kHabitatBlueprints[0];

  /// Applies one authored animation step.
  void apply(AnimationStep step) {
    _apply(step);
    notifyListeners();
  }

  void _apply(AnimationStep step) {
    switch (step.action) {
      // ---- K.G.1 clearing steps -----------------------------------------
      case 'buddy-turn-toward':
        final t = step.params['target'];
        if (t is String) facingLandmarkId = t;
      case 'pointer-move-buddy':
        final position = step.params['position'];
        final landmark = step.params['landmark'];
        if (position is String && landmark is String) {
          buddySpot = ClearingSpot(landmarkId: landmark, positionId: position);
          facingLandmarkId = landmark;
          pointerVisible = true;
        }
      case 'buddy-return-to-center':
        buddySpot = null;
        facingLandmarkId = null;
      // ---- K.G.5 / K.G.6 build steps ------------------------------------
      case 'pointer-pickup-from-pool':
        carrying = switch (step.params['itemType']) {
          'clay-ball' => HabitatCarry.clay,
          'stick' => HabitatCarry.stick,
          _ => HabitatCarry.roofPiece,
        };
        handTarget = null;
        handVisible = true;
      case 'pointer-place':
      case 'pointer-place-clay':
      case 'pointer-place-stick':
        _placeHabitatPiece(step.params['target']);
      case 'ghost-outline-fade-out':
        // The ghost is only drawn where a piece is missing, so the piece
        // landing is the fade. Nothing to do, and saying so beats a silent
        // default that reads as "unhandled".
        break;
      case 'fawn-walk-toward-habitat':
      case 'fawn-enter-habitat':
        fawnHome = true;
        carrying = HabitatCarry.none;
        handVisible = false;
      case 'frame-solidify-with-lift-stinger':
        // The build is finished; the demonstrator's hand comes off it so the
        // last thing she looks at is the frame she is about to make.
        handVisible = false;
        carrying = HabitatCarry.none;
      // `directional-arrow` is authored and deliberately not drawn. The glide
      // from centre stage to the spot already carries the direction, from the
      // same vector the round will use - an arrow drawn separately is a second
      // statement of the same fact that can disagree with the first.
      case 'pointer-appear':
        pointerVisible = true;
        handAtTarget = false;
        final t = resolveTargetId(step.params['position']) ??
            resolveTargetId(step.params['target']);
        if (t != null) pointerTargetId = t;
      case 'pointer-touch':
        pointerVisible = true;
        handAtTarget = true;
        final t = resolveTargetId(step.params['target']);
        if (t != null) pointerTargetId = t;
        pokeCounter++;
      case 'pointer-fade-out':
        pointerVisible = false;
        handAtTarget = false;
        pointerTargetId = null;
        handVisible = false;
      case 'sparkle':
        final t = resolveTargetId(step.params['target']);
        if (t != null) _sparkle(t);
      case 'count-badge-show':
      case 'count-badge-update':
        final v = step.params['value'];
        if (v is num) badgeValue = v.toInt();
      default:
        break;
    }
  }

  void _sparkle(String id) {
    sparkled.add(id);
    burstCounters[id] = (burstCounters[id] ?? 0) + 1;
  }

  /// Resolves a JSON `target` / `position` value into a scene target id.
  /// Strips the `left-of-` prefix that some `pointer-appear` steps use.
  static String? resolveTargetId(Object? raw) {
    if (raw is! String) return null;
    final stripped = raw.startsWith('left-of-') ? raw.substring(8) : raw;
    return stripped.isEmpty ? null : stripped;
  }

  // ---- The demonstrator's hand, one beat at a time -------------------------

  /// The hand glides to [id] ahead of touching it, so the poke lands on time.
  void aimAt(String id) {
    pointerTargetId = id;
    handAtTarget = true;
    notifyListeners();
  }

  /// Reach for [id]: the hand moves there but has not touched yet.
  void reachFor(String id) {
    pointerVisible = true;
    pointerTargetId = id;
    handAtTarget = false;
    notifyListeners();
  }

  /// Touch [id]: poke and sparkle.
  void touch(String id) {
    handAtTarget = true;
    pokeCounter++;
    _sparkle(id);
    notifyListeners();
  }

  /// The hand comes away.
  void handAway() {
    pointerVisible = false;
    handAtTarget = false;
    pointerTargetId = null;
    notifyListeners();
  }

  // ---- Habitat -------------------------------------------------------------

  /// Puts the carried piece on [target].
  ///
  /// Targets are `vertex-N`, `edge-N` and the phase-2 ghost, which map one to
  /// one onto the blueprint's corners, edges and roof - so the lesson places
  /// pieces at exactly the spots the round will ask her to fill.
  void _placeHabitatPiece(Object? target) {
    final blueprint = _blueprint;
    if (target is String && target.startsWith('vertex-')) {
      final i = (int.tryParse(target.substring(7)) ?? 1) - 1;
      if (i >= 0 && i < blueprint.corners.length) placedCorners.add(i);
      handTarget = _stageSpot(blueprint.corners[i]);
    } else if (target is String && target.startsWith('edge-')) {
      final i = (int.tryParse(target.substring(5)) ?? 1) - 1;
      if (i >= 0 && i < blueprint.edges.length) placedEdges.add(i);
      handTarget = _edgeSpot(i);
    } else {
      // The phase-2 ghost. Only ever one piece in this blueprint.
      placedRoof.add(0);
      handTarget = _stageSpot(blueprint.roof.first.position);
    }
    carrying = HabitatCarry.none;
  }

  /// Blueprint coordinates are normalized to the *build site*, a sub-rect of
  /// the stage; the hand is positioned in stage space, so each spot is mapped
  /// back out through that rectangle.
  static Offset _stageSpot(Offset inBlueprintSpace) => Offset(
        kHabitatSiteRect.left + inBlueprintSpace.dx * kHabitatSiteRect.width,
        kHabitatSiteRect.top + inBlueprintSpace.dy * kHabitatSiteRect.height,
      );

  static Offset _edgeSpot(int i) {
    final pair = _blueprint.edges[i];
    final a = _blueprint.corners[pair[0]];
    final b = _blueprint.corners[pair[1]];
    return _stageSpot(Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2));
  }

  void _placeAllCorners() {
    for (var i = 0; i < _blueprint.corners.length; i++) {
      placedCorners.add(i);
    }
  }

  void _placeAllEdges() {
    for (var i = 0; i < _blueprint.edges.length; i++) {
      placedEdges.add(i);
    }
  }

  // ---- We-Try --------------------------------------------------------------

  /// Her turn starts from a clean scene. The I-Show leaves every creature it
  /// counted lit, and opening the We-Try on top of that asks her to touch the
  /// first fawn while three are already glowing - so the halo, the one thing
  /// telling her where to go, competes with leftovers of a demonstration
  /// that is over. The demo hand goes too: during her turn she is the hand.
  void resetForWeTry(WeTryPhase weTry) {
    haloed
      ..clear()
      ..addAll(<String>[
        if (weTry.initialGlowTarget != null) weTry.initialGlowTarget!,
      ]);
    pointerVisible = false;
    handVisible = false;
    handAtTarget = false;
    pointerTargetId = null;
    sparkled.clear();
    burstCounters.clear();
    badgeValue = null;
    buddySpot = null;
    facingLandmarkId = null;
    fawnHome = false;
    carrying = HabitatCarry.none;
    handTarget = null;
    // The build site is whatever this phase's own scene declares, not
    // whatever the demonstration finished with.
    placedCorners.clear();
    placedEdges.clear();
    placedRoof.clear();
    if (weTry.framePrebuilt) {
      _placeAllCorners();
      _placeAllEdges();
    }
    notifyListeners();
  }

  /// Lights exactly [ids].
  void halo(Iterable<String> ids) {
    haloed
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  /// A gate has resolved on [targets]. Sparkles them if she touched, and
  /// puts the scene in the state the prompt asked for either way.
  ///
  /// "Put the Buddy above the star fountain" is answered by the Buddy being
  /// above the star fountain. Without this she touches the ring and nothing
  /// moves, which reads as the touch not registering. It runs on a miss too:
  /// "correct steers; incorrect corrects" - the corrective line names the
  /// right place, and then the right place is shown.
  void settleGate(List<String> targets, {required bool byHer}) {
    haloed.clear();
    for (final id in targets) {
      if (byHer) _sparkle(id);
      final zone = parseClearingZone(id);
      if (zone != null) {
        buddySpot = ClearingSpot(
          landmarkId: zone.landmarkId,
          positionId: zone.positionId,
        );
        facingLandmarkId = zone.landmarkId;
        continue;
      }
      // Habitat targets name a piece of the frame; the piece going down is
      // what "she placed it" looks like.
      _placeHabitatPiece(id);
    }
    notifyListeners();
  }

  /// The lowest-numbered piece of the frame that is not down yet, for
  /// `halo-pulse-next-vertex` and friends - a relative instruction, because
  /// the author could not know which corner she would take first.
  List<String> nextUnplacedFramePiece(String action) {
    if (action.contains('vertex')) {
      for (var i = 0; i < _blueprint.corners.length; i++) {
        if (!placedCorners.contains(i)) return ['vertex-${i + 1}'];
      }
    }
    if (action.contains('edge') || action.contains('stick')) {
      for (var i = 0; i < _blueprint.edges.length; i++) {
        if (!placedEdges.contains(i)) return ['edge-${i + 1}'];
      }
    }
    return const <String>[];
  }

  /// "The system completes the rest", which fourteen lessons ask for by
  /// name. Without it the habitat We-Try leaves a triangle with one corner and
  /// one stick on it while the narrator says the frame is finished. The halo
  /// comes off with it: nothing is being asked of her while it runs.
  void autoCompleteFrame(String action) {
    haloed.clear();
    if (action.contains('clay') || action.contains('vertex')) {
      _placeAllCorners();
    }
    if (action.contains('stick') || action.contains('edge')) {
      _placeAllEdges();
    }
    notifyListeners();
  }

  /// The frame stands. Every piece down, the hand off it.
  void completeFrame() {
    _placeAllCorners();
    _placeAllEdges();
    handVisible = false;
    carrying = HabitatCarry.none;
    notifyListeners();
  }
}
