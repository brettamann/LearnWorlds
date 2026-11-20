// A claim on the music bed has to be given back exactly once.
//
// SfxEngine counts claims, because during a route change two screens hold the
// bed at the same time — Flutter mounts the incoming route before it disposes
// the outgoing one, and a release that assumed sole ownership would schedule
// the music to stop a few seconds into a screen that was still asking for it.
// See music_bed_handoff_test.dart for that behaviour under a real router.
//
// The counting only works while the books balance, and an unmatched release
// does not fail loudly: it gives away somebody else's claim, so the music stops
// one screen early, somewhere else entirely, with nothing pointing back at the
// screen that miscounted. So the shape is checked in the source, the way
// map_labels_test checks that place names are never inlined.
//
// This is a lint, not a parser — it reads for the two shapes that have actually
// gone wrong rather than trying to understand the code.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart file under lib/.
List<File> _libSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// Counts calls to [method], ignoring its own declaration and doc comments.
int _callsTo(String source, String method) =>
    RegExp('[.]$method[(]').allMatches(source).length;

/// The body of every `addPostFrameCallback(...)` in [source], found by matching
/// parentheses from the call rather than by regex — the callbacks are nested
/// and multi-line, and a regex over them is a guess.
Iterable<String> _postFrameBodies(String source) sync* {
  var from = 0;
  while (true) {
    final start = source.indexOf('addPostFrameCallback(', from);
    if (start < 0) return;
    var depth = 0;
    var i = source.indexOf('(', start);
    for (; i < source.length; i++) {
      if (source[i] == '(') depth++;
      if (source[i] == ')') {
        depth--;
        if (depth == 0) break;
      }
    }
    yield source.substring(start, i.clamp(start, source.length));
    from = i + 1;
  }
}

void main() {
  test('every screen that releases the bed also claims it, once each', () {
    // A file-level count rather than a per-widget one. Two runners live in
    // shape_garden_runner.dart, so the numbers are 2 and 2 there; what matters
    // is that they match.
    final wrong = <String>[];
    for (final file in _libSources()) {
      final source = file.readAsStringSync();
      final claims = _callsTo(source, 'startMusicBed');
      final releases = _callsTo(source, 'releaseMusicBed');
      if (claims == releases) continue;
      // The engine itself and its two direct callers are allowed to be
      // lopsided: sfx_engine.dart defines them, and audio_settings_provider
      // consumers only ever toggle.
      if (file.path.endsWith('sfx_engine.dart')) continue;
      wrong.add('${file.path}: $claims claims, $releases releases');
    }
    expect(
      wrong,
      isEmpty,
      reason: 'a claim never given back means the music outlives every screen; '
          'a release never claimed cuts short the next screen\'s music',
    );
  });

  test('no claim is taken from inside a post-frame callback', () {
    // The bug this replaced. Every runner claimed inside
    //   addPostFrameCallback((_) { if (!mounted) return; ... })
    // and released unconditionally in dispose(), so a screen torn down before
    // its first frame gave back a claim it had never taken. Nothing about
    // startMusicBed needs a frame; claiming beside the dispose-time engine
    // reference is what makes the pair unconditional on both ends.
    final offenders = <String>[];
    for (final file in _libSources()) {
      for (final body in _postFrameBodies(file.readAsStringSync())) {
        if (body.contains('startMusicBed')) offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'claim it in initState instead, next to the engine reference '
          'kept for dispose',
    );
  });

  test('the lint can actually see a claim', () {
    // A path typo or a rename would make both tests above pass by finding
    // nothing at all, which is the usual way a source lint dies.
    //
    // It used to ask for more than ten claims, which stopped being a fixed
    // point once the runners moved onto SanctuaryRoundShell and their claims
    // became its one. So it asks for the claims it must be able to see: the
    // shell's, and the lesson screen's.
    final claimers = <String>{
      for (final f in _libSources())
        if (_callsTo(f.readAsStringSync(), 'startMusicBed') > 0)
          f.uri.pathSegments.last,
    };
    expect(
      claimers,
      containsAll(<String>['sanctuary_round_shell.dart', 'lesson_screen.dart']),
      reason: 'the lint is reading no source',
    );
  });
}
