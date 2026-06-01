# Save & Recovery

> Consolidated save behavior across all activities + crash/background recovery rules. Activity specs each define their own "what happens when backgrounded mid-round" rules; this file unifies them into a single policy and details how the device persists kid state across launches and crashes.

References: `schemas/mastery-state.schema.json`, `specs/shared/adaptive-scaffolding.md`, `specs/shared/multi-kid-device-routing.md`, individual activity specs.

---

## Goals

1. **Never lose mastery progress.** Per-kid mastery state survives crashes, force-quits, low-battery shutdowns.
2. **Forgive interruptions.** A kid who pauses for a snack returns to the same round they left.
3. **Discard cleanly when interruption was too long.** Day-old in-progress rounds restart fresh.
4. **No data lost to a single crash.** Writes are durable enough that a crash mid-round costs at most one round.

---

## Implementation phases

Save/recovery is **largely platform-agnostic** per `platform-architecture.md`. Both Phase 1 (Flutter) and Phase 2 (native) write the **same JSON files in the same layout** — only the file-system API differs.

| Phase | File API | Atomic-write API |
|---|---|---|
| Phase 1 (Flutter) | `path_provider` + `dart:io` File | `File.rename()` after temp-file write |
| Phase 2 (native iPadOS) | `FileManager` | `replaceItemAt:` |

This preservation rule is critical: post-Mac migration, the native app picks up wherever the Flutter app left off without any data migration.

---

## What persists

### Always persisted (per kid)
- `KidProfile` (avatar, buddy, hub home, name)
- `MasteryState` — every `ConceptState` record (per `adaptive-scaffolding.md`)
- `LibraryEntries` — completed MicroLessons
- `RewardInventory` — earned coins, collectibles, blueprints, parts
- `AggregateCounters` — lifetime rounds, lifetime sessions, etc.
- `SessionLog` — per-day session records, retained 90 days (then aggregated + archived)

### Session-scoped state (per kid, ephemeral)
- `currentSession` — start time, current activity, current round count
- `SavedRoundState` — when activity exits or app backgrounds mid-round
- `dailyQuestProgress` — which Daily Quest rounds completed today

Session-scoped state expires per the rules in **Recovery windows** below.

---

## Recovery windows

| Scenario | What's preserved | What's discarded |
|---|---|---|
| **Backgrounded ≤ 5 min** | Mid-round state (placed items, partial frames, current question, hints used) | Nothing |
| **Backgrounded 5 min – 1 hour** | Round state for the **current activity only** (continue to that activity, restart the round) | Mid-round placements; restart from round start |
| **Backgrounded 1 hour – 24 hours** | The kid's session log entry for the day | Round state (not restored on relaunch) |
| **Backgrounded > 24 hours** | Mastery + all persistent data | Session log carries over; current-session-context is reset |
| **Force quit / crash** | Same as backgrounded — depends on time gap | Mid-round state if write hadn't flushed |
| **Device reboot** | Same as crash | Same |
| **App update** | All persistent data via migration on first launch | TBD per migration spec |

The **5 min** window is short enough that "kid ate a snack and came back" feels seamless; long enough that "kid abandoned" doesn't leave permanent stale state.

---

## Write strategy

### Per-mutation writes (always, no batching)
- Mastery state changes (`firstEncounter` flip, layer promotion/demotion, mastery threshold reached).
- Library entry creation.
- Coin awards (per `economy.coins_earned` event).
- Collectible drops.

These can be small writes batched in memory and flushed on:
- Round completion
- Activity exit
- App backgrounded
- App force-quit (caught via `applicationWillTerminate`)

