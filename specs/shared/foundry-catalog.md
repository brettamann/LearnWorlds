# Foundry Catalog

> The central workshop where every customization item is bought, commissioned, or built. Spans six categories: Buddy gear, Avatar gear, home interior decor, home exterior decor, vehicles, and the parts that compose larger creations. Coin sink for casual play; blueprint+parts treasure hunt for prestige play.

References: `we-are-going-to-eventual-lantern.md` (Foundry section), `specs/shared/reward-economy.md`, `schemas/reward-catalog.schema.json`, `data/reward-catalog/foundry-items.json`.

---

## Design philosophy

### The Foundry is the central workshop

Originally the plan separated the Foundry (big creations) from per-section shops (Avatar / Buddy / Home). That separation is gone: **the Foundry yard is the central catalog and workshop for every customization purchase**. Tabs within the Foundry route to:

- **Buddy** — outfits, hats, costumes, toys, treats, props
- **Avatar** — outfits, accessories, props (hairstyles + faces are part of the customizer, not the Foundry)
- **Home inside** — furniture, decor, posters, plants, themed sets
- **Home outside** — paths, plants, fountains, fences, lighting, signage
- **Vehicles** — fully composed creations (mechs, sky-ships, etc.) built from parts
- **Workshop** — the parts catalog (the building blocks for vehicles + larger decor)

The "Workshop" tab is where the kid sees their blueprints + parts inventory and can commit them to a build.

### Two-track economy

Per `reward-economy.md`:

1. **Coin purchase track** — most cosmetic items can be bought outright with coins. Paint jobs, common parts, themed clothing, simple decor. Predictable, gratifying progress.
2. **Blueprint + special parts track** — rare and prestige items require a **blueprint** (a recipe) plus **special parts** (rare ingredients earned through specific activities, portal chapters, or chests). The blueprint shows in the Workshop tab with a clear "need: 2 more parts" indicator. **Visible progress, no mystery.**

Most items at launch are coin-purchase. The blueprint+parts track surfaces for **vehicles** and a small set of prestige decor.

### Long-term arcs

The Foundry's centerpiece progression is a **vehicle**. Built in stages over weeks of play:

```
[Wagon (entry-level)]                  → 200 coins, 1 part, ~4 days play
        ↓
[Sky-Skiff (single-passenger flyer)]   → 800 coins + 1 blueprint + 2 parts, ~2 weeks
        ↓
[Patrol Mech (small walking robot)]    → 1500 coins + 1 blueprint + 4 parts, ~5 weeks
        ↓
[Cloud-Galleon (flying sailing ship)]  → 3200 coins + 1 blueprint + 6 parts, ~3 months
        ↓
[Astrolabe Glider (prestige showpiece)] → 5000 coins + 2 blueprints + 8 special parts, ~6+ months
```

The kid can be saving toward "my dragon-shaped mech" for weeks. That's the intended emotional arc.

### Rotation strategy

- The launch catalog covers ~70 items across the six categories.
- Every **2–3 months post-launch**, the Foundry catalog rotates: ~5 new items appear, a few old common items move to "limited inventory" (still buyable until stock 0), seasonal items appear in their season.
- **Prestige items never leave** — once buyable, always buyable (subject to blueprint/parts availability).
- **Seasonal items leave when the season ends** but return next year.

This keeps the catalog feeling alive without losing access to items kids already have.

### Tone

The Foundry is **warm-industrial**: forge orange lighting, wooden workbenches, scattered tools, gentle steam. The blacksmith/inventor is implied but not visible (no NPC shopkeeper at launch — the kid is the inventor). Music bed is the warm sanctuary palette with light hammer/forge ambient texture.

---

## Pricing tiers

Calibrated to the coin economy (Daily Quest = ~10–15 coins/day; Free Play more):

| Tier | Coin price | Time to afford via Daily Quest | Use |
|---|---|---|---|
| **Trivial** | 20–50 | 2–4 days | Paint jobs, small flags, simple props |
| **Small** | 60–150 | ~1 week | Buddy hats, basic plants, single furniture pieces |
| **Medium** | 200–500 | 2–4 weeks | Avatar outfits, statement furniture, complete themed sets, vehicle parts |
| **Large** | 600–1500 | 1–3 months | Vehicle frames, prestige furniture, complete avatar costumes |
| **Prestige** | 1500+ + blueprint + parts | 3+ months | Fully built vehicles, multi-blueprint compositions |

The economy balance audit (per `reward-economy.md`) will validate these.

---

## Categories

### 1. Buddy parts / props / costumes

