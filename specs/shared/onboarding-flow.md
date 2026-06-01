# Onboarding Flow

> The first-launch experience: from "kid opens the app for the first time" to "kid is playing their first round." Establishes parent setup, kid profile creation, hub home selection, avatar + buddy customization, and grade-region routing.

References: `specs/shared/k-activity-patterns.md`, `specs/shared/save-recovery.md`, `specs/shared/multi-kid-device-routing.md`, `we-are-going-to-eventual-lantern.md` (top-level plan).

---

## Goals

1. **Parent first.** First launch defaults to a parent-facing setup screen, not a kid-facing welcome. The app needs to know who's playing before showing kid UI.
2. **Quick.** End-to-end first-launch onboarding completes in ≤ **5 minutes** including parent setup + first kid setup.
3. **Forgiving.** Every choice in onboarding can be changed later from the parent dashboard.
4. **Pre-literate-safe.** Kid-facing onboarding screens use audio + icons. Text exists for parents to read aloud but is not required for kid completion.

---

## Flow at a glance

```
[First Launch]
      ↓
[Parent Setup] ─────────────────────► [Parent Dashboard saved]
      ↓
[Create First Kid Profile]
      ↓
[Kid Onboarding]
   ├─ Pick Hub Home (cottage / castle / treehouse / sci-fi base)
   ├─ Name your home (procedurally suggested or custom)
   ├─ Customize Avatar (skin tones, hair, faces, outfits)
   ├─ Customize Buddy (body, ears, tail, eyes, fur, accessories)
   ├─ Pick starting grade region (K / 1 / 2)
   └─ "Welcome to the island" cutscene (~20s)
      ↓
[First Daily Quest auto-launches]
      ↓
[Kid is playing]
```

---

## Phase 1 — Parent Setup

**Audience:** parent. Required on first launch. Parent dashboard becomes accessible from the kid hub via a long-press on a dedicated icon after this.

### Steps

1. **Welcome + permissions** — brief intro to the product; request system permissions (mic always-off-no-request; Apple Pencil already detected; **location: not requested at launch** — opt-in later in dashboard).
2. **Parent name + email** — optional, used for restore/account if cloud sync ships. **Skippable**; the app works fully offline without an account.
3. **First kid profile setup** — see Phase 2.
4. **Real-world integration toggles** (default OFF, parent can flip):
   - Weather (mirrors local weather in-game)
   - Holiday events
   - Birthday celebrations (parent enters kid birthdate if enabled)
   - Day/night cycle
   - Approximate location for weather (city-level, never precise)
5. **Audio settings** — narration on/off, music volume, SFX volume.
6. **Accessibility toggles** — VoiceOver, color-blind palette (v1.1), motor-accessibility tap-vs-drag fallbacks (v1.1).

### Save behavior
- Parent settings persist immediately as they're toggled (no "save" button).
- If parent quits mid-setup, on next launch the app resumes at the unfinished step.

---

## Phase 2 — Create Kid Profile

**Audience:** parent (with kid possibly watching). First step of Phase 1 chains into this; subsequent kid additions are reached from the parent dashboard.

### Steps

1. **Kid name** — used only in the in-app UI; not for advertising or tracking.
2. **Kid age / grade** — sets the **starting grade region** (K, 1, or 2). Parent can also pick "let the kid choose."
3. **Birthday** — optional. If provided AND the birthday-events toggle is on, the Buddy/Avatar throws a party on the day.
4. **Avatar parts** — defer to Phase 3 (kid does this themselves).

### Multi-kid note

When adding a second kid on the same device, Phase 1's parent setup is skipped. See `multi-kid-device-routing.md` for the kid-picker UI that appears at app launch when 2+ kids exist.

---

## Phase 3 — Kid Onboarding (kid-facing)

**Audience:** the kid. Audio narration leads; text is parent-readable but not required. Tone: warm, welcoming, slightly mysterious ("you've arrived at a magical island").

