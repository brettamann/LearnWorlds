# Parent / Teacher Dashboard

> The grown-up view of what the kid is doing. Two surfaces (parent + teacher) sharing most data with a few teacher-only capabilities. Entry-point: discrete gear icon in the Hub, long-press to open, optional PIN gate.

References: `specs/shared/onboarding-flow.md`, `specs/shared/multi-kid-device-routing.md`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/daily-quest-curation.md`, `specs/shared/playtest-watchlist.md`, `we-are-going-to-eventual-lantern.md` (Parent / Teacher Dashboard section).

---

## Goals

1. **Reassure, don't pressure.** Parents see progress, not deficits framed as deficits. Teachers see actionable data without "ranking" kids.
2. **Glanceable.** A parent checks in for 30 seconds; the most important thing is on screen immediately.
3. **Trustworthy.** No dark patterns, no manufactured urgency, no upsell. Parents see exactly what's saved and what's shared.
4. **Empowering.** Teachers can push specific activities, export reports, and customize what their classroom sees.
5. **Warm.** The dashboard looks like the game's island world (soft, hand-drawn) — not a corporate analytics product. Same design language as the kid Hub.

---

## Entry & access

### From the kid Hub

- A discrete **gear icon** sits in the top-right corner of the Hub interior, sized small enough that a kid focused on play doesn't fixate on it.
- **Long-press** (1.5 s) opens the dashboard. Single-tap does nothing (deliberate friction so a kid doesn't accidentally enter).
- A subtle "long-press the gear" tooltip appears the first time a parent enters the Hub (one-time, dismissed after).

### Optional PIN gate

- Parents can set a 4-digit PIN in dashboard settings.
- When set, long-press → PIN prompt → dashboard.
- Default: **off** at launch. Confirm in playtest whether kids accidentally enter; if yes, change default to on or auto-suggest PIN setup after N kid-triggered openings.

### Multi-kid devices

- Dashboard opens to the **last-active kid's** parent view by default.
- A kid-switcher dropdown at the top lets the parent flip to another kid's view.
- Teacher mode (see below) defaults to the **class overview** instead.

### Parent vs teacher mode

- A device is in **parent mode** by default.
- Switching to **teacher mode** happens once during initial setup (parent dashboard → "I'm a teacher / homeschool parent" toggle).
- Mode is per-device, not per-kid. A device's kid profiles are still per-kid; mode just changes which tabs appear in the dashboard.

---

## Information architecture

### Parent mode tabs

```
[Today]  [Progress]  [Library]  [Family Wins]  [Settings]  [Manage Kids]
```

### Teacher mode tabs (additional)

```
[Today]  [Class Roster]  [Progress]  [Assignments]  [Library]  [Export]  [Settings]  [Manage Kids]
```

The shared tabs render the same data in both modes; teacher-mode-only tabs (Class Roster, Assignments, Export) appear only when teacher mode is enabled.

---

## Screen: Today (default landing)

The first thing a parent / teacher sees. ~30-second glance answers "what did they do recently?"

```
┌─────────────────────────────────────────────────────────┐
│  [Lila ▾]                                       [⚙]    │
│                                                          │
│  Today                                                   │
│  ───────                                                 │
│                                                          │
│  ✨  Lila played for 8 minutes today                     │
│      Counting Parade · Ten-Frame Pond · Storyteller's   │
│      Pond                                                │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │   🌱  K.OA.4 reached Practicing!                │   │
│  │       Make sums of 10 — first time              │   │
│  │       [Send a card]                              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  This week                                               │
│  4 days played · 12 rounds passed · 2 lessons watched   │
│                                                          │
│  Heads up                                                │
│  • Lila has had some trouble with K.CC.7 (compare       │
│    numerals). The system is offering it more often      │
│    at the Concrete layer. Nothing to do — just FYI.     │
│                                                          │
│  [See full progress →]                                  │
└─────────────────────────────────────────────────────────┘
```

### What's on this screen

- **Kid selector** at top (only shown if ≥ 2 kids).
- **Today's session summary**: minutes played, activities touched.
- **Big-win card**: a mastery promotion or milestone earned today, with a "Send a card" button for family sharing.
- **This week** roll-up: days played, rounds passed, lessons watched.
- **Heads up section**: gentle flags surfaced by the system (struggle patterns, demote events). Framed as informational, not alarming. Never blames the kid.
- **Footer link** to the Progress tab.

### Data sources

- Session log (last 7 days)
- Recent `mastery.standard_practicing` / `_mastered` events
- Scaffolding demote events flagged for parent attention (3+ consecutive at the floor)

### Empty state (kid hasn't played today)

> "Lila hasn't played today. That's fine — yesterday she practiced ten-frames and earned a frog-collector card."

No nag, no urgency.

---

## Screen: Progress

The heart of the parent view. Standards-by-standards status with friendly framing.

```
┌─────────────────────────────────────────────────────────┐
│  Lila's Progress                                         │
│  ───────────────                                         │
│                                                          │
│  Kindergarten                                            │
│                                                          │
│  Counting & Cardinality                                  │
│  ████████░░░░░░░░  5 of 7 areas in progress              │
│   ✅ K.CC.4a (one-to-one) — Mastered                    │
│   🌿 K.CC.4b (cardinality) — Practicing                 │
│   🌿 K.CC.4c (each-one-more) — Practicing               │
│   🌱 K.CC.1 (count to 100) — Introduced                 │
│   🌱 K.CC.2 (count forward from N) — Introduced         │
│   ⚪ K.CC.6 (compare groups) — Not yet                   │
│   ⚪ K.CC.7 (compare numerals) — Not yet                 │
│                                                          │
│  Operations & Algebraic Thinking                         │
│  ██████░░░░░░░░░░  3 of 5 areas in progress              │
│  [...]                                                   │
│                                                          │
│  Number & Operations in Base Ten                         │
│  Measurement & Data                                      │
│  Geometry                                                │
│                                                          │
│  Ready to advance                                        │
│  Lila is consistently passing K.OA.3 at the Concrete    │
│  layer. The system will offer the Pictorial layer       │
│  in upcoming rounds.                                     │
│                                                          │
│  Worth revisiting                                        │
│  K.CC.7 has been difficult. Storyteller's Pond and      │
│  Picnic Baskets are giving extra practice.              │
└─────────────────────────────────────────────────────────┘
```

### Visual symbols (color-blind safe icons + text)

| Icon | Meaning |
|---|---|
| ⚪ | Not yet introduced |
| 🌱 | Introduced (lesson played, first practice) |
| 🌿 | Practicing (consistent passes; building) |
| ✅ | Mastered (5/3/3 threshold met) |
| ⚠️ | Struggle flagged (system actively offering more support) |

### Strand-level progress bar

Filled fraction = (introduced + practicing + mastered) / total. Mastered standards fully color in.

### Per-standard detail

Tapping a standard expands a panel:

```
┌─────────────────────────────────────────────────────────┐
│  K.OA.3 — Decompose numbers ≤ 10 in multiple ways       │
│                                                          │
│  Status: Practicing — Concrete layer                    │
│  Streak: 2 consecutive passes (1 more to promote)       │
│  Sessions: 4 days, 12 rounds                            │
│  Activities exercising this: Ten-Frame Pond             │
│                                                          │
│  Most recent: 2 hours ago in Ten-Frame Pond (passed)    │
│                                                          │
│  Lesson available: ▶ "Splitting numbers two ways"       │
│  [Replay lesson]   [See full Utah standard text]        │
└─────────────────────────────────────────────────────────┘
```

### Per-instance progress for K.CC.3 (Scribe's Tower)

For per-instance concepts, the panel shows individual progress:

```
┌─────────────────────────────────────────────────────────┐
│  K.CC.3 — Write numerals 0–20                            │
│                                                          │
│  Status: Practicing (5 of 21 numerals mastered)         │
│                                                          │
│  ✅ 0  ✅ 1  ✅ 2  ✅ 3  ✅ 5  🌿 4  🌿 6  🌿 8  🌱 7   │
│  ⚪ 9  ⚪ 10 ⚪ 11 ⚪ 12 ⚪ 13 ⚪ 14 ⚪ 15 ⚪ 16 ⚪ 17    │
│  ⚪ 18 ⚪ 19 ⚪ 20                                       │
│                                                          │
│  Milestones earned                                       │
│  🏅 Five Numerals Written  (this week)                   │
│                                                          │
│  Next milestone                                          │
│  🎯 All Single Digits (5 more to go)                     │
└─────────────────────────────────────────────────────────┘
```

---

## Screen: Library

A view of the kid's filed MicroLessons. Parents can browse and tap to play any lesson the kid has seen.

```
┌─────────────────────────────────────────────────────────┐
│  Lila's Library                                          │
│  ──────────────                                          │
│                                                          │
│  Sanctuary (Stamp Wall)                                  │
│  ────────────────────────                                │
│                                                          │
│  [Stamp]  [Stamp]  [Stamp]  [Stamp]  [Stamp]            │
│  Counting Cardinality   +1    Position  Sticks &        │
│  one at   The last     Each   Words     Clay            │
│  a time   number...    one...                            │
│                                                          │
│  [Stamp]  [Stamp]  [Stamp]                              │
│  Compose  Decomposi-  ...                                │
│  3D       tion                                           │
│                                                          │
│  Wundletown (Spell Book)   — empty                       │
│  Mathopolis (Casebook)     — empty                       │
└─────────────────────────────────────────────────────────┘
```

Tapping a stamp opens the lesson in replay mode (no rewards fire; per `micro-lessons.md`).

Useful when:
- Parent wants to know exactly what the kid was shown.
- Kid asks a question and the parent wants to look at the demo themselves.
- Teacher wants to verify what concept was introduced when.

---

## Screen: Family Wins

Share-ready cards for moments the kid would want to celebrate with family.

```
┌─────────────────────────────────────────────────────────┐
│  Family Wins — Lila                                      │
│  ──────────────────                                      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  🌟  Lila mastered K.CC.4a — counting one-to-│      │
│  │      one.                                     │      │
│  │      Today                                    │      │
│  │      [Send card via Messages / Mail / Save]  │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  🏗  Lila built her first habitat for a fawn │      │
│  │      shelter!                                 │      │
│  │      Yesterday                                │      │
│  │      [Send card]                             │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  📚  First 5 numerals written.               │      │
│  │      3 days ago                               │      │
│  │      [Send card]                             │      │
│  └──────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### Card design

