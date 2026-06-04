# Project Bootstrap

> The Flutter project's foundational decisions: state management, routing, JSON code-gen, folder layout, lint config, CI, formatting. One spec doc + a starter skeleton at `app/`. Once these are committed, every code change has clear conventions to follow.

References: `specs/shared/platform-architecture.md`, `specs/shared/system-architecture.md`, `app/` skeleton directory.

---

## Tech stack commitments

Per `platform-architecture.md` we're on Flutter for Phase 1, with a clean platform boundary for the Phase 2 native swap. The remaining choices we lock here:

| Concern | Choice | Why |
|---|---|---|
| **State management** | **Riverpod 2** (`flutter_riverpod`) | Provider scoping matches our state-scope model exactly. AutoDispose handles session-scope cleanup. Family providers cleanly key per-kid + per-session. Strong testability (override providers for tests). |
| **Routing** | **`go_router`** | Declarative routes, deep-linking ready, well-supported by Riverpod via `riverpod_navigator` patterns. Less ceremony than `Navigator 2.0` directly. |
| **Immutable value types** | **`freezed`** + **`json_serializable`** | Compile-time guaranteed immutability for all models. Pattern-matching support. JSON ser/de generated from the same source. |
| **JSON schema validation** | **`json_schema` package** | Bootable-time validation of all bundled data files against their `schemas/*.schema.json`. |
| **Lints** | **`flutter_lints`** + custom rules | Standard Flutter recommended lints + a few local additions (no print, no implicit dynamic, etc.). |
| **Formatter** | `dart format` defaults (80-char line) | Universal Dart convention. CI fails on unformatted. |
| **Logger** | **`logger` package** | Simple structured logging. Production logging gates on a release-mode flag. |
| **Stylus capture (Phase 1)** | **Flutter `Listener` widget + `PointerEvent`** | Native PencilKit comes in Phase 2 per `platform-architecture.md`. |
| **Audio (Phase 1)** | **`just_audio`** | Gapless music beds, low latency, cross-platform. Plays pre-rendered narration once it exists. |
| **System TTS (deferral fallback)** | **`flutter_tts`** | Per `text-and-tts-deferral.md`. Wraps device-built-in TTS (iOS AVSpeechSynthesizer / Android TextToSpeech). Free, robotic, dev-friendly. Used as fallback when no pre-rendered audio file exists for a cueId. Becomes a safety-net post-launch. |
| **File I/O (Phase 1)** | **`path_provider`** + `dart:io` | Standard. |
| **Handwriting CNN (Phase 1)** | **`tflite_flutter`** | Same `.tflite` model later converts to Core ML for Phase 2. |
| **Share sheet** | **`share_plus`** | Wraps `UIActivityViewController`. |
| **Rive (character animation)** | **`rive`** | Cross-platform, performant, works in Flutter and natively on iOS. |
| **Lottie (UI transitions)** | **`lottie`** | Same files as Phase 2 Lottie iOS. |
| **CI** | **GitHub Actions** | Standard. `flutter analyze`, `flutter test`, format check, schema validation. |
| **Versioning** | **Semantic versioning, manual** | `pubspec.yaml` version bumped per release; CI doesn't auto-bump. |
| **Min iOS target** | **iPad iOS 15+** | Covers the supported iPad fleet. M-series and A14+ recommended in spec; older iPads may run with degraded latency. |

---

## Repository layout

```
critmath/                            (repo root)
├── README.md                        (top-level intro)
├── specs/                           (the markdown specs)
├── schemas/                         (JSON Schema files)
├── data/                            (bundled data files)
├── content/                         (string tables per locale)
├── assets/                          (art / audio / fonts — created in art phase)
├── tools/
│   └── tts/                         (TTS pipeline tooling — Dart CLI)
├── app/                             (the Flutter app — Phase 1)
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── lib/
│   ├── test/
│   ├── integration_test/
│   ├── assets/                      (symlink or copy of repo-root assets/)
│   └── ios/
└── .github/
    └── workflows/
        ├── flutter.yml              (build + test + analyze + format check)
        ├── data-validation.yml      (schema validation)
        └── tts-cues-coverage.yml    (every cueId has audio)
```

