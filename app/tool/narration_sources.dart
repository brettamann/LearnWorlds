// Finds spoken lines that live in Dart source rather than in a catalog.
//
// Why this exists: `narration_script.dart` enumerates what the runners
// *compose* from catalogs, and the lesson JSON holds the I-Show/We-Try script,
// but a third of the game's narration is neither. It is plain string literals -
// Haddock's opening monologue in `sanctuary_cutscene_screen`, the `keeperLine`
// on every const round, the mystery-egg dialog. Those were still speaking in
// the browser voice long after everything else had been rendered, which is a
// bad failure to leave lying around: it is not silence, it is a jarring switch
// of voice mid-session.
//
// Classifying the 90 `NarrationLine(...)` sites showed why static extraction of
// the `text:` argument alone cannot work - 60 of them pass an identifier
// (`_pages[_page]`, `_currentRound.keeperLine`, `_introDialog`) rather than a
// literal, and resolving those means resolving arbitrary Dart. So this goes the
// other way round: lex every string literal out of `lib/`, then keep the ones
// that read like something a person says.
//
// The filter is deliberately generous. A false positive costs one ~30KB clip
// that nothing ever plays, and rendering is free; a false negative is a line
// that speaks in the wrong voice in front of a child. When in doubt, include.

import 'dart:io';

/// One string literal found in source, with enough context to judge it.
class _Literal {
  _Literal(this.value, this.interpolated);
  final String value;
  final bool interpolated;
}

const String _backslash = r'\';

/// Reads one string literal starting at [start], which must be a quote.
///
/// Returns the decoded value, whether it interpolated, and the index just past
/// the closing quote.
({String value, bool interpolated, int next}) _readLiteral(
  String source,
  int start,
) {
  final n = source.length;
  final quote = source[start];
  final raw = start > 0 && source[start - 1] == 'r';
  final triple =
      start + 2 < n && source[start + 1] == quote && source[start + 2] == quote;
  final delim = triple ? quote * 3 : quote;

  var i = start + delim.length;
  final buffer = StringBuffer();
  var interpolated = false;

  while (i < n) {
    if (!raw && source[i] == _backslash && i + 1 < n) {
      // Keep the escaped character, drop the backslash, so an escaped
      // apostrophe reads as one - which is what the clip key has to hash.
      final next = source[i + 1];
      const escapes = <String, String>{'n': '\n', 't': '\t', 'r': '\r'};
      buffer.write(escapes[next] ?? next);
      i += 2;
      continue;
    }
    if (!raw && source[i] == r'$') interpolated = true;
    if (source.startsWith(delim, i)) {
      i += delim.length;
      break;
    }
    // An unescaped newline ends a single-quoted literal; treat that as a
    // lexing failure rather than running on to the end of the file.
    if (!triple && source[i] == '\n') break;
    buffer.write(source[i]);
    i++;
  }

  return (value: buffer.toString(), interpolated: interpolated, next: i);
}

/// Lexes Dart string literals out of [source].
///
/// A regex cannot do this correctly: Dart has single and double quotes, triple
/// quotes, raw strings, escapes, and `'a' 'b'` adjacent concatenation, and the
/// literals here contain apostrophes and em dashes. Comments are skipped so a
/// commented-out line is never rendered.
///
/// Adjacent concatenation is joined with an inner loop rather than by recursing
/// on the rest of the file. The recursive version was correct and quadratic -
/// it re-lexed every remaining byte once per literal, which took the test suite
/// from three seconds to six minutes and forty-four.
List<_Literal> _lex(String source) {
  final out = <_Literal>[];
  var i = 0;
  final n = source.length;

  bool isSpace(String c) => c == ' ' || c == '\n' || c == '\r' || c == '\t';
  bool isQuote(String c) => c == "'" || c == '"';

  while (i < n) {
    final ch = source[i];

    // Comments.
    if (ch == '/' && i + 1 < n) {
      if (source[i + 1] == '/') {
        while (i < n && source[i] != '\n') {
          i++;
        }
        continue;
      }
      if (source[i + 1] == '*') {
        i += 2;
        while (i + 1 < n && !(source[i] == '*' && source[i + 1] == '/')) {
          i++;
        }
        i += 2;
        continue;
      }
    }

    if (!isQuote(ch)) {
      i++;
      continue;
    }

    // Dart concatenates adjacent literals. `'one ' 'two'` is one sentence, and
    // most long lines in this codebase are wrapped that way.
    final buffer = StringBuffer();
    var interpolated = false;
    while (i < n && isQuote(source[i])) {
      final piece = _readLiteral(source, i);
      buffer.write(piece.value);
      interpolated = interpolated || piece.interpolated;
      i = piece.next;

      var look = i;
      while (look < n && isSpace(source[look])) {
        look++;
      }
      if (look < n && isQuote(source[look])) {
        i = look;
        continue;
      }
      break;
    }

    out.add(_Literal(buffer.toString(), interpolated));
  }
  return out;
}

