# System Architecture

> How the modules wire together at runtime. Layers, dependency direction, source-of-truth ownership, runtime flows for the canonical scenarios. This is the contract between the ~25 component specs and the code that has to make them work as one product.

References: every other shared spec. In particular `platform-architecture.md` (phase boundary), `adaptive-scaffolding.md` (mastery engine), `micro-lessons.md` (lesson runner), `reward-economy.md` (reward engine), `save-recovery.md` (persistence), `voice-pipeline.md` (audio pipeline).

---

## Goals

1. **Single source of truth per concern.** Each piece of runtime state has exactly one owner. Other modules read; only the owner writes.
2. **Dependency direction is strict.** UI → coordinators → engines → data → platform. Same-layer cross-talk happens through documented interfaces, never private state.
3. **Engines are pure logic.** No UI, no platform calls. Testable without Flutter.
4. **Platform boundary is narrow.** Phase 2 native swap touches only platform adapters + UI widgets, not engines or data.
5. **Scope-bounded state.** App-scoped vs device-scoped vs kid-scoped vs session-scoped. Switching kids tears down kid-scope; quitting an activity tears down session-scope.

---

## Layer overview

```
┌──────────────────────────────────────────────────────────────────────┐
│ UI LAYER                                                             │
│ Flutter widgets (Phase 1) / SwiftUI views (Phase 2)                  │
│ Screens: KidPicker, Onboarding, Hub, Activity, Lesson, Dashboard,    │
│          Foundry, Library                                            │
│ Subscribes to Coordinator / engine state via Riverpod providers      │
└────────────────────────────────┬─────────────────────────────────────┘
                                 │ events / state subscriptions
┌────────────────────────────────▼─────────────────────────────────────┐
│ COORDINATORS                                                         │
│ Orchestrate engines for a use case. Hold transient flow state.       │
│ RunActivityCoordinator, RunLessonCoordinator, OnboardingCoordinator, │
│ DashboardCoordinator                                                 │
└──────────────┬────────────────────────────────┬─────────────────────┘
               │                                │
┌──────────────▼────────────────┐  ┌────────────▼─────────────────────┐
│ ENGINES (pure logic)          │  │ DATA LAYER (in-memory caches)    │
│ ScaffoldEngine                │  │ ConceptRegistry                  │
│ MasteryEngine                 │  │ ActivityRegistry                 │
│ LessonRunner                  │  │ RewardCatalog                    │
│ ActivityRunner                │  │ FoundryCatalog                   │
│ RewardEngine                  │  │ TelemetryCatalog                 │
│ DailyQuestCurator             │  │ StandardsReference               │
│ FactScheduler                 │  │ LessonRuntimeLoader (lazy)       │
│ TelemetryPipe                 │  │ ActivityNarrationLoader (lazy)   │
│ SaveCoordinator               │  │ StringTableLoader (lazy)         │
└──────┬────────────────────────┘  │ AssetPathResolver                │
       │                           └─────────────┬────────────────────┘
       │                                         │
┌──────▼─────────────────────────────────────────▼────────────────────┐
│ PLATFORM ADAPTERS (phase boundary)                                  │
│ StylusInputProvider, AudioProvider, StorageProvider,                │
│ HandwritingRecognizer, LocaleResolver, SystemSharePort              │
│ Phase 1: Flutter packages    Phase 2: native iOS APIs               │
└──────────────────────────────────────────────────────────────────────┘
```

### Dependency rules (enforced by code review)

1. **UI → coordinators**. UI never imports engines or data layer directly. State is consumed via Riverpod providers exposed by coordinators.
2. **Coordinators → engines, data, platform**. Coordinators call into multiple engines and assemble their results.
3. **Engines → data, platform**. Engines may read from the data layer and platform adapters. Engines do NOT call each other directly except through documented interfaces (e.g., RewardEngine subscribes to MasteryEngine events via a shared event bus, not direct method calls).
4. **Data → platform**. Data layer uses StorageProvider for I/O and AssetPathResolver for paths.
5. **Platform adapters depend on nothing internal**. They wrap the OS/framework APIs.

**Violation patterns to avoid:**
- A widget directly reading `ConceptRegistry` (bypass: subscribe to a Coordinator-exposed view of it).
- An engine calling another engine via constructor injection of the concrete type (bypass: shared event bus or read-only interface).
- A platform adapter calling into an engine (bypass: never; adapters fire events that engines can subscribe to).

