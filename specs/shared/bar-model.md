# Bar Model

> The visual representation for math structures in word-problem activities. Colored horizontal bars whose lengths correspond to counts. Anchors the *structure* of an addition / subtraction / comparison problem before the kid has to think symbolically.

References: `specs/shared/adaptive-scaffolding.md` (CPA-layer visibility), `specs/shared/k-activity-patterns.md` (Bar Model Representation pattern).

---

## Purpose

The bar model gives kids a **visual structure** for the math relationship in a word problem — distinct from the *story* and from the *equation*. It's the bridge:

```
Story          →     Bar Model        →     Equation
"5 ducks +     →     [ █ █ █ █ █ ]+   →     5 + 2 = 7
 2 more"             [ █ █ ]     =
 (Concrete)         [ █ █ █ █ █ █ █ ]      (Abstract)
                    (Pictorial)
```

At Concrete and Pictorial layers, the bar model visualizes the math structure. At Abstract, the equation form takes over and the bar may disappear or shrink.

---

## Visual Schema

A bar model is composed of one or more **horizontal bars** of variable length. Each bar represents a quantity. Bars are stacked vertically with consistent spacing.

### Bar properties
- **Length** — proportional to the count (e.g., a bar of count 5 is 2.5× longer than a bar of count 2).
- **Color** — semantic; see "Color Conventions" below.
- **Segment markers** — optional vertical tick marks at each unit boundary (visible at Concrete; hidden at higher layers).
- **Label** — the numeral count visible above or inside the bar (depending on layout).

### Bar units
- Each bar unit corresponds to one count (one duck, one cube, etc.).
- Unit pixel-size is **consistent within a single bar model** so the kid can visually compare lengths.
- Unit pixel-size **may vary across rounds** to fit the available screen real estate (small counts get bigger units; large counts get smaller units).

---

## Math Structures Supported

### Add-to (`start + change = result`)

```
       start (N)              change (M)
[ █ █ █ █ █ ] (blue)  +  [ █ █ ] (yellow)  =  ? (gray bracket)
                                                ^
                                                | combined bar appears at round-pass
                                              [ █ █ █ █ █ █ █ ] (purple)
```

The "?" appears as a gray placeholder bracket whose length matches start + change. Resolves to the colored combined bar at round-pass.

### Take-from (`start − change = result`)

```
       start (N)
[ █ █ █ █ █ █ █ ] (blue)
      −
       change (M)
[ █ █ █ ] (yellow, with strikethrough or "leaving" animation)
      =
       result (?)
[ █ █ █ █ ] (gray bracket → purple at round-pass)
```

The change segment visually animates "leaving" the start bar (slides off-screen or fades).

### Put-together (`part1 + part2 = whole`)

```
       part1 (A)             part2 (B)
[ █ █ █ ] (blue)  +  [ █ █ █ █ ] (yellow)
        =
       whole (?)
[ █ █ █ █ █ █ █ ] (gray bracket → purple)
```

Same visual as `add-to` but with two equally-weighted parts.

### Take-apart (`whole = part1 + part2`)

```
       whole (N)
[ █ █ █ █ █ █ █ █ ] (purple, given)
        =
       part1 (A, given)        part2 (?)
[ █ █ █ ] (blue)        +    [ █ █ █ █ █ ] (gray bracket → yellow)
```

The whole is given. One part is given. The other part is what the kid finds.

### Comparison (`greater − less = difference`)

```
       greater (N)
[ █ █ █ █ █ █ █ ] (blue)
       less (M)
[ █ █ █ █ ] (yellow, stacked below for visual length comparison)
       difference (?)
                  [ █ █ █ ] (gray bracket → green at round-pass)
                  ^
                  | the difference visually fills the "gap" between the bars
```

Comparison is the trickiest visualization — the difference bar appears as the "extra" length of the greater bar over the less bar. Used in 2nd-grade comparison word problems (and possibly 1st-grade with simpler ranges).

---

## Color Conventions

Colors are **semantic** and **accessibility-safe**. The palette is consistent across all bar-model uses so kids learn what each color means.

