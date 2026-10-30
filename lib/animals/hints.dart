import '../data/model.dart';
import 'bands.dart';
import 'catalog.dart';
import 'hints_data.dart';
import 'lookup.dart';

const _notFussy = 'Not fussy about when or how.';

const Map<String, (String, String)> _kindPhrases = {
  'Run': ('Turns up on', 'runs'),
  'Walk': ('Trots along on', 'walks'),
  'Hike': ('Found out on', 'hikes'),
  'Ride': ('Flies over', 'rides'),
  'Swim': ('Paddles by on', 'swims'),
  'Climb': ('Seen on', 'climbs'),
  'Yoga': ('Joins', 'yoga'),
  'Workout': ('Joins', 'workouts'),
  'Sleep': ('Comes while you', 'sleep'),
};

const Map<Affinity, String> _affinityLeads = {
  Affinity.loves: 'Loves',
  Affinity.likes: 'Fond of',
  Affinity.avoids: 'Shy of',
};

const Map<Band, (String, String?)> _bandWords = {
  PartOfDay.day: ('daylight', 'daytime naps'),
  PartOfDay.twilight: ('dusk and dawn', 'dusk and dawn'),
  PartOfDay.night: ('the night', 'the night'),
  LengthBand.brief: ('quick activities', 'short naps'),
  LengthBand.short: ('short activities', 'short sleeps'),
  LengthBand.medium: ('middling activities', 'a good night\'s sleep'),
  LengthBand.long: ('long activities', 'long lie-ins'),
  DistanceBand.near: ('staying close', null),
  DistanceBand.far: ('going far', null),
  SpeedBand.slow: ('an easy pace', null),
  SpeedBand.steady: ('a steady pace', null),
  SpeedBand.fast: ('speed', null),
};

bool hintUnlocked(
  AnimalEntry entry, {
  required Set<String> met,
  Set<String> hinted = const {},
  String? timeZone,
}) {
  if (met.contains(entry.id)) return false;
  final legend = entry.legend;
  if (legend != null && legend.isRegional) return legend.matchesZone(timeZone);
  return hinted.contains(entry.id);
}

String? hintFor(
  AnimalEntry entry, {
  required Set<String> met,
  Set<String> hinted = const {},
  String? timeZone,
}) => hintUnlocked(entry, met: met, hinted: hinted, timeZone: timeZone)
    ? hintText(entry)
    : null;

String? duplicateHint({
  required Set<String> met,
  required Set<String> hinted,
  required double roll,
}) {
  final open = [
    for (final e in animalEntries)
      if (!met.contains(e.id) &&
          !hinted.contains(e.id) &&
          !(e.legend?.isRegional ?? false) &&
          (e.colour == null || met.contains(e.shape!.id)))
        e,
  ];
  if (open.isEmpty) return null;
  return open[(roll * open.length).floor().clamp(0, open.length - 1)].id;
}

String hintText(AnimalEntry entry) {
  final legend = entry.legend;
  if (legend != null) return legendRiddles[legend.id]!;
  final colour = entry.colour;
  if (colour != null) {
    final coat = colour.chance < 0.05 ? 'A very rare' : 'An uncommon';
    return '$coat coat of the ${entry.shape!.name}';
  }
  return _habitLine(entry.base, entry.shape!);
}

String _habitLine(Base base, Species species) {
  final kinds = [...base.homeKinds, ...species.alsoHomeKinds];
  final phrases = [for (final k in kinds) _kindPhrases[k]!];
  final kind =
      '${phrases.first.$1} ${[for (final p in phrases) p.$2].join(' and ')}';
  final sleeping =
      base.homeKinds.length == 1 && base.homeKinds.first == 'Sleep';

  final ranked = [
    for (final affinity in [Affinity.loves, Affinity.likes, Affinity.avoids])
      for (final e in species.affinities.entries)
        if (e.value == affinity && _bandWords.containsKey(e.key))
          (affinity, e.key),
  ].take(2).toList();
  if (ranked.isEmpty) return '$kind. $_notFussy';

  String words(Band band) {
    final (plain, sleepWords) = _bandWords[band]!;
    return sleeping ? sleepWords ?? plain : plain;
  }

  final (firstAffinity, firstBand) = ranked.first;
  var text = '${_affinityLeads[firstAffinity]} ${words(firstBand)}';
  if (ranked.length > 1) {
    final (affinity, band) = ranked[1];
    final joiner = words(firstBand).contains(' and ') ? ', and' : ' and';
    text += affinity == firstAffinity
        ? '$joiner ${words(band)}'
        : ', ${_affinityLeads[affinity]!.toLowerCase()} ${words(band)}';
  }
  return '$kind. $text.';
}

Set<String> hintedIds(Iterable<Sighting> sightings) => {
  for (final s in sightings)
    if (s.hint != null) s.hint!,
};
