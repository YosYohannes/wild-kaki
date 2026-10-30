import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/boosts.dart';
import 'package:wildkaki/animals/catalog.dart';
import 'package:wildkaki/animals/catalog_data.dart';
import 'package:wildkaki/animals/facts.dart';
import 'package:wildkaki/animals/holidays.dart';
import 'package:wildkaki/animals/picker.dart';
import 'package:wildkaki/animals/rolls.dart';
import 'package:wildkaki/data/model.dart';

const none = NoHolidays();
const fillers = 195;
const total = 200;

Outing run(String id) => Outing(
  id: id,
  kind: 'Run',
  start: DateTime(2026, 11, 4, 18),
  distanceKm: 6,
  minutes: 30,
);

Base baseOf(String id, Set<String> kinds) => Base(
  id: id,
  name: id,
  homeKinds: kinds,
  habitat: Habitat.meadow,
  sound: 'yip',
  bubble: 'x',
  arrival: '{activity}',
  frames: const ['stub_fox_1'],
  headPoints: const [(x: 0, y: 0)],
);

const goldColour = ColourSpecies(
  id: 'x-gold',
  name: 'Gold',
  shapeSpeciesId: 'x',
  chance: 0.03,
);

final boostCatalog = Catalog(
  bases: [
    baseOf('a', {'Run'}),
    baseOf('pad', {}),
  ],
  species: [
    const Species(id: 'x', name: 'X', baseId: 'a', colours: [goldColour]),
    for (var i = 0; i < fillers + 2; i++)
      Species(id: 'f$i', name: 'F', baseId: 'pad'),
  ],
  legends: const [Legend(id: 'a-leg', name: 'Leg', baseId: 'a')],
  hats: const [],
);

Set<String> metAt(int entries, {Set<String> extra = const {}}) => {
  ...extra,
  for (var i = 0; i < entries - extra.length; i++) 'f$i',
};

Pick boosted(
  Set<String> met, {
  int drought = 0,
  double colour = 0.5,
  double legend = 0.5,
}) => pickFor(
  facts: ActivityFacts.from(run('t'), none),
  rolls: Rolls(
    visitor: 0.5,
    base: 0,
    species: 0,
    colour: colour,
    hat: 0.5,
    legend: legend,
  ),
  met: met,
  drought: drought,
  catalog: boostCatalog,
);

final pullCatalog = Catalog(
  bases: [
    baseOf('a', {'Run'}),
    baseOf('b', {'Run'}),
    baseOf('pad', {}),
  ],
  species: [
    const Species(id: 'a1', name: 'A', baseId: 'a'),
    const Species(
      id: 'b1',
      name: 'B',
      baseId: 'b',
      colours: [
        ColourSpecies(id: 'b1-c', name: 'C', shapeSpeciesId: 'b1', chance: 0.1),
      ],
    ),
    for (var i = 0; i < fillers; i++)
      Species(id: 'f$i', name: 'F', baseId: 'pad'),
  ],
  legends: const [
    Legend(id: 'a-leg', name: 'A', baseId: 'a'),
    Legend(id: 'b-leg', name: 'B', baseId: 'b'),
  ],
  hats: const [],
);

Pick chosenBase(
  Set<String> met,
  double base, {
  Catalog? catalog,
  double visitor = 0.5,
}) => pickFor(
  facts: ActivityFacts.from(run('t'), none),
  rolls: Rolls(visitor: visitor, base: base, species: 0, colour: 0.5, hat: 0.5),
  met: met,
  catalog: catalog ?? pullCatalog,
);

