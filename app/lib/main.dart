// CritMath app entry point. See specs/shared/system-architecture.md for the
// runtime architecture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'platform/sfx_engine.dart';
import 'platform/system_tts.dart';
import 'providers/save_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every scene in this game is composed wide. This is a real lock on iOS and
  // Android native and a no-op on web, where nothing can lock orientation -
  // see ui/scopes/landscape_gate.dart, which is the ask that has to stand in
  // for it on the iPad.
  unawaited(
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  );
  final container = ProviderContainer();
  final save = container.read(saveCoordinatorProvider);
  await save.hydrate();
  // Every change to anything saved is written from here on; nothing else in
  // the app has to remember to save.
  save.startAutosave();
  // Eagerly construct the TTS adapter so its async _init() starts running
  // before the first narration cue fires. Browser SpeechSynthesis especially
  // needs the warm-up to avoid clipping the first utterance.
  container.read(systemTtsProvider);
  // Decode every SFX clip up front. Not awaited — the maps render fine in
  // silence, and a child can't reach a sound-making screen before this
  // finishes. Waiting on it would just delay first paint.
  unawaited(container.read(sfxEngineProvider).warmUp());
  runApp(
    UncontrolledProviderScope(container: container, child: const CritMathApp()),
  );
}
