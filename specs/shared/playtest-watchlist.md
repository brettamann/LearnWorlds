# Playtest Watchlist

> Items the K (and later 1st/2nd) review identified as **small risks worth watching during playtest**, but not worth fixing pre-launch. Each entry: the concern, the planned observation, and the trigger threshold for action.

---

## Purpose

Spec authors flag concerns that *might* matter but aren't worth pre-launch effort to fix speculatively. The watchlist captures those concerns so playtest reports can confirm or reject them and we know which to act on.

This file is **not** a place to dump every uncertainty — only items that:
1. Are observable in playtest (a clear pass/fail signal exists).
2. Have a defined trigger threshold ("if X happens, do Y").
3. Are reversible / fixable post-launch without major rework.

---

## K Items (added 2026-05-30 from K-review pass)

### 1. "Soft no puff" sensitivity

**Concern:** K kids are sensitive to even gentle negative feedback. The "soft no puff" SFX used in many activities for wrong taps/drops might still feel like rejection.

**Watch for:**
- Kids who **stop tapping** after a single soft-no.
- Kids who **shift to long hesitations** specifically after a wrong-input event (compare hesitation patterns before vs after wrong inputs).
- Parent feedback: "they get sad/give up when X happens."

**Trigger to act:** if ≥ 20% of K kids in playtest show post-no-input hesitation spikes ≥ 30% longer than baseline, swap the puff for a positive visual-only cue ("try this one" with an arrow, no SFX).

**Owner:** UX + audio direction.

---

### 2. Single-species monotony at Concrete (counting activities)

**Concern:** The Concrete-layer "single species per round" rule (per `k-activity-patterns.md`) prevents species being a counting crutch but may feel visually monotonous over many rounds (Counting Parade, Care Pantry phase 2).

**Watch for:**
- Drop-off in engagement during rounds 5–10 of Counting Parade Concrete (which all show the same species).
- Kids requesting "different animals" between rounds.

**Trigger to act:** if Counting Parade Concrete-layer session lengths shrink ≥ 30% by round 7 compared to round 2, allow **species rotation within a single Concrete session** (different species per round, still single-species per round). This preserves the no-species-crutch rule while restoring visual variety.

**Owner:** activity design.

---

### 3. Per-instance progress feeling endless

**Concern:** Even with the new intermediate milestones (Five Stamps, All Single Digits, etc.), the 21-numeral / 42-fact roads might still feel long enough to demotivate. Milestones added in the K-review pass should help.

**Watch for:**
- Kids who stop opening Scribe's Tower after 3–5 numerals mastered (suggesting "I've done this" boredom).
- Kids who never engage Fluency Within 5 after the first few sessions.
- Time between consecutive `scribe.numeral_mastered` events stretching beyond ~10 days.

**Trigger to act:** if median time-between-numerals-mastered exceeds 14 days, add a smaller mid-tier milestone (every 3 numerals instead of every 5 / 10).

**Owner:** reward economy + activity design.

---

### 4. Daily Quest 5-round cadence feeling short

**Concern:** Daily Quest is ~5 minutes (5 rounds at ≤1 min each). Some kids may want more; others may want fewer.

**Watch for:**
- Kids who immediately go to Free Play after Daily Quest ends (suggesting unsatisfied want for more).
- Kids who exit mid-Daily-Quest (suggesting too long).

**Trigger to act:**
- If ≥ 50% of kids continue into Free Play immediately, consider extending Daily Quest to 7 rounds OR adding a "Bonus Round" button at the end.
- If ≥ 30% of kids exit mid-Quest, consider shortening to 3–4 rounds.

**Owner:** Daily Quest curation algorithm.

---

### 5. 21 numeral character designs (Scribe's Tower)

**Concern:** Each numeral 0–20 has its own personality. That's substantial art investment, and some personalities (e.g., 11, 12) may end up generic or forced.

**Watch for:**
- Kid feedback during playtest: "which numeral is your favorite?" answers concentrated on 5–6 favorites suggests the others are forgettable.
- Mastery-pacing data: are kids mastering personality-strong numerals (5, 8, 10) faster than personality-weak ones (11, 12, 17)?

