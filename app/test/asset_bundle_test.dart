// Declared means opened, and opened means declared.
//
// `pubspec.yaml`'s asset list is the only statement anywhere of what the app
// carries, and it drifted in both directions.
//
// The direction that crashes: a path built in `asset_paths.dart` that no
// entry covers throws "Unable to load asset" the first time a child reaches
// that screen, and only that screen - so it survives a full test run and a
// manual pass that did not happen to open it. Nothing was wrong here when
// this was written, which is the point of pinning it.
//
// The direction that misleads: five data directories were being bundled that
// the app never opened - `reward-catalog`, `telemetry-catalog`,
// `standards-reference`, `slot-vocabulary`, and `content/strings`. The last
// of those had a helper, `AssetPaths.activityStrings`, whose only caller was
// its own definition, and 155 authored narration cues behind it. Two of those
// 155 are lines the game says. The rest are older text - written before the
// fiction reframe, still calling the companion "the Buddy" - templated on 68
// slots with no resolver, one of which is the name the child gives her own
// Buddy and therefore a line no recorded clip can ever exist for. Wiring them
// up was a plan item; measuring them is what retired it. See
// `specs/shared/localization.md`.
//
// Those files are all still in the repo. They are source and reference
// material - the data validator reads them, the specs cite them - and
// re-declaring one is a one-line change on the day something loads it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The asset entries in `pubspec.yaml`, in order.
List<String> _declared() {
  final out = <String>[];
  var inBlock = false;
  for (final raw in File('pubspec.yaml').readAsLinesSync()) {
    if (RegExp(r'^\s*assets:\s*$').hasMatch(raw)) {
      inBlock = true;
      continue;
    }
    if (!inBlock) continue;
    final entry = RegExp(r'^\s*-\s*(\S+)\s*$').firstMatch(raw);
    if (entry != null) {
      out.add(entry.group(1)!);
      continue;
    }
    final blank = raw.trim().isEmpty;
    final comment = raw.trim().startsWith('#');
    // A non-indented, non-comment line ends the block.
    if (!blank && !comment && !raw.startsWith('    ')) break;
  }
  return out;
}

/// Every `assets/...` string literal anywhere in `lib/`.
///
/// Stops at a `$` so that an interpolated path contributes the literal
/// prefix it is built from, which is the part an asset entry has to cover.
Set<String> _referenced() {
  final out = <String>{};
  final pattern = RegExp(r"'(assets/[^'$]*)");
  for (final file
      in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    for (final m in pattern.allMatches(file.readAsStringSync())) {
      out.add(m.group(1)!);
    }
  }
  return out;
}

void main() {
  final declared = _declared();
  final referenced = _referenced();

  test('the asset list was actually found', () {
    // Every check below passes vacuously against an empty list, and the
    // parser above is regex over YAML.
    expect(declared.length, greaterThan(15));
    expect(referenced.length, greaterThan(50));
  });

  test('every path the app builds is covered by an entry', () {
    final uncovered = <String>[];
    for (final path in referenced) {
      final dir = '${path.substring(0, path.lastIndexOf('/'))}/';
      if (declared.any(dir.startsWith)) continue;
      uncovered.add(path);
    }
    expect(
      uncovered,
      isEmpty,
      reason:
          'built in lib/ and not in the bundle. This throws "Unable to '
          'load asset" on the one screen that opens it, so a test run that '
          'does not reach that screen will not notice.',
    );
  });

  test('every entry is a directory the app opens', () {
    final unopened = <String>[];
    for (final entry in declared) {
      if (referenced.any((r) => r.startsWith(entry) || entry.startsWith(r))) {
        continue;
      }
      unopened.add(entry);
    }
    expect(
      unopened,
      isEmpty,
      reason:
          'declared and never opened. Either something should load it, '
          'or it is repo material rather than runtime content and the entry '
          'should go - a bundle that claims to carry narration the app has '
          'never read is how a whole refactor got planned around it.',
    );
  });

  test('everything declared exists on disk', () {
    // Flutter fails the build on a declared-but-missing directory, which is
    // a slow way to find out; the pubspec says so in a comment and this says
    // so in a second.
    for (final entry in declared) {
      final path = entry.endsWith('/')
          ? entry.substring(0, entry.length - 1)
          : entry;
      expect(
        Directory(path).existsSync() || File(path).existsSync(),
        isTrue,
        reason: '$entry is declared and is not there',
      );
    }
  });
}
