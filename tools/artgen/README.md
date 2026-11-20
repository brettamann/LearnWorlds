# artgen — generating game art through the ImageGen service

Talks to a self-hosted [ImageGeneration](https://github.com/Weetermachine/ImageGeneration)
instance to produce the sprites the app already asks for and cannot get, then
post-processes them locally so they register against the art already in the
repo.

No dependencies. Node 24 has `fetch`, `FormData` and `Blob` built in, and
`png.mjs` is a small PNG codec over `node:zlib`, so there is nothing to install.

## Setup

`app/.env`, which is gitignored:

```
IMAGEGEN_URL=https://imagegen.example.com
IMAGEGEN_TOKEN=ig_...
```

Point at the **nginx front end** (the published `WEB_PORT`, 8094 by default),
not the Express container. ImageGen authorises a file request and then hands
the transfer to nginx via `X-Accel-Redirect`, so bypassing nginx returns an
empty `200` and you get a zero-byte PNG with no error.

```
node tools/artgen/probe.mjs
```

confirms reachability, works out which auth header the token wants, and reports
whether image-input (edit mode) is live.

## Commands

```
node tools/artgen/artgen.mjs status            what exists, what is cached, what it has cost
node tools/artgen/artgen.mjs gen [id...]       generate only what is missing
node tools/artgen/artgen.mjs process [id...]   re-run local post-processing from cache — free
node tools/artgen/artgen.mjs sheet [id...]     contact sheet, each result beside its reference
node tools/artgen/artgen.mjs preview           mouths composited on Buddy as the app renders them
node tools/artgen/artgen.mjs install [id...]   copy finished art into app/assets/
```

`gen` never regenerates something already cached, so re-running it is free.
Only `--force` spends money on an image you already have.

## Nothing is generated twice

A request is keyed by its content — prompt, provider, effort, aspect,
resolution, and the bytes of the reference image — and that key is both the
local cache filename and the server-side idempotency key. Editing a prompt
produces a new key, which is the point: the old image stays cached so a
regression is one edit away, and `status` reports how many cached images no
longer match any catalog entry.

Reference uploads are hashed too, so the same `v1.png` is uploaded once and
reused by all three mouths.

This is the clip-key idea from the narration work applied to pixels. There it
stopped one sentence being recorded five times; here it stops one sprite being
generated five times.

## Effort is not just quality

Measured on this deployment, not assumed:

| effort | model | cost | alpha |
|---|---|---|---|
| `draft` | `gpt-image-1-mini` | 1.1¢ | **real transparency, 67–74%** |
| `standard` | `gpt-image-2` | 4.1¢ | **none — fully opaque** |
| `premium` | `gpt-image-2` | 16.5¢ | untested |

`gpt-image-2` follows instructions noticeably better and still hands back a
background however the prompt is worded — plain white for a simple subject, and
for a busy one a *drawn* transparency checkerboard, which cannot be removed
because it is real pixels rather than alpha. Flood-filling the white off works
but leaves a scatter of speckles that is plainly visible composited on Buddy.

**So cutout sprites use `draft`.** It is also four times cheaper. Use
`standard` only where you will check the cutout by eye afterwards.

`provider` must always be sent explicitly: `/api/models` reports
`default_provider: gemini` with `configured: false`, so an omitted provider
routes to a provider with no credentials.

## Why there is a post-processing step

Every Buddy layer renders with `BoxFit.contain` inside a fixed fractional box
(`_frac` in `buddy_widget.dart`). That means the **transparent margins of the
PNG decide where the art lands and how big it looks** — two mouths drawn at
different scales inside their canvases render at different sizes on the same
face.

`reframeTo` fixes that: it measures the reference's content box and the new
image's content box, then places the new content at the reference's centre,
scaled to `widthScale` of the reference's width. Registration is enforced;
proportion stays an art decision, which is why a small "o" mouth can be 0.62
without drifting off the face.

Ahead of it: `knockOutBackground` (flood-fill inward from the border, so white
teeth survive), `hardenAlpha` (kills the drop shadow models add regardless of
instruction, keeping antialiasing), and `softenBlacks` (pulls pure black
linework to `#2A1F26`, which `specs/shared/art-direction.md` requires).

`reframe` is right for a part that must register against another sprite and
wrong for a free-standing object. Matching a tall lantern's content box to a
wide watering can's pushed it off the top and bottom of the frame; the eight
sanctuary decor items set no `reframe` at all and size themselves on screen
through `DecorItem.widthFraction` under `BoxFit.contain`.

`maxSize` caps the longest side on disk, last in the chain. The service always
returns 1024x1024, which is enormous for a sprite drawn at a fraction of a map:
the decor set first shipped 14MB into a web build to be rendered at about
150px. At `maxSize: 400` the same eight are 848KB and look identical.

Because processing is separate from generation, prompts and framing can be
retuned against bytes already paid for. `process` costs nothing, so a `maxSize`
or `reframe` change is free.

## Backgrounds are the exception to everything above

`cutout: false` turns off the whole knock-out chain. It exists for one entry —
`wheres-buddy-clearing` — and the reason is that every other asset here is a
sprite drawn on a card and this one is the card. `knockOutBackground` floods
inward from the border, which on a painted sky eats the sky, and `softenBlacks`
pulls linework a painted background does not have.

A background also wants `standard`, not `draft`: gpt-image-2 returns a fully
opaque image, which for once is exactly what is needed, and it follows a
composition instruction ("the horizon a quarter of the way down, the rest one
empty meadow") far better — the whole ask there is composition rather than
subject.

Note `maxSize` still matters and matters more. A background keeps most of its
pixels because it is drawn full-bleed under a whole screen. 1024 was 1.98MB;
860 — the width of the courtyard illustration it replaces, so the two cost the
build the same — is 1.3MB and looks identical under `BoxFit.cover`.

## Paired sprites

`mirror: 'path/to/other-half.png'` writes a horizontally flipped copy at
install time. It exists for Buddy's arms and legs, where the left limb is the
right one seen from the other side.

Generate one and flip it — do not generate both. Two independent generations of
"a left paw" and "a right paw" come back disagreeing about how many toes Buddy
has, and at Buddy's size that reads as a glitch rather than as asymmetry. The
original `arm-1-l.png` in the repo is itself a mirror of `arm-1-r.png`.

This is the same idea as the README's rule against pose variants — facing left
is `Transform.scale(scaleX: -1)`, not an asset — applied where the code does
want two files.

Orientation is the thing to check by eye afterwards. `buddy_widget.dart`
rotates each arm about its shoulder (`alignment: Alignment.topLeft` for the
right arm, `topRight` for the left), so a sprite whose shoulder ends up at the
wrong corner of its canvas swings from the hand. `reframeTo` matches content
boxes; it cannot tell you which end is the shoulder.

## Adding an asset

An entry in `catalog.mjs` earns its place by being art the shipped code already
reaches for and cannot get. Two things that are **not** entries:

- **Colour and pose variants.** Buddy has twelve body colours from one
  silhouette; a thirteenth is a local recolour. Facing left is
  `Transform.scale(scaleX: -1)`, not a mirrored asset.
- **Art for unbuilt features.** The reward catalog authors 24 creature cards,
  but `creature_card_catalog.dart` runs Counting Parade only, so the pond cards
  would be sprites for a screen that cannot show them.

Always set `reference` to the asset the new art must sit beside. Editing
against an existing sprite holds line weight and palette far better than any
prompt, and `gen` warns if the service returns a generation whose
`input_upload_ids` does not contain the reference — a service that ignored the
field would otherwise bill for a picture in the wrong style and say nothing.

## Installing Buddy parts

New mouths need a catalog entry or `buddyMouthAsset()` silently falls back to
`v1`. Mood sprites go in `kBuddyExpressionMouths`, **not** `kBuddyMouths` —
`buddy_shop_catalog.dart` prices every entry in the latter, so an expression
mouth there would put a pensive flat line on sale and leave it on Buddy's
resting face if a child bought it. `app/test/buddy_expression_mouths_test.dart`
holds both halves of that in place.
