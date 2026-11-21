# Text-Only Narration & TTS Deferral

> Decision: voice line production is **deferred** until the game is in a good state. Until then, the runtime renders narration as **text on screen**, with optional **system TTS** as a free dev-time read-aloud. The ElevenLabs pipeline is built, tested, and idle — we'll come back to it once gameplay is validated.

References: `specs/shared/voice-pipeline.md`, `specs/shared/system-architecture.md`, `specs/shared/lesson-runtime-actions.md`, `specs/shared/k-activity-patterns.md`, `tools/tts/`.

---

## Why we deferred

Voice production is **expensive in three ways**:

1. **Money** — ElevenLabs Pro tier ~$99 for the K initial generation; bigger for 1st & 2nd grade. Re-renders after narration tweaks burn additional credits.
2. **Lock-in** — once you pick voice IDs and ship audio, changing narration text means a re-render burst. Changes are cheaper while the only artifact is JSON.
3. **Time** — voice picking, sample listening, profile locking, QA listening all take real attention. Not worth that attention until the game it's narrating actually exists in playable form.

The smart sequencing is: **build → playtest → refine narration → render audio.** Not the other way around.

---

## What stays in place

The TTS pipeline tooling is fully built and tested in dry-run end-to-end. It will be ready to go when we want to come back:

| Component | State | Notes |
|---|---|---|
| `data/slot-vocabulary/en-US.json` | ✅ Authoritative | Every slot the narration uses is defined here. |
| `content/strings/en-US/activities/*.json` | ✅ Authoritative | 11 activity narration files, 155 cues. |
| `data/lesson-runtime/*.json` | ✅ Authoritative | 22 lesson runtime JSONs with embedded narration scripts. |
| `tools/tts/verify-harvest.mjs` (Stage 1) | ✅ Implemented | Walks the above, produces harvest manifest. |
| `tools/tts/canonicalize.mjs` (Stage 2) | ✅ Implemented | Expands slots, produces canonical manifest. |
| `tools/tts/check-cache.mjs` (Stage 3) | ✅ Implemented | Diffs against `.hash` sidecars. |
| `tools/tts/generate.mjs` (Stage 4) | ✅ Implemented | Calls ElevenLabs. Gated behind `--live` + env-var + locked voiceId. |
| `tools/tts/build-manifests.mjs` (Stage 5) | ✅ Implemented | Walks rendered audio + produces runtime manifest. |
| `tools/tts/build-preview.mjs` (Stage 6) | ✅ Implemented | HTML QA bundle. |
| `tools/tts/voice-profiles.json` | ⏸ Placeholders | `voiceId: "REPLACE_WITH_REAL_VOICE_ID"` — pre-flight blocks live calls. |
| ElevenLabs account / API key | ⏸ Not yet | Sign up when we come back. |

**Net effect:** no audio files exist anywhere. The pipeline is a complete, unrun blueprint.

---

## Runtime behavior during deferral

The game must still narrate at runtime — we can't ship a silent product. The narration text in the JSON files is the source of truth, and the runtime renders it in one of two modes:

### Mode 1 — Text caption (default)

For each narration cue the runtime would normally play as audio:

- **Display the text as a caption** at a consistent location (top banner for in-activity, bottom banner during lessons).
- **Cue lifetime**: appears at the time the audio would have started; auto-dismisses after a calculated "reading-time" based on character count (~50 ms/char minimum, 2 s minimum, 6 s maximum).
- **Sanctuary-warm visual treatment** matching the in-game palette. Not a debug overlay — this is a launchable presentation mode.
- **Tap to dismiss** lets parents / older kids skim ahead.
- **Always-on by default** during the deferral phase.

### Mode 2 — System TTS (opt-in, dev-friendly)

For testing with non-reading K kids, parents can opt into the device's built-in text-to-speech via the parent dashboard:

- Uses **`flutter_tts`** (free Flutter package wrapping `AVSpeechSynthesizer` on iOS / `TextToSpeech` on Android).
- Quality is **robotic but functional** — close to OS Siri/Google Assistant voice. Not ElevenLabs-grade, but kid can hear something.
- **Caption stays visible** even when system TTS plays (belt + suspenders).
- Implemented via the `SystemTtsProvider` adapter, separate from the production `AudioProvider`.
- **Cost**: $0. Latency: small but acceptable for K pacing.

This mode is the realistic playtest experience during deferral: parents can opt in, the kid hears robotic narration, gameplay proceeds.

### Mode 3 — Pre-rendered audio (post-deferral)

