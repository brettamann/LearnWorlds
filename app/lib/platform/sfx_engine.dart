// SfxEngine — the game's sound effect and music adapter, over `just_audio`.
//
// Shaped deliberately like SystemTts: construction is cheap, `warmUp()` runs
// once and silently no-ops when the platform plugin isn't available (unit
// tests, headless environments), and every public method swallows its errors.
// Sound is a garnish — a failure here must never take gameplay down with it.
//
// Why pooled, preloaded players
// -----------------------------
// A child taps a creature roughly once a second and expects the sound *now*.
// Decoding on demand costs tens of milliseconds and reads as lag, so every
// clip is decoded up front and kept warm. Clips a child can retrigger quickly
// get a pool of more than one player so repeats overlap instead of cutting
// each other off (see SfxClip.poolSize).
//
// Web autoplay
// ------------
// Browsers refuse to play audio until the user has interacted with the page,
// and for HTML5 audio — which is what just_audio_web wraps — that permission
// is granted *per element*, not per document. So unlocking means starting and
// immediately pausing every pooled player once, from inside a real gesture.
// AudioUnlockScope does that on pointer-down.
//
// The one thing to know before touching that code again: **`play()` completes
// when playback ENDS, not when it starts.** Awaiting it to bless a player
// therefore waits out the entire clip. The first version of `unlock` did
// exactly that, sequentially, over 42 players — 11.7 seconds of sound effects
// before it even reached the counting ladder, then the twelve ladder notes
// blessed one every 0.55 s, and finally the music bed, whose `play()` under
// `LoopMode.one` never completes at all, so the unlock pass never finished.
//
// What a child heard: she tapped creatures and the rising counting tone was
// missing for the first several taps of a session, then arrived partway
// through, seemingly at random. `_bless` below is the fix, and it is why
// `play()` is deliberately not awaited there.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/sfx_catalog.dart';

/// How long a released bed keeps playing before it fades.
///
/// Generous on purpose. The window has to cover the worst screen change in the
/// app - a route swap where the next screen waits on a provider before the
/// runner that claims the bed is even built - and the cost of being too long
/// is that music trails a few seconds past the map, which nobody minds. The
/// cost of being too short is the music cutting out mid-lesson, which is the
/// bug this whole mechanism exists to prevent.
const Duration kMusicBedReleaseGrace = Duration(seconds: 5);

class SfxEngine {
  /// [playerFactory] is a test seam: inject a fake so unit tests can assert
  /// what would have been played without needing the audio plugin.
  SfxEngine({AudioPlayer Function()? playerFactory})
      : _newPlayer = playerFactory ?? AudioPlayer.new;

  final AudioPlayer Function() _newPlayer;

  final Map<Sfx, List<AudioPlayer>> _pools = <Sfx, List<AudioPlayer>>{};
  final Map<Sfx, int> _cursors = <Sfx, int>{};
  final List<AudioPlayer> _ladder = <AudioPlayer>[];
  AudioPlayer? _music;

  // Who owns the music bed
  // ----------------------
  // Nobody, is the short answer — the engine does. Every runner used to start
  // the bed on mount and stop it on dispose, so walking from one sub-mode into
  // the next tore the music down and rebuilt it from the top, and the lesson
  // in between played in silence. Three sections of one visit to the Sanctuary
  // sounded like three separate places.
  //
  // Instead a screen *claims* a bed and *releases* it, and a release is a
  // deferred stop. Re-claiming the same asset inside the grace window cancels
  // the stop and leaves playback exactly where it was, which is what makes a
  // route change inaudible.

  /// Asset currently loaded in the music player, or null when the bed is
  /// stopped. The identity is the asset rather than the variant key, so two
  /// lesson-authored names for one file don't restart each other.
  String? _bedAsset;

  /// The bed a screen currently *wants* playing, whether or not it is. Kept
  /// across a mute so that turning music back on resumes rather than waiting
  /// for the next screen to claim, and cleared only when a release actually
  /// expires.
  String? _claimedKey;

