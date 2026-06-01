# Art Direction

> The visual language for the entire product. Bright + colorful + not overwhelming. Hand-drawn warmth over corporate cartoon. Pipeline: cohesive asset packs + AI generation + targeted freelance work, with consistency rules so the seams don't show.

References: `we-are-going-to-eventual-lantern.md` (Tone & Aesthetic section), `specs/shared/k-activity-patterns.md` (per-activity scene descriptions), `specs/shared/asset-paths.md`, `specs/shared/onboarding-flow.md` (home styles + customization parts).

---

## Visual language principles

Drawn from the top-level plan, made concrete here:

1. **Charming, fun, creative — never condescending, never babyish.** A 7-year-old should want to show it to a 10-year-old.
2. **Hand-drawn warmth over corporate cartoon.** Visible brush texture, soft outlines, slight asymmetries. Not perfectly clean vector.
3. **Bright but not saturated.** Colors lean **medium-saturated with high value** — feel sunny, not neon. Avoid pure primaries; prefer warm and slightly desaturated alternatives.
4. **Generous space.** Each scene has clear focal points. Backgrounds are decorated, not crowded. Negative space is part of the design.
5. **Charmingly imperfect.** Slight wobble in linework, gentle wear textures on objects, organic shapes over geometric ones. Avoid pixel-perfect or sharply clinical.
6. **Variety of worlds is part of the charm.** Pirates next to bakeries next to dinosaurs — the mix is intentional. Each world keeps its own identity within the shared visual language.
7. **Respect for kid intelligence visually.** No giant text labels, no condescending "GREAT JOB!" banners, no over-the-top sparkles on every action. Reward signals are warm, not loud.
8. **Color and shape carry meaning together.** Per accessibility: never rely on color alone. A "wrong" cue is a soft visual *and* a soft audio puff, not red flashing.

---

## Reference style touchstones

To anchor the team's mental image (these are pointers, not licenses to copy):

| Reference | What we take from it |
|---|---|
| **Stardew Valley** | Warm pixel-art-adjacent feel; cozy environments; characters with personality; UI that doesn't shout |
| **Animal Crossing: New Horizons** | Soft pastel palettes; charming creature designs; relaxed pacing in environment art |
| **Pikmin / A Hat in Time** | Painted background style; sense of scale; large-headed characters that read clearly at small size |
| **Sky: Children of the Light** | Generous negative space; mood lighting; "this place feels meaningful" |
| **Toca Boca apps** | The reference for "kid-friendly UI without being babyish"; clear actions, no text dependence |
| **The Sapling / Untitled Goose Game** | Hand-drawn linework + flat color fills with subtle texture |
| **Numberblocks (BBC)** | Character-driven numerals with distinct personalities (relevant for Scribe's Tower's 21 numeral characters) |