| Color | Meaning |
|---|---|
| **Blue** (#3B82F6, with deep navy outline for color-blind contrast) | Start / Part 1 / Greater |
| **Yellow** (#F59E0B) | Change / Part 2 / Less |
| **Purple** (#8B5CF6) | Whole / Combined / Total |
| **Green** (#10B981) | Difference (comparison) |
| **Gray** (#9CA3AF, dashed border) | Placeholder for unknown (?) |

**Accessibility:**
- Each color paired with a **distinct pattern or outline style** so color alone doesn't carry meaning (blue has navy outline, yellow has thick border, purple has subtle stripe pattern).
- Colors verified against common color-blind palettes (deuteranopia, protanopia).
- Color-blind alternative palette available as an accessibility option.

---

## CPA-Layer Visibility

The bar model adapts to the kid's CPA layer:

| Layer | Bar Model State |
|---|---|
| **Concrete** | Bar model **always visible** during the answer phase. Segment tick marks shown. Labels (numeral counts) shown inside each bar. Animation of "change" segments is slow and explicit. |
| **Pictorial** | Bar model **visible** during the answer phase. Segment ticks **hidden** (kid eyeballs lengths). Labels still shown. Animation is faster. |
| **Abstract** | Bar model **hidden** by default. The **equation form** (e.g., `5 + 2 = ?`) appears instead. Bar model can be summoned on-demand via a small "show structure" button for kids who want it. |

The bar model is **never the answer-entry surface** — kids don't tap on the bar. The answer is entered separately (notebook free-write or tile-select per the activity's number-writing-mode design).

---

## Layout

The bar model occupies a **horizontal band** in the playfield, typically **below the activity's main scene** and **above the answer-entry area**.

Vertical stacking:
- Multiple bars in a single model are stacked **with consistent vertical spacing** (~12 pt gap).
- The "?" placeholder appears in the position the kid would naturally expect the result.

Horizontal alignment:
- Bars are **left-aligned** by default.
- For comparison, the greater and less bars are left-aligned so the difference visually fills the right-side gap.

Screen-fit:
- Maximum total width ~80% of playfield width.
- Unit size scales down for large counts.
- For counts > 10, consider grouping bar units in chunks of 5 for easier visual reading (`█████ █████ █` for 11).

---

## Used By

- **Storyteller's Pond** (K.OA.1 / K.OA.2 word problems) — first activity to use the bar model.
- **Wundle Tales** (1.OA.1 / 1.OA.2 word problems) — planned use.
- **Hero Missions** (2.OA.1 word problems) — planned use.
- **Compare Baskets** / **Picnic Baskets** (K.CC.6 comparison) — may use the comparison bar at higher layers.

---

## Implementation Notes

### Suggested widget tree

Per `platform-architecture.md`: Phase 1 = Flutter widgets, Phase 2 = SwiftUI views. Decomposition is identical across phases.


```
BarModelView(structure: BarStructure)
├── BarStack (vertical layout)
│    └── Bar (horizontal; configured per BarSpec)
├── LabelLayer (numerals above/inside bars)
├── PlaceholderBracket (gray dashed ?)
└── AnswerRevealLayer (animates combined/result bar on round-pass)

BarStructure {
  type: AddTo | TakeFrom | PutTogether | TakeApart | Comparison
  bars: [BarSpec]
  unitSize: Double         // pixels per unit, computed to fit playfield
}

BarSpec {
  count: Int
  color: BarColor          // Blue / Yellow / Purple / Green / Gray
  label: String?
  showTicks: Bool          // by CPA layer
  animation: AnimationSpec? // e.g., "change leaves" for take-from
}
```

### Reusable component

Should be a single shared component, not per-activity. Activities pass a `BarStructure` describing their problem; the component renders.

### Performance

Bar rendering is procedural geometry (colored rectangles). Trivial cost.

---

## Open Questions

- **Comparison bar at K** — K standards don't formally require comparison (K.CC.6 is "matching" comparison, not bar-length comparison). Confirm whether to expose the comparison bar form in K activities or save for 1st/2nd.
- **Unit grouping threshold** — `█████ █████ █` chunking for counts > 10 proposed. Confirm with art that this reads cleanly without making the bar look segmented as if it's multiple bars.
- **"Show structure" button at Abstract layer** — should kids who've mastered abstract still be able to peek at the bar model? Suggest yes; some kids benefit from seeing the structure even when they can do the abstract math. Small button at the bottom of the answer area.
- **Color-blind alternative palette** — defer to accessibility design phase; the palette here is the launch default. The alternative should swap purple for orange (or similar) to handle deutan vs protan color spaces.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-30 | Initial draft — extracted from Storyteller's Pond's word-problem visualization to a shared component | |