Items that customize or accessorize the Math Buddy. The Buddy is **smaller than the Avatar** so items are scaled accordingly — a tiny chef's hat, a small cape, etc.

**Subcategories:**
- **Hats** (~8 at launch): leaf cap, chef's hat, wizard hat, pirate tricorn, astronaut helmet, party hat, garden sun-hat, detective deerstalker
- **Costumes** (~6): superhero cape, scientist coat, wizard robe, knight tabard, sailor outfit, baker apron
- **Toys** (~5): chew rope, squeaky ball, puzzle cube, plush starfish, tiny telescope
- **Props** (~3): little book, mini paintbrush, tiny wand
- **Treats** (per `kindergarten.json`): 10 milestone-driven treats already specified

### 2. Home decor (interior)

Items that fill the kid's hub home. Decor **adapts its finish** to the home style (wooden bookshelf in a cottage becomes a holo-shelf in the sci-fi base — same item slot, different finish overlay).

**Subcategories:**
- **Furniture** (~10): armchair, beanbag, hammock, bookshelf (3 sizes), dresser, work-table, side-table, ottoman
- **Posters** (~6): creature poster, math-hero poster, space poster, world map, sanctuary scene, foundry blueprint frame
- **Storage** (~4): treasure chest, woven basket, crate, footlocker
- **Plants** (~5): potted fern, hanging vines, dragonfruit plant, glowing crystal-flower, succulent collection
- **Lighting** (~4): table lamp, hanging lantern, fairy lights, glow-orb
- **Small decor** (~5): wall clock, model ship, snow-globe, framed photo, geode display
- **Themed sets** (~3 sets, each unlocks a configuration): Pirate set, Wizard set, Naturalist set

### 3. Avatar props / costumes

Outfits + accessories for the kid's Avatar. Distinct from the customization parts library (which is set during onboarding and adjustable in the Closet); these are unlockable additions earned via play.

**Subcategories:**
- **Outfits** (~10 complete looks): explorer kit, lab coat, knight armor (kid-sized), pirate captain, astronaut suit, gardener apron, chef whites, wizard robe, hero costume, ranger outfit
- **Accessories** (~8): backpack, satchel, sash, scarf, cap, headband, goggles, belt with pouches
- **Props** (~6 held items): magnifying glass, telescope, sketchbook, small toolbox, butterfly net, wand
- **Themed costume sets** (~3): Detective set, Pirate set, Astronaut set (each bundles outfit + accessory + prop at a slight discount vs buying separately)

### 4. Home exterior decorations

The space outside the kid's home — yard, paths, garden, signage. Visible whenever the kid enters/exits the Hub.

**Subcategories:**
- **Paths** (~4 styles): cobblestone, wood plank, glow-stone, leaf-stepping-stones (treehouse-style)
- **Plants** (~6): hedge, small tree, flower bed, mushroom patch, garden vines, magical sprouts
- **Water features** (~3): small fountain, bird bath, koi pond miniature
- **Signage** (~4): name post (customizable), weathervane, mailbox, welcome sign
- **Lighting** (~3): lamp post, hanging lantern, glow-firefly cluster
- **Features** (~5): garden bench, gnome statuette, sundial, archway, picnic table

### 5. Vehicles

The big aspirational creations. Mostly built in stages from frames + parts. Used to decorate the Foundry yard at launch; v1.1 makes them rideable in portal cutscenes.

**Launch roster (7 vehicles):**

| Vehicle | Composition | Total cost | Theme |
|---|---|---|---|
| **Wagon** | Bought outright | 200 coins | Entry-level; appears in front of home |
| **Hover-Bike** | 3 parts | 600 coins + 1 part | Mathopolis hero-vibe; one passenger |
| **Hot-Air Balloon** | 4 parts | 1200 coins + 2 parts | Wundletown whimsical; basket + envelope + burner + ropes |
| **Sky-Skiff** | 3 parts | 1500 coins + 2 parts + blueprint | Smaller flying skiff |
| **Dragon-Cart** | 4 parts | 1800 coins + 2 parts + blueprint | Sanctuary-themed; pulled by a baby dragon (creature collectible required) |
| **Patrol Mech** | 5 parts | 2500 coins + 3 parts + blueprint | Walking robot; bipedal, customizable arms |
| **Cloud-Galleon** | 6 parts | 3500 coins + 4 parts + 2 blueprints | The flagship. 18th-century sailing ship rigged for the stars |
| **Astrolabe Glider** *(prestige)* | 8 parts | 5000 coins + 6 special parts + 3 blueprints | Ultimate showpiece; takes 6+ months |

