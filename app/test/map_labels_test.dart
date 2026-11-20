// The maps speak in the narrator's voice, not the browser's.
//
// This is a regression test for a bug that was invisible from inside the code
// and obvious the moment anyone opened the app: 'Mystic Sanctuary' and
// 'Welcome' — the first two things a five-year-old taps in a session — were
// still being read by the OS synth long after every other line in the game had
// been rendered by Kokoro. Nothing was broken. The clips simply did not exist,
// because neither source the renderer reads could see those two strings, and
// no gate anywhere reports "this line has no recording".
//
// So the gate is here. Each of these asserts one link in the chain from a
// label on a map to an mp3 on disk, and any of them breaking means a line has
// quietly fallen back to the browser voice.

import 'dart:convert';
import 'dart:io';

import 'package:critmath/data/map_labels.dart';
import 'package:critmath/data/narration_script.dart';
import 'package:critmath/platform/narration_clip_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// Display names off the activity registry, the same way
/// `tool/dump_narration_script.dart` reads them. Duplicated rather than
/// imported because that file is a script with a `main`, and a test that
/// imports it would run its argument handling.
List<String> _activityDisplayNames() {
  final dir = Directory('assets/data/activity-registry');
  final out = <String>{};
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) continue;
    final decoded = jsonDecode(file.readAsStringSync());
    final activities = (decoded as Map)['activities'];
    for (final activity in (activities as List).cast<Map<String, dynamic>>()) {
      final name = activity['displayName'];
      if (name is String) out.add(name);
    }
  }
  return out.toList()..sort();
}

/// The clip the app would look for, or null if nothing is rendered for [text].
File? _clipFor(String text) {
  final dir = Directory('assets/audio/narration');
  if (!dir.existsSync()) return null;
  final key = narrationClipKey(text);
  for (final file in dir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('$key.')) return file;
  }
  return null;
}

void main() {
  test('every map label is in the recording script', () {
    final script = narrationScriptTexts();
    for (final label in kSpokenMapLabels) {
      expect(
        script,
        contains(label),
        reason: '"$label" is spoken by ReadAloudGate but the renderer will '
            'never see it, so it will speak in the browser voice',
      );
    }
  });

  test('every map label has a rendered clip', () {
    for (final label in kSpokenMapLabels) {
      expect(
        _clipFor(label),
        isNotNull,
        reason: 'no clip for "$label". Re-render:\n'
            '  cd app && dart run tool/dump_narration_script.dart '
            '> ../tools/tts/kokoro/script.json\n'
            '  node tools/tts/kokoro/render.mjs render',
      );
    }
  });

  test('every activity name on the map has a rendered clip', () {
    // These come from the registry JSON rather than Dart, so nothing about
    // renaming an activity would otherwise tell you its banner went silent.
    final names = _activityDisplayNames();
    expect(names, isNotEmpty, reason: 'the activity registry looks empty');
    for (final name in names) {
      expect(_clipFor(name), isNotNull, reason: 'no clip for "$name"');
    }
  });

  test('the map screens use the catalog rather than inline labels', () {
    // The whole reason the two labels went unrendered is that they were typed
    // where no enumeration could reach them. A third one typed inline next
    // week would fail exactly the same way and just as silently, so this
    // reads the source rather than trusting the convention.
    const screens = <String>[
      'lib/ui/screens/home_map_screen.dart',
      'lib/ui/screens/sanctuary_map_screen.dart',
    ];
    final inlineLabel = RegExp(r'''label:\s*['"]''');
    for (final path in screens) {
      final source = File(path).readAsStringSync();
      expect(
        inlineLabel.hasMatch(source),
        isFalse,
        reason: '$path has a `label:` with a string literal. Map labels are '
            'spoken, so they belong in data/map_labels.dart where the '
            'narration script can enumerate them.',
      );
    }
  });

  test('the labels are distinct, so no two places share a clip', () {
    final texts = <String>[...kSpokenMapLabels, ..._activityDisplayNames()];
    expect(texts.toSet(), hasLength(texts.length));
  });
}