---

## `app/lib/` folder structure

Per `system-architecture.md`'s module catalog. Folders mirror the layers:

```
app/lib/
├── main.dart                                 # entrypoint
├── app.dart                                  # root widget + ProviderScope + routing
├── theme/                                    # ThemeData, colors, text styles
│   ├── critmath_theme.dart
│   └── palette.dart
├── ui/                                       # presentation layer
│   ├── screens/
│   │   ├── kid_picker/
│   │   ├── onboarding/
│   │   ├── hub/
│   │   ├── activity/
│   │   ├── lesson/
│   │   ├── library/
│   │   ├── foundry/
│   │   └── dashboard/
│   ├── widgets/                              # shared widgets
│   │   ├── buddy_view.dart
│   │   ├── hud.dart
│   │   ├── notebook_tab.dart
│   │   └── done_button.dart
│   └── animations/                           # Rive/Lottie wrappers
├── coordinators/
│   ├── run_activity_coordinator.dart
│   ├── run_lesson_coordinator.dart
│   ├── onboarding_coordinator.dart
│   ├── daily_quest_coordinator.dart
│   └── dashboard_coordinator.dart
├── engines/
│   ├── scaffold_engine.dart
│   ├── mastery_engine.dart
│   ├── lesson_runner.dart
│   ├── activity_runner/
│   │   ├── activity_runner.dart              # generic state machine
│   │   └── activities/                       # per-activity behavior
│   │       ├── counting_parade.dart
│   │       ├── ten_frame_pond.dart
│   │       └── ...
│   ├── reward_engine.dart
│   ├── daily_quest_curator.dart
│   ├── fact_scheduler.dart
│   ├── telemetry_pipe.dart
│   ├── save_coordinator.dart
│   ├── slot_resolver.dart
│   └── lesson_queue.dart
├── data/
│   ├── concept_registry.dart
│   ├── activity_registry.dart
│   ├── reward_catalog.dart
│   ├── foundry_catalog.dart
│   ├── telemetry_catalog.dart
│   ├── standards_reference.dart
│   ├── lesson_runtime_loader.dart
│   ├── activity_narration_loader.dart
│   ├── string_table_loader.dart
│   ├── slot_vocabulary_loader.dart
│   └── asset_path_resolver.dart
├── platform/                                 # adapters (phase boundary)
│   ├── stylus_input_provider.dart            # interface
│   ├── stylus_input_provider_flutter.dart
│   ├── audio_provider.dart
│   ├── audio_provider_just_audio.dart
│   ├── storage_provider.dart
│   ├── storage_provider_flutter.dart
│   ├── handwriting_recognizer.dart
│   ├── handwriting_recognizer_tflite.dart
│   ├── locale_resolver.dart
│   └── share_port.dart
├── models/                                   # freezed value classes
│   ├── concept_state.dart
│   ├── kid_profile.dart
│   ├── round_state.dart
│   ├── lesson_state.dart
│   ├── reward_inventory.dart
│   ├── library_entry.dart
│   ├── saved_round_state.dart
│   └── ...
├── events/
│   ├── event_bus.dart
│   └── events.dart                           # typed events
├── providers/                                # Riverpod provider definitions
│   ├── app_providers.dart                    # app-scope (registries, adapters)
│   ├── device_providers.dart                 # device-scope (kid index, settings)
│   ├── kid_providers.dart                    # kid-scope (mastery, inventory, etc.)
│   └── session_providers.dart                # session-scope (activity runner, etc.)
└── util/
    ├── logger.dart
    └── result.dart                           # generic Result<Success, Failure>
```

---

## Naming conventions

