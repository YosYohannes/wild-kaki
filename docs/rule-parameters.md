# Rule parameters

How an activity becomes an animal: the raw values we read, the processed parameters the decision uses, the values each one can take, and what happens when a value is missing.

An activity is anything Health Connect reports: an exercise session or a sleep session. Nothing is read from the location or any other app. The phone's time zone is read for regional legends. The network is used for the public holiday list (below) and the scene's weather.

## Raw values

| Raw value | Source | Always there? |
|---|---|---|
| `kind` | Health Connect exercise type, or a sleep session (table below) | Yes. Unknown exercise types become Workout |
| `datetime` | Start time in the phone's time zone. For Sleep, the time you went to bed | Yes |
| `duration` | End minus start, in whole minutes | Yes. Zero or negative counts as 1 |
| `distance` | Health Connect distance records over the session, in km | No. Missing for yoga, indoor climbing, most workouts and sleep. A total of 0 counts as missing |
| `roll` | Stable hash of the activity's Health Connect id | Yes. Same activity, same roll, on any phone, offline |

### Exercise types behind `kind`

| kind | Health Connect exercise types |
|---|---|
| Run | running, running on a treadmill |
| Walk | walking |
| Hike | hiking |
| Ride | biking, stationary biking |
| Swim | open-water swimming, pool swimming |
| Climb | rock climbing, stair climbing, stair machine |
| Yoga | yoga, pilates, stretching |
| Workout | every other exercise type, including ones we do not know |
| Sleep | a Health Connect sleep session |

## Processed parameters

The decision looks at `kind`, `partOfDay`, the three bands and the rolls. `dayOff` and the hat roll never change which animal you get, only how it looks (see Hats).

| Parameter | Made from | Values | What it says |
|---|---|---|---|
| `kind` | kind | Run, Walk, Hike, Ride, Swim, Climb, Yoga, Workout, Sleep | Where you were, so which habitat |
| `partOfDay` | datetime | Day, Twilight, Night | Which animals are awake: day animals, dawn-and-dusk animals, night animals |
| `lengthBand` | duration, kind | Brief, Short, Medium, Long | How long you stayed: patience |
| `distanceBand` | distance, kind | Near, Medium, Far, Epic, or Unknown | How far you ranged |
| `speedBand` | distance, duration, kind | Slow, Steady, Fast, or Unknown | How quickly you moved |
| `dayOff` | datetime, holiday list | Day off, Working day | A Saturday, a Sunday or a public holiday. Looks only: the animal wears a hat |
| `region` | the phone's time zone when the bush is opened | the regional legend whose time zones include it, or none | Which regional legend can appear |
| `recentExercise` | the known activities and the sleep's bedtime | A whole number, 0 or more | For a Sleep only: how many known non-sleep activities started in the 7 days before bedtime, revealed or still waiting. Sets the sleep's visitor share (a short sleep has none) |
| `completion` | the met entries and the catalog | 0 up to 1 | Met entries divided by all entries, not counting regional legends (89 today). Sets the completion bonus |
| `drought` | the revealed activities, in the order they were revealed | A whole number, 0 or more | Activities revealed since the last one that showed something new. Only colour species and base legends you have not met use it |
| `roll` | roll | seven independent numbers from 0 up to 1: regional, visitor, base, legend, species, colour, hat | Luck |

Public holidays come from the free Nager.Date service, asked once for this year and next by the phone's country code (from the phone's locale). The answer is cached on the phone for 30 days. Offline, or before the first answer, Singapore uses the list bundled with the app; any other country has no list, so only Saturdays and Sundays count as days off.

### `partOfDay` hours (phone local time)

| Value | Hours |
|---|---|
| Twilight | 05:00 to 06:59 and 17:00 to 20:59 |
| Day | 07:00 to 16:59 |
| Night | 21:00 to 04:59 |

### `lengthBand` cut-offs (minutes)

| kind | Brief | Short | Medium | Long |
|---|---|---|---|---|
| Run | under 15 | 15 to 29 | 30 to 59 | 60 or more |
| Walk | under 15 | 15 to 39 | 40 to 89 | 90 or more |
| Hike | under 30 | 30 to 89 | 90 to 179 | 180 or more |
| Ride | under 20 | 20 to 44 | 45 to 119 | 120 or more |
| Swim | under 15 | 15 to 29 | 30 to 59 | 60 or more |
| Climb | under 20 | 20 to 44 | 45 to 89 | 90 or more |
| Yoga, Workout | under 15 | 15 to 29 | 30 to 59 | 60 or more |
| Sleep | under 240 | 240 to 359 | 360 to 539 | 540 or more |

### `distanceBand` cut-offs (km)

