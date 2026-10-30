# How an activity becomes an animal

One page. The exact cut-offs are in `rule-parameters.md`, the animals in `animals.md`.

Every activity Health Connect reports (an exercise or a sleep) hides one animal. The same activity always gives the same animal: the luck comes from rolls made from the activity's own id, not from the moment you tap the bush.

## The steps

| Step | What decides it | Chances |
|---|---|---|
| 0. Regional legend | the phone's time zone and the regional roll | Only where a regional legend lives (the Merlion in Singapore). **0.2%**, about 1 in 500 activities, whatever else is true. If it hits, it is the animal; skip to step 5 |
| 1. Home or visitor | the visitor roll | **90%** home: the bases that live with this kind of activity (a run brings Fox or Hare). **10%** visitor: any other base |
| 2. Base | equal weights, ×3 for a base with something unmet, then the base roll | With everything unmet or everything met: two home bases are 45% each, and a visitor is about 0.8% for each of the other 13 bases. An unmet base is three times as likely as a met one |
| 2b. Base legend | the legend roll | **1%** that the animal is the base's legend (a Kitsune for Fox), **2%** when the activity matches what the legend likes. If it hits, skip to step 5 |
| 3. Shape species | affinities, ×3 for an unmet species, then the species roll | Each species' weight is its affinities multiplied: avoids ×0.25, neutral ×1, likes ×2, loves ×4. An unmet species is three times as likely as a met one. Odds are in proportion to the weights |
| 4. Colour species | the colour roll | If the species has colour species: usually **12%** for a common colour (Black cat) and **3%** for a rare one (Golden cat). No discovery multiplier here, so rare stays rare |
| 5. Hat | day off (weekend or public holiday) and the hat roll | **100%** on a day off, **0%** otherwise. Five hats, **20%** each |

Affinities look at three things about the activity, each a band set per kind:
- **Part of day:** Day, Twilight or Night. For sleep, the time you went to bed.
- **Length, distance and speed:** for example a Run is Fast from 12 km/h. A value that is not available (no distance on yoga) counts as neutral.

## Example: a fast 30-minute run at 18:00 on a Saturday, everything already met

The run is Twilight, Medium length, Medium distance and Fast.

| Base (chance) | Species | Weight | Chance overall |
|---|---|---|---|
| Fox (45%) | Fennec: loves Fast | 4 | 26% |
| | Red fox: likes Twilight | 2 | 13%, of which Silver fox 1.5% and Arctic fox 0.4% |
| | Grey fox | 1 | 6% |
| Hare (45%) | Hare: loves Fast | 4 | 26%, of which Snow hare 0.8% |
| | Rabbit: likes Twilight | 2 | 13% |
| | Jackrabbit | 1 | 6% |
| Visitor (10%) | any other base | | about 0.8% per base |

It is a Saturday, so whatever comes wears a hat: party hat, sombrero, beanie, top hat or bowler hat, 20% each.

## What discovery does

Discovery is only a multiplier: **×3 on the chance of a base or species you have not met yet.** It never removes a choice, never forces one, and never changes the 90% home and 10% visitor split.
- **New animals come a bit faster, not in a fixed order.** An unmet species is three times as likely as a met one, and everything else about the pick stays the same.
- **Activities you never do still pay off, slowly.** A base you never reach at home sits among the visitors. At the start (everything unmet) a visitor base is about 0.8% per activity. Once you have met most other bases, an unmet base is about 2%. If you never ride, songbirds arrive roughly once in 130 activities at first, and once in about 50 later.
- **Colours and legends are pure luck:** a golden animal or a legend is never guaranteed, and discovery does not touch them.

## What never changes the pick

Effort, streaks, missed days, steps, calories, heart rate, weather and location. The phone's time zone only decides which regional legend can appear. A short, slow or late activity is never worse, only different.