| Element | Convention | Example |
|---|---|---|
| File names | `snake_case.dart` | `mastery_engine.dart` |
| Class names | `PascalCase` | `MasteryEngine`, `ConceptState` |
| Variable names | `camelCase` | `currentKidId` |
| Constants | `lowerCamelCase` for top-level finals; `SCREAMING_SNAKE` for `const` enums | `kDefaultLocale`, `MAX_ATTEMPTS_FIRST_ENCOUNTER` |
| Provider names | suffix with `Provider` | `masteryEngineProvider`, `activeKidIdProvider` |
| Event types | suffix with `Event` | `RoundPassedEvent`, `MasteryPracticingEvent` |
| Adapter interfaces | suffix with `Provider` (matches Riverpod's term) | `StylusInputProvider` |
| Adapter implementations | suffix with `_<impl>` | `StylusInputProviderFlutter` |

---

## Imports & dependencies

```yaml
# app/pubspec.yaml (excerpt)
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  json_schema: ^5.0.0
  just_audio: ^0.9.36
  flutter_tts: ^4.0.2          # per text-and-tts-deferral.md — fallback for un-rendered cueIds
  path_provider: ^2.1.2
  path: ^1.9.0
  tflite_flutter: ^0.10.4
  share_plus: ^9.0.0
  rive: ^0.13.0
  lottie: ^3.1.0
  logger: ^2.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.8
  freezed: ^2.5.0
  json_serializable: ^6.7.0
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
```

---

## Lint configuration

`app/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    - always_declare_return_types
    - avoid_print               # use logger instead
    - prefer_final_locals
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - use_super_parameters
    - directives_ordering
    - unawaited_futures
    - cancel_subscriptions
    - close_sinks
```

---

## Routing strategy

`go_router` with these top-level routes:

```
/                       → LaunchRouter (decides next)
/onboarding             → OnboardingScreen
/picker                 → KidPickerScreen
/hub                    → HubScreen (kid scope must be initialized)
/activity/:activityId   → ActivityScreen
/lesson/:lessonId       → LessonScreen (typically nested under activity)
/library                → LibraryScreen
/foundry                → FoundryScreen
/dashboard              → DashboardScreen (parent/teacher gate)
/dashboard/settings
/dashboard/kids
/dashboard/today
/dashboard/progress
```

Long-press on the Hub gear icon dispatches a route to `/dashboard`. PIN gate is a guard middleware in `go_router`.

---

## Build sequencing (recommended)

Once Mac access + Dart SDK are available:

### Sprint 0 — Bootstrap
1. `flutter create app` in the project root, replace with the skeleton in `app/`.
2. `pub get`. Verify lint + format. `flutter analyze` clean.
3. Wire `ProviderScope`, root widget, theme, base routes.
4. Stub out platform adapters (return mock data).
5. Implement schema validation at boot (debug only).

### Sprint 1 — Vertical slice (Counting Parade end-to-end)
1. ConceptRegistry + ActivityRegistry + LessonRuntimeLoader (real data).
2. MasteryEngine (just enough for K.CC.4a).
3. ScaffoldEngine query.
4. ActivityRunner state machine for `count-the-parade` sub-mode only.
5. Counting Parade activity behavior (creature spawning, tap-pick, cardinality).
6. LessonRunner with I-Show/We-Try phases (animation step library — stub the actions, render as text-on-screen).
7. RewardEngine (just coins for now).
8. TelemetryPipe (in-memory log only).
9. SaveCoordinator (real persistence).
10. Hub screen + Activity screen.
11. **Integration test**: fresh K kid → Counting Parade → K.CC.4a lesson → round → save → relaunch → state survives.

### Sprint 2 — Second activity (Ten-Frame Pond)
- Adds Drag-and-Drop snap-to-grid mechanic + Mode 1 trace scoring.
- Adds K.OA.3 / K.OA.4 / K.NBT.1 lessons.

### Sprint 3 — Rounds out remaining K activities + lessons.

### Sprint 4 — Onboarding flow + multi-kid picker.

### Sprint 5 — Parent/Teacher dashboard.

### Sprint 6 — Foundry + Library.

### Sprint 7 — Polish, launch prep.

Each sprint ends with a runnable demo on iPad simulator (Phase 1) — visible progress.

---

## CI

`.github/workflows/flutter.yml` runs on every PR + push to main:

```yaml
name: Flutter CI
on:
  push: { branches: [main] }
  pull_request:

jobs:
  ci:
    runs-on: macos-latest   # Flutter for iOS needs macOS
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: 3.24.x
      - name: pub get
        working-directory: app
        run: flutter pub get
      - name: Format check
        working-directory: app
        run: dart format --output=none --set-exit-if-changed .
      - name: Analyze
        working-directory: app
        run: flutter analyze
      - name: Test
        working-directory: app
        run: flutter test
```

`.github/workflows/data-validation.yml` validates bundled JSON against schemas:

```yaml
name: Data validation
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm install -g ajv-cli
      - name: Validate data files
        run: bash tools/scripts/validate-data.sh
```

The `validate-data.sh` script walks `data/**/*.json` and `content/**/*.json`, runs `ajv validate -s` against each file's referenced schema. (Script TBD; this CI yaml is a placeholder.)

`.github/workflows/tts-cues-coverage.yml` ensures every referenced cueId has a rendered audio file (post-Stage 4 of the TTS pipeline; placeholder for now).

---

## Code-gen workflow

Models use `freezed` + `json_serializable`. After changes, regenerate:

```bash
cd app
dart run build_runner build --delete-conflicting-outputs
```

Watch mode during development:

```bash
dart run build_runner watch
```

Generated files (`*.freezed.dart`, `*.g.dart`) are not committed by default; reviewers should `pub run build_runner build` after pulling.

---

## Testing convention

- **Unit tests** in `app/test/`, mirror `lib/` structure.
- **Widget tests** in `app/test/ui/`.
- **Integration tests** in `app/integration_test/`.
- Engines have no Flutter import — pure Dart tests in `app/test/engines/`.
- Use `mocktail` for fakes; prefer real implementations + Riverpod overrides where possible.

A canonical integration test (per `system-architecture.md`):

```dart
// app/integration_test/counting_parade_first_round_test.dart
testWidgets('Fresh K kid plays Counting Parade and state persists', (tester) async {
  await tester.bootstrapApp(asNewKid: 'Lila', age: 5);
  await tester.tap(find.text('Counting Parade'));
  await tester.pumpAndSettle();

  // K.CC.4a lesson should play first
  expect(find.text("Let's count these fawns together..."), findsOneWidget);
  await tester.skipLesson();

  // You-Do: 4 fawns, tap each, tap Done
  for (final fawn in find.byType(FawnSprite).evaluate()) { ... }
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();

  // Round passed: mastery should be Practicing, coins should be +2, lesson in library
  expect(kid.masteryState.byConceptId('K.CC.4a').first.status, MasteryStatus.practicing);
  expect(kid.rewardInventory.coins, greaterThanOrEqualTo(2));
  expect(kid.library.entries.any((e) => e.lessonId == 'lesson-k-cc-4a-one-to-one'), isTrue);

  // Force-quit + relaunch
  await tester.restartApp();
  expect(kid.masteryState.byConceptId('K.CC.4a').first.status, MasteryStatus.practicing);
});
```

If this test passes, ~70% of the system is wired correctly.

---

## What this spec does NOT decide

- **App icon / splash screen** — design pass.
- **Crash reporting** — Sentry-or-equivalent, deferred to launch readiness.
- **Analytics service** — TelemetryPipe writes locally only at launch; cloud export deferred.
- **Continuous deployment** — manual TestFlight uploads at launch; CD pipeline deferred to v1.1.
- **Hot fix strategy** — App Store review cycle plus internal beta channel.

---

## Open Questions

- **Flutter channel** — `stable` recommended. Consider `beta` only if we need a feature it gates. Default = `stable`.
- **Min iOS deployment target** — iOS 15 covers ~95% of in-use iPads. Confirm with Apple's published iPad fleet share.
- **Should `app/` be a git submodule or in-tree?** — In-tree at launch. Simpler. Revisit if app code grows huge.
- **PR review checklist** — Should we have a `.github/PULL_REQUEST_TEMPLATE.md`? Suggest yes, with bullets for: schema migrations? new lints? new spec? new asset?
- **Storybook-equivalent for widget previews** — Some teams use `widgetbook`. Defer to mid-sprint; nice-to-have.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — tech stack commitments (Riverpod, go_router, freezed, just_audio, tflite_flutter, etc.), repo layout, app/lib/ folder structure, naming conventions, pubspec.yaml excerpt, lint config, routing strategy, sprint sequencing, CI yaml, code-gen workflow, testing convention, canonical integration test | |