| kind | Near | Medium | Far | Epic |
|---|---|---|---|---|
| Run | under 3 | 3 to under 8 | 8 to under 21 | 21 or more |
| Walk | under 2 | 2 to under 5 | 5 to under 12 | 12 or more |
| Hike | under 4 | 4 to under 10 | 10 to under 20 | 20 or more |
| Ride | under 8 | 8 to under 25 | 25 to under 60 | 60 or more |
| Swim | under 0.5 | 0.5 to under 1.5 | 1.5 to under 4 | 4 or more |

Climb, Yoga, Workout and Sleep are always Unknown, even if Health Connect has a distance.

### `speedBand` cut-offs (km per hour)

| kind | Slow | Steady | Fast |
|---|---|---|---|
| Run | under 8 | 8 to under 12 | 12 or more |
| Walk | under 3.5 | 3.5 to under 5.5 | 5.5 or more |
| Hike | under 2.5 | 2.5 to under 4.5 | 4.5 or more |
| Ride | under 14 | 14 to under 22 | 22 or more |
| Swim | under 1.5 | 1.5 to under 2.5 | 2.5 or more |

Unknown for the other kinds, when the distance is missing, or for activities under 5 minutes.

## The decision

The animals, their bases and their affinities are in `animals.md`. The same activity with the same history always gives the same animal, but the kind does not fix the base: about 1 in 7 activities brings a visitor from another base.

### Step 0: regional legend

If the phone's time zone belongs to a regional legend (see `animals.md`) and the regional roll is under 0.002, the animal is that legend. Nothing else is looked at; only the hat (step 5) still applies.

### Step 1: home or visitor

- If the visitor roll is `visitorShare` (0.15) or more, the activity stays **home**: the candidate bases are the bases whose home kinds include the activity's kind. A species listed as "also home" on a kind (for example the Kingfisher on Swim) joins as if its base were home.
- If the visitor roll is under `visitorShare`, it brings a **visitor**: the candidate bases are all the other bases.
- A kind with no home base uses the Fox base.
- For a **Sleep**, the share is `visitorShare × f`, with `f = min(1, n / 3)` and `n` the `recentExercise` count. So f is 0, 1/3, 2/3 or 1 for 0, 1, 2 or 3 or more activities, and a sleep with no exercise in the week never brings a visitor. `n` counts known non-sleep activities whose start is at or after bedtime minus 7 days and before bedtime. Other kinds always use the full share.

### Step 2: pick the base

- Each candidate base starts with weight 1. A base that still has a shape species you have not met gets the **discovery multiplier** (×3), so its weight is 3. A base with any unmet entry (shape species, colour species or base legend) is also multiplied by the family pull `B(c)` (below).
- The base roll picks one candidate, with odds in proportion to the weights.
- The home or visitor split from step 1 is never changed by discovery: 85% stays home and 15% brings a visitor (for a sleep, the visitor share is scaled as in step 1).

This is how a non-rider still meets songbirds: a base you never reach at home keeps its place among the visitors, and the discovery multiplier makes it three times as likely as a base you have already met.

### Step 2b: base legend

If the legend roll is under 0.01, or under 0.02 when the activity has the band the base's legend likes, the animal is the base's legend. While you have not met that legend, the chance is multiplied by the completion tier and the drought boost (below), and is never above 1. The species and colour steps are skipped; the hat still applies.

### Step 3: pick the shape species

Every shape species has an affinity for each value of `partOfDay`, `lengthBand`, `distanceBand` and `speedBand`, from this scale:

| Affinity | Weight |
|---|---|
| avoids | ×0.25 |
| neutral (the default) | ×1 |
| likes | ×2 |
| loves | ×4 |

A species' weight is the product of its affinities for the activity's values. An Unknown value counts as neutral, so missing data needs no special case.

- A species you have not met yet gets the discovery multiplier (×3) on top of its affinity weight.
- The species roll picks one species, with odds in proportion to the final weights.

### Step 4: colour species

If the picked shape species has colour species, the colour roll can turn it into one of them, at the chance listed in `animals.md` (for example Black cat 12%, Golden cat 3% for the Tabby). The discovery multiplier does not apply here, so rare colours stay rare. A colour you have not met has its slice multiplied by the completion tier and the drought boost (below); the slices of one species never add up to more than 1.

### The drought boost

The drought `D` is the number of revealed activities since the most recent one that revealed a new entry, an entry id not met before it, counting the reveals in the order they were opened. With no activities revealed, or when every one revealed something new, `D` is 0.

The boost is `m = min(8, 1 + D / 100)`, so ×1 at 0, ×2 at 100 and ×8 from 700 on (`droughtStep` 100, `droughtCap` 8.0). It multiplies the colour slice of a colour species you have not met (step 4) and the legend chance of a base legend you have not met (step 2b), together with the completion tier below. Colours and legends you have met, shape species and regional legends are not boosted. `D` is worked out from the stored history and handed to the pick, so the same activity with the same history gives the same animal.

### The completion bonus

