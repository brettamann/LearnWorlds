// AudioUnlockScope — the app's audio root. Two jobs, both of which have to
// happen above every screen, which is why they share one widget:
//
//  1. Unlock playback. Browsers (and iOS Safari) refuse to play audio until
//     the user has interacted with the page, and for the HTML5 audio elements
//     just_audio_web wraps, that permission is per-element. So a pointer-down
//     anywhere in the app starts and immediately pauses every pooled player
//     once.
//
//     It keeps offering gestures until the engine reports success, rather than
//     firing once and hoping. The clips may still be decoding on the very
//     first touch, and a browser only honours the grant near a real
//     interaction — so a single one-shot attempt could spend the only gesture
//     it gets on players that were not loaded yet, and the counting tones
//     would stay silent for the rest of the session. Once it succeeds the
//     listener takes itself out of the hot path, as before.
//
//  2. Keep SfxEngine in sync with the user's audio settings, so no call site
//     ever has to check "is sound on?" before making a noise.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../platform/narration_audio.dart';
import '../../platform/sfx_engine.dart';
import '../../providers/audio_settings_provider.dart';

class AudioUnlockScope extends ConsumerStatefulWidget {
  const AudioUnlockScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AudioUnlockScope> createState() => _AudioUnlockScopeState();
}

class _AudioUnlockScopeState extends ConsumerState<AudioUnlockScope> {
  bool _unlocked = false;
  bool _attempting = false;

  @override
  void initState() {
    super.initState();
    // Seed the engine from the hydrated save before anything can play. The
    // `ref.listen`s in build() only fire on *changes*, so without this a saved
    // "sound off" wouldn't take effect until the setting was next touched.
    final engine = ref.read(sfxEngineProvider);
    engine
      ..setSfxEnabled(ref.read(sfxEnabledProvider))
      ..setMusicEnabled(ref.read(musicEnabledProvider))
      ..setSfxVolume(ref.read(sfxVolumeProvider))
      ..setMusicVolume(ref.read(musicVolumeProvider));
    // Recorded narration clips are discovered from the asset manifest. Kick
    // it off here so the first spoken line already knows whether it has a
    // human voice available; it no-ops on a build with no recordings.
    unawaited(ref.read(narrationAudioProvider).load());
  }

  Future<void> _onPointerDown(PointerDownEvent _) async {
    if (_unlocked || _attempting) return;
    // Guarded rather than latched: a fast double-tap must not start two passes
    // over the same players, but a tap after a *failed* pass has to be allowed
    // to try again.
    _attempting = true;
    // Narration owns its own audio element, so the browser's per-element
    // autoplay grant has to be claimed for it separately.
    unawaited(ref.read(narrationAudioProvider).unlock());
    final ok = await ref.read(sfxEngineProvider).unlock();
    _attempting = false;
    if (ok && mounted) setState(() => _unlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(sfxEngineProvider);

    // Push settings down rather than having the engine read providers: it's a
    // platform adapter and shouldn't know Riverpod exists beyond its own
    // provider declaration.
    ref.listen<bool>(
      sfxEnabledProvider,
      (_, next) => engine.setSfxEnabled(next),
    );
    ref.listen<bool>(
      musicEnabledProvider,
      (_, next) => engine.setMusicEnabled(next),
    );
    ref.listen<double>(
      sfxVolumeProvider,
      (_, next) => engine.setSfxVolume(next),
    );
    ref.listen<double>(
      musicVolumeProvider,
      (_, next) => engine.setMusicVolume(next),
    );

    if (_unlocked) return widget.child;
    return Listener(
      onPointerDown: _onPointerDown,
      // Translucent so the unlock listener sees the gesture without eating it —
      // the child's first tap still does whatever it was going to do.
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