### Step 3.1 — "Welcome to the island" intro (~10 s)
- Visual: arrival cutscene from above the Mystical Island (whichever grade region they'll start in glows softly).
- Narrator: "Welcome to your island! Let's set up your home."

### Step 3.2 — Pick Hub Home
Per `we-are-going-to-eventual-lantern.md`, four home styles. Kid taps a card:

| Style | Procedural names (random pick offered, kid can rename) |
|---|---|
| Cottage | Lantern Cottage, Hearthstone Cottage, Mossfern House, Brookfield Cottage |
| Castle | Sparrow Keep, Moonshell Keep, Driftspire Castle, Bramblewell Keep |
| Treehouse | Bramble Roost, Skylark Roost, Highleaf Treehold, Nestwood |
| Sci-fi Base | Astra Outpost, Beacon Base, Pulsewing Outpost, Helix Station |

After picking a style, a name appears with two buttons: **Keep this name** or **Pick another**. Custom rename requires parent assist (text input).

### Step 3.3 — Customize Avatar
Kid customizes from parts library. Parts at launch:
- **Skin tone** — palette of 8 (inclusive range)
- **Hair** — 12 styles × 8 colors
- **Face** — 6 base shapes, separate eye/mouth options
- **Outfit** — 6 starter outfits (more unlocked via play)

UI: a paper-doll mannequin with category tabs (skin/hair/face/outfit). Tap a category, swipe through options, tap to commit. No "save" button — final state saves on exit.

### Step 3.4 — Customize Buddy
Kid customizes the Math Buddy creature from parts:
- **Body** — 6 base shapes (round, lanky, blob, etc.)
- **Ears** — 8 styles
- **Tail** — 8 styles
- **Eyes** — 6 styles
- **Fur/skin pattern** — 8 patterns + 8 color tints
- **Accessory** — 4 starter accessories (more unlocked)

Same UI pattern as Avatar.

### Step 3.5 — Pick starting grade region (only if parent set "let the kid choose")
Three big tappable cards: **Sanctuary** (K), **Wundletown** (1st), **Mathopolis** (2nd). Each with a short audio intro on tap. Kid picks; app routes there.

### Step 3.6 — "Welcome to the island" cutscene (~20 s)
- Visual: kid's customized Avatar and Buddy walk into the Hub interior of their picked home.
- Narrator: "This is your home. Your math buddy [Buddy name] lives here too. Let's see your island!"
- Visual transition: pulls back to show the island map with the grade-region pathway glowing.
- Narrator: "Today, you'll start at [Sanctuary/Wundletown/Mathopolis]. Let's go."

### Step 3.7 — First Daily Quest auto-launches
The Daily Quest curation algorithm (`daily-quest-curation.md`) selects the first kid's first quest. For a fresh K kid, this is typically:
- Counting Parade (introduces K.CC.4a + K.CC.4b)
- Bounded to ≤ 5 rounds and ≤ 5 minutes
- Lesson cap applies (per `micro-lessons.md` — max 2 lessons per session for fresh kids)

---

## Time budget

| Phase | Target | Cap |
|---|---|---|
| Parent setup | ~2 min | 5 min |
| First kid profile | ~30 s | 2 min |
| Kid onboarding | ~2.5 min | 5 min |
| **Total** | **~5 min** | **12 min** |

If the parent quits mid-onboarding, resume on next launch from the last completed step.

---

## What's NOT in onboarding

- **Tutorial of game mechanics** — those play as activity-spec MicroLessons on first encounter, not as a separate onboarding flow.
- **Reading-load assessment** — pre-K assumption is no reading; 1st and 2nd grade auto-show short text alongside audio per the audio-supported-text-decision in the plan.
- **Skill placement test** — no quiz on launch. Adaptive scaffolding figures out the kid's level through play.
- **Account/cloud sync** — optional in parent setup; not blocking.

---

## Parent dashboard re-entry

After first launch, parents reach the dashboard via:
- A discrete icon in the top-right of the Hub (e.g., a small gear).
- **Long-press** to open (prevents kid accidentally entering the dashboard).
- Optional **PIN gate** parents can enable from within the dashboard (off by default at launch).

The dashboard is documented separately (per `we-are-going-to-eventual-lantern.md`'s "Parent / Teacher Dashboard" section).

---

## Privacy & data

- **No data leaves the device by default.** All saved state is local.
- **Cloud sync** is opt-in via parent account; v1.1 if not in launch scope.
- **Telemetry** (analytics) is parent-toggleable; default to OFF at launch, prompt parent during setup. Telemetry is anonymized and aggregate when on.
- **No advertising IDs, no third-party tracking.**

---

## Error states

- **Network unavailable during parent setup** — app proceeds (offline is supported); cloud sync prompts deferred.
- **Mid-onboarding crash** — resume from last completed step on relaunch.
- **Kid abandons mid-onboarding** — Avatar/Buddy/home state is saved as configured so far; on next launch, kid is taken to the unfinished step (not restarted).
- **No Apple Pencil detected** — finger-input fallback always works; gentle prompt suggests "an Apple Pencil might feel nicer" but doesn't block.

---

## Implementation notes

### Suggested widget tree

Per `platform-architecture.md`, Phase 1 is Flutter widgets; Phase 2 swaps to SwiftUI views. The component decomposition is identical across phases — only the framework names change.

```
OnboardingCoordinator (state machine across all phases)
├── ParentSetup (steps 1-4 of Phase 1)
├── KidProfileSetup (Phase 2)
├── KidOnboardingFlow (Phase 3)
│    ├── HomePicker
│    ├── AvatarCustomizer (paper-doll component)
│    ├── BuddyCustomizer (same component, different parts library)
│    └── RegionPicker
├── ArrivalCutscene
└── HandoffToDailyQuest (calls into DailyQuestCoordinator)
```

### Reusable components

- **PaperDollCustomizer** — generic part-picker used for both Avatar and Buddy (different parts libraries).
- **ProceduralNameSuggester** — pulls from per-home-style name pool.
- **CutsceneRunner** — also used by lesson runner's I-Show phases; reuse.
- **RegionPickerCard** — also used in the kid-picker (multi-kid routing).

### Performance

- Onboarding screens are mostly static + simple animations. Negligible overhead.
- Cutscenes use 2–5 sprite sequences; budget normally.

---

## Open Questions

- **PIN gate default** — off at launch (per spec); parents flip on if needed. Confirm in playtest this isn't a problem (kids accidentally entering dashboard).
- **Onboarding repeatability** — should the parent dashboard offer "redo onboarding" (e.g., kid hates their avatar choice)? Probably yes via per-element edit screens; full re-run unnecessary.
- **Multi-language onboarding** — English at launch (per `localization.md`); architecture ready for second language post-launch.
- **Age verification** — we don't verify kid age beyond what parent enters. COPPA assumes parent gate; the long-press dashboard + parent setup is our parent gate. Confirm with legal.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — covers parent setup, first kid profile, kid-facing onboarding (home / avatar / buddy / region), and handoff to first Daily Quest | |
