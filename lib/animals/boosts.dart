import '../data/model.dart';
import 'catalog.dart';

const sleepWindow = Duration(days: 7);
const sleepFullVisitorAt = 3;

const droughtStep = 100;
const droughtCap = 8.0;

const completionTiers = [
  (at: 0.98, boost: 25.0),
  (at: 0.95, boost: 10.0),
  (at: 0.90, boost: 4.0),
  (at: 0.80, boost: 1.5),
  (at: 0.70, boost: 1.25),
];

const familyPullTiers = [
  (at: 0.98, pull: 24.0),
  (at: 0.95, pull: 12.0),
  (at: 0.90, pull: 6.0),
  (at: 0.80, pull: 3.0),
  (at: 0.70, pull: 1.5),
];

double completionOf(Catalog catalog, Set<String> met) {
  var total = 0;
  var seen = 0;
  void count(String id) {
    total++;
    if (met.contains(id)) seen++;
  }

  for (final s in catalog.species) {
    count(s.id);
    for (final c in s.colours) {
      count(c.id);
    }
  }
  for (final l in catalog.legends) {
    if (!l.isRegional) count(l.id);
  }
  return total == 0 ? 0 : seen / total;
}

double completionBoost(double completion) {
  for (final tier in completionTiers) {
    if (completion >= tier.at) return tier.boost;
  }
  return 1;
}

double familyPull(double completion) {
  for (final tier in familyPullTiers) {
    if (completion >= tier.at) return tier.pull;
  }
  return 1;
}

int droughtSince(Iterable<String> entryIdsInRevealOrder) {
  final seen = <String>{};
  var sinceNew = 0;
  for (final id in entryIdsInRevealOrder) {
    sinceNew = seen.add(id) ? 0 : sinceNew + 1;
  }
  return sinceNew;
}

double droughtBoost(int drought) {
  final boost = 1 + drought / droughtStep;
  return boost > droughtCap ? droughtCap : (boost < 1 ? 1 : boost);
}

List<String> inRevealOrder(Iterable<Sighting> sightings) {
  final legacy = [
    for (final s in sightings)
      if (s.order == null) s,
  ]..sort((a, b) => a.outing.start.compareTo(b.outing.start));
  final ordered = [
    for (final s in sightings)
      if (s.order != null) s,
  ]..sort((a, b) => a.order!.compareTo(b.order!));
  return [
    for (final s in [...legacy, ...ordered]) s.animal,
  ];
}

int recentExercise(Outing sleep, Iterable<Outing> known) {
  final from = sleep.start.subtract(sleepWindow);
  return known
      .where(
        (o) =>
            o.kind != sleepKind &&
            !o.start.isBefore(from) &&
            o.start.isBefore(sleep.start),
      )
      .length;
}

double sleepVisitorScale(int recentExercise) =>
    recentExercise >= sleepFullVisitorAt
    ? 1
    : (recentExercise < 0 ? 0 : recentExercise / sleepFullVisitorAt);