  /// How many screens are currently holding the bed.
  ///
  /// Usually one, and two for the length of a route transition — the incoming
  /// screen claims before the outgoing one is disposed. That overlap is the
  /// entire reason this is a count rather than a flag; see [releaseMusicBed].
  int _claims = 0;

  /// Pending release, if the last screen has let go and nothing has re-claimed
  /// yet.
  Timer? _bedRelease;

  /// Watches the bed for having stopped on its own.
  StreamSubscription<PlayerState>? _bedWatch;

  /// Bumped by every claim and every stop. A fade-out in flight checks it and
  /// bails, so a bed claimed mid-fade isn't stopped a moment later by the
  /// tail of the fade that was already running.
  int _bedGeneration = 0;

  bool _ready = false;
  bool _unlocked = false;
  Future<bool>? _unlockFuture;
  bool _disposed = false;
  Future<void>? _warmUpFuture;

  // Seeds only. AudioUnlockScope pushes the real levels down from the
  // settings providers as soon as the app is up, and again on every change.
  double _sfxVolume = kDefaultSfxVolume;
  double _musicVolume = kDefaultMusicVolume;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  /// Which rung of the counting ladder the current round is on. Reset between
  /// rounds so every round restarts at the bottom of the scale.
  int _ladderStep = 0;

  bool get isReady => _ready;

  /// True once every player has been granted the browser's autoplay
  /// permission. AudioUnlockScope keeps offering gestures until it is.
  bool get isUnlocked => _unlocked;

  /// Decode and buffer every clip. Call once at boot; safe to call again.
  Future<void> warmUp() {
    return _warmUpFuture ??= _warmUp();
  }

  /// One decoded, silent player for [asset].
  Future<AudioPlayer> _loaded(String asset) async {
    final player = _newPlayer();
    await player.setAsset(asset);
    await player.setVolume(0);
    return player;
  }

  Future<void> _warmUp() async {
    try {
      // Decoded in parallel, not one after another. Each `setAsset` on web is
      // a fetch and a decode; serialising 42 of them made time-to-first-sound
      // the sum of all of them instead of the slowest one.
      //
      // The counting ladder is awaited first because it is the only sound tied
      // to a tap the child makes in her first few seconds, so it should be the
      // first thing ready rather than whatever the catalog happens to list
      // last.
      _ladder.addAll(await Future.wait(kCountLadder.map(_loaded)));

      final entries = kSfxCatalog.entries.toList();
      final pools = await Future.wait(<Future<List<AudioPlayer>>>[
        for (final entry in entries)
          Future.wait(
            List<Future<AudioPlayer>>.generate(
              entry.value.poolSize,
              (_) => _loaded(entry.value.asset),
            ),
          ),
      ]);
      for (var i = 0; i < entries.length; i++) {
        _pools[entries[i].key] = pools[i];
      }

      final music = _newPlayer();
      await music.setLoopMode(LoopMode.one);
      await music.setVolume(0);
      _music = music;
      _watchBed(music);
      _ready = true;
    } catch (_) {
      // No audio on this platform (or no plugin under `flutter test`).
      // Everything below degrades to a no-op.
      _ready = false;
    }
    if (_disposed) await _disposeAll();
  }

  /// Restart the bed if it ever stops on its own.
  ///
  /// LoopMode.one should make this dead code: just_audio_web implements it by
  /// seeking to zero on the element's `ended` event. But a bed going quiet
  /// mid-session is close to invisible from the code and very obvious from the
  /// sofa, and the recovery costs one seek — so it is worth not depending on
  /// every platform getting the loop right.
  ///
  /// Guarded separately from _warmUp's own catch: a player that has no state
  /// stream (a test fake) must lose the watchdog, not the whole engine.
  void _watchBed(AudioPlayer music) {
    try {
      _bedWatch = music.playerStateStream.listen((PlayerState state) {
        if (state.processingState != ProcessingState.completed) return;
        if (_claimedKey == null || !_musicEnabled) return;
        // On its way out anyway; restarting it here would fight the fade.
        if (_bedRelease != null) return;
        unawaited(
          _guard(
            () async {
              await music.seek(Duration.zero);
              await music.setVolume(_musicVolume);
              unawaited(_guard(music.play()));
            }(),
          ),
        );
      });
    } catch (_) {
      // No state stream on this player. The bed simply does not self-heal.
    }
  }

