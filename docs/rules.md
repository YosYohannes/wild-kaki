# How an activity becomes an animal

One page. The exact cut-offs are in `rule-parameters.md`, the animals in `animals.md`.

Every activity Health Connect reports (an exercise or a sleep) hides one animal. The same activity always gives the same animal: the luck comes from rolls made from the activity's own id, not from the moment you tap the bush.

## The steps

| Step | What decides it | Chances |
|---|---|---|
| 0. Regional legend | the phone's time zone and the regional roll | Only where a regional legend lives (the Merlion in Singapore). **0.2%**, about 1 in 500 activities, whatever else is true. If it hits, it is the animal; skip to step 5 |
| 1. Home or visitor | the visitor roll | **85%** home: the bases that live with this kind of activity (a run brings Fox or Hare). **15%** visitor: any other base. A sleep brings visitors less often when you have not been moving (Sleep and visitors, below) |
| 2. Base | equal weights, ×3 for a base with something unmet, then the base roll | With everything unmet or everything met: two home bases are 42.5% each, and a visitor is about 1.2% for each of the other 13 bases. An unmet base is three times as likely as a met one. Near a full collection, a base with something missing is pulled harder (Completion bonus, below) |
| 2b. Base legend | the legend roll | **1%** that the animal is the base's legend (a Kitsune for Fox), **2%** when the activity matches what the legend likes. Raised by the drought boost and the completion bonus while you have not met that legend (below). If it hits, skip to step 5 |
| 3. Shape species | affinities, ×3 for an unmet species, then the species roll | Each species' weight is its affinities multiplied: avoids ×0.25, neutral ×1, likes ×2, loves ×4. An unmet species is three times as likely as a met one. Odds are in proportion to the weights |
| 4. Colour species | the colour roll | If the species has colour species: usually **12%** for a common colour (Black cat) and **3%** for a rare one (Golden cat). No discovery multiplier here, so rare stays rare. Raised by the drought boost and the completion bonus for a colour you have not met (below) |
| 5. Hat | day off (weekend or public holiday) and the hat roll | **100%** on a day off, **0%** otherwise. Five hats, **20%** each |

Affinities look at three things about the activity, each a band set per kind:
- **Part of day:** Day, Twilight or Night. For sleep, the time you went to bed.
- **Length, distance and speed:** for example a Run is Fast from 12 km/h. A value that is not available (no distance on yoga) counts as neutral.

## Example: a fast 30-minute run at 18:00 on a Saturday, everything already met

The run is Twilight, Medium length, Medium distance and Fast.

| Base (chance) | Species | Weight | Chance overall |
|---|---|---|---|
| Fox (42.5%) | Fennec: loves Fast | 4 | 24% |
| | Red fox: likes Twilight | 2 | 12%, of which Silver fox 1.5% and Arctic fox 0.4% |
| | Grey fox | 1 | 6% |
| Hare (42.5%) | Hare: loves Fast | 4 | 24%, of which Snow hare 0.7% |
| | Rabbit: likes Twilight | 2 | 12% |
| | Jackrabbit | 1 | 6% |
| Visitor (15%) | any other base | | about 1.2% per base |

It is a Saturday, so whatever comes wears a hat: party hat, sombrero, beanie, top hat or bowler hat, 20% each.

## What discovery does

Discovery is only a multiplier: **×3 on the chance of a base or species you have not met yet.** It never removes a choice, never forces one, and never changes the 85% home and 15% visitor split.
- **New animals come a bit faster, not in a fixed order.** An unmet species is three times as likely as a met one, and everything else about the pick stays the same.
- **Activities you never do still pay off, slowly.** A base you never reach at home sits among the visitors. At the start (everything unmet) a visitor base is about 1.2% per activity. Once you have met most other bases, an unmet base is about 3%. If you never ride, songbirds arrive roughly once in 87 activities at first, and once in about 33 later.
- **Colours and legends are luck:** a golden animal or a legend is never guaranteed, and discovery does not touch them. Only the drought boost and the completion bonus below help them.

## Sleep and visitors

Sleep brings visitors only if you have been moving. With three or more activities in the week before, a sleep brings visitors as often as any activity (15%); with none, a sleep brings only sleep animals. In between it scales: one activity gives a third of the visitors, two give two thirds. The week is the 7 days before you went to bed, and it counts every activity the app knows about, whether you have opened its bush or not. Sleeps themselves do not count, and nothing changes for exercise.

## The drought boost

The drought is the number of activities you have revealed since the last time one showed you something new, an animal you had not met before. It counts the reveals in the order you opened them. Right after a new animal it is 0, and with no activities yet it is 0.

While the drought lasts, the chance of a **colour species or a base legend you have not met** is multiplied by 1 + drought / 100, up to ×8. After 100 dry activities the chance is doubled, after 300 it is four times as much, and from 700 on it stays at ×8 (a 1% legend becomes 8%, a 3% golden coat becomes 24%). The longer you go without something new, the closer the rare ones come.
- **Only what you have not met.** A colour or a legend you already have keeps its normal chance. Shape species keep their ×3 discovery and nothing more, and regional legends are never boosted.
- **It stays a chance.** The chances of a species' colours never add up to more than 100%, and a legend is never certain.
- **It adds to the completion bonus.** The two multiply (see below).
- **Nothing is lost.** The first new animal sets the drought back to 0, and the same activity still gives the same animal for the same history.

## Completion bonus

Completion is how much of the collection you have: the entries you have met, divided by all the entries, not counting the regional legends (89 today, because a regional legend can only be met in its own region). A step table gives the bonus from the highest step you have reached.

| Completion | Unmet colour or legend chance | Pull toward a base with something missing |
|---|---|---|
| under 70% | ×1 | ×1 |
| 70% | ×1.25 | ×1.5 |
| 80% | ×1.5 | ×3 |
| 90% | ×4 | ×6 |
| 95% | ×10 | ×12 |
| 98% | ×25 | ×24 |

The closer you are to a full collection, the more the missing ones and their families come to you.
- **Missing colours and legends.** The first column multiplies the chance of a colour species or a base legend you have not met, together with the drought boost (for example ×4 at 90% and a drought of 100 is ×8). A colour's slices still total at most 100% and a legend is never certain. Met ones and regional legends are not boosted.
- **Families with something missing.** The second column multiplies the weight of a base that still has an unmet shape species, colour species or base legend. It comes on top of the ×3 for an unmet shape species, and works for home and visitor bases alike. It never changes the 85% home and 15% visitor split.

## What never changes the pick

Effort, streaks, missed days, steps, calories, heart rate, weather and location. The phone's time zone only decides which regional legend can appear. A short, slow or late activity is never worse, only different.
