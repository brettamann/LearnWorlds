// CritMath app entry point. See specs/shared/system-architecture.md for the
// runtime architecture.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'platform/system_tts.dart';
import 'providers/save_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(saveCoordinatorProvider).hydrate();
  // Eagerly construct the TTS adapter so its async _init() starts running
  // before the first narration cue fires. Browser SpeechSynthesis especially
  // needs the warm-up to avoid clipping the first utterance.
  container.read(systemTtsProvider);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CritMathApp(),
    ),
  );
}