  /// Every player the unlock pass should bless, ladder first.
  List<AudioPlayer> get _allPlayers => <AudioPlayer>[
        ..._ladder,
        ..._pools.values.expand((List<AudioPlayer> p) => p),
        // The music player is skipped while a bed is actually playing.
        // Blessing pauses and rewinds, so an unlock that only succeeds on the
        // third or fourth gesture - which is the whole point of retrying -
        // would otherwise stop the music the child is listening to. It needs
        // no grant in that state anyway: it could not be playing without one.
        if (_music != null && _bedAsset == null) _music!,
      ];

  /// Claim the browser's per-element autoplay grant for one player.
  ///
  /// `play()` is deliberately NOT awaited: it completes at the END of
  /// playback, so awaiting it here waits out the whole clip — and forever on
  /// the looping music bed. Starting playback is what earns the grant; pausing
  /// straight afterwards is what keeps it silent.
  Future<void> _bless(AudioPlayer player) async {
    // Never touch something that is already playing. Blessing pauses and
    // rewinds, and this pass can run late — AudioUnlockScope keeps offering
    // gestures until one succeeds — so without this guard an unlock that only
    // lands on the third tap would stop the music the child is listening to.
    // A playing element demonstrably has the grant already.
    //
    // In its own try: a player that cannot report its state has not been
    // playing anything, and must still be blessed rather than skipped.
    try {
      if (player.playing) return;
    } catch (_) {}
    try {
      await player.setVolume(0);
      unawaited(player.play());
      await player.pause();
      await player.seek(Duration.zero);
    } catch (_) {
      // One stubborn element shouldn't abort the rest of the pass.
    }
  }

  /// Grant the browser's per-element autoplay permission. MUST be called from
  /// inside a real user-gesture handler or the browser ignores it.
  ///
  /// Returns whether every player is now blessed. False means the clips were
  /// not decoded yet, and the caller should offer the next gesture — a browser
  /// only honours this close to a real interaction, so waiting inside one
  /// gesture for a decode that has not finished can spend the grant on
  /// nothing.
  Future<bool> unlock() {
    if (_unlocked) return Future<bool>.value(true);
    return _unlockFuture ??= _unlock()
      ..whenComplete(() => _unlockFuture = null);
  }

  Future<bool> _unlock() async {
    await warmUp();
    if (!_ready) return false;
    // All at once. Blessing is a pause and a seek per player, so the whole
    // pass is one frame's work rather than the eighteen seconds it took when
    // each player was waited out in turn.
    await Future.wait(_allPlayers.map(_bless));
    _unlocked = true;
    return true;
  }

  void play(Sfx id, {double volume = 1.0}) {
    if (!_ready || !_sfxEnabled) return;
    final pool = _pools[id];
    final clip = kSfxCatalog[id];
    if (pool == null || pool.isEmpty || clip == null) return;
    final index = (_cursors[id] ?? 0) % pool.length;
    _cursors[id] = index + 1;
    _fire(pool[index], clip.gain * _sfxVolume * volume);
  }

  /// Play the [step]-th note of the counting ladder (1-based).
  ///
  /// This is the counting mechanic made audible: the child hears the count
  /// climb. Steps past the end of the ladder clamp to the top note rather than
  /// going silent, so counting past twelve still sounds like something.
  void playCountStep(int step) {
    if (!_ready || !_sfxEnabled) return;
    if (_ladder.isEmpty || step < 1) return;
    final index = (step - 1).clamp(0, _ladder.length - 1);
    _ladderStep = step;
    _fire(_ladder[index], _sfxVolume * 0.75);
  }

