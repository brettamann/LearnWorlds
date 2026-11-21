// The clip key: the filename a spoken line is recorded or rendered under.
//
// Pure Dart, deliberately. This used to live in narration_audio.dart, which
// imports flutter/services, riverpod and just_audio - so anything wanting to
// name a clip had to drag the whole Flutter runtime in with it. That made
// `dart run tool/dump_narration_script.dart` impossible to compile, and the
// hashing is a string function with no business needing a widget toolkit.
//
// narration_audio.dart re-exports everything here, so every existing import
// keeps working unchanged.
//
// The transform is reimplemented in tools/tts/record/index.html for the
// browser recording harness. Shared vectors are pinned in
// app/test/narration_script_test.dart and tools/tts/record/check.mjs, so a
// drift on either side fails loudly rather than writing files the app never
// opens.

import 'dart:convert';

/// Where recorded clips live. A file's stem is its spoken text, keyed.
const String kNarrationClipDir = 'assets/audio/narration/';

/// How much of the sentence survives into the filename before the hash.
const int _kSlugMax = 48;

/// [text] with leading/trailing space removed and internal runs collapsed to a
/// single space.
///
/// Dart builds most of these lines by concatenating adjacent string literals
/// across source lines, so a reflow can change the whitespace without changing
/// a word. Normalising means that edit doesn't orphan a perfectly good clip.
/// Nothing else is normalised: punctuation and case change how a line is read
/// aloud, so they change the key.
String narrationTextNormalize(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Filename stem for a spoken line.
///
/// **Keyed by the words, not by the cueId.** cueIds encode *position* — the
/// same sentence has 25 of them ('parade:tap-r0-3' through 'parade:tap-r4-7'
/// are all some number word), and worse, a single cueId's text is not stable:
/// species are seeded per session, so 'parade:counting-prompt-r2' says "Touch
/// each fawn" today and "Touch each baby dragon" tomorrow. A clip filed under
/// a cueId would eventually play the wrong words. A clip filed under its text
/// cannot.
///
/// The stem is a readable slug plus a hash of the exact (normalised) sentence,
/// so a folder of two hundred takes is browsable by eye while collisions and
/// near-misses stay impossible. Editing a line's wording deliberately orphans
/// its recording — the recording says the old words — and the Settings export
/// reports orphans so you know what to re-cut.
///
/// The recording harness in tools/tts/record/ implements this byte-for-byte.
/// If you change it here, change it there; `narration_clip_key_test.dart`
/// pins shared vectors against both.
String narrationClipKey(String text) {
  final normal = narrationTextNormalize(text);
  var slug = normal
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > _kSlugMax) {
    slug = slug.substring(0, _kSlugMax).replaceAll(RegExp(r'-+$'), '');
  }
  if (slug.isEmpty) slug = 'line';
  final hash = narrationTextHash(normal).toRadixString(16).padLeft(8, '0');
  return '${slug}__$hash';
}

/// FNV-1a over the UTF-8 bytes of [text], as an unsigned 32-bit int.
///
/// Hashing bytes rather than code units is what lets the JS harness agree with
/// us about em dashes and curly apostrophes, which these lines are full of.
int narrationTextHash(String text) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(text)) {
    h = _mul32(h ^ b, 0x01000193);
  }
  return h;
}

/// 32-bit multiply via 16-bit halves.
///
/// A plain `a * b` overflows 2^53 here, and on web Dart ints are JS doubles —
/// so the straightforward version silently returns a different hash in a
/// release web build than it does in tests. Splitting the operands keeps every
/// intermediate under 2^33.
int _mul32(int a, int b) {
  final aLo = a & 0xFFFF;
  final bLo = b & 0xFFFF;
  final mid =
      ((aLo * ((b >> 16) & 0xFFFF)) + (((a >> 16) & 0xFFFF) * bLo)) & 0xFFFF;
  return ((aLo * bLo) + (mid << 16)) & 0xFFFFFFFF;
}

/// Sanitized-cueId -> asset path, for every recorded clip in [assetPaths].
///
/// Split out of the loader so the rules that actually bite — ignore the
/// .gitkeep holding the folder open, ignore every other asset tree — are
/// testable without standing up an asset bundle.
Map<String, String> narrationClipsFrom(Iterable<String> assetPaths) {
  final clips = <String, String>{};
  for (final asset in assetPaths) {
    if (!asset.startsWith(kNarrationClipDir)) continue;
    final name = asset.substring(kNarrationClipDir.length);
    // A nested folder is not a cue; the flat directory is the whole scheme.
    if (name.contains('/')) continue;
    final dot = name.lastIndexOf('.');
    // `dot <= 0` drops dotfiles (the .gitkeep) and extensionless strays.
    if (dot <= 0) continue;
    clips[name.substring(0, dot)] = asset;
  }
  return clips;
}
