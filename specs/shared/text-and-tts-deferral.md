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
