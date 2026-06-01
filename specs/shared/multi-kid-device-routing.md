# Multi-Kid Device Routing

> How a single iPad supports multiple kid profiles. Most family devices will have 1–3 kids; classroom devices may have 5–30. The data model is per-kid; the launch flow has to route correctly to the right kid every time without slowing down the kid who just wants to play.

References: `specs/shared/onboarding-flow.md`, `specs/shared/save-recovery.md`, `specs/shared/adaptive-scaffolding.md`, `schemas/mastery-state.schema.json`.

---

## Goals

1. **Fast for the only kid.** A device with one kid never sees a picker — taps go straight into their Hub.
2. **Clear for shared devices.** A picker shows when ≥ 2 kids exist; kid taps their avatar to enter.
3. **No mistaken kid.** Once chosen, the kid is in their own state until they explicitly switch.
4. **Parent-gated kid management.** Adding, removing, or editing kid profiles is gated by the parent dashboard (long-press + optional PIN).

---

## Data model

### Device-level data
- `Device { deviceId, parentSettings, kidProfileIds: [KidId], lastActiveKidId, accessibilitySettings }`

### Per-kid data
- `KidProfile { kidId, displayName, avatar, buddy, hubHomeStyle, hubHomeName, gradeRegion, birthday?, lastActive, masteryState (per adaptive-scaffolding.md), libraryEntries, savedRoundStates }`

Each `KidProfile` is a self-contained save bundle. Switching kids is a context swap, not a data migration.

### Storage

Local file system (per `save-recovery.md`):
```
{appSupport}/
  device.json
  kids/
    {kidId}/
      profile.json
      mastery.json
      library.json
      saved_round_state.json
      session_log/
        2026-05-30.json
        2026-05-29.json
        ...
```

Cloud sync (v1.1+) preserves the same structure per kid.

---

## Launch routing

### 1 kid (most common at home)

```
[App launch]
   ↓
[Parent already setup? Yes]
   ↓
[1 kid profile exists, never PIN-gated]
   ↓
[Auto-enter that kid's Hub]
   ↓
[Daily Quest banner shows if not yet completed today]
```

No picker. No friction.

### 2+ kids

```
[App launch]
   ↓
[Parent already setup? Yes]
   ↓
[≥ 2 kid profiles exist]
   ↓
[Show Kid Picker screen]
   ↓
[Kid taps their avatar card]
   ↓
[Enter that kid's Hub]
```

### Kid Picker UI

- A grid of large avatar cards (1 row of 2–3 kids, scrolls if more).
- Each card shows: kid's avatar + buddy + their name + their hub home thumbnail.
- The most-recently-active kid is **first**, slightly larger, slightly highlighted (saves a tap for the common case where the same kid plays back-to-back days).
- Bottom-right: small "+" icon to **add a kid** (gated — opens parent dashboard for confirmation).
- Bottom-left: small "parent" gear icon (long-press to enter dashboard).

### First launch on this device

See `onboarding-flow.md`. Picker doesn't appear on first launch; flow goes straight to parent setup + first kid creation.

---

## Switching kids mid-session

If a kid wants to switch:
- **From the Hub**: tap the kid's avatar at the top-right of the Hub → drops to Kid Picker.
- **From an activity**: tap Exit → Hub → tap avatar → Kid Picker.
- Switching kid saves the current kid's `savedRoundState` (in case they come back to that activity within 5 min).

No "switch kid mid-activity" path; the kid has to exit the activity first. Prevents accidental score mix-up.

---

## Classroom / shared device considerations

For classroom devices with many kids:
- Picker can show up to **30 avatar cards** without performance issues (paged scroll if more).
- A teacher dashboard mode (v1.1) might offer **search by name** if 30+ kids.
- Classroom-licensed devices may add **session timeouts** (e.g., auto-return-to-picker after 2 min of idle) to free the iPad for the next student. Default off; opt-in via classroom dashboard.

---

## Adding a kid