Once we come back to voice production:

- Run the TTS pipeline to generate `.mp3` files.
- `AudioProvider` plays the pre-rendered files when available.
- `SystemTtsProvider` becomes the **safety net** — fires only when a cueId has no rendered audio.
- Captions stay available as an **accessibility option**, opt-in / opt-out via parent dashboard.

---

## Runtime architecture during deferral

The `NarrationPlayer` (a new module in the lesson + activity runners) takes a cueId + text + slot bindings and dispatches to the available output channels:

```
NarrationPlayer.play(cue) {
  // 1. Resolve final text (slot-fill if needed).
  final text = SlotResolver.resolve(cue.text, cue.slotBindings);

  // 2. Show caption (always-on during deferral).
  CaptionLayer.show(text, expectedDurationMs(text));

  // 3. Try pre-rendered audio.
  final audio = AudioProvider.tryLoad(cue.cueId);
  if (audio != null) {
    audio.play();
    return;
  }

  // 4. Fall back to system TTS if parent enabled it.
  if (Settings.systemTtsEnabled) {
    SystemTtsProvider.speak(text, voiceProfileSettings);
  }
  // Otherwise: caption-only.
}
```

Lesson runner's animation choreography continues to use the original `at` timestamps to drive narration kick-offs — text appears at the same beats audio would have. Tap-to-dismiss accelerates reading; auto-dismiss based on character count handles unattended play.

---

## What changes per spec

| Spec | What changes |
|---|---|
| `voice-pipeline.md` | Top-of-doc banner pointing here. Pipeline content stays; status is "ready to run, not running." |
| `system-architecture.md` | Add `CaptionLayer`, `SystemTtsProvider`, `NarrationPlayer` to the module catalog. `AudioProvider` semantics now distinguish pre-rendered playback from fallback. |
| `lesson-runtime-actions.md` | The `narration` action now explicitly describes the text-display fallback in addition to the audio cue dispatch. |
| `k-activity-patterns.md` | Note that the "narrator lines" prose maps to caption text during deferral. |
| `project-bootstrap.md` | Add `flutter_tts` as an opt-in dev/launch dependency. |
| `parent-teacher-dashboard.md` | Add settings toggles: **System read-aloud** (during deferral); **Captions** (post-deferral; default on for accessibility). |
| `playtest-watchlist.md` | New entry — watch playtest reactions to text + system-TTS combination; tune the come-back trigger. |
| `voice-profiles.json` | Stays with placeholder voiceIds. |
| `data/slot-vocabulary/en-US.json` | Stays — runtime SlotResolver uses it identically for text or audio substitution. |

---

## Come-back checklist

When we decide to render voice:

### Pre-flight
- [ ] Confirm game is playable end-to-end through at least Counting Parade and Ten-Frame Pond.
- [ ] Confirm narration text has stabilized — recent edits trail off to ≤1 change per week.
- [ ] Budget approved (~$22–99/month ElevenLabs for K; expect ~1 month of generation).
- [ ] Sign up for ElevenLabs account.

### Voice picking
- [ ] Set `ELEVENLABS_API_KEY` in environment.
- [ ] Browse ElevenLabs voice library + Voice Design for 3–5 Sanctuary-warm-naturalist candidates.
- [ ] Run `node tools/tts/sample-voices.mjs --voices ID1,ID2,ID3 --profile sanctuary-warm-naturalist`.
- [ ] Open `voice-samples/index.html`, listen blind, pick a winner.
- [ ] Edit `tools/tts/voice-profiles.json`: replace `REPLACE_WITH_REAL_VOICE_ID` for `sanctuary-warm-naturalist`, set `locked: true`, set `lastLockedAt` date.

### Initial render
- [ ] `node tools/tts/verify-harvest.mjs && node tools/tts/canonicalize.mjs && node tools/tts/check-cache.mjs`.
- [ ] `node tools/tts/generate.mjs --live --max 20` — small validation batch (~$0.50 credits).
- [ ] Run `build-preview.mjs`; listen to the 20 samples in the bundle. Tune narration text if anything sounds off.
- [ ] `node tools/tts/generate.mjs --live` for the full bank.
- [ ] `node tools/tts/build-manifests.mjs && node tools/tts/build-preview.mjs`.
- [ ] Full QA pass via the preview bundle.

