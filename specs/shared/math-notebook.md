# Math Notebook & Digit Recognition

> The persistent stylus surface that accompanies most activities. Doubles as a scratch space (free drawing, no recognition) and an answer-entry surface (with recognition). Composes the *Free-Write* mechanic and the *Three Number-Writing Modes*.

References: `stylus-mechanics.md`, `number-writing-modes.md`.

---

## Purpose

- Give kids a place to **show their work** — sketches, partial sums, place-value columns.
- Provide a recognized **answer-entry surface** for activities that want it.
- Make the **pencil-and-paper feel** explicit, not a metaphor.

The notebook is the single most-reused surface in the product. Every activity that *can* benefit from it gets it.

---

## Surface Anatomy

The notebook is a side-drawer that slides in from the **right edge** of the screen. States:

- **Collapsed (default in most activities)** — a small tab/handle on the right edge with a notebook-corner icon. Untouched, it's quiet.
- **Peek** — partial reveal (~25% of screen width). The kid can sketch a quick mark and dismiss.
- **Open (full)** — ~50% of screen width. Full notebook page visible.
- **Fullscreen** — replaces the activity for kids who want a clean workspace; activity context shown as a thumbnail at the top.

State transitions are stylus-friendly: tap-and-drag the tab to open/close, or auto-open via activity prompt.

---

## Page Anatomy

Each page contains:

- **Free-draw region** — the bulk of the page. Strokes are free ink with no recognition.
- **Recognition zone(s)** — visually distinguished areas (a light baseline, a faint box) where the system runs digit recognition on settled strokes.
- **Tool palette** (top of page) — pen, eraser, color (matched to home theme), undo, redo, clear page, page navigator.
- **Page tabs** (left of page) — multi-page support; kid can add/remove pages within a session.

---

## Recognition Zones

A recognition zone is declared by the *active activity*, not by the notebook itself. The activity passes a `recognitionContract` to the notebook:

```
RecognitionContract {
  zones: [
    Zone {
      id: String                  // e.g., "answer-1"
      bounds: Rect                // in notebook page coordinates
      mode: Mode1 | Mode2 | Mode3 // from number-writing-modes.md
      expected: DigitOrEquation   // for mode 1/2; nil for mode 3
      maxDigits: Int              // e.g., 1, 2, 3
      onClassify: (Result) -> Void
    }
  ]
}
```

When the kid writes inside a zone and the **end-of-input timeout** fires (1.2 s), the notebook runs the digit classifier (per `number-writing-modes.md`) and reports results back to the activity.

Zones outside this contract are pure scratch — free draw, no recognition, no judgment.

---

## Free-Draw Behavior

- Strokes settle on the page; they're inked and stay until cleared.
- No semantic interpretation.
- No coin / scoring effect from free-draw scribbles.
- The kid can erase with the eraser tool or clear the whole page.

---

## Persistence

- **Within an activity round** — pages persist; strokes remain across rounds in the same activity.
- **Across activity sessions** — the notebook resets to blank at the start of each new activity entry. (Kids don't expect to see yesterday's work.)
- **Optional "save to scrapbook"** — kid can tap "keep this page" to save a snapshot to the Hub's scrapbook. Pages saved here persist forever.

---

## Activity Integration Contract

Activities can be in one of three relationships with the notebook:

### Optional
- Notebook is **collapsed** by default.
- A small "notebook" hint icon may appear (activity choice).
- Using the notebook earns a **+small coin bonus** per round it's used (see `reward-economy.md`).
- Example: K Story Pond, 1st Wundle Tales.

### Encouraged
- Notebook is **peeked open** by default.
- The activity prompt explicitly mentions it ("you can write your work in the notebook").
- Using it is rewarded; not using it is fine.
- Example: 1st Tenforge (later rounds), 2nd Hero Missions.

### Required
- Notebook is **open** by default, sometimes fullscreen.
- The activity's answer is entered via a recognition zone in the notebook.
- The kid cannot complete the round without using the notebook.
- Example: 2nd Casebook (standard algorithm).

Each activity spec declares which relationship it has, per round if needed.

---

## Bonus Coin Logic

(Specifics live in `reward-economy.md`; summarized here for reference.)

- **+1 coin** when a kid completes a round with **any non-trivial notebook use** (≥3 strokes covering ≥1% of the page area).
- **+1 additional coin** when the kid's notebook work matches a "shown your work" signature (e.g., wrote a number in the place value column, drew a bar model). Pattern recognition is heuristic, not strict.
- Capped at **+2 coins per round** from notebook bonuses.

---

