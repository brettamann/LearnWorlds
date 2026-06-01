# Localization

> Architecture for routing all kid-facing text and audio through a localization layer. **English-only at launch**, but every string and audio cue is addressed by ID + locale from day 1 so adding a second language post-launch is a content-add, not an engineering rewrite.

References: `specs/shared/asset-paths.md`, `specs/shared/lesson-runtime-actions.md`, all lesson runtime JSONs, all activity specs.

---

## Why architecture-ready

Per the K-review decision: localization is **English-only at launch**, but rewriting hardcoded strings later is a 10× more expensive job than getting the architecture right from day 1. This spec defines:

- The string table format
- The audio asset routing convention
- How lesson runtime JSONs reference strings/audio without hardcoding language
- Locale fallback behavior

A new language post-launch becomes: translate the string table, record voice lines, drop them in place.

---

## Locale codes

We use BCP 47 language tags:
- `en-US` — English (United States), the launch locale
- `en-GB`, `es-MX`, `es-ES`, `fr-FR`, `pt-BR`, `de-DE`, etc. — post-launch as added

The runtime determines the active locale from:
1. Parent dashboard setting (explicit kid-locale choice, future v1.1+)
2. Device locale (iOS reports via `Locale.current`)
3. Fallback: `en-US`

A kid's locale is per-kid (one kid in a Spanish-speaking family may be set to en-US for school practice, another to es-MX).

---

## String table

All kid-facing text lives in a string table:

```
content/
  strings/
    {locale}/
      lessons/
        lesson-k-cc-4a-one-to-one.json
        lesson-k-cc-4b-cardinality.json
        ...
      activities/
        counting-parade.json
        ten-frame-pond.json
        ...
      shared/
        narrator-cues.json     # round-pass, round-fail, hesitation prompts
        ui-labels.json         # button labels, HUD strings
        onboarding.json
        dashboard.json         # parent dashboard text
        rewards.json           # collectible/trophy names + descriptions
```

### String table format

```jsonc
{
  "$schema": "../../../schemas/string-table.schema.json",
  "locale": "en-US",
  "namespace": "lesson:k-cc-4a-one-to-one",
  "strings": {
    "iShow.intro": "Let's count these fawns together. Watch how each one gets one touch.",
    "iShow.count.1": "One.",
    "iShow.count.2": "Two.",
    "iShow.count.3": "Three.",
    "iShow.insight": "Three fawns. Each one got exactly one touch.",
    "weTry.prompt-1": "Now you try. Touch this first fawn.",
    "weTry.after-tap-1": "One.",
    "weTry.prompt-next": "Now this one.",
    "weTry.after-tap-2": "Two.",
    "weTry.auto-complete": "Three. Four.",
    "weTry.closing": "Four fawns. Each one got one touch."
  }
}
```

Lesson runtime JSON references string IDs, not literal text:

```jsonc
// data/lesson-runtime/k-cc-4a-one-to-one.json
{
  "narrationScript": [
    { "at": "1s", "stringId": "lesson:k-cc-4a-one-to-one:iShow.intro" },
    { "at": "5s", "stringId": "lesson:k-cc-4a-one-to-one:iShow.count.1" },
    ...
  ]
}
```

### Migration from inline text (post-launch chore)

The current lesson runtime JSONs (and activity specs) have inline English narration text. The localization rollout converts:

```jsonc
// Before
{ "at": "5s", "text": "One." }

// After
{ "at": "5s", "stringId": "lesson:k-cc-4a-one-to-one:iShow.count.1" }
```

This migration is done **incrementally per lesson** and can be partial — the runtime supports both forms during transition (inline `text` wins if present; `stringId` resolves otherwise).

---

## Audio routing

Each narration `cueId` (per `lesson-runtime-actions.md`) resolves to an audio file via a per-locale path:

```
assets/lessons/{lesson-slug}/narration/{locale}/{cueId}.m4a
```

Activity SFX (chimes, stingers, etc.) are locale-independent:

```
assets/activities/{activity-slug}/sfx/{sfx-id}.m4a
```

Music beds are locale-independent.

Region narrator voice lines (cross-activity prompts like "Round complete!") live at:

```
assets/shared/region-narrators/{locale}/{narrator-voice-id}/{cue-id}.m4a
```

### Audio loader fallback

When the kid's locale is `es-MX` but the requested asset only exists in `en-US`:
1. Try `es-MX` first.
2. Fall back to `en-US` (the launch locale).
3. Log telemetry `localization.audio_fallback_used`.

A library entry might be filed under one locale (the locale active at lesson-pass time) but the kid switches locale later — the library replays in whatever locale is now active, regardless of when the lesson was filed. This is **intentional**: the kid hears what they understand now, not what they understood before.

