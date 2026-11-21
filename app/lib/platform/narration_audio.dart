// NarrationAudio — recorded voice lines, when they exist.
//
// specs/shared/text-and-tts-deferral.md defers the ElevenLabs render pipeline,
// which left the app speaking every line through the OS text-to-speech voice:
// one flat synth timbre for the keeper, the narrator and the numbers alike. A
// child tunes that out fast, and for a pre-reader the voice is half of the
// entire interface.
//
// The way out doesn't need the pipeline. This class looks a cueId up against
// whatever recorded clips happen to be bundled and plays one if it finds it;
// NarrationPlayer falls back to system TTS when it doesn't. That makes
// recording *incremental* — every clip dropped into
// `assets/audio/narration/` makes the game a little warmer, and none of them
// are required for anything to work.
//
// There is deliberately no manifest file to build. The set of clips is read
// straight off Flutter's own AssetManifest at boot, so the workflow is: record
// a line, drop the file in the folder, rebuild. Adding a JSON index between
// those two steps would be one more thing to forget.
//
// Monophonic on purpose: one narration line is audible at a time and a new one
// interrupts the last, matching SystemTts's own semantics so the two paths are
// interchangeable.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'narration_clip_key.dart';

// Re-exported so `import 'platform/narration_audio.dart'` still brings the
// clip key with it, as it did when the two lived in one file.
export 'narration_clip_key.dart';

class NarrationAudio {
  /// [playerFactory] and [bundle] are test seams, matching SfxEngine's shape.
  NarrationAudio({AudioPlayer Function()? playerFactory, AssetBundle? bundle})
    : _newPlayer = playerFactory ?? AudioPlayer.new,
      _bundle = bundle ?? rootBundle;

  final AudioPlayer Function() _newPlayer;
  final AssetBundle _bundle;

  /// Clip key -> asset path.
  final Map<String, String> _clips = <String, String>{};

  AudioPlayer? _player;
  Future<void>? _loadFuture;
  bool _ready = false;
  bool _disposed = false;
  double _volume = 1.0;

  /// True once at least one recorded clip has been found. False forever on a
  /// build with no recordings, which is the state this ships in.
  bool get isReady => _ready;

  int get clipCount => _clips.length;

  /// Every clip key present in the bundle. The Settings export diffs this
  /// against the script to report which recordings are orphaned.
  Set<String> get clipKeys => _clips.keys.toSet();

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
      _clips.addAll(narrationClipsFrom(manifest.listAssets()));
      if (_clips.isEmpty) return;
      _player = _newPlayer();
      _ready = true;
    } catch (_) {
      // No asset bundle, no plugin, or a malformed manifest. Everything below
      // degrades to a no-op and the caller falls back to TTS.
      _ready = false;
    }
    if (_disposed) await _disposeAll();
  }

  /// Whether a recording exists for [text]. Cheap enough to call on the
  /// speech path.
  bool has(String text) => _ready && _clips.containsKey(narrationClipKey(text));

  /// Grant the browser's per-element autoplay permission, the same way
  /// SfxEngine does. Must run inside a real user-gesture handler.
  Future<void> unlock() async {
    await load();
    final player = _player;
    if (!_ready || player == null) return;
    try {
      // There is nothing loaded yet, so the unlock has to ride on the first
      // real clip. Loading one silently is enough to bless the element.
      await player.setAsset(_clips.values.first);
      await player.setVolume(0);
      // NOT awaited: just_audio's play() completes when playback *ends*, so
      // awaiting it here waited out a whole narration clip — up to ten
      // seconds of nothing before the element was usable. See SfxEngine._bless
      // for the same bug and the same fix.
      unawaited(player.play());
      await player.pause();
      await player.seek(Duration.zero);
      await player.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> play(String text) async {
    final player = _player;
    final asset = _clips[narrationClipKey(text)];
    if (!_ready || player == null || asset == null) return;
    try {
      await player.stop();
      await player.setAsset(asset);
      await player.setVolume(_volume);
      await player.play();
    } catch (_) {}
  }

  Future<void> stop() async {
    final player = _player;
    if (!_ready || player == null) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  void setVolume(double v) => _volume = v.clamp(0.0, 1.0);

  Future<void> _disposeAll() async {
    final player = _player;
    _player = null;
    _ready = false;
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    unawaited(_disposeAll());
  }
}

final narrationAudioProvider = Provider<NarrationAudio>((ref) {
  final audio = NarrationAudio();
  ref.onDispose(audio.dispose);
  return audio;
});