  /// Play the next rung, wherever the round left off. Convenience for callers
  /// that don't already track the count themselves.
  void playNextCountStep() => playCountStep(_ladderStep + 1);

  /// Drop back to the bottom of the scale. Call at the start of every round.
  void resetCountLadder() => _ladderStep = 0;

  int get countLadderStep => _ladderStep;

  /// Claim the music bed for [variantKey].
  ///
  /// **Every call must be matched by exactly one [releaseMusicBed].** A screen
  /// that wants to change which bed it is asking for calls [switchMusicBed]
  /// instead — that is the same claim changing its mind, not a second one.
  ///
  /// Idempotent by asset: if that file is already playing this leaves the
  /// player completely alone, so the music does not restart. It also cancels
  /// any pending release, which is the half that carries the bed across the
  /// frame where the old screen is gone and the new one hasn't mounted.
  Future<void> startMusicBed(String variantKey) async {
    _claims++;
    return _claimBed(variantKey);
  }

  /// Point an existing claim at a different bed. Does not take a new claim.
  ///
  /// Only MusicBedScope.didUpdateWidget needs this: one screen whose bed key
  /// changed under it. Counting that as a fresh claim would leave the count
  /// permanently one too high and the music could never stop.
  Future<void> switchMusicBed(String variantKey) => _claimBed(variantKey);

  Future<void> _claimBed(String variantKey) async {
    _bedRelease?.cancel();
    _bedRelease = null;
    _bedGeneration++;
    // Recorded before the readiness checks so that a claim made while audio is
    // muted or still warming up is still a claim, and gets honoured the moment
    // the engine can honour it.
    _claimedKey = variantKey;
    if (!_ready || !_musicEnabled) return;
    final music = _music;
    if (music == null) return;
    final asset = kMusicBeds[variantKey] ?? kMusicBeds[kDefaultMusicBed];
    if (asset == null) return;
    if (_bedAsset == asset) {
      // Already ours. A release may have faded it part-way down before being
      // cancelled, so restore the level — but never the position.
      try {
        await music.setVolume(_musicVolume);
        // Not awaited: under LoopMode.one the bed never ends, so play() never
        // completes and awaiting it here never returns.
        if (!music.playing) unawaited(_guard(music.play()));
      } catch (_) {}
      return;
    }
    try {
      if (music.playing) await music.stop();
      await music.setAsset(asset);
      await music.setVolume(_musicVolume);
      _bedAsset = asset;
      // Not awaited, and this one bit for real: under LoopMode.one the bed
      // never ends, so `play()` never completes. Awaiting it here meant this
      // method never returned — harmless only because every caller already
      // dropped the future. See _bless() for the same trap.
      unawaited(_guard(music.play()));
    } catch (_) {
      _bedAsset = null;
    }
  }

  /// Give up one claim on the bed.
  ///
  /// The music stops only when the *last* claim is given up, and even then not
  /// immediately: it keeps playing for [grace] and only then fades out, so a
  /// screen that re-claims the same bed just after a route change is silent to
  /// the child. Actually leaving — back to the map, out of the activity —
  /// reaches the timer and the music ends.
  ///
  /// Counting claims is what makes this correct in both directions. Navigation
  /// does not tear the old screen down before building the new one: Flutter
  /// mounts the incoming route first and disposes the outgoing route as its
  /// transition finishes, so the real order of events is
  ///
  ///     claim(new screen) … release(old screen)
  ///
  /// and an unconditional deferred stop here would schedule the music to die a
  /// few seconds into a screen that is actively asking for it — with no later
  /// claim to cancel it, because the new screen already made its claim before
  /// the release was even scheduled. That is the "music played at the start of
  /// the lesson and then stopped once the taps began" report; it survived the
  /// first round of continuity work because the tests all rehearsed the
  /// opposite order.
  void releaseMusicBed({Duration grace = kMusicBedReleaseGrace}) {
    // Floored rather than asserted. An unmatched release means some screen
    // released twice or never claimed, and the safe failure is music that
    // outstays its welcome, not a crash in front of a five-year-old.
    if (_claims > 0) _claims--;
    if (_claims > 0) return;
    if (!_ready) return;
    if (_claimedKey == null && _bedAsset == null) return;
    _bedRelease?.cancel();
    _bedRelease = Timer(grace, () {
      _bedRelease = null;
      // Nobody wants it any more, as opposed to a mute — so the claim goes
      // too, and re-enabling music will not bring it back.
      _claimedKey = null;
      unawaited(stopMusicBed());
    });
  }