---

## What's NOT localized (intentionally)

- **Math notation** — numerals `0–9`, operators `+`, `−`, `=`, `>`, `<` are universal at our grade range. Numerals stay numerals.
- **Sound effects** — taps, chimes, sparkles, stingers don't translate.
- **Music** — instrumentation may carry cultural connotations; per-locale music swap is a v2+ consideration.
- **Visual art** — Buddy / Avatar / environments are universal. Some seasonal/holiday art is locale-influenced (US Thanksgiving vs nothing in es-MX) but that's a separate "holiday calendar" axis, not localization per se.
- **Numeral character names** — "the 5", "the 8" stay numerals visually. The narrator says "five" / "eight" in the target language. No issue.

---

## Right-to-left languages

The launch architecture supports RTL (Arabic, Hebrew) without committing to it:
- All layouts use SwiftUI's leading/trailing rather than left/right.
- Text mirroring happens automatically.
- Audio is direction-agnostic.

RTL languages are **not in launch scope**. The architecture allows them without rework.

---

## Pluralization, number formatting, dates

Localization-aware formatters:
- **Numbers**: `1,234` vs `1.234` (per locale). Defer to system formatters.
- **Dates**: birthday display, dashboard charts — use system date formatters.
- **Pluralization**: narrator scripts use slot-filled templates. Each locale's string table can declare plural variants:

```jsonc
{
  "round-pass.count-creatures": {
    "one": "{count} {creature}!",
    "other": "{count} {creature_plural}!"
  }
}
```

The runtime picks `one` or `other` based on the count + locale's CLDR plural rules.

---

## Voice talent considerations

When a second language is added:
- Each region narrator + Buddy needs a voice actor for that language.
- Voice direction notes from the original (e.g., "Sanctuary warm naturalist — like an older sibling pointing things out") must travel to the new actor.
- **The character's identity stays** — same vibe, same personality, in a new language. Not a different character.

---

## Storyteller's Pond visible character

Storyteller's Pond's turtle narrator (per `storytellers-pond.md`) has **mouth-sync animation**. When localized:
- Mouth shapes don't need per-locale frames; generic open/closed/round-vowel shapes work cross-language.
- Sync timing per-locale (timing of narration tracks varies between languages).

---

## Telemetry

| Event | Payload |
|---|---|
| `localization.locale_resolved` | `kidId`, `requestedLocale`, `resolvedLocale`, `fallbackReason?` |
| `localization.string_missing` | `stringId`, `locale` — a string referenced in a runtime JSON wasn't in the table |
| `localization.audio_fallback_used` | `cueId`, `requestedLocale`, `fallbackLocale` |

The first two events are critical for QA when adding a new language.

---

## Implementation notes

### Suggested module structure

```
LocalizationCoordinator
├── LocaleResolver (per-kid locale lookup)
├── StringTableLoader (lazy-load per namespace)
├── AudioPathResolver (lesson/activity/shared)
└── PluralRuleEngine (CLDR-based)
```

### Performance

- String tables are JSON files in app bundle.
- Loader caches per-namespace tables in memory; LRU eviction at ~10 MB total cache.
- Per-locale assets that ship as bundle resources are loaded on demand.

### Adding a new language (post-launch)

1. Add `assets/.../narration/{new-locale}/` and record voice lines.
2. Add `content/strings/{new-locale}/...` and translate.
3. Add `{new-locale}` to the supported list in parent-dashboard locale picker.
4. Optionally: re-record music if cultural fit issues surface (v2+).
5. Test fallback paths (intentionally missing strings should fall back to en-US without crashing).
6. Ship.

No code change required if the architecture-ready approach is held.

---

## Open Questions

- **Pre-launch string-table migration scope** — do we migrate inline text in all 22 K lesson runtime JSONs before launch, or just author new content with stringIds while leaving existing inline text? Suggest the latter — leave inline as the en-US fallback; the runtime supports both forms.
- **Voice variant per gender/identity** — should we ship multiple voice actors per region narrator (e.g., feminine / masculine / non-binary variants)? Out of scope for launch; consider for v1.1+.
- **Asset bundling per locale** — at launch, only en-US ships; total bundle stays small. Post-launch, ship per-locale audio as on-demand resources to keep base bundle small. Confirm with iOS bundling strategy.
- **Translation memory tooling** — need a CAT tool / glossary for consistent voice across grade regions and lessons. Defer until first non-English language is approved.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — architecture-ready model. Locale codes, string-table format, audio routing, fallback rules. English-only at launch; new languages are post-launch content adds. | |