In practice, flushing on **activity exit** is the typical write point (per `adaptive-scaffolding.md`'s persistence guidance). Round-completion flushes happen often enough that mid-activity crashes lose at most one round.

### Round-state writes (defensive)

When a round is in-progress, write `SavedRoundState` to disk:
- On every meaningful kid action (tap, drop, draw line, etc.).
- Throttled to ~1 write per second (avoid disk thrash on rapid kid input).

`SavedRoundState` is a small JSON blob (typically < 5 KB):
```jsonc
{
  "activityId": "ten-frame-pond",
  "subMode": "fill-to-target",
  "roundStartedAt": "2026-05-30T14:32:11Z",
  "roundParams": { "target": 7, "presentationLayer": "Concrete" },
  "placements": [{"fish": "f1", "pad": "top-row-1"}, ...],
  "countSoFar": 4,
  "hintsFired": ["highlight-empty-pad"],
  "attemptsThisRound": 1
}
```

On resume:
- The activity reads `SavedRoundState` and reconstructs the scene.
- Animations are skipped (no replay of arrivals); state is the final settled state.
- A subtle "welcome back" cue plays (a Buddy hop) but no narration interruption.

---

## Crash recovery

A crash mid-round means:
1. The kid's mastery state is at whatever the last flush captured (usually the last completed round).
2. `SavedRoundState` was likely written shortly before the crash (within ~1 s).
3. On relaunch:
   - App routes to the kid's last-active state.
   - If `SavedRoundState` exists and is ≤ 5 min old: offer "continue your round" (auto-yes within 5 min, prompt for 5 min – 1 hour).
   - If older: discard.

The kid sees, at most, a "let's start a new round" moment — never a "your progress is gone" moment.

---

## Per-activity background behavior

Each activity spec declares its own "app backgrounded mid-round" rule. They should align with this global policy:

| Activity | Background behavior (consistent with policy) |
|---|---|
| Counting Parade | Pause and persist; resume within 5 min restores tap state; beyond, restart round |
| Ten-Frame Pond | Same; placements restored within 5 min |
| Scribe's Tower | Trace in progress is canceled on disconnect/background; ghost outline remains; kid restarts trace on resume |
| Storyteller's Pond | Story playback pauses mid-stream; resume within 5 min continues from pause point; beyond, restart the story |
| Build-a-Habitat | Phase + placements preserved within 5 min; resume to active phase; beyond, restart current phase |
| Care Pantry | Phase + placements preserved within 5 min |
| Picnic Baskets | Drawn lines + placements preserved within 5 min |
| Caretaker's Bench | Object placements preserved within 5 min |
| Shape Garden | Tap progress preserved within 5 min |
| Where's Buddy? | Drop state preserved within 5 min (rare for a kid to interrupt mid-drop) |
| Fluency Within 5 | Round restarts on resume regardless of timing (rounds are short — 8 problems in <2 min) |
| MicroLessons (any) | Pause and persist; resume from the same step within 5 min; restart phase if longer |

The 5-min window is consistent across activities.

---

## Backup & restore (v1.1)

At launch, save data is **local only**. v1.1 adds:
- iCloud sync (per Apple's standard mechanism — Phase 2 / native-phase feature per `platform-architecture.md`).
- Manual export/import (for switching devices or family handoff).
- Per-kid restore (in case of corrupted profile).

This file defers v1.1 specifics until then.

---

## Storage size budget

Per-kid total storage ceiling (year 1 of play):
- KidProfile + customizations: ~10 KB
- MasteryState: ~80 KB worst case (per-instance grade 2 kid)
- LibraryEntries: ~5 KB (just IDs + dates; assets cached elsewhere)
- RewardInventory: ~20 KB
- SessionLog (90 days): ~300 KB
- SavedRoundState: ~5 KB

**Total ~420 KB per kid.** A family device with 4 kids fits well under 2 MB. Cloud sync per kid is similarly cheap.

---

## Migration on schema changes

When mastery-state.schema.json or related schemas bump version:
- On first launch after update, app detects version mismatch and runs `migrate(oldData, oldVersion, newVersion)`.
- Migrations are forward-only; no rollback.
- Migration logs to telemetry; crashes during migration must be reproducible from logs.
- Pre-launch: only one schema version exists, so migration is a stub until v1.1.

---

## Telemetry

| Event | Payload |
|---|---|
| `save.flushed` | `kidId`, `flushReason` (activity-exit / round-complete / background / etc.), `bytesWritten` |
| `save.resume_offered` | `kidId`, `savedRoundAgeSec`, `activityId` |
| `save.resume_accepted` | `kidId`, `activityId` |
| `save.resume_declined_too_old` | `kidId`, `savedRoundAgeSec` |
| `save.crash_recovery_detected` | `kidId`, `lastFlushAgeSec` |
| `save.migration_run` | `fromVersion`, `toVersion`, `durationMs`, `success` |

---

## Implementation notes

### Suggested module structure

```
SaveCoordinator
├── KidStateStore (per-kid loader/saver; lazy-loaded)
├── SavedRoundStateBuffer (throttled writer)
├── ResumeRouter (decides on launch: continue / restart / fresh)
└── MigrationRunner (v1.1+)
```

### File format

JSON at launch. Pros: human-readable, easy to debug, well-supported in Dart (Phase 1) and Swift (Phase 2). Same file layout in both phases — the native phase reads exactly the files Flutter wrote.

Consider migrating to a binary format (protobuf, MessagePack) in v2 if file sizes grow beyond ~5 MB per kid.

### Atomic writes

All persistent writes use atomic file replacement (write to temp file, fsync, rename). Prevents partial-write corruption from a crash mid-write.

### Disk I/O

Save flushes run on a background queue; never block the main thread. The lesson runner / activity runner await flush completion only when transitioning between activities (to ensure the next activity sees consistent state).

---

## Open Questions

- **Cloud sync conflict resolution** — last-write-wins is the default; more sophisticated merge for v1.1 if needed.
- **Backup encryption** — local saves are not encrypted at rest (the iPad's filesystem is already device-encrypted under Apple's standard). Confirm with security review.
- **Crash recovery for the lesson runner** — if a lesson crashes mid-I-Show, do we resume from the last animation step or restart the lesson? Suggest restart for simplicity; consider partial-resume in v1.1 if telemetry shows kids hitting this.
- **Session log archival policy** — 90 days at launch. Some teachers may want longer for end-of-year reports; defer to teacher dashboard requirements.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — consolidated per-activity background rules into a single 5-min/1-hr/24-hr window policy; added crash recovery, write strategy, storage budgets, and v1.1 backup-and-restore deferral | |
