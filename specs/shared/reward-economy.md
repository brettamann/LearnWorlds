# Reward Economy Event Model

> The contract for how activities emit reward events and how the system translates them into coins, chests, collectibles, blueprints, and Foundry parts. Activity specs declare what they emit; this spec defines what those events do.

References: `adaptive-scaffolding.md` (mastery events), `math-notebook.md` (notebook-use bonus).

---

## Principles

1. **Earning is the core feedback loop.** Practice math → earn currency → spend on cosmetics → return tomorrow.
2. **Nothing is pay-to-win.** No purchasable advantage in math problems. Ever.
3. **No real-money chest purchases. No pay-to-spin.** Chests are earned only.
4. **Guaranteed value.** Every chest has named, guaranteed contents — never empty, never trash. Surprise lives inside a known category, never in *whether* you got something good.
5. **Transparent pity.** Every Nth chest of a kind guarantees a rare item; the kid can see how close they are. Anticipation without manipulation.
6. **Two-track Foundry economy.** Coin-purchase for predictable progress, blueprint + special parts for aspirational long arcs.
7. **All cosmetic.** Every spending sink is cosmetic — Avatar / Buddy / home / Foundry creations / portal unlocks.

---

## Currency Types

| Currency | Earned by | Spent on |
|---|---|---|
| **Coins** | Activities, daily quests, completion bonuses | Avatar, Buddy, decor, common Foundry parts, portal unlocks |
| **Blueprints** | Specific activities & portal chapters | Foundry prestige items (paired with special parts) |
| **Special Parts** | Specific activities, chests | Foundry prestige items (paired with blueprints) |
| **Collectibles** | Activity-specific drops, chest contents | Display in Hub scrapbook (not spent) |

There is **no premium currency** at launch. One coin type, transparent pricing.

---

## Reward Emission Events

Activities emit these events; the reward system aggregates them and pays out.

### Core round events

| Event | Emitted by | Default reward |
|---|---|---|
| `round.completed` | Any activity round that finishes (pass or fail) | 0 coins (just a count) |
| `round.passed` | Round with correct outcome | +2 coins |
| `round.failed` | Round with incorrect outcome | 0 coins (no penalty) |
| `round.notebook_bonus` | Notebook was used non-trivially (per `math-notebook.md`) | +1 coin |
| `round.strategy_shown` | Kid used the Strategy Explainer (2nd) or equivalent | +1 coin |

**Per-round cap: +4 coins.** Prevents stacking.

### Streak events

| Event | When | Reward |
|---|---|---|
| `streak.session_3` | 3 correct rounds in a row in one session | +3 coins |
| `streak.session_5` | 5 in a row | +5 coins + 1 collectible |
| `streak.session_10` | 10 in a row | small chest |

Session streaks reset between sessions. They are *bonus*, not the main income.

### Milestone events

| Event | When | Reward |
|---|---|---|
| `milestone.problems_25` | 25 problems completed (lifetime, per activity) | small chest |
| `milestone.problems_100` | 100 problems completed (lifetime, per activity) | medium chest |
| `milestone.activity_first_play` | First-ever entry into an activity | welcome collectible |
| `milestone.region_first_play` | First-ever entry into a grade region | region badge |

### Mastery events

(Delegated from `adaptive-scaffolding.md`.)

| Event | When | Reward |
|---|---|---|
| `mastery.standard_practicing` | Concept moves from Introduced to Practicing | +1 coin + collectible card |
| `mastery.standard_mastered` | Concept reaches Mastered | medium chest + mastery card for the Hub trophy wall |

### Daily quest

| Event | When | Reward |
|---|---|---|
| `daily.completed` | Daily Quest finished (any day) | small chest |
| `daily.streak_3` | 3-day quest streak | medium chest |
| `daily.streak_7` | 7-day streak | large chest + rare collectible |
| `daily.streak_30` | 30-day streak | prestige chest + Foundry blueprint |