Cards are PNG images generated on-device, sized for share-sheet output. They include:
- A celebratory illustration (the kid's avatar + buddy + a themed background)
- The achievement text
- Date
- A tiny CritMath logo
- **No coin counts, no leaderboard, no comparisons to other kids**

Sharing uses the system share sheet (Messages, Mail, Save to Photos, etc.). Phase 1: Flutter's `share_plus` package wraps the same iOS sheet; Phase 2: native `UIActivityViewController`.

### What triggers a card

- Mastery promotion (`Introduced → Practicing → Mastered`).
- Milestone trophy unlock (per `reward-catalog.schema.json`).
- Permanent fixture built (Build-a-Habitat).
- Streak achievements (7 days, 30 days, etc.).

---

## Screen: Settings

```
┌─────────────────────────────────────────────────────────┐
│  Settings                                                │
│  ─────────                                               │
│                                                          │
│  Real-world integration                                  │
│                                                          │
│   [○] Weather mirrors local weather                     │
│   [○] Holiday events                                    │
│   [○] Birthday celebrations                             │
│        Birthday: [not set]   [Set]                      │
│   [○] Day/night cycle                                   │
│   [○] Approximate location for weather                  │
│        Current: [not set]   [Set city]                  │
│                                                          │
│  Audio                                                   │
│                                                          │
│   Narration            [ ON ]                            │
│   Music volume         ▆▆▆▆▆▁▁▁▁▁                       │
│   SFX volume           ▆▆▆▆▆▆▆▁▁▁                       │
│                                                          │
│  Accessibility (v1.1 items shown grayed out)             │
│                                                          │
│   VoiceOver labels     [ ON ]                            │
│   Color-blind palette  [ off ] (coming soon)             │
│   Dyslexia-friendly    [ off ] (coming soon)             │
│   Tap-only mode        [ off ] (coming soon)             │
│                                                          │
│  PIN gate                                                │
│                                                          │
│   Require PIN to enter dashboard    [ off ]              │
│   [Set PIN]                                              │
│                                                          │
│  Privacy & data                                          │
│                                                          │
│   [○] Send anonymous usage telemetry                    │
│        (off by default)                                  │
│   [Export this kid's data]                              │
│   [Delete this kid's data]                              │
│                                                          │
│  About                                                   │
│   Version, credits, support contact                      │
└─────────────────────────────────────────────────────────┘
```

All settings are per-kid where appropriate (audio is per-device; real-world toggles are per-kid; PIN is per-device).

---

## Screen: Manage Kids

```
┌─────────────────────────────────────────────────────────┐
│  Manage Kids                                             │
│  ────────────                                            │
│                                                          │
│  Lila (Kindergarten)        last played today           │
│  [Edit profile]   [Remove]                              │
│                                                          │
│  Jaime (1st grade)          last played yesterday       │
│  [Edit profile]   [Remove]                              │
│                                                          │
│  [+ Add a kid]                                           │
└─────────────────────────────────────────────────────────┘
```

Remove flow follows the triple-confirm pattern in `multi-kid-device-routing.md`.

---

## Teacher-only screen: Class Roster

A grid of all kids on this device with at-a-glance status.

```
┌─────────────────────────────────────────────────────────┐
│  Mrs. Walker's K class    [Filter by: All ▾]           │
│  ─────────────────────                                  │
│                                                          │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐         │
│  │Lila  │ │Jaime │ │Sam   │ │Ari   │ │Quinn │         │
│  │ 🟢🟢🟢│ │ 🟢🟡 │ │ 🟢🟢 │ │ 🟡🟡 │ │  ⚪   │         │
│  │ 🟢🟡⚪│ │ 🟢🟢🟡│ │ 🟡⚪⚪│ │ ⚪⚪⚪│ │  ⚪   │         │
│  │ 4d   │ │ 3d   │ │ today│ │ 6d   │ │ never│         │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘         │
│                                                          │
│  Legend  🟢 Mastered  🟡 Practicing  🟠 Struggling     │
│          ⚪ Not yet started                              │
│                                                          │
│  Each card shows 6 strand-tiles (rough mastery roll-up) │
│  and "last played N days ago" or "today".               │
│                                                          │
│  Tap a card to enter that kid's full Progress view.     │
└─────────────────────────────────────────────────────────┘
```

### Filters

- "All" — every kid
- "Played today" — focus on active kids
- "Needs attention" — kids with struggle flags or no recent play

### Heat-map perspective

Toggle to a horizontal grid (kids × standards) for a class heat map. Standard mastery shown as colored cells. Same data, different shape — useful for "where is my class as a whole?"

---

## Teacher-only screen: Assignments

Push a specific activity to one kid or the whole class.

```
┌─────────────────────────────────────────────────────────┐
│  Assign an activity                                      │
│  ──────────────────                                      │
│                                                          │
│  To:    [ Whole class ▾ ]   (or pick kids)              │
│                                                          │
│  Activity:                                               │
│    ○ Counting Parade                                     │
│    ○ Ten-Frame Pond                                      │
│    ● Storyteller's Pond                                  │
│    ○ Shape Garden                                        │
│    ...                                                   │
│                                                          │
│  Sub-mode:                                               │
│    ● add-to (default)                                    │
│    ○ take-from                                           │
│    ○ put-together                                        │
│    ○ take-apart                                          │
│                                                          │
│  Number of rounds: [3 ▾]                                │
│                                                          │
│  Window: [Tonight only ▾]                                │
│           (Tonight / This week / Until next class)       │
│                                                          │
│  Note to kids: ┌────────────────────────────┐           │
│                │ "Let's practice add-to     │           │
│                │  stories today!"           │           │
│                └────────────────────────────┘           │
│                                                          │
│              [Cancel]  [Assign]                          │
└─────────────────────────────────────────────────────────┘
```

### How an assignment appears to the kid

- The kid sees a small "From your teacher" banner in their Hub when they next open the app.
- Tapping the banner launches the assigned activity directly (skipping the kid's choice of activity).
- The assignment counts toward their Daily Quest streak.
- After completion, the banner clears.

### Assignment management

A teacher can see in-progress assignments + completion status from this tab.

---

## Teacher-only screen: Export

LMS / report export.

```
┌─────────────────────────────────────────────────────────┐
│  Export                                                  │
│  ──────                                                  │
│                                                          │
│  Format:                                                 │
│    ○ Standards-by-kid CSV                                │
│    ○ Class summary PDF                                   │
│    ○ Individual kid PDF                                  │
│    ○ Google Classroom CSV (v1.1)                         │
│    ○ Schoology CSV (v1.1)                                │
│                                                          │
│  Time range:                                             │
│    ○ This week                                           │
│    ○ This month                                          │
│    ○ Custom: [Start] - [End]                             │
│                                                          │
│  Kids:                                                   │
│    [✓] All     (or pick specific kids)                  │
│                                                          │
│              [Cancel]   [Generate & Save]                │
└─────────────────────────────────────────────────────────┘
```

### Launch scope

- **Standards-by-kid CSV** (mastery state per Utah standard per kid)
- **Class summary PDF** (one-page snapshot suitable for parent night handouts)
- **Individual kid PDF** (one-page progress report per kid)

### v1.1+ scope

- Google Classroom CSV format
- Schoology CSV format
- Direct LMS sync (OneRoster, ClassLink)

The PDF / CSV files save to the iPad's Files app for teacher distribution.

---

## Permissions model

| Capability | Parent | Teacher (in-classroom mode) |
|---|---|---|
| View kid's progress | ✅ | ✅ (any kid on device) |
| Replay lessons | ✅ | ✅ |
| Toggle real-world integration | ✅ | ✅ (per-device-wide) |
| Set PIN | ✅ | ✅ |
| Add/remove kids | ✅ | ✅ |
| Assign activities | — | ✅ |
| Export reports | — | ✅ |
| View class roster heatmap | — | ✅ |

Teacher mode is a superset of parent mode (plus 3 extra tabs).

---

## Data sources & freshness

| View | Data source | Refresh |
|---|---|---|
| Today summary | session log + mastery state | live (re-read on tab open) |
| Progress heat | mastery state | live |
| Library | filed lesson entries | live |
| Family wins | recent reward events | live |
| Class roster | mastery state per kid | live (cached 1 min between tab switches for perf) |
| Assignments | assignment state per kid | live |
| Export | mastery + session log over time range | computed at export-time |

All data is read locally; no network call required for any view.

---

## Visual design language

- **Same art style as the Hub** — hand-drawn warmth, soft colors, gentle UI.
- **Same fonts** — readable for parents/teachers (slightly larger size than the kid UI's icon-first design).
- **No spreadsheet vibes** — even the class heatmap uses soft gradients and rounded cells, not Excel-grid lines.
- **Region accents** — when a kid is in Sanctuary, their progress view has subtle Sanctuary leaf decoration in the corners. Wundletown view uses wand iconography. Mathopolis uses badge iconography.
- **Tone in text** — warm, informational, never panicky. "Lila has had some trouble with X" not "Lila is failing at X."

---

## Accessibility

- **VoiceOver labels** on every interactive element.
- **Dynamic Type** support (font scales with parent's iOS text size preference).
- **High-contrast mode** support (per iOS system setting).
- **Keyboard navigation** for parents using accessibility keyboards.
- **Color-blind safe** — every color-coded status (🟢🟡⚪) is paired with a text label or icon shape.

---

## Telemetry (dashboard-specific)

| Event | Payload |
|---|---|
| `dashboard.opened` | `mode` (parent / teacher), `tab` |
| `dashboard.tab_switched` | `fromTab`, `toTab` |
| `dashboard.lesson_replayed` | `kidId`, `conceptId`, `lessonId` |
| `dashboard.family_card_shared` | `kidId`, `cardType`, `shareDestination` (Messages / Mail / SaveToPhotos) |
| `dashboard.setting_changed` | `settingName`, `newValue`, `kidId?` |
| `dashboard.assignment_pushed` | `targetKidIds`, `activityId`, `subMode`, `rounds`, `window` |
| `dashboard.export_generated` | `format`, `kidIds`, `timeRangeDays` |

---

## Empty / first-time states

- **First time a parent opens the dashboard** — show a brief 4-card walkthrough (Today / Progress / Library / Settings). Skippable. Never shown again unless the parent taps "How does this work?" in Settings.
- **No kids yet** — should never happen post-onboarding, but if it does, dashboard shows "Add a kid to get started" with a button.
- **Kid hasn't played yet** — Today screen says "Lila hasn't played yet. When she does, you'll see what she's been working on here."

---

## Open Questions

- **Family sharing without iCloud** — at launch, family-win cards are device-local share-sheet exports. v1.1+ may add iCloud Family Sharing integration so cards auto-route to family members.
- **Teacher class size** — current spec assumes ≤ 30 kids per device. Larger class districts may want 60+. Defer to classroom pilot feedback.
- **Custom mastery thresholds** — should teachers be able to adjust the 5/3/3 thresholds for IEP cases? Plan says v1.1. Confirm.
- **Notifications** — should parents get a push notification when a kid hits a milestone? Tempting but adds friction (notification permission prompt). Suggest **no notifications at launch**; opt-in in v1.1.
- **Privacy policy / terms-of-service surface** — link in Settings → About is enough at launch; consider in-onboarding consent flow for COPPA-strict deployments.
- **Web-based teacher dashboard** — accessing from a desktop instead of the iPad. Substantial scope; defer to v2+.
- **Pre-built lesson plans for teachers** — "here's a 5-day plan for K.OA introduction." Defer to v1.1 if teachers ask for it.

---

## Implementation notes

### Suggested widget tree

Per `platform-architecture.md`, Phase 1 is Flutter widgets; Phase 2 swaps to SwiftUI views. The decomposition is identical across phases.

```
DashboardRoot (tab coordinator; parent vs teacher mode)
├── Today
├── Progress
│    ├── StrandSummaryCard
│    └── StandardDetailPanel (expanded view)
├── Library
├── FamilyWins
│    └── ShareCardComposer (PNG generation + system share sheet)
├── Settings
├── ManageKids
├── ClassRoster (teacher only)
│    └── HeatMapToggle
├── Assignments (teacher only)
│    └── AssignmentComposer
└── Export (teacher only)
     └── ExportGenerator (CSV / PDF)
```

### Reusable components

- **StandardBadge** — the ⚪🌱🌿✅⚠️ status indicators. Reusable for both parent and teacher views.
- **ProgressBar** — strand-level bar. Used in Progress + Class Roster.
- **KidSelector** — dropdown at top of parent views (only when ≥ 2 kids).
- **ShareCardComposer** — generates a PNG card and triggers the system share sheet.

### Performance

- Class Roster with 30 kids: each card is a small widget/view. Should render in < 100 ms.
- Export generation: CSV is trivial. PDF generation runs on a background queue with a progress indicator if > 1 second.
- All views read from the in-memory mastery state index (per `adaptive-scaffolding.md`'s Runtime Implementation Notes). No disk read on tab switch.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — parent mode (Today / Progress / Library / Family Wins / Settings / Manage Kids), teacher mode (adds Class Roster / Assignments / Export), per-screen ASCII mockups, permissions model, data sources, accessibility, telemetry, v1.1 deferrals (LMS sync, notifications, custom thresholds) | |