### 6. Parts of larger decor objects

Components for the multi-stage builds in categories 4 and 5. These appear in the Workshop tab as inventory; the kid commits them to a build when they have enough.

**Cloud-Galleon parts (6):**
- Keel + Hull (frame)
- Mast + Spars
- Sails (3 style choices: canvas, silk, dragon-hide)
- Rigging
- Cannons (decorative — 4 cannon slots)
- Astrolabe (steering instrument)

**Patrol Mech parts (5):**
- Legs (3 style choices: bipedal heavy, bipedal nimble, quad)
- Chassis (the torso/cockpit)
- Arms (left + right, 3 style choices each: gripper, hammer, drill)
- Weapons/tools (optional — pickaxe, drill, paintbrush; non-combat)
- Antenna + head module

**Sky-Skiff parts (3):**
- Frame (the body)
- Wings or balloon (style choice)
- Steering yoke

**Hot-Air Balloon parts (4):**
- Basket
- Envelope (3 patterns: striped, dragon-scale, star-pattern)
- Burner
- Ropes + sandbag ballast

**Dragon-Cart parts (4):**
- Cart body
- Harness
- Baby dragon companion (creature collectible from Sanctuary — see Sanctuary Creature Cards)
- Wheels (decorative variants)

**Hover-Bike parts (3):**
- Frame
- Repulsor pads
- Handlebars + control panel

