// Words Kokoro says wrong, and the spellings that make it say them right.
//
// Kokoro phonemises with eSpeak-NG and then synthesises from the phonemes, so
// a mispronunciation is settled before the model runs and is *readable* rather
// than a matter of ear. `node phonemes.mjs <text>` prints the IPA; every entry
// below records what came out and what we wanted, so the next person can check
// the claim instead of trusting it.
//
// The respelling is applied ONLY to the text handed to the synthesiser. The
// clip key is still the hash of the real sentence, and the caption, the cue
// log and the script all still say "gryphon" — the game does not learn to
// misspell a word because the voice needed help.
//
// Adding an entry re-renders every affected clip on the next `render`: the
// manifest stores the words each clip was actually spoken from, so a clip is
// stale when the lexicon changes what it would say. Nothing to remember.

/**
 * @typedef {Object} SayAs
 * @property {string} word     the real word, as the game writes it
 * @property {string} say      the spelling eSpeak reads correctly
 * @property {string} heard    IPA it produced for `word`
 * @property {string} want     IPA it produces for `say`
 * @property {string} why      what that sounded like out loud
 */

/** @type {SayAs[]} */
export const SAY_AS = [
  {
    word: 'gryphon',
    say: 'griffin',
    heard: 'ɡɹˈɪfɑːn',
    want: 'ɡɹˈɪfɪn',
    why: 'GRIFF-ahn instead of GRIFF-in. eSpeak reads the "-phon" ending as '
      + 'the one in "siphon" stressed the other way, and there are 64 lines '
      + 'with a gryphon in them.',
  },
  {
    word: 'toucan',
    say: 'toucann',
    heard: 'tˈuːkən',
    want: 'tˈuːkæn',
    why: 'TOO-kuhn instead of TOO-can — the second vowel reduced to a schwa. '
      + 'The doubled n is the smallest edit that fixes it; "too-can" also '
      + 'works but comes out with two stresses (tˈuːkˈæn), which reads as '
      + 'someone spelling the word out.',
  },
];

/**
 * Match the capitalisation of [source] onto [replacement].
 *
 * Only the first letter matters here — these are common nouns that turn up
 * mid-sentence and at the start of one.
 */
function matchCase(source, replacement) {
  if (!source || !replacement) return replacement;
  if (source[0] !== source[0].toUpperCase()) return replacement;
  return replacement[0].toUpperCase() + replacement.slice(1);
}

const RULES = SAY_AS.map((entry) => ({
  ...entry,
  // The optional trailing s is carried across rather than listed twice: the
  // plural of the respelling is the respelling plus s in both cases, which is
  // checked in check.mjs rather than assumed.
  pattern: new RegExp(`\\b(${entry.word})(s?)\\b`, 'gi'),
}));

/**
 * The text to actually synthesise for [text].
 *
 * Returns the input unchanged when no rule applies, which is the common case —
 * callers can compare identity to tell whether a line is affected at all.
 */
export function spokenText(text) {
  let out = text;
  for (const rule of RULES) {
    out = out.replace(rule.pattern, (_, word, plural) =>
      matchCase(word, rule.say) + plural);
  }
  return out;
}

/** Every word the lexicon touches, for the coverage check. */
export function lexiconWords() {
  return SAY_AS.map((e) => e.word);
}