### Runtime integration
- [ ] Wire `AudioProvider` to load from `assets/narration-manifest.json` at boot.
- [ ] Switch caption default to **opt-out** for kids who can hear (still opt-in for accessibility).
- [ ] Confirm `SystemTtsProvider` falls back gracefully for any cueIds that didn't render.
- [ ] Update parent dashboard toggle copy.

### Spec cleanup
- [ ] Remove the deferral banner from `voice-pipeline.md`.
- [ ] Update this file's status to "completed, kept for reference."
- [ ] Update playtest-watchlist entry to "resolved."

### Estimated time
- Voice picking: ~1–2 days (listening + iterating settings)
- Initial render: ~1 day (mostly waiting for ElevenLabs to chew through 150K chars)
- QA + integration: ~3–5 days
- **Total: ~1 work-week** when the time comes.

---

## What this does NOT defer

We're deferring **voice production**, not narration design. The text content stays a first-class authoring concern:

- Narration text in lesson + activity JSONs is **still the source of truth**.
- Slot vocabulary is **still actively maintained**.
- New activities authored during deferral period **must include narration text** per the activity-spec template.
- The TTS harvester runs in CI to catch broken cueIds whether or not audio exists.

If we ship text-only and never come back to voice, the product still works — kids whose parents read aloud, or who enable system TTS, can play. Voice is a polish layer, not a requirement.

---

## Open Questions