---

## Source-of-truth ownership

The principle: every piece of mutable runtime state has **one owner**. Other modules can read but must mutate through the owner's API.

| State | Owner | Backing persistence |
|---|---|---|
| `ParentSettings` | App-scoped Settings module | `device.json` |
| `KidProfileIndex` (list of all kids) | KidProfileManager | `device.json` |
| Active `KidId` | KidSessionScope | in-memory; restored on launch from `device.lastActiveKidId` |
| `KidProfile` (one kid's avatar/home/etc.) | KidProfileManager (per-kid) | `kids/{kidId}/profile.json` |
| `ConceptState` (one entry) | MasteryEngine | `kids/{kidId}/mastery.json` |
| `ConceptStateIndex` (in-memory map) | MasteryEngine | mirrors `mastery.json` at load |
| `LibraryEntries` | LessonRunner (writes), Library UI (reads) | `kids/{kidId}/library.json` |
| `RewardInventory` (coins, items, blueprints, parts) | RewardEngine | `kids/{kidId}/inventory.json` |
| `AggregateCounters` (lifetime rounds, sessions) | TelemetryPipe | `kids/{kidId}/counters.json` |
| `ActiveSession` (start time, current activity) | KidSessionScope | in-memory only |
| `SavedRoundState` (mid-activity) | ActivityRunner | `kids/{kidId}/saved_round_state.json` (1 entry at a time) |
| `DailyQuestState` (today's quest) | DailyQuestCurator | `kids/{kidId}/daily_quest/{date}.json` |
| `SessionLog` (events) | TelemetryPipe | `kids/{kidId}/session_log/{date}.json` |
| In-flight `LessonState` | LessonRunner | in-memory; on completion writes through to Library |
| In-flight `RoundState` | ActivityRunner | in-memory; throttled write to `SavedRoundState` |
| Registries (Concept/Activity/Reward/Foundry/Telemetry/StandardsReference) | DataLayer (read-only at runtime) | bundled `.json` in assets/data |

**Tests for ownership integrity:**
- A widget that mutates `ConceptState` directly fails review.
- Two engines that both write `RewardInventory` is a bug.
- The "single owner" rule is checked by integration tests that snapshot state hashes before/after each round and verify only the expected owner's hash changed.

---

## Module catalog

### UI screens

| Screen | Purpose | Lives in |
|---|---|---|
| `KidPickerScreen` | Multi-kid device routing per `multi-kid-device-routing.md` | `lib/ui/screens/kid_picker.dart` |
| `OnboardingScreen` | First-launch + new-kid flow per `onboarding-flow.md` | `lib/ui/screens/onboarding/` |
| `HubScreen` | The kid's home view; entry into activities, library, foundry | `lib/ui/screens/hub/` |
| `ActivityScreen` | Wrapper for any running activity | `lib/ui/screens/activity/` |
| `LessonScreen` | MicroLesson player (I-Show / We-Try / You-Do) | `lib/ui/screens/lesson/` |
| `LibraryScreen` | Stamp wall / Spell book / Casebook | `lib/ui/screens/library/` |
| `FoundryScreen` | Workshop + yard + tabs per `foundry-catalog.md` | `lib/ui/screens/foundry/` |
| `DashboardScreen` | Parent/teacher per `parent-teacher-dashboard.md` | `lib/ui/screens/dashboard/` |

### Coordinators (orchestration)

| Coordinator | Owns | Composes |
|---|---|---|
| `RunActivityCoordinator` | An activity-session flow from start to end-of-session | ScaffoldEngine, ActivityRunner, LessonRunner, RewardEngine, TelemetryPipe |
| `RunLessonCoordinator` | A single MicroLesson run (I-Show → We-Try → You-Do) | LessonRunner, RewardEngine, TelemetryPipe; calls into RunActivityCoordinator for the You-Do |
| `OnboardingCoordinator` | First-launch flow | KidProfileManager, SettingsModule |
| `DailyQuestCoordinator` | Today's quest assembly + execution | DailyQuestCurator, RunActivityCoordinator |
| `DashboardCoordinator` | Read-only views into all kids' state | MasteryEngine, RewardEngine, TelemetryPipe, all registries |

### Engines (pure logic, no UI/IO)

| Engine | Responsibility |
|---|---|
| `ScaffoldEngine` | Given (kidId, conceptIds, problemType), return `(presentationLayer, hintsAllowed, maxAttempts, firstEncounterLesson?)`. Stateless query interface; reads from MasteryEngine + ConceptRegistry. |
| `MasteryEngine` | The state machine in `adaptive-scaffolding.md`. Holds `ConceptStateIndex` in memory. Receives `success`/`failure`/`hint_used` events; mutates state; emits `mastery.*` events. |
| `LessonRunner` | Plays a MicroLesson runtime JSON. Drives the I-Show animation steps and We-Try choreography. Resolves slot-fills via SlotResolver. Hands off to ActivityRunner for You-Do. |
| `ActivityRunner` | Executes the activity's round lifecycle state machine (see `activity-lifecycle.md` — to be authored). Handles input events from StylusInputProvider, emits `round.*` events. |
| `RewardEngine` | Subscribes to `round.*`, `streak.*`, `mastery.*`, `lesson.*`, `challenge.*` events. Applies the rules in `reward-economy.md`. Mutates RewardInventory. Emits `economy.*` events. |
| `DailyQuestCurator` | Implements `daily-quest-curation.md`. Stateless except for the assembled-today cache. |
| `FactScheduler` | Per-instance fact selection for Fluency Within 5 (and 1st/2nd grade equivalents). Picks the next fact to present. |
| `TelemetryPipe` | Receives every event from every engine. Aggregates into SessionLog. Updates AggregateCounters. Optional cloud-export (deferred to v1.1). |
| `SaveCoordinator` | Per `save-recovery.md`. Throttled writes for round state; flush triggers (activity exit, app background, etc.). |
| `SlotResolver` | Reads slot-vocabulary + active round state + kid profile + system context. Returns the resolved value for a `{slot}` template variable. |
| `LessonQueue` | Decides which lesson fires next for the kid (per `micro-lessons.md` queue rules + session cap). |

### Data layer (in-memory caches over bundled JSON)

| Module | Loads from |
|---|---|
| `ConceptRegistry` | `data/concept-registry/{grade}.json` files |
| `ActivityRegistry` | `data/activity-registry/{grade}.json` files |
| `RewardCatalog` | `data/reward-catalog/*.json` files (kindergarten, foundry-items, etc.) |
| `FoundryCatalog` (view) | Subset of `RewardCatalog` filtered to Foundry items + blueprints + parts |
| `TelemetryCatalog` | `data/telemetry-catalog/{shared,grade}.json` files |
| `StandardsReference` | `data/standards-reference/utah-core-k-5.json` |
| `LessonRuntimeLoader` | `data/lesson-runtime/{lesson-id}.json` (lazy, cached) |
| `ActivityNarrationLoader` | `content/strings/{locale}/activities/{activity-id}.json` (lazy, cached) |
| `StringTableLoader` | `content/strings/{locale}/...` (lazy by namespace) |
| `SlotVocabularyLoader` | `data/slot-vocabulary/{locale}.json` |
| `AssetPathResolver` | Resolves cueIds + asset names to file paths per `asset-paths.md` |

All registries are **read-only at runtime**. Updates require an app rebuild. Schema validation runs at app boot (in debug builds) to catch authoring drift.

### Platform adapters (phase boundary)

| Adapter | Phase 1 (Flutter) | Phase 2 (native iPadOS) |
|---|---|---|
| `StylusInputProvider` | `Listener` widget + `PointerEvent` stream | `PKCanvasView` + `PKStrokePoint` |
| `AudioProvider` | `just_audio` package | `AVAudioEngine` / `AVPlayer` |
| `StorageProvider` | `path_provider` + `dart:io` File | `FileManager` |
| `HandwritingRecognizer` | `tflite_flutter` package + bundled `.tflite` | Core ML + converted model |
| `LocaleResolver` | Flutter `Localizations` + per-kid override | `Locale.current` + per-kid override |
| `SystemSharePort` | `share_plus` package | `UIActivityViewController` |
| `AssetLoader` | Flutter asset bundle | `Bundle.main` |
| `PencilDoubleTapPort` *(stub in Phase 1)* | not available | `UIPencilInteraction` (Phase 2 only) |

---

## State scoping

The app has four state scopes, each tied to a lifecycle.

```
┌──────────────────────────────────────────────────────────────────┐
│ App scope (lifetime = app process)                               │
│ - ConceptRegistry, ActivityRegistry, RewardCatalog,              │
│   TelemetryCatalog, StandardsReference (loaded once)             │
│ - ParentSettings                                                 │
│ - LocaleResolver                                                 │
│ - Platform adapters (singletons)                                 │
└─────────────────────────────┬────────────────────────────────────┘
                              │ creates
┌─────────────────────────────▼────────────────────────────────────┐
│ Device scope (lifetime = current device profile)                 │
│ - KidProfileIndex                                                │
│ - LastActiveKidId                                                │
│ - Device-level accessibility settings                            │
└─────────────────────────────┬────────────────────────────────────┘
                              │ creates on kid selection
┌─────────────────────────────▼────────────────────────────────────┐
│ Kid scope (lifetime = selected kid is active)                    │
│ - MasteryStateIndex (ConceptState per concept)                   │
│ - RewardInventory                                                │
│ - LibraryEntries                                                 │
│ - AggregateCounters                                              │
│ - ActiveSession (start time, lifetime rounds counter)            │
│ - DailyQuestState (today's)                                      │
│ - KidProfile (avatar, buddy, home, name)                         │
└─────────────────────────────┬────────────────────────────────────┘
                              │ creates on activity launch
┌─────────────────────────────▼────────────────────────────────────┐
│ Session scope (lifetime = inside one activity)                   │
│ - RoundState (in-flight)                                         │
│ - ScaffoldQueryCache                                             │
│ - LessonState (if a lesson is playing)                           │
│ - SavedRoundState (throttled mirror of RoundState)               │
└──────────────────────────────────────────────────────────────────┘
```

### Scope teardown rules

| When | Tears down |
|---|---|
| App quit | All scopes (state persists via SaveCoordinator first) |
| Switch kids | Kid scope + Session scope (KidScope reinitializes for new kid) |
| Exit activity | Session scope only |
| New day rolls over | DailyQuestState only (recreated by DailyQuestCurator) |

### Riverpod organization

Phase 1 uses [Riverpod](https://riverpod.dev) for state management. Provider scopes mirror the four state scopes above.

```dart
// Approximate provider structure
final platformAdaptersProvider = Provider(...); // app scope
final conceptRegistryProvider = FutureProvider((ref) => ConceptRegistry.load()); // app scope
final activeKidIdProvider = StateProvider<KidId?>((ref) => null);

// Kid-scoped: rebuilt when activeKidId changes
final masteryEngineProvider = Provider.family<MasteryEngine, KidId>((ref, kidId) {
  final registry = ref.watch(conceptRegistryProvider);
  return MasteryEngine(kidId: kidId, registry: registry);
});

// Session-scoped: created when an activity starts
final activityRunnerProvider = Provider.autoDispose.family<ActivityRunner, ActivitySessionKey>((ref, key) {
  ...
});
```

`autoDispose` ensures session-scoped providers tear down on activity exit. `family` keys make per-kid and per-session providers naturally scoped.

---

## Runtime flow: app cold start

```
1. App launches
2. PlatformAdapters initialize (singletons)
3. AssetLoader pre-loads registries (concept, activity, reward, telemetry, standards)
4. Schema validator runs in debug builds (fails fast if data is broken)
5. SettingsModule loads device.json
   ├── If no parent setup → OnboardingCoordinator (Phase 1 onboarding)
   ├── If parent set up, 0 kids → Onboarding (Phase 2: create first kid)
   ├── If parent set up, 1 kid → auto-enter that kid's Hub
   └── If parent set up, ≥2 kids → KidPickerScreen
6. Kid selected → KidScope creates
   ├── Load kids/{kidId}/profile.json
   ├── Load kids/{kidId}/mastery.json → MasteryStateIndex
   ├── Load kids/{kidId}/inventory.json
   ├── Load kids/{kidId}/library.json
   ├── Load kids/{kidId}/counters.json
   └── Initialize ActiveSession
7. Check SavedRoundState
   ├── If exists and age ≤ 5 min → offer "Continue your {activity}?"
   └── Else → discard, show Hub
8. Hub renders. Daily Quest badge shows if today's quest incomplete.
```

---

## Runtime flow: kid taps an activity tile

```
1. UI: HubScreen → ActivityTile tapped
2. AppRouter navigates → ActivityScreen('counting-parade')
3. ActivityScreen requests a RunActivityCoordinator(kidId, activityId)
4. RunActivityCoordinator initializes:
   ├── Reads ActivityRegistry for the activity definition
   ├── For each round-to-play (typically 1, more for Daily Quest):
   │   ├── ScaffoldEngine.query(kidId, conceptIds, problemType)
   │   │   Returns ScaffoldResponse with:
   │   │   - presentationLayer (Concrete/Pictorial/Abstract)
   │   │   - hintsAllowed
   │   │   - maxAttempts
   │   │   - firstEncounterLesson? (if non-null, lesson must play first)
   │   ├── If firstEncounterLesson != null:
   │   │   ├── LessonRunner plays the lesson (I-Show + We-Try)
   │   │   ├── The lesson's You-Do BECOMES the round
   │   │   └── On lesson completion, MasteryEngine.firstEncounter -> false
   │   ├── Else: ActivityRunner plays a regular round
   │   ├── Round emits events to event bus:
   │   │   - activity-specific (e.g., counting_parade.tap_logged)
   │   │   - lifecycle (round.started, round.passed, round.failed)
   │   ├── MasteryEngine consumes round.passed/failed → updates ConceptState
   │   ├── RewardEngine consumes round.passed → emits economy.coins_earned
   │   ├── TelemetryPipe records every event
   │   └── SaveCoordinator flushes (on activity exit or round complete)
   └── On exit: tear down session scope, return to Hub
```

---

## Runtime flow: first-encounter lesson chain (intra-round)

Build-a-Habitat declares `intra_round_lesson_chain: true` for K.G.5 + K.G.6 (per `micro-lessons.md`). The flow:

```
1. Fresh kid enters Build-a-Habitat
2. RunActivityCoordinator queries ScaffoldEngine for Round 1
3. ScaffoldEngine sees K.G.5.firstEncounter=true → returns firstEncounterLesson = "lesson-k-g-5-sticks-and-clay"
4. LessonRunner plays K.G.5 lesson (I-Show, We-Try)
5. The lesson's You-Do = Phase 1 of the round (kid builds the frame)
6. K.G.5 lesson completes; LessonRunner files library entry; MasteryEngine.firstEncounter for K.G.5 -> false
7. Round.phase1Complete event fires
8. The activity declares intra_round_lesson_chain → coordinator queries ScaffoldEngine again, mid-round, for Phase 2's concept (K.G.6)
9. ScaffoldEngine sees K.G.6.firstEncounter=true → returns firstEncounterLesson = "lesson-k-g-6-compose-3d"
10. LessonRunner plays K.G.6 lesson INSIDE the same round (Phase 2's lesson chain)
11. The K.G.6 lesson's You-Do = Phase 2 of the same round (kid composes 3D structure)
12. Phase 2 completes → round.passed fires
13. Both K.G.5 and K.G.6 firstEncounter flags are now false; both filed in library; both at Practicing
```

The activity-spec's `intra_round_lesson_chain: true` declaration causes the coordinator to interleave lesson firing with round phases. Without that declaration (default), Round 2 would have played the K.G.6 lesson — i.e., Phase 2 would have been encountered cold the first time. The chain ensures it isn't.

---

## Runtime flow: kid taps "Done" with miscount

```
1. ActivityRunner: kid taps Done button
2. Runner evaluates pass condition against current round state → fail
3. Runner emits round.failed event
4. ScaffoldEngine consumes failure (via subscription) → updates streak counter
   - If 2 consecutive fails: trigger staggered demotion (CPA layer first, then sub-mode)
5. RewardEngine consumes round.failed → 0 coins (no penalty)
6. TelemetryPipe records event
7. Coordinator: warm narrator + demonstration animation
8. After demonstration, ScaffoldEngine.query() for next round → returns demoted layer
9. Next round starts at lower CPA layer
```

---

## Runtime flow: app backgrounded mid-round

Per `save-recovery.md`:

```
1. OS sends background notification
2. Platform adapter (e.g., AppLifecycleListener) fires app-backgrounded event
3. SaveCoordinator.flush() is called synchronously:
   ├── MasteryStateIndex → mastery.json
   ├── RewardInventory → inventory.json
   ├── ActiveSession → session.json
   └── SavedRoundState already throttled-written; nothing to do
4. App goes to background
5. On foreground return within 5 min:
   ├── Check SavedRoundState timestamp
   ├── ≤ 5 min → offer "continue round" (auto-yes)
   ├── 5 min – 1 hour → prompt
   └── > 1 hour → discard, return to Hub
6. On foreground return after long gap:
   ├── Re-check ConceptState.firstEncounter decay (60-day rule)
   ├── Update LastActiveKidId
   └── Show Hub
```

---

## Event bus

The engines communicate via a typed event bus. Pseudo-code:

```dart
// Pattern (Riverpod-style)
final eventBusProvider = Provider((ref) => EventBus());

class EventBus {
  Stream<TelemetryEvent> get events;
  void emit(TelemetryEvent event);
  StreamSubscription<T> on<T extends TelemetryEvent>(void Function(T) handler);
}

// Events are typed value classes
abstract class TelemetryEvent {
  String get eventName;  // matches telemetry-catalog.json
  Map<String, dynamic> get payload;
}

class RoundPassedEvent extends TelemetryEvent { ... }
class MasteryPracticingEvent extends TelemetryEvent { ... }
```

Subscribers:
- **MasteryEngine** subscribes to `round.passed`, `round.failed`, `hint_used`, `lesson.youdo_*`
- **RewardEngine** subscribes to `round.passed`, `streak.*`, `mastery.standard_*`, `challenge.*`, milestone-detection rules
- **TelemetryPipe** subscribes to **all** events (it's the catch-all)
- **SaveCoordinator** subscribes to lifecycle events (`activity.exited`, `round.completed`) and flushes accordingly

The event bus is the only sanctioned same-layer communication channel for engines. Engines do NOT inject each other.

---

## Loading & validation at boot

Debug builds run a schema-validation pass at app start:

```
1. For every JSON file in data/: validate against the schema referenced in $schema
2. For every cueId referenced in lesson-runtime JSONs: verify the corresponding text exists in the runtime JSON OR in content/strings/{locale}/...
3. For every concept-registry entry with introducedBy: verify the activity exists in activity-registry
4. For every concept-registry entry with requiresLesson=true: verify the lesson file exists
5. For every blueprint in reward-catalog with requiredParts: verify each part id resolves
```

Release builds skip these (assumed validated by CI).

---

## Threading model

| Activity | Thread |
|---|---|
| UI updates | Main thread (Flutter UI thread) |
| Engine logic | Main thread (kept fast; if any operation > 16ms, kick to isolate) |
| Stylus stroke processing | Main thread (latency-critical) |
| Handwriting classifier inference | Background isolate |
| File I/O (save flushes) | Background isolate |
| Audio playback | Audio thread (handled by platform adapter) |
| Telemetry aggregation | Main thread (cheap), batched flushes to background |

Phase 1 (Dart): isolates via `compute()` or `Isolate.spawn()`.
Phase 2 (Swift): GCD background queues, MainActor for UI.

---

## Testing strategy

| Layer | Test type | Tools |
|---|---|---|
| Engines | Pure unit tests (no Flutter import) | `package:test` |
| Coordinators | Unit + integration with fake engines | `package:test` + `mocktail` |
| Data layer | Schema validation tests | `package:json_schema` + golden manifests |
| UI widgets | Widget tests | `package:flutter_test` |
| End-to-end vertical slice | Integration test (one full activity round) | `package:integration_test` |
| TTS harvester | Snapshot test (manifest hash should be stable) | `package:test` |

A canonical integration test: "Fresh K kid plays Counting Parade for the first time, sees K.CC.4a lesson, passes the You-Do round, mastery promotes to Practicing, coins land in inventory, library entry filed, save written, app relaunches and all state survives." That test exercises ~70% of the system.

---

## Module → file map (Phase 1 Flutter)

```
app/
├── pubspec.yaml
├── lib/
│   ├── main.dart                       # entry point
│   ├── app.dart                        # root widget + Riverpod ProviderScope
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── kid_picker/
│   │   │   ├── onboarding/
│   │   │   ├── hub/
│   │   │   ├── activity/
│   │   │   ├── lesson/
│   │   │   ├── library/
│   │   │   ├── foundry/
│   │   │   └── dashboard/
│   │   ├── widgets/                    # shared UI bits (HUD, Buddy view, etc.)
│   │   └── theme/
│   ├── coordinators/
│   │   ├── run_activity_coordinator.dart
│   │   ├── run_lesson_coordinator.dart
│   │   ├── onboarding_coordinator.dart
│   │   ├── daily_quest_coordinator.dart
│   │   └── dashboard_coordinator.dart
│   ├── engines/
│   │   ├── scaffold_engine.dart
│   │   ├── mastery_engine.dart
│   │   ├── lesson_runner.dart
│   │   ├── activity_runner/
│   │   │   ├── activity_runner.dart    # state machine
│   │   │   └── activities/             # per-activity behavior modules
│   │   │       ├── counting_parade.dart
│   │   │       ├── ten_frame_pond.dart
│   │   │       └── ... 9 more
│   │   ├── reward_engine.dart
│   │   ├── daily_quest_curator.dart
│   │   ├── fact_scheduler.dart
│   │   ├── telemetry_pipe.dart
│   │   ├── save_coordinator.dart
│   │   ├── slot_resolver.dart
│   │   └── lesson_queue.dart
│   ├── data/
│   │   ├── concept_registry.dart
│   │   ├── activity_registry.dart
│   │   ├── reward_catalog.dart
│   │   ├── foundry_catalog.dart
│   │   ├── telemetry_catalog.dart
│   │   ├── standards_reference.dart
│   │   ├── lesson_runtime_loader.dart
│   │   ├── activity_narration_loader.dart
│   │   ├── string_table_loader.dart
│   │   ├── slot_vocabulary_loader.dart
│   │   └── asset_path_resolver.dart
│   ├── platform/
│   │   ├── stylus_input_provider.dart      # interface
│   │   ├── stylus_input_provider_flutter.dart
│   │   ├── audio_provider.dart
│   │   ├── audio_provider_flutter.dart
│   │   ├── storage_provider.dart
│   │   ├── storage_provider_flutter.dart
│   │   ├── handwriting_recognizer.dart
│   │   ├── handwriting_recognizer_tflite.dart
│   │   ├── locale_resolver.dart
│   │   └── share_port.dart
│   ├── models/                             # value classes (freezed)
│   │   ├── concept_state.dart
│   │   ├── kid_profile.dart
│   │   ├── round_state.dart
│   │   ├── lesson_state.dart
│   │   ├── reward_inventory.dart
│   │   └── ...
│   └── events/
│       ├── event_bus.dart
│       └── events.dart                     # typed TelemetryEvent classes
├── test/
├── integration_test/
└── assets/                                 # bundled data, audio, art
```

---

## What this spec does NOT decide

- **Specific UI navigation library** — `go_router` is the suggested default but the project-bootstrap spec will commit.
- **Specific JSON code-gen** — `freezed` + `json_serializable` is the natural pick but bootstrap commits.
- **Logger** — `logger` package is fine; bootstrap commits.
- **Crash reporting service** — out of scope until launch readiness.
- **Cloud sync transport** — v1.1; deferred entirely.

---

## Open Questions

- **Event bus persistence** — should the bus persist events across app launches (for analytics replay), or is per-session telemetry enough? Suggest per-session at launch.
- **Hot-reload during development** — when an engineer hot-reloads, kid-scoped state should re-hydrate from disk to avoid "in-memory diverged from disk" weirdness. Confirm Riverpod's `autoDispose` behavior matches this.
- **Lesson runner extensibility** — when 1st/2nd grade adds new lesson runtime action names, the runner needs to handle them. Defer to `lesson-runtime-actions.md`'s extension contract.
- **Backpressure** — if events fire faster than TelemetryPipe can flush, we need a backpressure model. Probably never hit at K (events are slow) but confirm with profiling.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — layers, dependency rules, source-of-truth ownership, module catalog, scoping, runtime flows for cold start / activity launch / intra-round lesson chain / failure path / background, event bus, threading, testing strategy, file map | |
