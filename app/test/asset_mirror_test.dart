// The app runs on a copy of the data, and the copy has to be current.
//
// Flutter web cannot load `../data/`, so `scripts/sync-assets.sh` mirrors the
// repo's `data/` and `content/` trees into `app/assets/`, and the app reads
// the mirror. Every edit to a registry or a lesson therefore takes two steps,
// and forgetting the second one is silent in the editor and loud in front of
// a child: four activities were added to the registry on 2026-09-24, the
// mirror was not re-synced, and opening any of them threw
// `No activity registered with id "care-pantry"` from the app bar. The tests
// that read the source registry all passed.
//
// The fix is one command, so the failure message is that command.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final tree in <String>['data', 'content']) {
    test('assets/$tree is an up-to-date copy of ../$tree', () {
      final source = Directory('../$tree');
      final stale = <String>[];
      var checked = 0;
      for (final f in source.listSync(recursive: true).whereType<File>()) {
        final rel = f.path
            .replaceAll(r'\', '/')
            .substring(source.path.replaceAll(r'\', '/').length + 1);
        if (!rel.endsWith('.json')) continue;
        checked++;
        final copy = File('assets/$tree/$rel');
        if (!copy.existsSync()) {
          stale.add('$rel (missing)');
        } else if (copy.readAsStringSync() != f.readAsStringSync()) {
          stale.add(rel);
        }
      }
      expect(checked, greaterThan(0), reason: 'read no source files');
      expect(
        stale,
        isEmpty,
        reason: 'the app reads app/assets/$tree, which is out of date. Run '
            'app/scripts/sync-assets.sh.',
      );
    });
  }
}