- **System TTS quality acceptability** — robotic OS voices may turn K kids off. Watch playtest reaction; if it's bad, parents-reading-aloud becomes the default path and we accelerate the come-back trigger.
- **Caption auto-dismiss timing** — 50 ms/char baseline. Tune in playtest. Younger kids may need slower; older kids may want faster + manual dismiss.
- **Caption position** — top banner vs bottom banner vs floating-near-narrator. Defer to UI prototyping.
- **Per-kid TTS voice selection** — should the parent dashboard let parents pick which OS voice the system TTS uses? Probably yes, low cost.
- **Lord Layerton specifically** — even at production time we flagged considering a human voice actor for Lord Layerton (the comedic-theatrical 2nd-grade villain). Defer; the come-back checklist can split production into "Sanctuary first, evaluate other voices separately."

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-06-04 | Initial draft — declared deferral, defined the text + system-TTS fallback chain, authored the come-back checklist, mapped per-spec changes | |
| 2026-08-21 | **Recorded-clip-first narration, without un-deferring the render pipeline.** `NarrationPlayer` now plays a bundled clip when one exists for a cueId and falls back to system TTS when it doesn't (`platform/narration_audio.dart`). A build with zero clips behaves exactly as before, so recording is incremental and never blocks — the point of the deferral is preserved while the owner records the highest-traffic lines himself. Clips live in `app/assets/audio/narration/`, are discovered from Flutter's own AssetManifest at boot (no manifest to rebuild), and are named after the cueId sanitized by `narrationClipStem()`. A browser recording harness lives at `tools/tts/record/`. Note the cueIds that matter are the runtime ones composed in Dart, not the authored ids in `tools/tts/canonical-manifest.json` — Settings gains "Copy narration cue list", which exports exactly what the app spoke this session. | |
| 2026-08-22 | **Recorded clips are keyed by their text, not by their cueId.** The previous day's scheme was wrong in a way that would only have surfaced as a child hearing the wrong words. A cueId names a *slot*, and a slot is neither unique per sentence nor stable across sessions: `parade:tap-r0-3` through `parade:tap-r4-7` are twenty-five ids whose text is only ever some number word, and `parade:counting-prompt-r2` says "Touch each fawn" or "Touch each baby dragon" depending on the session seed, because species are shuffled per session. Clips are now filed under `narrationClipKey(text)` — a readable 48-character slug plus FNV-1a over the UTF-8 bytes of the whitespace-normalised sentence. Consequences: one take of "Seven." serves all five counting activities; a line with no cueId is recordable, which the old scheme could not do; and rewording a line deliberately orphans its recording, which the export now reports. | |
| 2026-08-22 | **The recording script is enumerated, not observed.** `data/narration_script.dart` walks the catalogs and calls the same line-building functions the runners call — so a reworded line changes the script automatically rather than drifting from it — and emits 253 lines across eight batches sized for one sitting at a microphone. `NarrationCueLog` is now keyed by text and persisted, so the remainder (lines assembled from lesson JSON) accumulates across sessions instead of demanding one playthrough that touches every branch. Settings → **Copy recording script** exports both halves plus coverage and orphan counts. `paradeTransitionLine` is marked deliberately incomplete: it names the count, the species finished and the species next, which is 1,792 variants against four spoken per session, so it stays on system TTS. | |
| 2026-09-01 | **The narration is voiced. Kokoro-82M renders the whole script locally, for free, and the deferral stops costing anything.** This spec deferred the paid render pipeline and the consequence was that every line stayed in the OS synth voice - the engagement plan's diagnosis calls it "one flat synth voice at one pitch for the keeper, the narrator, and the numbers alike", for a child whose only two channels are sight and sound. Kokoro is Apache-2.0, 82M parameters, and runs on CPU at roughly two seconds a line, so the 253-line script is about ten minutes end to end and re-rendering after a wording change is not a decision that needs weighing. **No app code changed.** `NarrationPlayer` already preferred a bundled clip over system TTS and `NarrationAudio` already discovered clips off Flutter's `AssetManifest` at boot; a rendered clip is found because it sits in the folder under `narrationClipKey(text)`. That was the point of the Stage 2 design and this is it being used. The paid pipeline stays deferred and is now unlikely to be needed. | |
| 2026-09-01 | **Machine rendering never overwrites a human take, and the check is extension-agnostic.** `tools/tts/kokoro/render.mjs` skips any clip key that already has a file in `assets/audio/narration/` whatever its extension, so a line the owner records by hand as `.wav` survives every subsequent render and the machine fills in around it. The extension-agnostic part is not fussiness: `NarrationAudio` maps a clip by filename *stem*, so `key.wav` and `key.mp3` in one folder are two entries fighting over one key and which wins is whatever order the asset manifest happens to list. `check.mjs` fails on any key claimed twice. Orphans - clips whose line was reworded, so its key changed - are reported by `render.mjs orphans`, and `--delete` only removes clips the tool itself wrote, tracked in `rendered.json`. | |
| 2026-09-01 | **`narrationClipKey` moved to `platform/narration_clip_key.dart`, free of Flutter.** It had lived in `narration_audio.dart`, which imports `flutter/services`, `flutter_riverpod` and `just_audio` - so naming a clip dragged the whole widget toolkit in, and `dart run tool/dump_narration_script.dart` (which hands the script to the Node renderer) could not compile, failing with a bare "type 'InvalidType' is not a subtype of type 'FunctionType'" that names nothing. `narration_audio.dart` re-exports the new file, so every existing import is unchanged. A test walks the import graph from `narration_script.dart` and fails with a readable sentence if anything reachable from it imports Flutter again. | |
| 2026-09-01 | **Narration coverage closed to three sources, and two combinatorial families deliberately left on TTS.** Rendering revealed that `narration_script.dart` saw only what the Dart runners compose; the I-Show/We-Try script lives in `data/lesson-runtime/*.json` and a third group - Haddock's prologue, every const round's `keeperLine`, the reward dialog - is plain Dart literals. All three are now enumerated, plus a fourth group built inside the script itself by expanding interpolated templates against their catalogs - Shape Garden's target and sort lines, the Where's Buddy restate line, the two-attribute miss, the challenge call (739 lines, 726 distinct clips). Two families are marked incomplete on purpose: `paradeTransitionLine` at 1,792 variants, and Shape Garden's wrong-tap line at 648 (18 leads x 4 warm lines x 9 plurals), which would be 19MB for a line that plays on a miss. Dropping the lead - which names the child's mistake, and which `k-activity-patterns.md` never asks for - would collapse it to 36; that is a wording decision and is not taken here. | |
| 2026-09-01 | **`kShapeDisplayName`/`kShapeDisplayPlural` and the Where's Buddy words moved to Flutter-free catalogs.** They lived in `shape_intro_layer.dart` (imports flutter/material) and `wheres_buddy_landmarks.dart` (holds `Offset`s), so the narration script could not reach them without pulling in the widget toolkit - and the script has to compile under plain `dart run`. Now in `data/shape_words.dart` and `data/wheres_buddy_words.dart`. The landmark and position classes read their words back through getters rather than storing copies, so the script and the running game cannot disagree about wording; a drift there would render a clip nothing asks for and leave the real line in the synth voice with nothing reporting it. | |
| 2026-09-01 | **Voice chosen: `af_heart`.** Grade A in the Kokoro pack and confirmed by ear against `af_bella`, `af_nicole` and `bf_emma`. `VOICE_BY_BATCH` in `tools/tts/kokoro/render.mjs` can still split the keeper from the narrator from the numbers - the diagnosis complained they all shared one timbre - but that is a casting decision, not a technical one, and one warm voice is a large improvement on one flat synth voice. | |
