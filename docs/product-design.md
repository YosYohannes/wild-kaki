# Trail Buddy — Product Design Document

Oct 28, 2026 · @Yos Yohannes

## Overview

Trail Buddy is a fully offline, personal running app where every run reveals one wild animal, your trail buddy, chosen by how, where and when you ran. Over time the almanac of question-mark cards turns into a field log of every animal you have spotted.

The framing is **spotting, not capturing**. Each animal only shows itself to runners who move the way it does: a cheetah notices a sprinter, a kingfisher appears along water, an owl trusts someone out in the dark. It runs alongside you for that one run, then wanders off. The almanac records sightings; the animals stay wild.

Design principles:

- **Offline and personal.** No account, no server, no leaderboards. All data stays on the phone.
- **No purchases.** No skins, no currency, no premium animals.
- **Interesting, not pushing.** Rewards variety of runs. Absolute benchmarks (marathon, sub-12 s 100 m) are aspirational, never required for progress.
- **Deterministic and deducible.** The same run always yields the same animal. Hints and layout let you reason toward unseen ones.
- **Forgiving.** No streaks to break. Every run gives either a new buddy or a hint.

Working title: Trail Buddy. Shortlisted alternatives: Trackbook, Footfall, Spotted, Trailglimpse, Critterbook, Patapop, Phewpop.

## Core loop

Every run ends in one of two outcomes: a new buddy, or a repeat sighting that earns a hint.

&#91;embedded content: core loop · one buddy per run\]

The app scores the run after the Fitbit sync, picks the rarest eligible animal, and returns to the almanac either way.

## Axes and families

Three core axes decide the animal family and its tier; treadmill runs form a fourth, separate family. An attribute is an axis only if every run has a value for it. Everything contextual is a modifier (next section).

Thresholds are **absolute human benchmarks**, not personal baselines, so a marathon is always a marathon. Species names below are placeholders for the curated list.

| Family | Axis | Tiers (absolute) | Example ladder |
| --- | --- | --- | --- |
| Cats | Speed: average pace, plus best 100 m / 400 m / 1 km segments | slower than 6:30/km · 5:30–6:30 · 4:30–5:30 · 3:45–4:30 · faster than 3:45 | House cat → Ocelot → Caracal → Leopard → Puma; Cheetah (L) for 100 m under 12 s |
| Birds | Distance | 1 · 3 · 5 · 10 · 21.1 · 42.2 · 50+ km | Sparrow → Pigeon → Heron → Stork → Goose; Albatross (L) marathon; Arctic Tern (L) ultra |
| Hoofed | Climb: elevation gain | 100 · 200 · 500 · 1,000 m | Deer → Chamois → Mountain goat; Ibex (L) at 1,000 m |
| Rodents | Treadmill mode (no GPS) | first run · 30 min nonstop · incline · 10 km indoors | Hamster · Gerbil · Guinea pig · Capybara |

**Choosing the family.** An outdoor run lands in the family where it reached its highest tier, measured as a share of that axis's ladder. Ties break in a fixed order: Distance, then Climb, then Speed.

**Treadmill runs stay in Rodents.** Distance from Fitbit or manual entry is looser than GPS, so indoor runs never unlock outdoor legendaries. A treadmill marathon earns its own rodent instead.

## Modifiers

Modifiers pick the species within a family. A run carries any number of modifiers, and up to two shape the species: family + tier + modifiers = species.

| Group | Values | Detected by |
| --- | --- | --- |
| When | dawn, midday, dusk, night, 00:00–03:00 | Phone clock |
| Where | beach, river or reservoir, park, forest or trail, city | GPS route matched against a bundled OpenStreetMap extract (e.g. within 50 m of coastline) |
| Weather | rain, heat, cold, wind; season (monsoon in the tropics) | Post-run tag; season from latitude + date |
| Shape | loop, out-and-back, point-to-point, figure-8, laps, straight line | GPS geometry; loops under \~100 m perimeter ignored |
| Style | even splits, faster second half, intervals | GPS splits |
| Body | tired, after poor sleep, raised resting heart rate | One-tap check-in; Fitbit sleep and resting HR via Health Connect |
| Novelty | new route, familiar route (10th time) | Route history on device |

**Naming rule.** Use real species whose names or habitats carry the modifier, so one catch teaches the pattern. Sand cat = speed in heat. Fishing cat = speed in rain. Snowy owl = night in the cold. Kingfisher = distance by the river. After a sand cat, a runner can guess that other "desert" animals exist.

**Curation.** The raw combination space is roughly 400. Only about 100 combinations are real animals; any run that matches none gives the base species for its tier.

Surface (grass vs pavement) is not detected reliably, so it is a post-run tag at most.

## Rarity and variants

The launch almanac holds about 120 animals and never more than 150. Variants shrink as difficulty rises, so a hard feat is earned once, not ten times.

