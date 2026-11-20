// Every sound in the catalog is a sound the game makes.
//
// Six of the fifteen were not. `uiTap`, `whoosh`, `bubbleIn`, `eggCrack`,
// `drop`, `buddyHappy` and `buddyCurious` had been authored, generated,
// declared in `pubspec.yaml` and shipped into every build — about 125 KB of
// audio downloaded by every player — and played by nothing. (`uiTap` had one
// call site, in the character creator, which is worse in its way: it meant
// pressing a control made a sound on exactly one screen and nowhere else, so
// the arrow that ends every round in every activity was silent.)
//
// Nothing could catch that. A cue with no call site is not an error, an
// unused enum value is not a lint, and the symptom is an absence — which is
// the hardest kind of bug to notice in a game you have played a hundred times
// and know what is supposed to happen next.
//
// So the check is here, and it is deliberately crude: it reads the source for
// a mention of each cue outside the catalog that declares it. A cue can still
// be wired to the wrong beat, and this will not say so. What it will say is
// that somebody added a sound and forgot to play it, which is the failure that
// actually happened.
//
// It strips comments first, and that is not fastidiousness. The first version
// did not, and it passed while `Sfx.drop` was unplayed — because the doc
// comment on the method that plays it says the words "Sfx.drop had no call
// site". A guard written about a bug, satisfied by the sentence describing the
// bug.

import 'dart:io';

import 'package:critmath/data/sfx_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Source with `//` and `/* */` comments removed, so prose about a cue does
/// not count as playing it. Crude — it does not know about string literals —
/// which is fine here: a `//` inside a string is a URL, and no cue name is.
String _stripComments(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      final nl = source.indexOf(String.fromCharCode(10), i);
      i = nl == -1 ? source.length : nl;
      continue;
    }
    if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      i = end == -1 ? source.length : end + 2;
      continue;
    }
    out.write(source[i]);
    i++;
  }
  return out.toString();
}

/// Every `.dart` file under `lib/`, keyed by its repo-relative path.
Map<String, String> _sources() {
  final out = <String, String>{};
  for (final file in Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final path = file.path.replaceAll(r'\', '/');
    out[path.substring(path.indexOf('lib/'))] =
        _stripComments(file.readAsStringSync());
  }
  return out;
}

void main() {
  test('every cue is played by something', () {
    final sources = _sources();
    final dead = <String>[];
    for (final cue in Sfx.values) {
      // The unlock blip is played by SfxEngine itself, inside the first
      // pointer-down, and is silent by design.
      if (cue == Sfx.silence) continue;
      final needle = 'Sfx.${cue.name}';
      final played = sources.entries.any(
        (e) => e.key != 'lib/data/sfx_catalog.dart' && e.value.contains(needle),
      );
      if (!played) dead.add(cue.name);
    }
    expect(
      dead,
      isEmpty,
      reason: 'these sounds are bundled into every build and played by '
          'nothing: $dead',
    );
  });

  test('and the file it points at is really there', () {
    for (final entry in kSfxCatalog.entries) {
      expect(
        File(entry.value.asset).existsSync(),
        isTrue,
        reason: '${entry.key.name} points at ${entry.value.asset}, which is '
            'not in the repo',
      );
    }
  });

  test('and no two cues share one', () {
    // Two cues on one file is one cue with two names, and the second is a
    // slot someone will later assume has its own sound.
    final assets = kSfxCatalog.values.map((c) => c.asset).toList();
    expect(assets.toSet(), hasLength(assets.length));
  });

  test('the tap sound is wired once, centrally', () {
    // It used to be called from the character creator and nowhere else. The
    // fix is not "call it in more places" — it is that ReadAloudGate wraps
    // every piece of chrome in the game already, so one call there covers all
    // of it. If that moves back out to call sites this will notice.
    final gate = _sources()['lib/ui/widgets/read_aloud_gate.dart']!;
    expect(
      gate,
      contains('uiTap()'),
      reason: 'the one wrapper every control goes through no longer makes a '
          'sound, so most controls no longer do',
    );
  });

  test('the catalog is not bigger than the folder it reads from', () {
    // The other direction: a clip on disk that no cue names is dead weight in
    // the bundle, and pubspec ships the folder wholesale.
    final named = kSfxCatalog.values.map((c) => c.asset).toSet();
    final onDisk = Directory('assets/audio/sfx')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll(r'\', '/'))
        .map((p) => p.substring(p.indexOf('assets/')))
        // The counting ladder is addressed by index rather than by cue.
        .where((p) => !p.contains('/counting/'))
        .toSet();
    expect(
      onDisk.difference(named),
      isEmpty,
      reason: 'clips in the bundle that no cue names',
    );
  });
}
