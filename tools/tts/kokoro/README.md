# kokoro — the narration voice

Renders the narration script to voice clips with
[Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M), locally, for free.

`specs/shared/text-and-tts-deferral.md` deferred the paid render pipeline,
which left every line in the OS text-to-speech voice. The engagement plan's
diagnosis is blunt about what that costs: *"one flat synth voice at one pitch
for the keeper, the narrator, and the numbers alike"* — for a pre-reader, whose
only two channels are sight and sound.

Kokoro is Apache-2.0, 82M parameters, and runs on the CPU here at roughly two
seconds per line. The whole 253-line script is about ten minutes and costs
nothing, so re-rendering after a wording change is not a decision that needs
weighing.

## Nothing in the app changes

`NarrationPlayer` already prefers a bundled clip and falls back to system TTS
when there is none, and `NarrationAudio` discovers clips straight off Flutter's
`AssetManifest` at boot. A rendered clip is picked up because it is in the
folder under the right name. There is no manifest to build and no code to wire.

That was the point of the Stage 2 design, and this is it being used.

## Setup

```
cd tools/tts/kokoro && npm install
```

First run downloads ~86MB of quantised ONNX weights into the transformers.js
cache. `npm audit` reports a high-severity advisory in `sharp`, pulled in
transitively by transformers.js for **image** decoding — unused on this path,
build-time only, never shipped in the app.

## Commands

```
node render.mjs status                     what is rendered, what is missing, how big
node render.mjs audition "some line"       same line in several voices, to compare by ear
node render.mjs render [--only <batch>]    render everything missing or stale
node render.mjs render --matching <regex>  only lines whose text matches
node render.mjs orphans [--delete]         clips the script no longer asks for
node phonemes.mjs "toucan" "toucann"       the IPA Kokoro will actually say
```

Regenerate the script whenever a line changes:

```
cd app && dart run tool/dump_narration_script.dart > ../tools/tts/kokoro/script.json
```

## What gets rendered

Two sources, because neither alone is the whole game:

- **`narration_script.dart`** enumerates what the Dart runners compose - the 100
  counting words shared by all five counting activities, the warm miss/hint
  lines, and Counting Parade's keeper script. 253 lines.
- **`data/lesson-runtime/*.json`** holds the I-Show / We-Try narration, which
  reaches the app through `LessonRuntime` and which the Dart enumerator cannot
  see. 257 lines.

The second one was missed on the first pass, and the symptom was precise and
misleading: every lesson still *opened* in the browser synth voice, because the
first thing anyone hears in a lesson is authored in JSON. Counting Parade's own
lines were voiced the whole time.

The dumper reads the lesson JSON from `app/assets/data/lesson-runtime/` - the
mirror the app actually loads - rather than the repo-root `data/`, so if the
two have drifted this renders what will really be spoken.

A fourth group is enumerated inside `narration_script.dart` itself: lines built
from an interpolated template, whose variants come from a catalog. Shape
Garden's target lines, the Where's Buddy restate line and the two-attribute
miss line are all expanded that way.

Two template families are deliberately left on system TTS, because expanding
them is a bad trade:

| family | variants | why |
|---|---:|---|
| `paradeTransitionLine` | 1,792 | names count, species finished and species next; a session speaks four |
| Shape Garden wrong-tap | 648 | 18 leads x 4 warm lines x 9 plurals, ~19MB for a line heard on a miss |

Both are marked `isComplete: false` and carry a sample, so the shape of the
line can be heard without committing to the set. Both collapse if the line
stops naming one of its slots - the parade one to 64, the Shape Garden one to
36 by dropping the lead that names the child's mistake. Those are wording
decisions, not tooling ones.

Still not covered: lines built from interpolated Dart strings (`'Tap all the
$targetPlural.'`). There are only a handful, they vary at runtime, and
`NarrationCueLog` records them as they are heard so they can be reviewed later.

## Nothing is rendered twice