**Larger decor object parts:**
- **Foundry yard centerpiece** (a forge/anvil display in the kid's home yard): anvil + bellows + tool rack — 3 parts, 800 coins total
- **Greenhouse** (large garden feature in home exterior): glass panels + frame + door + roof vent — 4 parts, 1500 coins
- **Observatory** (treehouse-style attic feature): telescope + dome + platform + star-chart — 4 parts, 2000 coins + blueprint

---

## Blueprint + parts mechanic

### How blueprints surface

Blueprints are earned via:
- **Activity drops** at rare rates (e.g., Build-a-Habitat's `permanent_fixture_built` event occasionally drops a vehicle-part blueprint)
- **Portal chapter completions** (a Pirate Planet chapter might drop the Cloud-Galleon's hull blueprint)
- **Chest contents** at medium+ tiers
- **Challenge completion** for unique themed parts

### How special parts are earned

| Part type | Where earned | Drop rate |
|---|---|---|
| **Common parts** (wheels, ropes, panels) | Any activity round drop | ~1 in 8 round-pass |
| **Uncommon parts** (sails, antennae, frames) | Challenge activity drops, milestone trophies | ~1 in 3 challenge-pass |
| **Rare parts** (dragon-hide sail, astrolabe lens) | Portal chapter completions, prestige chests | ~1 in 10 chapter-complete |
| **Prestige parts** (Astrolabe Glider components) | Lord Layerton arc completion, specific portal final-chapter | one-time per arc |

### The Workshop UI

```
┌──────────────────────────────────────────────────────────┐
│  Workshop                                          [Yard] │
│  ────────                                                 │
│                                                            │
│  In progress                                               │
│                                                            │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 🛠  Cloud-Galleon                                   │  │
│  │    Frame: ✅  Mast: ✅  Sails: ⏳ need 1 more       │  │
│  │    Rigging: ⚪  Cannons: ⚪  Astrolabe: ⚪          │  │
│  │    Total earned: 1800 / 3500 coins                  │  │
│  │    [Continue building →]                            │  │
│  └────────────────────────────────────────────────────┘  │
│                                                            │
│  Blueprints owned                                          │
│   📜 Cloud-Galleon Hull (start)                            │
│   📜 Patrol Mech Bipedal Legs (acquired today)             │
│                                                            │
│  Parts inventory                                           │
│   🪵 Wood plank × 4    ⚓ Rigging hook × 2                 │
│   🛞 Wheels × 3        🧵 Canvas sail × 1                 │
│   ⭐ Astrolabe lens × 0  (need from Pirate Planet)         │
│                                                            │
│  [Start a new build →]                                     │
└──────────────────────────────────────────────────────────┘
```

---

## Coin balance check (preliminary)

Aligning launch catalog prices to the `reward-economy.md` audit targets:

| Target | Time | Catalog item that fits |
|---|---|---|
| **First meaningful Foundry creation** | ≤ 14 days | A Buddy outfit (Wizard Robe) at 250 coins, or a Wagon at 200 coins, or a paint job. Achievable in 1.5–2 weeks of Daily Quest. ✓ |
| **First frame-level creation** | ≤ 42 days | The Hover-Bike frame at 400 coins, or the Sky-Skiff frame at 600 coins. Achievable in ~6 weeks. ✓ |
| **Aspirational vehicle** | 3–6 months | The Cloud-Galleon at 3500 coins. Hit-able in ~5 months of consistent play. ✓ |
| **Showpiece prestige** | 6+ months | Astrolabe Glider at 5000 coins. Reasonable lifetime goal. ✓ |

These targets meet `reward-economy.md`'s pending audit. The audit will validate against actual playtest data.

---

## Cross-system tie-ins

### Cards earned in portals come home with adapted finishes

Per the plan: a Pirate Planet trophy hangs as a sail-banner in a treehouse vs. a holo-display in a sci-fi base. The asset slot (a wall-mounted decor) is the same; the finish overlay matches the home style. Implementation: each home decor item ships with finish variants for each of the 4 home styles. The system picks the variant based on the kid's home.

### Blueprints surface via activities the kid already plays

Mapping which activities drop which blueprints / parts (informs activity reward specs):

| Activity | Likely drops |
|---|---|
| Counting Parade | Common parts (wheels, ropes) — frequent |
| Ten-Frame Pond | Common parts; rare drop of "decorative crystal" for greenhouse |
| Scribe's Tower | Uncommon: ink-color collectibles; rare blueprint for "starchart-poster" |
| Storyteller's Pond | Uncommon: pond creature for Dragon-Cart |
| Build-a-Habitat | **Rare blueprint drops** for vehicle parts (the building activity dropping building parts) |
| Care Pantry | Common: storage items (basket, crate) |
| Picnic Baskets | Common: outdoor decor (picnic table, blanket pattern) |
| Caretaker's Bench | Uncommon: workshop parts (tools, anvil) — for the Foundry-yard centerpiece |
| Shape Garden | Uncommon: garden plants |
| Where's Buddy? | Common: hide-and-seek hats for Buddy |
| Fluency Within 5 | Buddy treats (already specified); uncommon blueprint for the Buddy treat cabinet |

### Foundry yard display

Every built creation appears in the **Foundry yard** — a small outdoor extension of the Hub. The kid sees their accumulated creations parked there: a Wagon by the gate, a Hot-Air Balloon tethered overhead, a half-built Cloud-Galleon on the dock. **The yard fills up over time** — visible long-term progression.

The Yard view is **accessed from the Hub** via a path; it's also where the kid kicks off new builds.

### v1.1 — vehicles become rideable in portal cutscenes

Per the plan: at launch, vehicles decorate. v1.1 makes them usable as the kid's "ride" between Hub and portal worlds, with brief travel cutscenes.

This affects asset authoring **now**: vehicles should be designed with future side-views (for travel cutscenes) and rideable scale (kid + Buddy fit on/in them). Authors should produce both a "Yard display" pose and a "cutscene-ready" rig.

---

## Open Questions

- **Number of items per category at launch** — current draft is ~70 total. Is that enough variety, or too many to populate quickly? Suggest ~70 at launch; ~15–20 added in each rotation.
- **Vehicle blueprint sourcing** — should the Cloud-Galleon's blueprint come exclusively from Pirate Planet portal completion (thematic) or from a more distributed set of sources? Suggest Pirate Planet for the GALLEON specifically; mechs from Mathopolis; balloons from Wundletown.
- **Themed set bundling discount** — current pricing is set per item; bundling a themed set (e.g., Pirate set for Avatar) at ~15% discount would encourage cohesive purchases. Confirm with economy audit.
- **Buddy Treats already specified** vs new Buddy-treat items proposed here — Buddy Treats are the 10 milestone-earned items in `kindergarten.json`; this catalog adds non-treat Buddy items (hats, costumes, toys, props). No overlap. Clarify in UI: treats appear separately from other Buddy items.
- **Foundry yard physical layout** — how much space does it have? Probably should expand as the kid earns more creations. Defer to UX.
- **Adapting decor to home styles** — every interior decor item needs 4 finish variants (cottage / castle / treehouse / sci-fi). That's 4× the art work for home interior. Confirm budget; alternative is "one finish per item" and accept that some items look out-of-place in some homes.
- **Coin caps + sale events** — should there be occasional "weekend sale, 20% off Foundry items" to give a payoff for return engagement? Suggest yes via seasonal events; defer specifics to economy audit.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-31 | Initial draft — Foundry as central workshop; six categories; pricing tiers calibrated to coin economy; vehicle progression arc; Workshop UI mockup; cross-system tie-ins to activities; v1.1 ride-in-cutscenes preparation | |
