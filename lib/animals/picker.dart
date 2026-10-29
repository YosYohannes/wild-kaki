import '../data/model.dart';
import 'catalog.dart';
import 'catalog_data.dart';
import 'facts.dart';
import 'holidays.dart';
import 'rolls.dart';

const visitorShare = 0.10;
const discoveryMultiplier = 3.0;
const fallbackBaseId = 'fox';

class Pick {
  const Pick({
    required this.baseId,
    required this.speciesId,
    required this.entryId,
    required this.hatId,
  });

  final String baseId;
  final String speciesId;
  final String entryId;
  final String? hatId;

  @override
  bool operator ==(Object other) =>
      other is Pick &&
      other.baseId == baseId &&
      other.speciesId == speciesId &&
      other.entryId == entryId &&
      other.hatId == hatId;

  @override
  int get hashCode => Object.hash(baseId, speciesId, entryId, hatId);

  @override
  String toString() => 'Pick($baseId, $speciesId, $entryId, hat: $hatId)';
}

Pick pickAnimal({
  required Outing activity,
  required Set<String> met,
  HolidayProvider? holidays,
  Catalog? catalog,
}) => pickFor(
  facts: ActivityFacts.from(activity, holidays ?? holidaysForPhone()),
  rolls: Rolls.of(activity.id),
  met: met,
  catalog: catalog ?? defaultCatalog,
);

Pick pickFor({
  required ActivityFacts facts,
  required Rolls rolls,
  required Set<String> met,
  required Catalog catalog,
}) {
  final home = _homeCandidates(catalog, facts.kind);
  final candidates = rolls.visitor < visitorShare
      ? _visitorCandidates(catalog, home)
      : home;

  bool unmet(Species s) =>
      !met.contains(s.id) && !s.colours.any((c) => met.contains(c.id));

  final bases = candidates.keys.toList();
  final base = _choose(bases, [
    for (final b in bases)
      candidates[b]!.any(unmet) ? discoveryMultiplier : 1.0,
  ], rolls.base);

  final options = candidates[base]!;
  final species = _choose(options, [
    for (final s in options)
      _affinityWeight(s, facts) * (unmet(s) ? discoveryMultiplier : 1.0),
  ], rolls.species);

  var entryId = species.id;
  var lower = 0.0;
  for (final colour in species.colours) {
    if (rolls.colour < lower + colour.chance) {
      entryId = colour.id;
      break;
    }
    lower += colour.chance;
  }

  final hats = catalog.hats;
  final hatId = facts.dayOff && hats.isNotEmpty
      ? hats[(rolls.hat * hats.length).floor()].id
      : null;

  return Pick(
    baseId: base,
    speciesId: species.id,
    entryId: entryId,
    hatId: hatId,
  );
}

double _affinityWeight(Species species, ActivityFacts facts) => facts.bands
    .map((band) => species.affinityFor(band).weight)
    .fold(1.0, (a, b) => a * b);

T _choose<T>(List<T> items, List<double> weights, double roll) {
  final total = weights.fold(0.0, (a, b) => a + b);
  final target = roll * total;
  var upTo = 0.0;
  for (var i = 0; i < items.length; i++) {
    upTo += weights[i];
    if (target < upTo) return items[i];
  }
  return items.last;
}

Map<String, List<Species>> _homeCandidates(Catalog catalog, String kind) {
  final home = <String, List<Species>>{};
  for (final base in catalog.bases) {
    final all = catalog.speciesOf(base.id);
    final allowed = base.homeKinds.contains(kind)
        ? all
        : [
            for (final s in all)
              if (s.alsoHomeKinds.contains(kind)) s,
          ];
    if (allowed.isNotEmpty) home[base.id] = allowed;
  }
  if (home.isNotEmpty) return home;
  final fallback = catalog.baseById(fallbackBaseId) ?? catalog.bases.first;
  return {fallback.id: catalog.speciesOf(fallback.id)};
}

Map<String, List<Species>> _visitorCandidates(
  Catalog catalog,
  Map<String, List<Species>> home,
) {
  final visitors = <String, List<Species>>{};
  for (final base in catalog.bases) {
    if (home.containsKey(base.id)) continue;
    final all = catalog.speciesOf(base.id);
    if (all.isNotEmpty) visitors[base.id] = all;
  }
  return visitors.isEmpty ? home : visitors;
}
