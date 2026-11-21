// TtsEnabled — per-device opt-in flag for system TTS during the voice
// deferral period. Defaults to ON because the project is currently in the
// deferral window (per text-and-tts-deferral.md, voiced files aren't being
// produced yet, so kids need *some* audio); flip to OFF once pre-rendered
// audio replaces system TTS, or whenever a parent prefers silent captions.
//
// Persisted by SaveCoordinator.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setting_notifiers.dart';

final ttsEnabledProvider = NotifierProvider<BoolSetting, bool>(BoolSetting.new);
