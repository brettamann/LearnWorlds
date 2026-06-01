# Platform Architecture

> The authoritative reference for how the app is built across the launch (Flutter-first) and post-Mac (native iPadOS) phases. Defines what is platform-agnostic, what crosses the platform boundary, and how the eventual native migration is a swap rather than a rewrite.

References: `we-are-going-to-eventual-lantern.md` (tech-stack decision), `specs/shared/stylus-mechanics.md`, `specs/shared/number-writing-modes.md`, `specs/shared/math-notebook.md`, every activity spec's Implementation Notes section.

---

## Why this exists

The original plan called for **Native iPadOS (Swift/SwiftUI + PencilKit)**. The durable target is now **Flutter cross-platform** — the product ships, lives, and grows on Flutter. A future native upgrade is **opportunistic, not planned**: if Mac access happens and the stylus feel is genuinely costing us, the boundary interfaces below make a partial swap possible. But we are not building toward that swap; we are building toward a great Flutter product that runs well on iPad (and, eventually, Android tablets).

This document defines the platform boundary regardless. Even within Flutter, isolating platform-specific concerns (stylus capture, audio playback, file I/O, recognition) behind interfaces keeps the engines testable and lets us target Android cleanly when that time comes.

---

## Durable architecture — Flutter cross-platform

> **Renamed from "Phase 1"** as of 2026-06-01. We're building Flutter as the durable target. The "Phase 2 — Native iPadOS swap" section below is now framed as an **optional opportunistic upgrade** rather than a planned migration.



### Stack

| Layer | Choice | Notes |
|---|---|---|
| UI framework | **Flutter (Dart)** | Compiles from Windows; iOS / Android / desktop targets available; iPad is the launch target |
| State management | **Riverpod** (recommended) | Or Provider / Bloc — pick one, document the choice; consistency matters more than which |
| Rendering | Flutter's Skia engine | Excellent for hand-drawn art + animations |
| Stylus capture | **`Listener` widget with `PointerEvent`** | Captures pressure + tilt on iOS; no prediction/palm rejection (deferred to native phase) |
| Audio | **`just_audio` + `audioplayers`** | Cross-platform; gapless music beds |
| Local storage | **`path_provider` + JSON files** | Same file layout Swift will read post-migration |
| Animations | **Flutter's animation framework + Lottie** for complex animations | Lottie files cross-platform |
| Handwriting recognition | **TFLite Flutter package** | Same `.tflite` model file used in native phase (via Core ML conversion) |

### What Flutter does NOT give us (Phase 1 deferred items)

| Native iOS feature | Workaround during Phase 1 | Migration trigger |
|---|---|---|
| **PencilKit stroke prediction** | Direct point capture; ~15–20 ms extra perceived latency | First measurable kid complaint about stylus feel |
| **PencilKit palm rejection** | Heuristic: discard touches with contact-area > N px² | When palm-touches cause confused state during playtest |
| **Apple Math Notes API** (v1.1 equation parsing) | Use MyScript Math SDK or custom CNN | When v1.1 equation parsing ships |
| **iCloud sync** (v1.1) | Local-only saves; manual export/import | When multi-device sync becomes a real requirement |
| **App Store subscriptions / family sharing** | One-time purchase only | If pricing model changes |
| **Apple Pencil double-tap gesture** (e.g., switch tools) | Defer | Native phase only |
| **System-level accessibility integrations** beyond basics | Flutter's accessibility is good but not full parity | Accessibility-heavy customer feedback |

These are **post-launch concerns**. Phase 1 ships a working, useful, kid-loved product without them.

---

## Optional upgrade — Native iPadOS (if Mac access happens)

> **Renamed from "Phase 2"** as of 2026-06-01. This section is preserved as a reference for *what could happen* if Mac hardware becomes available and the playtest data shows stylus latency hurting trace mastery. Until then, all the items below are out of scope. Flutter is the durable answer.



### Stack

| Layer | Choice |
|---|---|
| UI framework | **SwiftUI** |
| State management | **Swift Observation** / Combine |
| Rendering | Core Animation + Metal-backed views where needed |
| Stylus capture | **PencilKit** — `PKCanvasView` + `PKStrokePoint` |
| Audio | **AVFoundation** |
| Local storage | Same JSON files; native `FileManager` |
| Animations | SwiftUI's animation framework + Lottie (same files) |
| Handwriting recognition | Same `.tflite` → Core ML conversion |

The data files, lesson runtime JSONs, schemas, content templates — all unchanged.

---

## The platform boundary

The boundary between platform-agnostic logic and platform-specific code is the line that defines "how much do we rewrite at migration time."

### Platform-AGNOSTIC (lives in shared Dart code at launch; ports to Swift identically at Phase 2)

