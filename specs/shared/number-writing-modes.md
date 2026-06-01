# Three Number-Writing Modes

> Every place where the kid writes a numeral declares which of these three modes it uses. The modes are layered: harder modes fall back to easier ones automatically when the kid struggles, and easier modes promote to harder ones as the kid succeeds.

References: `stylus-mechanics.md` (the underlying Trace and Free-Write mechanics), `platform-architecture.md` (how the digit classifier and stylus-input pipeline are realized in Phase 1 / Phase 2).

**Implementation phases**: Mode 1 (Trace) is geometric scoring — pure math, platform-agnostic, runs identically in both phases. Modes 2 and 3 use a digit classifier; Phase 1 runs the model via TFLite-Flutter, Phase 2 runs the same model converted to Core ML. The model file is the same across phases; only the inference runtime differs.

---

## Mode Summary

| Mode | Cue shown | Recognition | Typical grade | Difficulty |
|---|---|---|---|---|
| **1 — Trace** | Dotted/ghost numeral path | Geometric stroke scoring (no ML) | K | Easiest |
| **2 — Prompted Free-Write** | Audio + visible quantity ("twelve" + 12 dots) | Digit classifier (ML) | K (late), 1st | Medium |
| **3 — Blind Free-Write** | No shape cue; kid computes the answer | Digit classifier (ML) | 1st (late), 2nd | Hardest |

---

## Mode 1 — Trace

### Purpose
Build motor familiarity with each numeral's shape. Cognitive load is on the *shape*, not on recall.

### Visual
- A dotted-line or low-opacity ghost numeral fills the write zone.
- Stroke order is implied by a faint "1, 2, 3" subscript on each sub-stroke's starting end (for numerals like 4 and 5 that have multiple strokes).

### Scoring (no ML)
See `stylus-mechanics.md` → Mechanic: Trace. Geometric % within tolerance band; pass at 80%.

### Pass / fail
- **Pass**: stroke score ≥ 80% AND covered ≥ 75% of path length. Numeral animates to life.
- **Fail**: retry up to 2 times. On 3rd consecutive fail, fall back to **Assisted Trace** (see below).

### Assisted Trace (fallback inside Mode 1)
- The dotted path becomes a wider, brighter glow.
- The Pencil "magnets" softly toward the path centerline (visual nudge, not physical force on input).
- Pass threshold relaxes to 60%.

### When used
- All K Number Tracing Studio / Scribe's Tower starts here.
- Any Mode 2 or 3 prompt that hits the fallback chain ends up here.

---

## Mode 2 — Prompted Free-Write

### Purpose
Recall and produce the correct digit when shown a quantity or hearing the name.

### Visual
- Write zone is empty (just a baseline).
- A prompt is shown via one of:
  - **Audio narration**: "Write twelve."
  - **Visible quantity**: 12 dots, 12 creatures in a parade, etc.
  - Both (default — supports the kid who missed the audio).

### Recognition
See `stylus-mechanics.md` → Mechanic: Free-Write. Digit classifier with confidence ≥ 0.70 to accept.

### Pass / fail
- **Pass**: classifier confidence ≥ 0.70 AND digit matches expected. Numeral confirmed; round complete.
- **Low confidence (0.40–0.70)**: confirmation prompt — "I think I see a 7 — is that right?" Kid taps Yes / Try Again.
- **Wrong digit (high confidence)**: gentle reveal — "That's a 7. We were looking for 8. Let's try again." Falls to retry.
- **2 consecutive fails** → fall back to **Mode 1 — Trace** for the same prompt.

### When used
- K Number Tracing Studio (after a kid has mastered the trace for that digit).
- 1st-grade activities that ask for a writeable answer with a visible quantity context (Wundleclock "read & write," Tenforge answer prompts, Coin Counter notation, etc.).

---

## Mode 3 — Blind Free-Write

### Purpose
Produce the correct digit from a computed result — no shape or quantity cue available.

### Visual
- Write zone is empty.
- The prompt is purely the problem (e.g., the displayed equation, the word problem, the question).

### Recognition
Same as Mode 2 (digit classifier, ≥ 0.70).

### Pass / fail
Same as Mode 2.

### Fallback chain
- 2 fails → drop to **Mode 2 — Prompted Free-Write** (system shows the answer as dots or speaks it, kid writes it).
- 2 more fails at Mode 2 → drop to **Mode 1 — Trace** (system reveals the correct numeral and the kid traces it).
- A wrong answer that the classifier reads correctly (e.g., kid writes "6" when answer is "8") is **the kid's error**, not a recognition failure. Treated per the activity's scaffolding triggers.

### When used
- 1st-grade Tenforge final stage.
- All 2nd-grade math-notebook arithmetic.
- 2nd-grade Casebook standard-algorithm work.

---

## Within-Activity Progression

When an activity uses multiple modes, the default progression is **Trace → Prompted Free-Write → Blind Free-Write** as the kid succeeds at each level. Specifics:

1. **First exposure** to a new numeral or digit-writing context starts at the activity's declared starting mode.
2. **3 consecutive successes** at the current mode → activity may promote to the next mode for the next round (activity-spec controlled; not all activities promote).
3. **2 consecutive failures** → activity demotes one mode for the next round.

These transitions are silent — no UI announces "level up." The kid just sees the prompt look slightly different.

---

## Across-Grade Progression

Default mode mix per grade (override per activity):

| Grade | Trace | Prompted | Blind |
|---|---|---|---|
| K | 70% | 30% | 0% |
| 1 | 15% | 60% | 25% |
| 2 | 5% | 25% | 70% |

Percentages are *first-exposure* defaults. As kids master content, blind use rises within a grade.

---

## Tile Selection Fallback (final fallback)

If the entire chain fails — Mode 3 → Mode 2 → Mode 1 → Assisted Trace, and the kid still can't produce a recognizable digit — the system offers **number tile selection**: 0–9 tiles appear, kid taps one. This is always a way out. It's logged distinctly so the dashboard can surface "kid is over-relying on tiles" as a teacher signal.

---

## Telemetry Events

| Event | When | Payload |
|---|---|---|
| `numwrite.attempt` | kid starts a write | mode, expected digit (or null for blind) |
| `numwrite.classified` | classifier returns | mode, expected, recognized, confidence |
| `numwrite.confirmed` | kid confirms a low-confidence read | mode, recognized, kid's confirmation |
| `numwrite.pass` | round completes successfully | mode, attempts used |
| `numwrite.fallback` | mode demoted | from-mode, to-mode, reason |
| `numwrite.tile_used` | kid resorted to tiles | expected digit, prior attempts |

---

## Audio Cues

| Event | Default cue |
|---|---|
| Mode 1 trace start | Soft pen-down tick |
| Mode 1 trace pass | Numeral-comes-to-life flourish (per activity) |
| Mode 1 trace fail | "Almost — let's try again" narration (region-narrator voice) |
| Mode 2/3 prompt | "Write {twelve}." or visible-only |
| Mode 2/3 low confidence | "I think I see a {7}. Is that right?" |
| Mode 2/3 wrong answer | "That's a {7}. We were looking for {8}." |
| Tile fallback offered | "Tap the number you mean." |

---

## Open Questions

- **Promotion thresholds (3 successes, 2 failures)** are starting positions; tune with playtesting.
- **Per-digit difficulty** — some digits are reliably harder for kids (4, 5, 7, 9). Should mode progression be per-digit rather than per-context? Defer to v1.1.
- **Stroke-order enforcement** in Mode 1 — soft (hint only) at launch, possibly strict in v1.1 for kids whose teachers want it.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