void main() {
  group('tiers', () {
    test('the tables', () {
      expect(
        [for (final t in completionTiers) (t.at, t.boost)],
        [(0.98, 25.0), (0.95, 10.0), (0.90, 4.0), (0.80, 1.5), (0.70, 1.25)],
      );
      expect(
        [for (final t in familyPullTiers) (t.at, t.pull)],
        [(0.98, 24.0), (0.95, 12.0), (0.90, 6.0), (0.80, 3.0), (0.70, 1.5)],
      );
    });

    test('the completion boost uses the highest threshold reached', () {
      for (final (c, expected) in [
        (0.0, 1.0),
        (0.699, 1.0),
        (139 / 200, 1.0),
        (140 / 200, 1.25),
        (0.799, 1.25),
        (0.8, 1.5),
        (0.899, 1.5),
        (0.9, 4.0),
        (0.949, 4.0),
        (0.95, 10.0),
        (0.979, 10.0),
        (0.98, 25.0),
        (1.0, 25.0),
      ]) {
        expect(completionBoost(c), expected, reason: '$c');
      }
    });

    test('the family pull uses the highest threshold reached', () {
      for (final (c, expected) in [
        (0.0, 1.0),
        (0.699, 1.0),
        (139 / 200, 1.0),
        (140 / 200, 1.5),
        (0.799, 1.5),
        (0.8, 3.0),
        (0.899, 3.0),
        (0.9, 6.0),
        (0.949, 6.0),
        (0.95, 12.0),
        (0.979, 12.0),
        (0.98, 24.0),
        (1.0, 24.0),
      ]) {
        expect(familyPull(c), expected, reason: '$c');
      }
    });
  });

  group('completionOf', () {
    final entries = {
      for (final s in defaultCatalog.species) ...[
        s.id,
        ...s.colours.map((c) => c.id),
      ],
      ...defaultCatalog.legends.where((l) => !l.isRegional).map((l) => l.id),
    };

    test('counts every entry except the regional legends', () {
      expect(entries, hasLength(89));
      expect(completionOf(defaultCatalog, const {}), 0);
      expect(completionOf(defaultCatalog, entries), 1);
      expect(completionOf(defaultCatalog, entries.take(63).toSet()), 63 / 89);
      expect(completionOf(defaultCatalog, entries.take(62).toSet()), 62 / 89);
    });

    test('a regional legend does not count', () {
      expect(completionOf(defaultCatalog, {'merlion'}), 0);
      expect(completionOf(defaultCatalog, {...entries, 'merlion'}), 1);
    });

    test('ids that are not in the catalog do not count', () {
      expect(completionOf(defaultCatalog, {'nonsense'}), 0);
    });

    test('63 of 89 is the first tier and 62 is not', () {
      expect(completionBoost(62 / 89), 1);
      expect(completionBoost(63 / 89), 1.25);
      expect(familyPull(62 / 89), 1);
      expect(familyPull(63 / 89), 1.5);
    });
  });

  group('colour slice with completion and drought', () {
    test('no boost below 70 percent', () {
      final met = metAt(139);
      expect(boosted(met, colour: 0.029).entryId, 'x-gold');
      expect(boosted(met, colour: 0.031).entryId, 'x');
    });

    test('each tier multiplies the unmet slice', () {
      for (final (entries, chance) in [
        (140, 0.0375),
        (160, 0.045),
        (180, 0.12),
        (190, 0.3),
        (196, 0.75),
      ]) {
        final met = metAt(entries);
        expect(boosted(met, colour: chance - 0.0005).entryId, 'x-gold');
        expect(boosted(met, colour: chance + 0.0005).entryId, 'x');
      }
    });

    test('the tier and the drought multiply together', () {
      final tier4 = metAt(180);
      expect(boosted(tier4, drought: 100, colour: 0.239).entryId, 'x-gold');
      expect(boosted(tier4, drought: 100, colour: 0.241).entryId, 'x');
      final tier15 = metAt(160);
      expect(boosted(tier15, drought: 300, colour: 0.179).entryId, 'x-gold');
      expect(boosted(tier15, drought: 300, colour: 0.181).entryId, 'x');
    });

    test('the slices total at most 1', () {
      final met = metAt(196, extra: {'a-leg'});
      expect(boosted(met, drought: 700, colour: 0.999999).entryId, 'x-gold');
      expect(boosted(met, drought: 100, colour: 0.999999).entryId, 'x-gold');
    });

    test('a met colour is not boosted', () {
      final met = metAt(196, extra: {'x-gold', 'a-leg'});
      expect(boosted(met, drought: 700, colour: 0.029).entryId, 'x-gold');
      expect(boosted(met, drought: 700, colour: 0.031).entryId, 'x');
    });
  });

  group('base legend with completion and drought', () {
    test('no boost below 70 percent', () {
      final met = metAt(139);
      expect(boosted(met, legend: 0.0099).entryId, 'a-leg');
      expect(boosted(met, legend: 0.011).entryId, 'x');
    });

    test('each tier multiplies the unmet legend chance', () {
      for (final (entries, chance) in [
        (140, 0.0125),
        (160, 0.015),
        (180, 0.04),
        (190, 0.1),
        (196, 0.25),
      ]) {
        final met = metAt(entries);
        expect(boosted(met, legend: chance - 0.0001).entryId, 'a-leg');
        expect(boosted(met, legend: chance + 0.0001).isLegend, isFalse);
      }
    });

    test('the tier and the drought multiply together', () {
      final met = metAt(180);
      expect(boosted(met, drought: 100, legend: 0.0799).entryId, 'a-leg');
      expect(boosted(met, drought: 100, legend: 0.0801).isLegend, isFalse);
    });

    test('the legend chance stays below 1', () {
      final met = metAt(196);
      expect(boosted(met, drought: 700, legend: 0.999999).entryId, 'a-leg');
    });

    test('a met legend is not boosted', () {
      final met = metAt(196, extra: {'a-leg'});
      expect(boosted(met, drought: 700, legend: 0.0099).entryId, 'a-leg');
      expect(boosted(met, drought: 700, legend: 0.011).isLegend, isFalse);
    });
  });

  group('regional legends', () {
    test('are not boosted by completion or drought', () {
      final entries = {
        for (final s in defaultCatalog.species) ...[
          s.id,
          ...s.colours.map((c) => c.id),
        ],
        ...defaultCatalog.legends.where((l) => !l.isRegional).map((l) => l.id),
      };
      Pick merlion(double regional) => pickFor(
        facts: ActivityFacts.from(run('t'), none),
        rolls: Rolls(
          visitor: 0.5,
          base: 0,
          species: 0.5,
          colour: 0.5,
          hat: 0.5,
          regional: regional,
        ),
        met: entries,
        drought: 700,
        catalog: defaultCatalog,
        timeZone: 'Asia/Singapore',
      );
      expect(merlion(0.0019).entryId, 'merlion');
      expect(merlion(0.0021).entryId, isNot('merlion'));
    });
  });

  group('family pull', () {
    Set<String> metWithBUnmetColour(int entries) => {
      'a1',
      'b1',
      'a-leg',
      'b-leg',
      for (var i = 0; i < entries - 4; i++) 'f$i',
    };

    test('a base with something unmet is pulled, a finished one is not', () {
      for (final (entries, pull) in [
        (139, 1.0),
        (140, 1.5),
        (160, 3.0),
        (180, 6.0),
        (190, 12.0),
        (196, 24.0),
      ]) {
        final met = metWithBUnmetColour(entries);
        final edge = 1 / (1 + pull);
        expect(chosenBase(met, edge - 0.0001).baseId, 'a', reason: '$entries');
        expect(chosenBase(met, edge + 0.0001).baseId, 'b', reason: '$entries');
      }
    });

    test('two bases with something unmet are pulled alike', () {
      final met = metWithBUnmetColour(196)..remove('a-leg');
      expect(chosenBase(met, 0.4999).baseId, 'a');
      expect(chosenBase(met, 0.5001).baseId, 'b');
    });

    test('it applies to visitor bases too', () {
      final custom = Catalog(
        bases: [
          baseOf('a', {}),
          baseOf('b', {}),
          baseOf('pad', {'Run'}),
        ],
        species: pullCatalog.species
            .map(
              (s) => Species(
                id: s.id,
                name: s.name,
                baseId: s.baseId == 'pad' ? 'pad' : s.baseId,
                colours: s.colours,
              ),
            )
            .toList(),
        legends: pullCatalog.legends,
        hats: const [],
      );
      final met = metWithBUnmetColour(180);
      expect(
        chosenBase(met, 1 / 7 - 0.0001, catalog: custom, visitor: 0.05).baseId,
        'a',
      );
      expect(
        chosenBase(met, 1 / 7 + 0.0001, catalog: custom, visitor: 0.05).baseId,
        'b',
      );
    });

    test(
      'an unmet shape species keeps its x3 and the pull multiplies on top',
      () {
        final met = {
          'a1',
          'a-leg',
          'b-leg',
          for (var i = 0; i < fillers; i++) 'f$i',
        };
        final edge = 1 / (1 + 3 * 24);
        expect(chosenBase(met, edge - 0.0001).baseId, 'a');
        expect(chosenBase(met, edge + 0.0001).baseId, 'b');
      },
    );
  });

  group('determinism', () {
    test('the same history gives the same animal', () {
      final met = {
        for (final s in defaultCatalog.species.take(60)) s.id,
        for (final l in defaultCatalog.legends.take(5)) l.id,
      };
      for (var i = 0; i < 300; i++) {
        Pick pick() => pickAnimal(
          activity: run('c$i'),
          met: met,
          drought: 250,
          holidays: none,
        );
        expect(pick(), pick());
      }
    });
  });
}