A clip's filename is `narrationClipKey(text)` — a readable slug plus FNV-1a
over the words. So a file is missing only when the *words* changed, and
`render` skips every key already present. Rewording one line re-renders one
line.

`render` also never overwrites a clip that already exists **in any format**. A
line the owner records by hand as `.wav` simply stays, and the machine fills in
around it. That check is extension-agnostic on purpose: `key.wav` and `key.mp3`
in the same folder are two entries fighting over one key, and which wins is
whatever order the asset manifest happens to list.

`orphans --delete` only ever removes clips this tool wrote, tracked in
`rendered.json`. Anything it does not recognise is left alone — a hand
recording is not something to bin silently.

## Words it says wrong

Kokoro phonemises with eSpeak-NG and then synthesises from the phonemes, so a
mispronunciation is settled before the model runs — which makes it something
you can *read* rather than only judge by ear. `phonemes.mjs` prints the IPA:

```
node phonemes.mjs gryphon griffin
gryphon        ɡɹˈɪfɑːn      <- GRIFF-ahn
griffin        ɡɹˈɪfɪn       <- GRIFF-in, which is the one we want
```

`lexicon.mjs` maps the real word to a spelling eSpeak reads correctly, and the
substitution happens **only** on the text handed to the synthesiser. The clip
key is still the hash of the real sentence, and the script, the captions and
the cue log all still say "gryphon" — the game does not learn to misspell a
word because the voice needed help.

Every entry records the IPA that came out and the IPA that was wanted, so the
next person can check the claim rather than trust it. Two rules today: gryphon
(read as GRIFF-ahn) and toucan (read as TOO-kuhn).

Because a rule changes what gets *said* while the text stays put, the manifest
stores the words each clip was actually spoken from. A clip is stale when the
lexicon would now say something different, `status` counts them, and `render`
re-renders them without being asked. Adding a rule is a one-command fix.

## Why MP3, when the SFX are WAV

Measured on the longest line in the script — 10.3s of 24kHz 16-bit mono:

| format | that line | whole script (~16 min of speech) |
|---|---:|---:|
| WAV 16-bit PCM | 483 KB | ~46 MB |
| MP3 64 kbps mono | 81 KB | **~8 MB** |

46 MB of narration is a bad first load for a Flutter web build, and
`parade-intro` alone accounts for 31 MB of it. `--wav` writes lossless instead
if that ever matters.

kokoro-js's own `save()` writes **32-bit float** WAV, which is not used here:
browser support for float WAV is uneven, and Safari/iOS is exactly the target
that matters. `wav.mjs` writes 16-bit PCM, matching what `tools/tts/record/`
produces for human takes, so the app cannot tell a recorded clip from a
rendered one.

Clips are trimmed and peak-normalised before encoding. Kokoro pads generously —
`"Seven."` comes back at 1.4s, most of it silence — and that matters more than
the bytes, because the counting ladder plays one per tap and dead air at the
head of a clip reads as lag between finger and sound.

## Voices

`af_heart` is the default: the only grade-A voice in the pack (`af_bella` is
A-). That is a starting point, not a judgement — **run `audition` and listen**.
A grade table cannot tell you which voice a five-year-old will want to come
back to.

`VOICE_BY_BATCH` in `render.mjs` assigns per batch. Everything is one narrator
today, since the plan's fiction has Keeper Haddock narrating and framing tasks
and Buddy never speaking, but the diagnosis specifically complained that the
keeper, the narrator and the numbers all shared one timbre — so the seam is
there.

Changing a voice does not change the clip key, so re-rendering needs `--force`.

## Why the clips are committed

They are regenerable for free, which argues for ignoring them. Two things argue
louder: a build needs them present, and because the key is content-addressed,
a wording change adds and removes individual files rather than rewriting all
253 — so git churn stays proportional to what actually changed.

`script.json` and `rendered.json` are committed as the provenance: which words,
which voice, which model, how long.
