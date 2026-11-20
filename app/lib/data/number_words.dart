// Number words — spelled-out numerals for narration.
//
// Spoken lines need "three", not "3": system TTS reads a bare digit
// inconsistently across voices, and the whole point of the counting activities
// is that the child hears the number word.
//
// Four runners had their own private copy of this list
// (counting_parade_runner, count_forward_from_n_runner, count_on_by_ones_runner,
// counting_challenge_layer). New callers should use this one.

const List<String> kNumberWords = <String>[
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
  'twenty',
];

/// Lowercase number word, falling back to digits past the table so a bigger
/// count degrades to something speakable rather than throwing.
String spellNumber(int n) =>
    (n >= 0 && n < kNumberWords.length) ? kNumberWords[n] : n.toString();

/// Capitalised, for a line that starts with the number ("Three fawns!").
String spellNumberCapitalized(int n) {
  final word = spellNumber(n);
  return word[0].toUpperCase() + word.substring(1);
}

/// Capitalised count words, 0–100, indexed by value.
///
/// Every counting runner speaks `'$${kSpelledCounts[n]}.'` on each tap, and
/// four of them used to keep a private copy of this list. They are one list
/// now for a concrete reason: recorded narration is keyed by the words
/// (`narrationClipKey`), so a single take of "Seven." serves Counting Parade,
/// Count On By Ones, Count Forward From N, Count Out N and the challenge
/// layer at once. A drifting duplicate would silently split that into two
/// recordings of the same syllable.
const List<String> kSpelledCounts = <String>[
  'Zero',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
  'Twenty',
  'Twenty-one',
  'Twenty-two',
  'Twenty-three',
  'Twenty-four',
  'Twenty-five',
  'Twenty-six',
  'Twenty-seven',
  'Twenty-eight',
  'Twenty-nine',
  'Thirty',
  'Thirty-one',
  'Thirty-two',
  'Thirty-three',
  'Thirty-four',
  'Thirty-five',
  'Thirty-six',
  'Thirty-seven',
  'Thirty-eight',
  'Thirty-nine',
  'Forty',
  'Forty-one',
  'Forty-two',
  'Forty-three',
  'Forty-four',
  'Forty-five',
  'Forty-six',
  'Forty-seven',
  'Forty-eight',
  'Forty-nine',
  'Fifty',
  'Fifty-one',
  'Fifty-two',
  'Fifty-three',
  'Fifty-four',
  'Fifty-five',
  'Fifty-six',
  'Fifty-seven',
  'Fifty-eight',
  'Fifty-nine',
  'Sixty',
  'Sixty-one',
  'Sixty-two',
  'Sixty-three',
  'Sixty-four',
  'Sixty-five',
  'Sixty-six',
  'Sixty-seven',
  'Sixty-eight',
  'Sixty-nine',
  'Seventy',
  'Seventy-one',
  'Seventy-two',
  'Seventy-three',
  'Seventy-four',
  'Seventy-five',
  'Seventy-six',
  'Seventy-seven',
  'Seventy-eight',
  'Seventy-nine',
  'Eighty',
  'Eighty-one',
  'Eighty-two',
  'Eighty-three',
  'Eighty-four',
  'Eighty-five',
  'Eighty-six',
  'Eighty-seven',
  'Eighty-eight',
  'Eighty-nine',
  'Ninety',
  'Ninety-one',
  'Ninety-two',
  'Ninety-three',
  'Ninety-four',
  'Ninety-five',
  'Ninety-six',
  'Ninety-seven',
  'Ninety-eight',
  'Ninety-nine',
  'One hundred',
];

/// Capitalised multiples of ten, indexed by the *multiple* — `kSpelledTens[3]`
/// is 'Thirty'. Counting by tens sounds the same climb as counting by ones,
/// so long-parade and the by-ones decade markers share this.
const List<String> kSpelledTens = <String>[
  'Zero',
  'Ten',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
  'One hundred',
];

/// Capitalised count word for [n], falling back to digits past the table.
String spellCount(int n) =>
    (n >= 0 && n < kSpelledCounts.length) ? kSpelledCounts[n] : n.toString();
