# CritMath app

The Phase 1 Flutter app. See `../specs/shared/platform-architecture.md` and `../specs/shared/system-architecture.md` for the design context.

## Prerequisites

- Flutter SDK ≥ 3.24 stable
- Xcode (for iOS build/test) — required for actual iPad builds; Phase 1 development can use Flutter's iOS simulator on macOS
- A Mac for the iOS build/test loop (current launch blocker — see `../specs/shared/platform-architecture.md`)

## First-time setup

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run                # debug, on connected device or simulator
flutter run -d ipad        # specific device
```

## Test

```bash
flutter test               # unit + widget tests
flutter test integration_test/  # end-to-end
```

## Lint + format

```bash
dart format .              # write formatting changes
dart format --output=none --set-exit-if-changed .  # CI check
flutter analyze            # lint check
```

## Code gen (after model changes)

```bash
dart run build_runner build --delete-conflicting-outputs
# OR for watch mode during development:
dart run build_runner watch
```

## Folder structure

See `../specs/shared/project-bootstrap.md` for the full layout. Quick reference:

| Folder | Purpose |
|---|---|
| `lib/ui/` | Screens and widgets |
| `lib/coordinators/` | Orchestrate engines for use cases |
| `lib/engines/` | Pure logic (mastery, scaffolding, lesson runner, etc.) |
| `lib/data/` | In-memory registries + lazy loaders for bundled JSON |
| `lib/platform/` | Adapters (the Phase 1/Phase 2 swap boundary) |
| `lib/models/` | Freezed value classes |
| `lib/events/` | Typed events on the event bus |
| `lib/providers/` | Riverpod provider definitions, organized by scope |

## What's here now

This is a **skeleton commit**. The `pubspec.yaml` and `analysis_options.yaml` are committed; the `lib/` tree is empty pending the first sprint. See `../specs/shared/project-bootstrap.md` → "Build sequencing" for the recommended sprint order.