| Rarity | What qualifies | Count at launch | Variants per animal |
| --- | --- | --- | --- |
| Common | One attribute (any night run, any loop) | \~50 | up to 6 |
| Uncommon | Two attributes together (night + 10 km) | \~35 | \~3 |
| Rare | Three attributes, or one hard benchmark | \~20 | 1–2 |
| Legendary | A real human feat (marathon, 100 m under 12 s, 1,000 m climb) | \~10 | 1, modifiers ignored |
| Mythic | An absurd Easter egg | \~5 | 1, no hints |

**Legendaries ignore modifiers.** A rainy night marathon still gives the Albatross on the first try. Repeat sightings add a "seen again" mark and the date.

**Mythic Easter eggs** sit outside the axes. Extinct animals fit: legendary because nobody sees them.

- 200 loops in one run, any distance (loop at least \~100 m)
- Exactly 3.14 km, ±10 m
- Any run on 29 February
- A palindrome finish time, such as 1:23:21
- 1,000 km lifetime

New animals arrive later through seasonal or expansion packs, not by growing the launch list.

## Buddy resolution and hints

Each run gives exactly one buddy, and discovery always wins over repeats.

When a run qualifies for several animals, pick in this order:

1. The rarest **undiscovered** animal the run qualified for
2. If all are discovered, the rarest overall, logged as a repeat sighting
3. Ties broken by the fixed family order

**Every run yields a new buddy or a hint.** A run that only produced a repeat sighting earns a hint, so no run feels wasted.

How hints work:

- **Neighbours first.** A hint points at an undiscovered animal one attribute away from the run you just did. After a dawn loop gives a Rooster, the hint might point at a dawn animal by the river.
- **Three levels.** Vague, then clearer, then nearly explicit. A hint also sharpens when you spot that card's neighbours in the same row.
- **Written as field notes.** For example: "Shy of crowds. Only seen by those who run where the river meets dawn."
- **Mythic animals get no hints.** They stay a surprise.
- **Mid-run hints are rare and optional.** At most one per run, as a short audio line ("fresh tracks by the water"), only when the condition is easily within reach. Users can turn them off.

**The reveal happens after the run.** Fitbit heart rate arrives only after it syncs, so the buddy appears post-run: a short *huff… pop* as the "?" card flips.

## Almanac

The almanac is one scrollable page showing every slot from day one, with undiscovered animals as "?" cards. At four cards per row, 120 animals is about 30 rows.

**Page structure**

- **Jump chips** at the top: tap a family to skip to it.
- **Sticky family headers** with counts, e.g. "Cats 7/28".
- **The same order inside each family:** tier ladder first (base species, easiest to hardest), then one row per modifier group, then rare two-modifier hybrids.
- **Mythic** sits last: "???" cards with no hints, but their count is visible.
- **Filters:** Spotted, Not yet spotted, and by modifier (Night, Beach, Rain). The modifier filter is the cross-family deduction view: seeing a night cat and a night bird sends you looking for the night goat.

**The "?" card**

- Same size and position as the real card, so a sighting flips it in place.
- Tinted with its family colour.
- Tap to read its hint, which sharpens as you spot neighbours.
- Only curated combinations get a slot, so a row's slot count is itself a clue.
- Its own design: avoid anything that reads as Mario's gold "?" block.

**Card detail** opens as a bottom sheet so the scroll position is kept. It shows the sprite, name, family, tier, modifiers, the date and route outline of the first sighting, times seen, and the runner's own note.

The total stays visible as a quiet goal: "87 question marks left."

## Data and tech

The app reads phone sensors directly and Fitbit data through Health Connect on Android, which keeps everything on the device. The cloud Google Health API is not used, since it needs internet and a Google sign-in.

