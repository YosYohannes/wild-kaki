# Rule parameters

How an activity becomes an animal: the raw values we read, the processed parameters the decision uses, the values each one can take, and what happens when a value is missing.

An activity is anything Health Connect reports: an exercise session or a sleep session. Nothing is read from the network, the location or any other app.

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
| `roll` | roll | five independent numbers from 0 up to 1: visitor, base, species, colour, hat | Luck |

Public holidays come from a list bundled with the app for the phone's region (from the phone's locale). If the region has no list, only Saturdays and Sundays count as days off.

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

The animals, their bases and their affinities are in `animals.md`. The same activity with the same history always gives the same animal, but the kind does not fix the base: about 1 in 10 activities brings a visitor from another base.

### Step 1: home or visitor

- If the visitor roll is 0.10 or more, the activity stays **home**: the candidate bases are the bases whose home kinds include the activity's kind. A species listed as "also home" on a kind (for example the Kingfisher on Swim) joins as if its base were home.
- If the visitor roll is under 0.10, it brings a **visitor**: the candidate bases are all the other bases.
- A kind with no home base uses the Fox base.

### Step 2: pick the base

- Each candidate base starts with weight 1. A base that still has a shape species you have not met gets the **discovery multiplier** (×3), so its weight is 3.
- The base roll picks one candidate, with odds in proportion to the weights.
- The home or visitor split from step 1 is never changed by discovery: 90% stays home and 10% brings a visitor, always.

This is how a non-rider still meets songbirds: a base you never reach at home keeps its place among the visitors, and the discovery multiplier makes it three times as likely as a base you have already met.

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

If the picked shape species has colour species, the colour roll can turn it into one of them, at the chance listed in `animals.md` (for example Black cat 12%, Golden cat 3% for the Tabby). The discovery multiplier does not apply here, so rare colours stay rare.

## Hats

On a day off the animal wears a hat. The hat roll picks one of the five hats with equal odds. A hat is a small separate sprite drawn at the base's head point, mirrored when the animal faces left. The hat belongs to the sighting, so the card, the animal page and the animal in the meadow all show it.

## Not used

Heart rate, steps, calories, elevation, speed samples, weather, season, climate, location, indoor or outdoor, which app recorded the activity.

## Decisions

1. Decide with the processed parameters and the rolls only.
2. Kind brings home bases; about 1 in 10 activities brings a visitor from another base instead.
3. Within a base, affinities pick the shape species. Discovery is a simple ×3 multiplier on the chance of an unmet base or unmet shape species. It never removes a choice and never changes the home or visitor split.
4. Colour species hang off shape species and are picked by the colour roll. Rarity lives there.
5. `partOfDay` has three values: Day, Twilight, Night. Sleep uses the time you went to bed.
6. Bands only, no continuous scores for now.
7. A day off (weekend or public holiday) gives a hat, chosen at random from five.
8. Start with 15 bases, 57 shape species and 16 colour species (73 in the collection), aiming for 50 to 120.