Everything in this category is **pure logic** — no UI, no input, no rendering. The Phase 2 rewrite of these is `git diff` minus syntax changes, not redesign.

- All **schemas** in `/schemas` (these are JSON Schema files; consumed by both languages)
- All **data files** in `/data` (concept registry, activity registry, content templates, lesson runtime JSONs, telemetry catalogs, standards reference, reward catalog) — unchanged across phases
- **Adaptive scaffolding** state machine + ConceptStateIndex
- **Lesson runner** orchestration logic (which lesson plays when, phase transitions)
- **Reward engine** (coin tallying, chest rolling, milestone detection)
- **Mastery engine** (rule evaluation, sibling credit, exercises-only coverage)
- **Daily Quest curation** algorithm
- **Telemetry event aggregation**
- **Save/recovery** state structures and serialization
- **Localization** string-table loader
- **Number-writing geometric scoring** (Mode 1 trace; pure math, no UI)

### Platform-SPECIFIC (rewritten in Phase 2)

Smaller surface area. These are the "swap" pieces.

- **UI widget trees** (Flutter widgets ↔ SwiftUI views) — same component decomposition, different syntax
- **Rendering of scenes, sprites, animations** (Skia ↔ Core Animation)
- **Audio playback** (just_audio ↔ AVFoundation)
- **Stylus input capture** (`Listener`+`PointerEvent` ↔ `PKCanvasView`)
- **File system I/O** (path_provider ↔ FileManager) — same file *layout*, different APIs

### The stylus boundary (most important)

Stylus input is the highest-stakes platform-specific code because it directly affects kid experience. The boundary is an **interface** that both implementations conform to:

```dart
// Phase 1 (Dart, in shared code)
abstract class StylusInputProvider {
  Stream<StylusPoint> get pointStream;
  bool get supportsPressure;
  bool get supportsTilt;
  bool get supportsPrediction;        // returns false in Flutter phase, true in native
  void enablePalmRejection(bool enabled);  // no-op in Flutter, real in native
}

class StylusPoint {
  final Offset position;
  final double pressure;       // 0.0 - 1.0
  final double tiltX, tiltY;
  final Duration timestamp;
  final bool isPredicted;      // always false in Flutter phase
}
```

Phase 2's native implementation provides a SwiftUI/PencilKit-backed implementation of the same interface. **Activity rendering code calls the interface, not the implementation** — so when we swap, nothing above the interface changes.

The same pattern applies to:
- `AudioProvider` (just_audio backend ↔ AVFoundation backend)
- `StorageProvider` (path_provider ↔ FileManager)
- `HandwritingRecognizer` (TFLite Flutter ↔ Core ML)

---

## How specs handle this

### Spec language convention

Specs are written **platform-agnostically** where possible. Where platform-specific structure is described (e.g., "Suggested widget tree" in Implementation Notes), the structure is **conceptual** — same boxes either way, the boxes are called Widgets in Flutter and Views in SwiftUI.

Specs that mention iOS-specific APIs (PencilKit, Apple Math Notes, iCloud) now reference them as **post-launch / native-phase** features. Phase 1 implementations use the Flutter alternatives documented here.

### Migration sections in specs

Any spec that touches platform-specific concerns includes a small "Migration notes" subsection saying:
- What Phase 1 (Flutter) does
- What Phase 2 (native) will do
- Where the boundary lives

---

## What we explicitly preserve for the migration

To make the swap clean, the launch implementation MUST:

1. **Write the same file layout that the native app will read.** No Flutter-shaped serialization that we'd have to migrate.
2. **Use the platform-agnostic schemas and data files unchanged.** No Flutter-flavored extensions.
3. **Conform to the platform-boundary interfaces** (StylusInputProvider, AudioProvider, etc.). The native swap implements these interfaces and drops in.
4. **Keep `lesson-runtime-actions.md` actions as the runtime vocabulary.** Both renderers (Flutter widgets in Phase 1, SwiftUI views in Phase 2) implement the same action library.
5. **Use Lottie / cross-platform animation formats.** No Flutter-specific animation files (`Rive` is acceptable; both Flutter and iOS support it natively).
6. **Author audio assets at native-iOS-friendly formats.** AAC `.m4a` at the bitrates specified in `asset-paths.md`. Same files play in both phases.

---

## What we explicitly defer to Phase 2

- **PencilKit-quality stylus feel** (prediction, palm rejection, sub-frame latency)
- **Apple Math Notes equation parsing** (v1.1 feature)
- **iCloud sync** (v1.1 feature)
- **Apple Pencil double-tap and squeeze gestures**
- **App Store subscriptions / family sharing**
- **iOS system accessibility features beyond basics** (Switch Control optimization, Voice Control optimization)