What we **don't** want:
- Disney-Pixar 3D plastic look
- Corporate edutainment "everyone smiling at the camera" art
- Steam-engine Victorian whimsy (too niche for the age range)
- Overstuffed maximalist scenes (Where's Waldo territory)

---

## Color palette system

### Master palette principles

- **Warm slightly-desaturated bases** for environments (HSL: 0–60°, S 40–60%, L 65–80%)
- **Brighter accents** for interactive elements (S 60–75%, L 55–70%)
- **Deep saturated punches** reserved for reward moments (S 80%+, L 50%)
- **Never pure black** — darkest line color is `#2A1F26` (warm near-black)
- **Never pure white** — lightest background is `#FBF6E9` (cream)

### Per-region palette anchors

These are starting points; per-activity art may adjust within the region.

#### Sanctuary (K) — "warm, alive, gentle preserve"

```
Background grass     #A8D08D   soft sage
Background sky       #BFE3F5   soft sky-blue
Path / dirt          #C8A877   warm tan
Sun yellow           #F9D976   sunlight
Lily pad green       #6DA659   pond-leaf
Water blue           #7BB8C9   pond-water
Sanctuary leaf       #5A8F44   logo + accent
Warm shadow          #3D2B2E   line color
Cream highlight      #FBF6E9   text on shadow
```

#### Wundletown (1st) — "village of accident-prone wizards, comedic"

```
Cobblestone gray     #B5A9A5   warm gray
Wizard purple        #8B5FBF   spell color (accent)
Spell green          #6FAE6D   misfired spell
Lantern gold         #E8B85F   shop lights
Mushroom red         #C2554A   accent (rare)
Sky dusty rose       #E8B8AE   sunset overhead
Wand wood            #8D5E3C   brown accents
Warm shadow          #3D2B2E
Cream highlight      #FBF6E9
```

#### Mathopolis (2nd) — "low-stakes superhero city, comedic-action"

```
City sky             #A5C9E8   blue daylight
Brick warm           #C97A5F   building red-brown
Concrete             #BFB8B0   neutral gray-tan
Hero blue            #4A7FBA   accent (heroes)
Villain magenta      #BA4A7F   accent (villains)
Sign yellow          #F5C84A   bright signage
Sidewalk             #D6CFC2   pavement
Warm shadow          #3D2B2E
Cream highlight      #FBF6E9
```

#### Foundry — "forge / workshop, industrial-warm"

```
Forge orange         #E8854A   fire glow
Steel cool           #8A9099   metal
Anvil dark           #5A4E4F   tool dark
Wood warm            #A87850   workbench
Ember red            #C04A3D   hot detail
Smoke gray           #D4CDC4   ambient
Warm shadow          #3D2B2E
Cream highlight      #FBF6E9
```

#### Portal worlds (each has its own palette)

Defer per-portal palette to portal-spec authoring. Each portal world's palette should feel **distinctly other** from the regions — that's the "step through a portal" reveal moment.

### Color-blind safety

- Every color-coded indicator (mastery status, sort bins, etc.) pairs with a **shape** or **icon** difference.
- The palette is tested against Deuteranopia, Protanopia, Tritanopia simulators before locking. A specific color-blind-safe variant lives in `assets/.../cb/` for v1.1 toggle (per `asset-paths.md`).

---

## Character design principles

### Math Buddy (the kid's creature companion)

- **Customizable from parts** (per top-level plan): body, ears, tail, eyes, fur/pattern, accessory.
- **Charming over cute.** Slightly chunky proportions; oversized eyes; soft outlines; idle animations include a blink + small movement every ~5s.
- **No fixed species** — the parts library lets the kid build something that looks plausibly animal-like but isn't a specific real creature. Avoids "is it a dog or a cat?" questions.
- **Color palette** — the kid picks within a curated palette (avoids garish combinations).
- **Size** — Buddy is **smaller than the kid's Avatar** in most scenes; **larger in Fluency Within 5** where Buddy is the activity host.
- **Reactions** — celebratory hops, attentive head-tilts, sleepy blinks. Never sad or disappointed reactions to wrong answers (the "soft no puff" handles that without a Buddy frown).

### Avatar (the kid's in-game self)

- **Customizable from parts**: skin tones (palette of 8, inclusive), hair (12 styles × 8 colors), face (6 base shapes + eye/mouth options), outfit (6 starter sets + more unlocks).
- **Stylized humanoid** — slightly chunky, large head, simple proportions. Reads at small size in dashboards and share cards.
- **Inclusive by default** — every skin tone option is equally featured in marketing/onboarding screens; no defaulting to one specific tone.

### Numeral characters (Scribe's Tower — 21 personalities)

Each numeral 0–20 has a personality. Per the K review's playtest-watchlist, the 21 unique characters is substantial art investment; the playtest will tell us if some feel anonymous.

**Style guidelines:**
- Each numeral is **based on the numeral's shape** — the "5" has the 5-shape's posture (curve at the bottom, horizontal top); the "1" stands tall.
- Faces and limbs are **minimal** — small dot eyes, no mouth or a tiny mouth, optional little arms/legs. The numeral shape is the character.
- **Personality cluster grouping** (suggested to keep production scope manageable):
  - **Single digits (0–9)** — most distinct personalities (heavily used; first encountered)
  - **Teen numbers (10–19)** — a "teen family" with shared visual language (similar accessories or coloring) — reduces art scope vs 10 fully unique designs
  - **20** — a "milestone" numeral with a small celebratory accent

### Region creatures

#### Sanctuary creatures (~24 species)
Mix of real (goats, fawns, ducks, koi) and mythical (unicorns, hatchling dragons, baby gryphons). Style: gentle and approachable; warm tones; mythical creatures are clearly kid-friendly (no scary fangs, no menacing poses). Asset-pack candidates: "Cute Animals" style packs on itch.io, often $5–30 per pack.

#### Wundletown wizards
Comedic-frazzled with mismatched robes, oversized hats, exasperated postures. Each wizard is a character (Mage Mortimer, etc.) — implies ~6–10 named wizards at launch, more emerging from content.

#### Mathopolis heroes & villains
Hero costumes are simple, color-coded, slightly silly (Captain Comet, Sky Patrol). Villains are obviously comedic — Lord Layerton has cake-themed costuming. Style note: more dynamic posing than Sanctuary; suggests comic-action energy without going Marvel-grade.

### Hub home interiors (4 styles)

Per `onboarding-flow.md`: cottage, castle, treehouse, sci-fi base. Each home has a **distinct interior aesthetic** that the kid sees every time they open the app. Same layout (decor slots, Buddy's spot, math notebook position) but different surfaces:

- **Cottage** — wood, fabric, soft textiles, warm lamp light
- **Castle** — stone, tapestries, heraldic accents (kid-sized scale)
- **Treehouse** — wood with bark detail, leaves visible through windows
- **Sci-fi base** — clean curved surfaces, gentle holographic accents, never cold

Decorative items earned in portal worlds adapt their finish to the home style (a Pirate Planet trophy hangs as a sail-banner in the treehouse vs holo-display in sci-fi). **Same item asset, different finish overlay.**

---

## Asset production pipeline (Mix approach)

Per user direction: asset packs + AI generation + targeted freelance.

### Decision matrix per asset type

| Asset type | Recommended source | Why |
|---|---|---|
| **Environment backgrounds** (Sanctuary clearing, ten-frame pond, etc.) | **Asset pack base + AI polish** | Packs give cohesive style; AI generates the specific compositions; manual polish unifies |
| **Buddy parts library** | **Freelance illustrator** | Needs internal consistency across many parts; the centerpiece of customization |
| **Avatar parts library** | **Freelance illustrator + AI** | Same consistency need; AI can help with skin-tone variants once the master is drawn |
| **Numeral characters (21)** | **Freelance illustrator** | Each needs personality; AI tends to converge on generic faces |
| **Sanctuary creatures** (~24 species) | **Asset packs + AI for variants** | Cute animal packs exist; AI adapts color/pose |
| **Wundletown wizards (~10)** | **Freelance** | Character designs need specific personalities |
| **Mathopolis heroes (~6) + villains (~4)** | **Freelance** | Same |
| **UI elements** (HUD, buttons, dialog frames) | **AI + manual polish** | Cohesive style achievable with prompt discipline |
| **Sprites for objects** (sticks, clay balls, fish, fruit, etc.) | **Asset packs + AI** | Many small objects; cheap to source |
| **Hub home interiors (4)** | **Asset packs + AI** | Furniture/decor packs exist for each style |
| **Stamps, trophies, collectibles** | **AI + manual polish** | High volume (~12 per activity × 11 activities); AI handles variety with style consistency |
| **Portal worlds** | **Asset packs + AI** | Each portal is distinct; cohesion within world > cohesion across portals |
| **Storyteller turtle character** | **Freelance** | Visible narrator; needs mouth-sync rigging |
| **Cutscenes** (onboarding arrival, round-pass celebrations) | **Mix** — environment from packs, characters from freelance, polish in motion |

### Asset pack vetting

When sourcing asset packs, evaluate:

| Criterion | Threshold |
|---|---|
| Style match to our visual language | Hand-drawn, warm, slightly imperfect; not vector-clean |
| Color palette compatibility | Can we recolor to our region palettes without losing the look? |
| Resolution | Vector or ≥ 4× target render (we display at @2x / @3x) |
| License | Commercial use OK, no attribution required (or attribution acceptable) |
| Internal cohesion | Pack feels designed together, not collage-of-random-art |
| Edit access | We can edit / extend without losing license |

**Vetted asset pack candidates** (to validate before purchase):
- **Itch.io "asset packs"** filtered by style — wide variety, often $5–30 per pack
- **Synty Studios** — strong character/environment packs (more 3D-leaning; check 2D options)
- **GameDevMarket** — cohesive packs by genre
- **OpenGameArt** — free CC0 packs; quality varies wildly
- **Kenney.nl** — free CC0 packs; very clean style (may be too "vector" for our hand-drawn aim)

### AI generation workflow

When generating with Midjourney / Stable Diffusion / Flux:

1. **Lock a master style prompt** — e.g., *"hand-drawn children's book illustration, warm palette, soft outlines, slight watercolor texture, gentle lighting, friendly mood, [subject], --ar 16:9 --style raw"*
2. **Reuse the same seed / model** across related assets for visual consistency.
3. **Generate 4–8 variations per concept**; pick the strongest.
4. **Polish in Procreate / Krita / Photoshop** — edit color to match region palette, fix any uncanny details, add hand-drawn touches AI tends to miss.
5. **Never ship pure AI output** — always at least one manual polish pass.

**Style prompt template** (starting point — refine through iteration):

```
hand-drawn children's book illustration, warm desaturated palette, 
soft pencil outlines, gentle watercolor texture, cozy mood, 
storybook composition, friendly atmosphere, kid-friendly, 
[SUBJECT DESCRIPTION HERE], 
--ar [ASPECT] --style raw --stylize 100
```

Per-region variations adjust the palette and mood:
- **Sanctuary** — add "lush sanctuary, dappled sunlight, gentle creatures"
- **Wundletown** — add "whimsical wizard village, comedic energy, gentle magic glow"
- **Mathopolis** — add "small city, comic-book inspired, low-stakes hero energy"
- **Foundry** — add "cozy workshop, warm forge light, soft industrial"

### Freelance brief template

When hiring per-asset:

```
Project: CritMath educational K–2 math app
Asset needed: [character / scene / sprite]
Style reference: [3–5 visual examples from our reference touchstones]
Color palette: [region palette swatches]
Deliverable format: [PNG @1x/@2x/@3x OR vector SVG; psd/procreate source file]
Resolution: [target render size × 4]
Usage rights: full commercial, perpetual, transferable
Revisions included: 2 rounds
Style anchors: hand-drawn warmth; not vector-clean; not Disney-Pixar 3D plastic;
              not corporate edutainment "everyone smiling"
Tone: charming, fun, creative — never condescending or babyish
```

Attach: existing app screenshots (once any exist), the region's palette card, the relevant section of this art-direction spec.

---

## File formats and sizing

### Static images

- **PNG with alpha** for sprites, characters, UI elements
- **Vector source** (SVG / AI / Sketch) preferred where geometry allows — rescales cleanly
- **Resolution variants** per `asset-paths.md`: `@1x`, `@2x`, `@3x`. Render @3x as source; downsample.
- **Color profile** — sRGB; no Display P3 (would shift on standard iPad displays)

### Animations

- **Rive** (recommended for character animations — Buddy idle, numeral comes-to-life, etc.) — runtime renders vectors; cross-platform; small file sizes
- **Lottie** acceptable for non-character UI animations (button presses, transitions)
- **Sprite sheets** for sprite-based animations (creature walks, fish swims) — author at @3x, downsample for atlas

### File size budgets

- Individual character sprite (@3x): **≤ 200 KB**
- Background scene (@3x): **≤ 800 KB**
- Animation file (Rive): **≤ 100 KB** per character animation set
- Total app bundle assets at launch: **≤ 500 MB** per `asset-paths.md`

---

## Quality control & consistency

### Style guide enforcement

Once palettes + master style prompts are locked, all new assets are reviewed against:

- [ ] Palette compliance (uses region anchor colors; no out-of-palette accents)
- [ ] Linework consistency (warm-dark outlines, not pure black; slight wobble OK)
- [ ] Negative space respected (not overstuffed)
- [ ] Reads at small size (test at 60% of intended size — does it still read?)
- [ ] Color-blind safe (run through CB simulator)
- [ ] Tone check (charming not condescending; no babyish exaggeration)

### "Does this fit?" gut check

Show the asset alongside 3 existing approved assets from the same region. If it visually clashes, iterate.

### Common pitfalls (to actively avoid)

- AI generation tends toward **uncanny / glassy eyes** — manually fix
- AI tends toward **5-fingered hands done wrong** — avoid hands when possible; cartoon mittens when needed
- Asset packs from different artists **clash even within a pack** — vet for true internal consistency
- Numerals from different sources will have **inconsistent stroke weight** — author all 21 from one source, ideally one illustrator
- Backgrounds that are **too detailed compete with the playfield** — playfield characters must read clearly against the background

---

## Production roadmap (suggested order)

Given solo-dev + mixed pipeline + limited budget:

### Phase 0 — Style lock (pre-launch dev start)
1. Pick + license a base asset pack for Sanctuary environment.
2. Generate ~20 sample AI assets in target style; pick the prompt that works.
3. Commission a freelance illustrator for **one** numeral character ("5") + Buddy in 2 sample customizations + Storyteller turtle.
4. Test all of these together in a mock Hub scene. **Does it feel cohesive?**
5. Lock the style guide. From here, everything ships in this style.

### Phase 1 — Sanctuary launch readiness (K)
1. Sanctuary environment art (asset pack + AI + polish): 11 activity backgrounds + 4 home interiors
2. Buddy + Avatar parts libraries (freelance)
3. ~24 Sanctuary creatures (asset pack + AI for variants)
4. Storyteller turtle with mouth-sync rig (freelance)
5. 21 numeral characters (freelance — could spread across 2–3 illustrators with style guide enforced)
6. ~50 UI elements (AI + polish)
7. ~150 collectibles, stamps, trophies (AI + polish)

### Phase 2 — Wundletown + Mathopolis (1st & 2nd grade)
Same pattern as Phase 1, with the respective region palettes and character casts.

### Phase 3 — Portal worlds
Each portal world is a self-contained art subproject. Reuse the pipeline.

---

## Budget order-of-magnitude

For Phase 1 (Sanctuary K launch):

| Line item | Estimated cost |
|---|---|
| Base asset packs (3–5 packs) | $50–200 |
| AI generation tooling (Midjourney $30/mo × 6 months) | $180 |
| Freelance: 21 numeral characters @ $50–150 each | $1,000–3,000 |
| Freelance: Buddy + Avatar parts (multi-asset commission) | $500–2,000 |
| Freelance: Storyteller turtle with rig | $200–600 |
| Freelance: ~10 Wundletown wizards (for grade 1) | deferred |
| Freelance: ~10 Mathopolis heroes/villains (for grade 2) | deferred |
| Manual polish time (your own labor) | sweat equity |
| **Sanctuary K total** | **~$2,000–6,000** |

Sliding-scale ranges acknowledge that solo-dev quality bar varies. Lower end uses cheaper freelancers + more AI; upper end gets a small studio for the character work.

---

## Mockup expectations

Before production at scale, produce **3 cohesion mockups**:

1. **Hub interior screenshot** — kid's home (one of the 4 styles), Avatar visible, Buddy in corner, math notebook tab visible, gear icon in corner. Should feel like a place a kid wants to be.
2. **Activity screenshot** — Counting Parade with creatures arriving on the path, count badge visible, Buddy at lower-left. Should feel inviting and clear.
3. **MicroLesson screenshot** — mid-I-Show with pointer touching a fawn, sparkle effect, narrator text caption. Should feel warm and unhurried.

These mockups become the "this is the look" reference for everything that follows.

---

## Open Questions

- **Specific asset pack(s) to license** — needs research session against the visual language. Suggest: pick top 3 candidates from itch.io's "cute" and "fantasy" tagged packs; do side-by-side palette/style comparison; license the strongest.
- **Freelance illustrator sourcing** — Cara.app, Behance, Dribbble, Reddit r/HungryArtists for character work. Vet portfolios against our reference touchstones.
- **Numeral character art scope** — 21 fully unique vs teen-family approach. Decide before commissioning. **Suggest teen-family** to land within ~$1,500 budget.
- **Rive vs Lottie vs sprite sheets** for character animations — Rive recommended; confirm Flutter Rive package is mature enough. Last check looked good.
- **Style guide as a living doc** — once Phase 0 is complete and the style is locked, this file may need an addendum locking specific values (exact line weight, exact texture overlay, exact shadow style). Defer to post-Phase-0.
- **Marketing / store screenshots** — separate art deliverable from in-game art. Defer to pre-launch marketing kickoff.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — visual language principles, reference style touchstones, per-region color palettes, character design principles (Buddy / Avatar / numerals / region casts), mixed asset pipeline (packs + AI + freelance), quality control, production roadmap, budget estimate | |