Completion `c` is the number of met entries divided by the number of entries that are not regional legends (89 today: 58 shape species, 16 colour species and 15 base legends). Each table uses the highest threshold reached (`completionTiers`, `familyPullTiers`).

| `c` at least | Tier `T(c)` | Family pull `B(c)` |
|---|---|---|
| under 0.70 | 1 | 1 |
| 0.70 | 1.25 | 1.5 |
| 0.80 | 1.5 | 3 |
| 0.90 | 4 | 6 |
| 0.95 | 10 | 12 |
| 0.98 | 25 | 24 |

- `T(c)` multiplies the colour slice of a colour species you have not met and the legend chance of a base legend you have not met, together with the drought boost: the total is `T(c) × m`. Colour slices of a species total at most 1 and a legend chance is at most 1. Met colours and legends, shape species and regional legends are not boosted.
- `B(c)` multiplies the base weight (step 2) of a candidate base that still has an unmet shape species, colour species or base legend among its candidates, on top of the ×3 for an unmet shape species. It applies to the home and the visitor candidates, so the home and visitor split is unchanged.
- `c` comes from the met entries and the catalog, so the same activity with the same history gives the same animal.

### Short sleep

A Sleep is short when its `lengthBand` is Brief or Short, that is under 360 minutes (6 hours, the top of the Short band for Sleep). A short sleep is picked with plain odds:
- no discovery multiplier (×3) on bases or species, so an unmet one counts like a met one;
- no drought boost, no completion tier and no family pull;
- visitor share 0, whatever `recentExercise` says, so only sleep home animals come;
- base legends keep their plain chance (1%, or 2% when liked), and colour slices keep their listed chances.

The regional legend still rolls first and the hat is unchanged. A Sleep of 360 minutes or more, and every other kind, are unaffected.

## Hats

On a day off the animal wears a hat. The hat roll picks one of the five hats with equal odds. A hat is a small separate sprite drawn at the base's head point, mirrored when the animal faces left. The hat belongs to the sighting, so the card, the animal page and the animal in the meadow all show it.

## Not used

Heart rate, steps, calories, elevation, speed samples, weather, season, climate, location (only the time zone, for regional legends), indoor or outdoor, which app recorded the activity.

Weather in particular never changes which animal you get: an activity can be synced hours or days after it happened, so the weather at sync time says nothing about it. Live weather is only for the look of the scene (see the README).

## Decisions

1. Decide with the processed parameters and the rolls only.
2. Kind brings home bases; about 1 in 7 activities (15%) brings a visitor from another base instead.
3. Within a base, affinities pick the shape species. Discovery is a simple ×3 multiplier on the chance of an unmet base or unmet shape species. It never removes a choice and never changes the home or visitor split.
4. Colour species hang off shape species and are picked by the colour roll. Rarity lives there.
5. `partOfDay` has three values: Day, Twilight, Night. Sleep uses the time you went to bed.
6. Bands only, no continuous scores for now.
7. A day off (weekend or public holiday) gives a hat, chosen at random from five.
8. Start with 15 bases, 58 shape species, 16 colour species and 20 legends (94 entries in the collection), aiming for 50 to 120.
9. `partOfDay` keeps the fixed hours; it does not follow sunrise and sunset.
10. Kingfisher stays a Swim animal through the songbird base, about 30% of swims.
11. Weather is a scene background only, never an input to the pick.
12. Every base has one legend, at 1% after the base is picked, 2% when the activity has the band it likes. No discovery multiplier; only the drought boost raises it, and only while the legend is unmet.
13. Regional legends depend only on the phone's time zone, at 0.2% before anything else.
14. Hedgehog is replaced by Raccoon as a Sleep base.
15. Droughts are paid back: while nothing new has been revealed for D activities, an unmet colour species or base legend is `min(8, 1 + D / 100)` times as likely (colour slices total at most 1, a legend chance at most 1). Shape species keep the ×3 discovery, regional legends are never boosted, and D comes from the reveal order of the stored history so the pick stays deterministic.
16. The closer the collection is to complete, the more the missing ones come: a step table on completion (regional legends excluded) multiplies unmet colours and base legends (×1.25 up to ×25, with the drought boost) and pulls the base weight of any family with something missing (×1.5 up to ×24). Met entries, shape species and regional legends are not boosted, the clamps stay, and the home or visitor split is unchanged.
17. Sleep brings visitors only if you have been moving: its visitor share is the usual 15% times min(1, n / 3), with n the known non-sleep activities in the 7 days before bedtime (revealed or waiting). Exercise keeps the full share, regional legends still roll first on every kind, and n comes from the known activities, so the same activity with the same known activities gives the same animal.
18. Bad sleep is not rewarded: a Sleep under 6 hours is picked with plain odds (no ×3 discovery, no drought boost, no completion tier, no family pull, no visitors), though it still gets a normal animal, regional legends still roll first and hats are unchanged. The "never worse" promise holds for exercise; for sleep, under 6 hours gets no help.