Always parent-gated.

```
[Kid Picker]
   ↓
[Tap "+"]
   ↓
[Long-press confirmation (parent gate)]
   ↓
[Optional PIN if enabled]
   ↓
[Kid Profile Setup flow per onboarding-flow.md Phase 2]
   ↓
[Kid Picker (new card visible)]
```

---

## Removing a kid

Always parent-gated. Triple-confirm (because this deletes all of that kid's progress).

```
[Parent Dashboard → Manage Kids]
   ↓
[Tap kid → Remove]
   ↓
[Confirm 1: "This deletes everything they've earned. Continue?"]
   ↓
[Confirm 2: type the kid's name to confirm]
   ↓
[Kid profile + save data deleted from disk; lastActiveKidId reset]
```

Cloud-synced kids may have a 30-day archive period before permanent deletion (v1.1).

---

## Edge cases

- **Last-active kid was deleted** — picker shows; no kid is highlighted/first; kid taps any card to enter.
- **All kids deleted** — picker shows "Add a kid" centered; tap goes to onboarding Phase 2.
- **Kid picker shown but only 1 kid remains** (after a deletion) — next launch auto-enters that 1 kid (no picker).
- **Two kids share an avatar appearance** — picker shows their kid-names below the avatar card; names disambiguate.
- **Kid's profile state is corrupted** — picker shows the kid with a small "needs help" icon; tapping prompts parent. App doesn't auto-delete.
- **Kid's birthday is today** — picker badges that kid's avatar with a small cake icon as a visual treat (no action required).

---

## Privacy & switch behavior

- No biometric kid-identification (no face unlock, no kid-voice).
- The picker is "the family knows who's playing." Trust model = "the kid taps their own avatar."
- A kid playing under another kid's profile won't break anything but their progress goes to the wrong saves — the dashboard surfaces this if mastery patterns shift dramatically between days.

---

## Telemetry

| Event | Payload |
|---|---|
| `device.app_launched` | `kidProfileCount`, `lastActiveKidId` |
| `device.kid_selected` | `kidId`, `secondsToTap` (how long picker was shown before tap) |
| `device.kid_switched_mid_session` | `fromKidId`, `toKidId`, `priorActivityId` |
| `device.kid_added` | `newKidId` |
| `device.kid_removed` | `removedKidId` |

---

## Implementation notes

### Suggested widget tree

Per `platform-architecture.md`, Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical.


```
AppRoot
├── LaunchRouter (decides: onboarding / picker / direct-to-hub)
├── KidPickerView (only shown when ≥ 2 kids)
│    ├── KidPickerCard (per kid)
│    └── AddKidButton (parent-gated)
└── KidSession (the rest of the app, scoped to one kid's state)
```

### Persistence

- `device.json` loads at app start; tells the router how many kids exist and who was last active.
- Per-kid state loads lazily when the kid is selected. Don't preload all kids' states.

### Performance

- Kid pickers with 5+ kids: avatar/buddy thumbnails should be pre-rendered to PNG at profile-save time, not regenerated on picker load.

---

## Open Questions

- **PIN gate for kid switching** (not just for adding/removing) — should parents be able to require a PIN to switch kids? Probably overkill for most families. Defer to v1.1.
- **Family identity (single Apple Account, multiple kids)** — at launch, no Apple ID required. v1.1 may add Apple-account-linked kid profiles for restore-across-devices.
- **Classroom session timeout** — proposed off-by-default. Confirm with classroom pilots.
- **Kid avatar collision** — two siblings might want very similar avatars. The customizer offers enough variation; if collisions occur, the picker uses the kid-name label.
- **Auto-pick last active** — current spec shows the picker on every launch when ≥ 2 kids. Alternative: skip the picker if last-active was < 1 hour ago. Suggest the always-show approach at launch for safety; revisit if friction surfaces.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — single-kid auto-enter, multi-kid picker, parent-gated add/remove, classroom considerations | |