## Digit Classifier (Launch)

### What it does
Classifies a single handwritten digit (0–9) from a settled stroke set within a recognition zone.

### How it works
- **Model** — small convolutional net, ~50k parameters. Targets <5 ms inference on iPad A12+ chips.
- **Training data** — MNIST (60k digits) + a custom set of ~10k digits collected from kids ages 5–8 (varied stylus angles, sizes, sloppy strokes).
- **Bundled on-device** — no network calls. Recognition works offline.
- **Confidence** — softmax output; activities use ≥0.70 threshold (per `number-writing-modes.md`).

### Implementation phases (per `platform-architecture.md`)
- **Phase 1 (Flutter)**: model runs via TFLite-Flutter package. Same `.tflite` artifact, Dart-side inference. Bundled in app, no network.
- **Phase 2 (native, post-Mac)**: same model converted to Core ML, runs via the Neural Engine on supported iPads for lower latency and battery cost. The conversion is a one-shot pipeline; model weights are identical.

The classifier API consumed by the notebook is the same in both phases — only the underlying inference runtime changes.

### What it doesn't do (yet)
- **Multi-digit numbers** — at launch, recognition zones with `maxDigits > 1` use **sequential single-digit recognition**: write the tens digit, then the ones digit, in side-by-side sub-zones.
- **Operators** (+, −, =) — handled by drag-tile equation layout at launch.
- **Algebraic structure** — `7 + 5 = 12` validated structurally — v1.1.

### Accuracy target
- **>95%** on the launch test set (mixed kid handwriting samples) for confident classifications (≥0.70 confidence).
- The remaining 5% surface as low-confidence prompts ("I think I see a 7 — is that right?") and resolve via confirmation.

---

## Multi-Digit Strategy at Launch

When an activity needs a 2- or 3-digit answer (e.g., 2nd Casebook computing `47 + 28 = ?`), the recognition zone is split into **digit cells**:

```
+---+---+
|   |   |
+---+---+
 ten ones
```

Each cell runs single-digit recognition independently. The activity reassembles `(tens, ones) → 75`. Cells highlight one at a time to indicate write order.

This eliminates the need for character segmentation at launch (the hardest part of multi-digit OCR) without giving up the handwritten experience.

---

## Visual Feedback

| Event | Visual |
|---|---|
| Notebook tab visible | Subtle pulse every 8 s if untouched for a while |
| Stroke entered | Ink in kid's chosen pen color |
| Settled in recognition zone | Brief outline pulse on the zone |
| Recognition pending | A small spinner at the zone edge for ~200 ms |
| Recognition pass | Zone fills with the confirmed numeral, faint green tint |
| Recognition low confidence | Yellow tint + "Is this a 7?" floating confirmation |
| Recognition fail / fall back | Tint dissolves, mode demotes per fallback chain |

---

## Audio Cues

| Event | Cue |
|---|---|
| Notebook opens | Soft paper rustle |
| Stroke down | Pen-on-paper sound (very subtle; off by default after first session) |
| Settled & classified | Soft "tick" |
| Low-confidence prompt | Region narrator voice |
| Page cleared | Eraser swish |
| Saved to scrapbook | Light camera-shutter snap |

---

## Accessibility

- **Keyboard / tile fallback** — every recognition zone has a tile-tap fallback (0–9 tiles appear on demand or after 2 recognition failures).
- **High-contrast ink** option in settings.
- **Pencil-grip-friendly tab placement** — the open/close tab is large enough for kids with motor differences.

---

## Telemetry Events

(Most events delegate to `number-writing-modes.md`; notebook-specific ones:)

| Event | When | Payload |
|---|---|---|
| `notebook.opened` | tab pulled open | how (tap, drag, auto) |
| `notebook.scratch_used` | ≥3 strokes in a round | activity id, round id |
| `notebook.saved_to_scrapbook` | kid taps save | page snapshot reference |
| `notebook.cleared` | clear-page tap | activity id, round id, stroke count cleared |

---

## Open Questions

- **Eraser semantics** — full-stroke erase (tap a stroke, it goes) vs paint-style erase (drag to scrub)? Suggest full-stroke at launch (clearer for kids), paint in v1.1.
- **Multi-page UX** — how many pages should a kid be able to add in one session? Cap at 5 to keep navigation simple, or unlimited?
- **Recognition latency budget** — current target is 200 ms from stroke-settle to result; tune with playtesting.
- **Multi-digit cell visualization** — should empty cells show ghost digits (like a "1_" placeholder for tens) to help kids? Suggest yes; activity-spec override allowed.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