Missing a day **pauses** the streak (it doesn't reset); a kid can miss up to 2 consecutive days and resume. This is gentler than typical streak mechanics.

### Portal chapter events

| Event | When | Reward |
|---|---|---|
| `portal.chapter_completed` | A chapter of a portal arc finishes | portal-themed chest + 1 special part |
| `portal.arc_completed` | A full portal arc completes | unique portal chest + cosmetic only obtainable here |

### Challenge events

| Event | When | Reward |
|---|---|---|
| `challenge.completed` | Challenge variant passed | challenge chest (rare/unique items) |
| `challenge.perfect` | Challenge passed with no fails | prestige chest |

---

## Coin Payout Defaults (playtest to tune)

Per-round coin payout starting values:

| Source | Coins |
|---|---|
| Round passed (base) | 2 |
| Notebook bonus | +1 |
| Strategy/explanation bonus | +1 |
| Round cap | 4 |

Daily Quest typical income:
- 5 rounds × 4 coins (full bonuses) = 20 coins, max
- Plus chest contents (variable)

Free Play 10-minute session typical income:
- ~15 rounds × 3 coins (mixed) = ~45 coins
- Plus streak / milestone bonuses

These targets feed the **spending economy** — cosmetic items should cost roughly the equivalent of a week of casual play for mid-tier items, a few weeks for prestige.

### ⚠ Coin balance audit pending (added 2026-05-30)

The K spec review flagged a concern that the **Foundry aspirational economy may be too slow for K kids playing 5 min/day**. A representative kid:
- Daily Quest = ~10–15 coins/day
- Foundry creations (sky-ship + sails + cannons + paint loadout) cost likely hundreds of coins

**Action required before launch:** author the launch Foundry catalog with concrete coin costs, then back-test whether a K kid playing the Daily Quest 4× per week can reach their first meaningful Foundry creation (e.g., a paint job for the Hub-displayed mech) in **≤ 2 weeks** and a frame-level creation in **≤ 6 weeks**. Tune one of:
- Coin payout per round (currently +2 base, +4 cap)
- Foundry per-item costs
- Chest coin contents
- Streak/milestone bonus magnitudes

Telemetry to feed the audit: `economy.coins_earned`, `economy.coins_spent`, and per-kid daily-quest engagement during alpha playtest.

---

## Chest System

### Chest tiers

| Tier | When earned | Typical contents |
|---|---|---|
| Small | Session-streak 10, milestone 25, daily quest | 1 cosmetic + 5–10 coins |
| Medium | Mastery, milestone 100, daily streak 3 | 2 cosmetics + 15–25 coins + chance of 1 special part |
| Large | Daily streak 7, region completion | 3 cosmetics + 40–60 coins + guaranteed 1 special part |
| Prestige | Daily streak 30, challenge perfect | 4 cosmetics + 100+ coins + guaranteed blueprint OR 3 special parts |
| Portal-themed | Portal chapter / arc | Themed cosmetics unique to that portal + portal-specific special parts |

### Chest contents are visible

Every chest, when shown to the kid, displays its **category contents** before opening:

> Pirate Planet Chest contains:
> - 1 outfit piece
> - 1 deck decoration
> - 12 coins
> - 1 of: Foundry sail blueprint, anchor decoration, treasure-map scrap

The **specific item** within a category is the surprise. The category itself is not.

### Pity timer

Some chest categories have **rare items** (e.g., a specific outfit that drops with ~10% chance). For each rare slot, a **pity counter** tracks misses. After **N consecutive misses** (defaults below), the next chest of that tier **guarantees** the rare drop.

| Tier | Pity counter |
|---|---|
| Small | 10 (next rare guaranteed by chest 10) |
| Medium | 6 |
| Large | 4 |
| Prestige | 2 |

The kid can **see the pity progress** in the chest detail screen: "Rare item next in 2 chests." Anticipation without manipulation.

### Anti-gambling guarantees

- **No purchase of chests with real money.** Period.
- **No "spin to win"** where the kid presses a button to see a randomized reward. Chests *open* with their contents predetermined when earned — the animation is decorative.
- **No daily limit on earning chests** (no FOMO mechanics).
- **No timed mechanics** ("come back in 4 hours to open").
- **No exclusivity windows** ("this chest is only available this weekend"). Seasonal events are *additive* (they layer in new items) but never withhold core content.

---

## Collectibles

Collectibles are **non-spendable** items that display in the Hub scrapbook, on the trophy wall, or as Buddy/Avatar accessories.

Categories:
- **Cards** — activity-specific (creature cards from Counting Parade, herb cards from Spell Garden)
- **Stamps** — number/letter/concept mastery markers (Scribe's Tower's stamp poster, mastery cards)
- **Badges** — milestone markers (region badges, streak badges, challenge badges)
- **Memorabilia** — story-arc-specific items from portal worlds

Each collectible has a known set size. Kids see "12 of 24 unicorn cards" — partial completion is meaningful.

---

## Blueprints & Special Parts (Foundry second track)

### Blueprint
A **plan** for a Foundry creation. The kid owns the blueprint but can't build the item until they have the required special parts.

Blueprint sources:
- Specific activity rewards (e.g., Rune Builder challenge mode drops 2D-rune blueprints)
- Portal chapter / arc completions
- High-tier chests
- Daily streak rewards (30-day = a blueprint)

### Special Part
A **component** required by one or more blueprints. The kid collects parts toward a buildable item.

Part sources:
- Activity-specific drops (a Spell Garden rare drop = a magical-component part)
- Portal chest contents (Pirate Planet chests yield sailing parts)
- Mastery chests

### Catalog visibility

The Foundry shows the kid every blueprint they own with a clear **progress indicator**:

> Dragon-Scale Mech [blueprint owned]
> Need: 2 special parts
>   ✓ Dragon Scale (from Sanctuary chest, owned)
>   ✓ Forge Core (from Mastery chest, owned)
>   ☐ Wind Ember (from Atlantis portal chapter 3)
> Coin cost: 250

The kid sees exactly what they need to complete each prestige item. No mystery, no "open chests until you get lucky."

---

## Spending Sinks

Where the kid spends coins (and blueprints/parts):

### Avatar shop
- Outfits, hairstyles, accessories
- Coin-only (no blueprints/parts at launch)
- Item costs: 8–80 coins (common), 100–250 (rare)

### Buddy shop
- Buddy outfits, hats, accessories, toys (Buddy interacts with toys for ambient charm)
- Coin-only
- Item costs: 10–100 coins

### Home shop
- Furniture, posters, decor matching the kid's home style (Cottage / Castle / Treehouse / Sci-fi Base)
- Coin-only
- Item costs: 20–300 coins; bundled "themed sets" at 500–800

### Foundry catalog
- **Coin-only items** — paint jobs (20–60 coins), common frames (150–250), basic upgrades (50–100)
- **Blueprint items** — see above
- Most prestige items cost 200–600 coins on top of their part requirements

### Portal unlocks
- New portal worlds: 500 coins each (after the initial 2–3 are free)
- Portal-specific bonus chapters: 100–200 coins each

---

## Income Targets & Time-to-Earn

Sanity check: how long does it take to buy stuff?

| Item | Cost | Casual-play earn time |
|---|---|---|
| Cheap Avatar outfit | 25 coins | < 1 daily quest |
| Mid-tier Avatar outfit | 80 coins | 2–3 daily quests |
| Rare Avatar outfit | 200 coins | ~1 week of daily quests |
| Hub furniture piece | 50 coins | 1 daily quest + some free play |
| Themed home set | 500 coins | ~2 weeks |
| Common Foundry mech frame | 150 coins | ~1 week |
| Prestige Foundry mech (blueprint + 3 parts + coins) | 400 coins + parts | ~3–6 weeks (parts gate this, not coins) |
| Portal world unlock | 500 coins | ~2 weeks |

This is the **inflation curve** the dashboard should respect when teachers assign extra activities — earnings shouldn't trivially break the economy.

---

## Telemetry Events

| Event | When | Payload |
|---|---|---|
| `economy.coins_earned` | Any coin payout | source event, amount, current balance |
| `economy.coins_spent` | Any purchase | item, cost, balance after |
| `economy.chest_earned` | Chest awarded | tier, source event |
| `economy.chest_opened` | Kid taps to open | tier, contents revealed |
| `economy.collectible_obtained` | Collectible added | type, set progress |
| `economy.blueprint_obtained` | Blueprint added | item name, source |
| `economy.special_part_obtained` | Part added | part name, source, parts toward each blueprint |
| `economy.foundry_built` | Foundry creation completed | item, total cost (coins + parts) |

These feed both the dashboard and balance analytics (are kids running out of coin sinks? are blueprints stalled?).

### Activity-Defined Reward Events

Beyond the canonical events above, activities can emit **custom reward events** for their specific reward patterns. Conventions:

- **Naming**: prefix with the activity slug (e.g., `habitat.*`, `pond.*`, `tenframe.*`).
- **Payload**: include the activity slug and any activity-specific data needed by the reward emitter.
- **Routing**: activities specify in their spec what reward fires for the custom event (e.g., `habitat.permanent_fixture_built` → fires a permanent fixture; `pond.story_memento_earned` → adds a story memento collectible).
- **Registry**: custom events are declared in the activity spec's Reward Emissions table; the reward engine reads activity specs to know how to route them.

This keeps activity-specific reward patterns inside the activity's spec while the canonical events stay generic.

### Reward Type: Permanent Fixture

A **permanent fixture** is a reward that **persists in the Hub view** between sessions. The kid's accumulated fixtures populate the Hub's region-themed display (e.g., Sanctuary Habitat Map for built habitats, future regions may use similar patterns).

**Properties of a permanent fixture:**

```jsonc
{
  "rewardType": "permanent-fixture",
  "fixtureType": "habitat",         // activity-defined; routes to a Hub display category
  "fixtureId": "fawn-shelter-1",    // unique id; duplicates are deduplicated (only first awarded)
  "hubDisplay": {
    "region": "sanctuary",
    "category": "habitat-map",
    "position": "auto"               // or { x, y } for hand-placed
  },
  "thumbnail": "fixture-thumb-fawn-shelter-1.png"
}
```

**Behaviors:**
- Fixtures **deduplicate** by `fixtureId`. Building the same fawn-shelter layout twice doesn't double the map.
- The Hub view aggregates all fixtures of a given `fixtureType` and renders them per their region's display logic.
- Fixtures may unlock Hub trophies when complete sets accumulate (e.g., all 12 habitat layouts → Sanctuary Keeper's Map trophy).

**Used by:**
- Build-a-Habitat (`habitat.permanent_fixture_built` → habitat in Sanctuary Habitat Map)
- (Future) any creation activity where outputs should persist in the Hub world

---

## Edge Cases

- **Two kids on one device** — each has their own coin / chest / collection state (per-profile).
- **Offline play** — coins and chests accumulate locally; sync on next online connect.
- **Backed-up state restored after a long gap** — kid keeps everything; daily streak resumes paused (per the gentler streak rules).
- **Activity completion before reward system load** — events queue; payouts process in order on next load. No lost rewards.
- **Kid spams a low-effort activity for coin grinding** — capped per-round payout limits ceiling. Activities that are too grindable should be flagged during playtest tuning.

---

## Open Questions

- **Coin payout amounts** — starting numbers above are guesses; playtest with real session lengths to tune.
- **Cosmetic item pricing curve** — needs to be calibrated against typical earn rates so rare items feel rare without feeling unachievable.
- **Pity timer values per tier** — tuned with chest-drop probability tables (not yet specified).
- **Daily quest reward escalation** — should daily quests scale rewards with streak length (more coins on day 7 than day 1)? Suggest yes; specifics TBD.
- **Activity-specific special part assignment** — which activities produce which parts. Must be designed alongside the Foundry catalog.

---

## Changelog

| Date | Change | Author |
|---|---|---|
| 2026-05-29 | Initial draft | |
| 2026-05-30 | Added **Activity-Defined Reward Events** extension point (custom events prefixed with activity slug); added **Permanent Fixture** reward type (rewards that persist in the Hub view between sessions — e.g., Build-a-Habitat's built habitats accumulating in the Sanctuary Habitat Map) | |