| Source | Provides | Notes |
| --- | --- | --- |
| Phone GPS | Route, pace, splits, shape, elevation, sprint segments | Recorded live by the app |
| Phone barometer | Elevation gain | Cleaner than GPS altitude where available |
| Phone clock + latitude | Time of day, season | Tropics use monsoon instead of winter |
| Fitbit via [Health Connect](https://sahha.ai/integrations/google-health/) | Heart rate, sleep, resting heart rate | Arrives after the Fitbit app syncs; Android only |
| Bundled OpenStreetMap extract | Beach, river, park, forest, city | Singapore extract is small enough to ship; elsewhere a one-time region download |
| Post-run tags | Weather, tired check-in, optional surface | Honour system, fine for a personal app |
| Manual treadmill entry | Distance, time, incline | Or Fitbit's treadmill workout via Health Connect |

**Known limits**

- **Sprint timing.** Phone GPS samples about once a second with 3–5 m error, so a 12 s 100 m can read 11 or 13 s. Sprint animals need a track mode or an accelerometer cross-check.
- **Tiny loops.** Loops under about 100 m blur into GPS noise.
- **Offline Fitbit sync is unconfirmed.** Test with airplane mode on and Bluetooth on: sync, then check whether heart rate appears in Health Connect.
- **No live heart rate.** Fitbit devices cannot talk directly to third-party apps. A Bluetooth chest strap, or a Fitbit that broadcasts heart rate, would allow it.
- **iOS needs another heart-rate source**, because Fitbit writes to Health Connect but not Apple Health.
- **Do not build on the Fitbit Web API.** Google retires it on 30 October 2026 in favour of the [Google Health API](https://developers.google.com/health/about?authuser=4).

## Art direction

All animals are 32×32 pixel sprites built from shared family templates, so card 120 matches card 1.

**Sprite spec**

- 32×32 canvas; the animal fills about 26×24 and stands on the same baseline row.
- One master palette of 24–32 colours; each family owns 3–4 tones (dark, base, light, highlight).
- Side view, facing right, mid-stride.
- Light from the top-left; dark 1px outline.
- Static sprites first; a two-frame idle bob can come later.

**How sprites are built**

1. **Family templates:** cat (long, low, tail), bird (perched or in flight), hoofed (tall legs, horn slot), rodent (compact, round).
2. **Part library:** ears, head size, tail length, horns, beak, and pattern overlays (spots, stripes, rosettes, plain). A cheetah is cat + small head + long legs + spots.
3. **Checks:** view at 1× and 8×, run a solid-black silhouette test, and compare each family on one contact sheet.
4. **Human polish** on legendaries and mythics, in Pixelorama, LibreSprite or Aseprite.

**Card layers**

- Animal sprite, one per species
- Modifier background (night sky, sand, rain, river), about 30 reusable
- Rarity frame, one per tier (5)

CC0 packs can seed the style: [Kenney Animal Pack Redux](https://opengameart.org/content/animal-pack-redux) (30 animals) and [Tiny Creatures](https://clintbellanger.itch.io/tiny-creatures) (50+ animals at 16×16). Neither covers the full list, so missing species are drawn to match one chosen pack.

## Sharing and privacy

Sharing stays offline: the app draws a share card on the device and hands it to the system share sheet, and the chosen app does the uploading.

- **Share card:** sprite, rarity, run stats and a route outline on a stylised background, not real map tiles.
- **Destinations:** any app in the share sheet, or save to gallery when there is no signal. Instagram's direct "add to Story" route may need a registered Meta app ID; the generic share sheet needs none.
- **Home protection:** trim the first and last \~200 m of the route by default, or offer a card with no map.
- **No spoilers:** show only the animal spotted, never the remaining list.
- **Not competitive:** no "beat my score" framing. A good share line is "Spotted a Lynx today."

Privacy: no account, no server, no analytics. Health Connect access is requested per data type, and all run data stays on the phone.

## Side projects

Three learning projects feed the art, none of them shipped inside the app: RAG produces part specs, a generator turns specs into sprites, and approved sprites become training data.

**1. Sprite generation in code.** Claude writes each sprite as a grid of palette indices from the family templates and part library, renders it to PNG, checks it, and exports palette-indexed PNGs plus a JSON map of family, tier and parts. This is the main art path.

**2. Pixel transformer (the "mini LLM").** Each pixel is a token from the 32-colour palette, so a sprite is a 1,024-token sequence. A small GPT-style model predicts the next pixel after a label prefix such as "cat, river, dawn", so every output is on-palette and on-grid.

- Conditioned on structured labels (family, tier, modifier), not free text
- Trained on the app's own sprites, multiplied by flips, palette swaps and background variations
- Copyrighted sprite sets (e.g. Pokémon) are excluded
- Reference reading: DeepSeek's [Janus-Pro](https://www.infoq.com/news/2025/01/deepseek-ai-janus/), an open autoregressive image generator

**3. RAG for part specs.** Retrieval supplies the anatomy a small model lacks.

1. Query a species, e.g. "fishing cat".
2. Retrieve anatomy notes from an open knowledge base (Wikipedia and similar).
3. An LLM extracts a part spec: skeleton, ears, tail, pattern, palette.
4. Retrieve the nearest existing sprites as style references.
5. Generate, then run the silhouette test and a similarity score.
6. Approved sprites go back into the library, so retrieval improves.

Stack: open sentence-transformer embeddings; FAISS, Chroma or LanceDB; CLIP or SigLIP for sprite similarity (upscale to \~224 px first); a small local model or Claude for extraction. Evaluation: hand-write correct part specs for 20 species, then score retrieval and extraction against them.

For quick drafts instead, Stable Diffusion 3.5 with a pixel-art LoRA on a rented GPU works, followed by downscaling and palette snapping. Check each model's licence.

## Open questions and next steps

The biggest open risk is whether Fitbit data reaches Health Connect without internet; test that before building on it.

- [ ] Test Fitbit → Health Connect sync in airplane mode with Bluetooth on
- [ ] Confirm the final name and check the App Store, Google Play and trademarks
- [ ] Confirm the family tie-break order (Distance, Climb, Speed)
- [ ] Decide whether to support iOS, and with which heart-rate source
- [ ] Curate the launch list of \~120 animals with conditions, rarity and hint riddles
- [ ] Make the cat family test sheet: template, part library, five species
- [ ] Decide whether consistency across runs becomes a separate companion track later
- [ ] Define track mode for sprint animals