  /// How many screens currently hold the bed. Exposed for tests, which is
  /// where the claim/release balance is actually enforced.
  int get musicBedClaims => _claims;

  /// Stop the bed now. Prefer [releaseMusicBed] from a screen's dispose —
  /// this is for the settings toggle and teardown, where "now" is meant.
  Future<void> stopMusicBed({
    Duration fade = const Duration(milliseconds: 600),
  }) async {
    _bedRelease?.cancel();
    _bedRelease = null;
    final music = _music;
    if (!_ready || music == null) return;
    _bedAsset = null;
    final generation = ++_bedGeneration;
    try {
      const steps = 8;
      final startVolume = music.volume;
      for (var i = steps - 1; i >= 0; i--) {
        if (generation != _bedGeneration) return;
        await music.setVolume(startVolume * i / steps);
        await Future<void>.delayed(fade ~/ steps);
      }
      if (generation != _bedGeneration) return;
      await music.stop();
      await music.setVolume(_musicVolume);
    } catch (_) {}
  }

  /// Asset the bed is currently playing, or null. Exposed for tests.
  String? get musicBedAsset => _bedAsset;

  void setSfxVolume(double v) => _sfxVolume = v.clamp(0.0, 1.0);

  void setMusicVolume(double v) {
    _musicVolume = v.clamp(0.0, 1.0);
    final music = _music;
    if (_ready && music != null && music.playing) {
      unawaited(_guard(music.setVolume(_musicVolume)));
    }
  }

  void setSfxEnabled(bool enabled) => _sfxEnabled = enabled;

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      // Stops the sound but deliberately leaves _claimedKey alone: a mute is
      // not the screen letting go.
      unawaited(stopMusicBed(fade: const Duration(milliseconds: 250)));
      return;
    }
    // Turning music back on used to do nothing until the next screen change,
    // because nothing remembered what had been playing.
    final claimed = _claimedKey;
    if (claimed != null) unawaited(startMusicBed(claimed));
  }

  void _fire(AudioPlayer player, double volume) {
    // Fire-and-forget: a tap sound must never make a caller await. Rewinding
    // first is what lets the same player retrigger mid-clip.
    unawaited(
      _guard(
        () async {
          await player.setVolume(volume.clamp(0.0, 1.0));
          await player.seek(Duration.zero);
          await player.play();
        }(),
      ),
    );
  }

  Future<void> _guard(Future<void> future) async {
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _disposeAll() async {
    await _bedWatch?.cancel();
    _bedWatch = null;
    for (final player in <AudioPlayer>[
      ..._pools.values.expand((List<AudioPlayer> p) => p),
      ..._ladder,
      if (_music != null) _music!,
    ]) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    _pools.clear();
    _ladder.clear();
    _music = null;
    _bedAsset = null;
    _claimedKey = null;
    _ready = false;
  }

  void dispose() {
    _disposed = true;
    _bedRelease?.cancel();
    _bedRelease = null;
    unawaited(_disposeAll());
  }
}

final sfxEngineProvider = Provider<SfxEngine>((ref) {
  final engine = SfxEngine();
  ref.onDispose(engine.dispose);
  return engine;
});