/// True if [text] reads like something the narrator says out loud.
bool _soundsSpoken(String text) {
  final trimmed = text.trim();
  if (trimmed.length < 6 || trimmed.length > 300) return false;

  // Must contain at least two words.
  if (!trimmed.contains(' ')) return false;

  // Paths, ids, keys, code fragments.
  if (RegExp(r'^(assets/|package:|http|lib/|data/)').hasMatch(trimmed)) {
    return false;
  }
  if (RegExp(r'[<>{}\[\]|]|=>|\|\||&&|::').hasMatch(trimmed)) return false;
  if (trimmed.contains('  ')) return false;

  // Identifier-ish: kebab or snake ids, cue names like `parade:tap-r0-3`.
  if (RegExp(r'^[a-z0-9]+([-_:][a-z0-9]+)+$').hasMatch(trimmed)) return false;

  // Real prose has a lowercase letter somewhere and starts like a sentence.
  if (!RegExp('[a-z]').hasMatch(trimmed)) return false;
  if (!RegExp(r'''^["'‘“A-Z0-9]''').hasMatch(trimmed)) return false;

  // Ends like a sentence. This is the strongest single signal, and it is what
  // separates 'Six fawns! Now some gryphons are catching up.' from a debug
  // string or a semantic label.
  if (!RegExp(r'[.!?…]$').hasMatch(trimmed)) return false;

  // Developer-facing strings that end in a full stop but are never spoken.
  const codeish = <String>[
    'TODO',
    'deprecated',
    'assert',
    'Exception',
    'Error:',
    'null.',
    'true.',
    'false.',
  ];
  if (codeish.any(trimmed.contains)) return false;

  return true;
}

/// Every spoken-sounding literal under [root], deduplicated and sorted.
///
/// Interpolated literals are dropped: a template is not a line, and its
/// variants have to be enumerated from the catalog that fills the slot - which
/// is what `narration_script.dart` does. `NarrationCueLog` records anything
/// neither source reaches, as it is heard.
List<String> dartNarrationLiterals(String root) {
  final seen = <String>{};

  final files = Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final source = file.readAsStringSync();

    // Only look in files that either speak, or hold the catalogs the speakers
    // read from. Without this the sweep also picks up UI copy that merely
    // reads like a sentence - the Settings reset description, a picker
    // subtitle - and renders a voice clip nothing will ever play.
    //
    // `lib/data/` is included wholesale because the strings there are consumed
    // elsewhere: `build_a_habitat_blueprints.dart` holds keeperLines the
    // habitat runner speaks, and `wheres_buddy_words.dart` holds the position
    // phrases. Neither file mentions narration at all.
    final speaks = source.contains('NarrationLine(') ||
        source.contains('narrationPlayerProvider') ||
        source.contains('narration.say(');
    // Windows reports lib\data\...; normalise before matching.
    final path = file.path.replaceAll(_backslash, '/');

    // The script generator lives in lib/data/ and is therefore a catalog by
    // the rule below, but it is not a source of lines - it *is* the script,
    // and it contributes through its batches. Sweeping it too made its own
    // `note:` fields into narration: twelve clips of developer prose, one of
    // them nineteen seconds of explanation about a const in a runner. Nothing
    // could ever play them, since a clip is only ever looked up by the text of
    // a line someone speaks, so they were pure download weight.
    if (path.endsWith('/data/narration_script.dart')) continue;

    final isCatalog = path.contains('/data/');
    if (!speaks && !isCatalog) continue;

    for (final literal in _lex(source)) {
      if (literal.interpolated) continue;
      final text = literal.value.trim();
      if (_soundsSpoken(text)) seen.add(text);
    }
  }

  return seen.toList()..sort();
}