**Trigger to act:** if some numerals feel anonymous, consolidate their personalities (e.g., teen numbers as a "teen family" with shared art language) and reduce art scope for the next iteration.

**Owner:** art direction.

---

### 6. Music BPM bump in Speed Run (Fluency Within 5)

**Concern:** Music tempo subtly bumps from 100 to 110 BPM in Speed Run mode. The bump is intentional energy; for sensitive kids it may feel like pressure.

**Watch for:**
- Kids who try Speed Run once and never opt in again.
- Kids who report Speed Run feeling "fast" or "stressful" in interviews.

**Trigger to act:** if ≥ 25% of kids who try Speed Run never return, remove the BPM bump and keep tempo constant; rely on the combo multiplier alone for energy.

**Owner:** audio direction.

---

### 7. K.G.1 second lesson timing

**Concern:** `lesson-k-g-1b-more-position-words` fires on the kid's second Where's Buddy session. If the gap between sessions is long, the kid may have forgotten the first 3 words, making the comparison-pairing structure ("you know above — now below") confusing.

**Watch for:**
- K.G.1b lesson failures (`lesson.youdo_failed_out`) clustered for kids whose first-to-second Where's Buddy session gap exceeded 2 weeks.

**Trigger to act:** if these failures spike, prepend a 5-second "remember above? remember behind?" recall beat to the K.G.1b lesson opening.

**Owner:** lesson author.

---

### 8. K.OA.1 sibling credit rule reachability

**Concern:** The added sibling credit (K.OA.2 grants `scene-manipulation` mode) makes K.OA.1 reachable, but kids who never use the notebook AND only do equation-form rounds at Abstract layer might still get stuck.

**Watch for:**
- Kids whose K.OA.2 is `Mastered` but K.OA.1 stays `Practicing` for 30+ days.

**Trigger to act:** if this pattern persists for ≥ 5% of mastered-K.OA.2 kids, lower K.OA.1's `minModesDemonstrated` from 2 to 1 (with sibling credit, that's effectively just K.OA.2 success).

**Owner:** mastery engine + concept registry.

---

### 9. Coin economy reachability (already flagged)

See `reward-economy.md`'s "Coin balance audit pending" section. The watchlist entry here is just to remind us during playtest to actually measure:
- Daily-quest engagement (% of kids completing 4+ days/week)
- Days-to-first-Foundry-creation (target: ≤ 14 days)
- Days-to-first-Foundry-frame-creation (target: ≤ 42 days)

**Trigger to act:** any of the targets missed by ≥ 50% suggests rebalancing.

### 10. Text-only narration + system TTS during the deferral period

**Concern:** Voice production deferred (see `text-and-tts-deferral.md`). During the deferral, kid-facing narration is rendered as on-screen text + (optional) the device's robotic system TTS. K kids can't read; parents either read aloud or enable system TTS. The robotic voice might erode engagement enough to flag voice production as an early come-back priority.

**Watch for:**
- Parent feedback in the first cohort: "the robotic voice is grating" vs. "fine for now."
- Kid drop-off rate in activities where caption text is dense (Storyteller's Pond especially).
- Time-to-first-tap after a caption appears — if kids freeze (can't read), they're waiting for narration that isn't coming.

**Trigger to act:**
- ≥ 30% of cohort 1 parents say the system TTS is "too robotic" → accelerate voice production come-back.
- ≥ 25% kid-tap latency increase in activities heavy in narration → same trigger.
- Otherwise: defer voice through cohort 2; re-evaluate quarterly.

**Owner:** project lead (decides come-back timing); UX (caption design); audio direction (voice picking).

---

## How to use this file

- Each playtest cohort: review entries, plan observation points, log triggered concerns.
- Items that **trigger** convert to actual backlog work (with a fix spec).
- Items that **don't trigger after 3 cohorts** can be marked `[stale]` and archived; the concern was overblown.
- New concerns: add an entry following the template (Concern / Watch for / Trigger / Owner).

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — 9 K items from the K-review pass | |