These are listed in each relevant spec's "Migration notes" subsection. None of them block Phase 1 launch.

---

## Migration trigger conditions

Phase 2 (native rewrite of platform-specific code) becomes worth doing when **any** of these is true:

1. **Mac hardware is available** AND there's bandwidth (solo dev or contractor with Mac).
2. **Playtest data shows stylus latency hurting K-grade trace mastery** (e.g., K.CC.3 per-numeral mastery rate is suspiciously low despite high engagement; we suspect the stylus feel).
3. **v1.1 features require iOS-specific APIs** that don't have viable Flutter alternatives (Apple Math Notes parsing; Apple Pencil hover; iCloud sync).
4. **App Store review concerns** about cross-platform performance for an Apple Pencil-marketed product.

When any trigger fires, the migration becomes a project: estimated **6–10 weeks** for a single dev assuming the boundary interfaces have been kept clean.

---

## Risk register

### Risk 1: Stylus latency erodes kid experience
- **Likelihood**: Medium (Flutter latency is "fine" but not "great")
- **Impact**: Medium-high (K kids notice; affects trace mastery)
- **Mitigation**: Capture telemetry on per-stroke latency from day 1; if trace pass rates drop, prioritize native migration

### Risk 2: Flutter package gaps for niche needs
- **Likelihood**: Low-Medium (the K activity set is mainstream — touch, drag, draw)
- **Impact**: Low (worst case: roll your own implementation)
- **Mitigation**: Audit Flutter packages for each activity's needs during sprint planning

### Risk 3: Boundary interfaces drift from theoretical
- **Likelihood**: High if not enforced
- **Impact**: High (migration becomes a rewrite)
- **Mitigation**: Code reviews must call out direct platform-specific calls in activity code; only the boundary implementations may touch platform APIs. Set up a lint rule if possible.

### Risk 4: Dart skills vs Swift skills (contractor switching)
- **Likelihood**: Low (small product, one dev)
- **Impact**: Medium (contractor pool differs by language)
- **Mitigation**: Pick a contractor familiar with both at migration time, or accept some learning curve

### Risk 5: App Store positioning around "Native iOS" claim
- **Likelihood**: Medium (Apple sometimes preferences "native" apps in editorial coverage)
- **Impact**: Low (marketing concern, not user-facing)
- **Mitigation**: Don't claim "native" until Phase 2; "designed for iPad" is honest and accurate either way

---

## Phase 1 success criteria

Before kicking off Phase 2, Phase 1 should have demonstrated:

- ≥ 4 weeks of playtest with K kids using Flutter stylus
- Per-stroke latency telemetry collected (`stylus.stroke_latency_ms`)
- Round pass rates per activity to confirm stylus isn't a confound
- K.CC.3 trace mastery progressing at expected pace
- No widespread "this feels laggy" feedback from parents/teachers
- Coin economy balance audit completed (per `reward-economy.md`)

If Phase 1 hits these targets, the product is genuinely shippable in Flutter form and Phase 2 becomes a polish upgrade rather than a fix.

---

## Decision log

| Date | Decision | Reason |
|---|---|---|
| Original plan | Native iPadOS (Swift/SwiftUI + PencilKit) | Best stylus latency and feel |
| 2026-05-31 | **Revised**: Phase 1 = Flutter cross-platform; Phase 2 = native iPadOS swap when Mac is available | Solo dev on Windows; preserves stylus-quality upgrade path without blocking launch |
| 2026-06-01 | **Revised again**: Flutter is the durable target. The native iPadOS swap is now framed as an opportunistic upgrade, not a planned phase. The boundary interfaces remain valuable for testability + future Android targeting, regardless of whether a Mac swap ever happens. | Solo-dev pragmatism. Targeting cross-platform from day one keeps options open and avoids architecting around a swap that may never happen. |

---

## Open Questions

- **Flutter state-management library** — Riverpod is the suggested default. Final pick at sprint kickoff. Bloc and Provider are also fine.
- **Lottie vs Rive for complex animations** — Rive has better runtime performance and cross-platform consistency; Lottie has broader designer tooling. Defer to whoever's authoring animations.
- **TFLite vs ONNX for handwriting CNN** — TFLite has the better Flutter ecosystem. ONNX has slightly better tooling for training pipelines. Suggest TFLite for Phase 1; reconvert to Core ML in Phase 2.
- **Specific iPad model targeting** — Flutter on iPad runs well on M-series and A14+. Pre-A14 iPads (e.g., 2019 base) may show the latency more visibly. Decide minimum-target iPad before launch.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — establishes Flutter-first Phase 1 with native swap Phase 2; defines platform boundary, stylus input interface pattern, migration triggers, risk register, success criteria | |
