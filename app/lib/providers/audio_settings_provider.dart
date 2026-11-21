// Audio settings — per-device toggles and levels for SFX and the music bed.
//
// Mirrors tts_settings_provider.dart: plain Notifiers, persisted by
// SaveCoordinator, defaulted ON. Sound is the primary feedback channel for a
// pre-reading player, so a fresh install must make noise without anyone
// visiting settings first.
//
// Music defaults quieter than SFX because it sits underneath narration — the
// bed is atmosphere, and it must never compete with the voice telling a child
// what to do.
//
// [kDefaultMusicVolume] is the one place that number lives. The save blob
// reads it too, and treats a stored value equal to a *previous* default as
// never having been chosen — see kSupersededMusicVolumes in save_provider.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sfx_catalog.dart';
import 'setting_notifiers.dart';

final sfxEnabledProvider = NotifierProvider<BoolSetting, bool>(BoolSetting.new);
final musicEnabledProvider = NotifierProvider<BoolSetting, bool>(
  BoolSetting.new,
);
final sfxVolumeProvider = NotifierProvider<VolumeSetting, double>(
  () => VolumeSetting(kDefaultSfxVolume),
);
final musicVolumeProvider = NotifierProvider<VolumeSetting, double>(
  () => VolumeSetting(kDefaultMusicVolume),
);
