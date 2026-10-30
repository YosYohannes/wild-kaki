import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/catalog.dart';
import 'package:wildkaki/animals/catalog_data.dart';
import 'package:wildkaki/animals/boosts.dart';
import 'package:wildkaki/animals/facts.dart';
import 'package:wildkaki/animals/holidays.dart';
import 'package:wildkaki/animals/picker.dart';
import 'package:wildkaki/animals/rolls.dart';
import 'package:wildkaki/data/model.dart';

const none = NoHolidays();

Outing run(String id, {DateTime? start}) => Outing(
  id: id,
  kind: 'Run',
  start: start ?? DateTime(2026, 11, 4, 18),
  distanceKm: 6,
  minutes: 30,
);

Sighting seen(String animal, int hour, {int? order}) => Sighting(
  run('o$hour', start: DateTime(2026, 10, 1, hour)),
  animal,
  order: order,
);

final base = Base(
  id: 'a',
  name: 'a',
  homeKinds: const {'Run'},
  habitat: Habitat.meadow,
  sound: 'yip',
  bubble: 'x',
  arrival: '{activity}',
  frames: const ['stub_fox_1'],
  headPoints: const [(x: 0, y: 0)],
);

Catalog catalogWith({
  List<ColourSpecies> colours = const [],
  List<Legend> legends = const [],
}) => Catalog(
  bases: [base],
  species: [Species(id: 'x', name: 'X', baseId: 'a', colours: colours)],
  legends: legends,
  hats: const [],
);

const gold = ColourSpecies(
  id: 'x-gold',
  name: 'Gold',
  shapeSpeciesId: 'x',
  chance: 0.03,
);
const blue = ColourSpecies(
  id: 'x-blue',
  name: 'Blue',
  shapeSpeciesId: 'x',
  chance: 0.12,
);

Pick pickWith(
  Catalog catalog, {
  Set<String> met = const {},
  int drought = 0,
  double colour = 0.5,
  double legend = 0.5,
  double regional = 1,
  String? timeZone,
}) => pickFor(
  facts: ActivityFacts.from(run('t'), none),
  rolls: Rolls(
    visitor: 0.5,
    base: 0,
    species: 0,
    colour: colour,
    hat: 0.5,
    regional: regional,
    legend: legend,
  ),
  met: met,
  drought: drought,
  catalog: catalog,
  timeZone: timeZone,
);

void main() {
  group('droughtSince', () {
    test('no sightings is zero', () {
      expect(droughtSince(const []), 0);
    });

    test('every sighting new is zero', () {
      expect(droughtSince(['a', 'b', 'c']), 0);
    });

    test('counts the repeats after the last new entry', () {
      expect(droughtSince(['a', 'b', 'a', 'b', 'a']), 3);
      expect(droughtSince(['a', 'a', 'b', 'a', 'a', 'b']), 3);
    });

    test('a repeat run resets when something new shows up', () {
      expect(droughtSince(['a', 'a', 'a', 'b']), 0);
      expect(droughtSince(['a', 'a', 'a', 'b', 'a']), 1);
    });

    test('a colour is a new entry even when its shape was met', () {
      expect(droughtSince(['tabby', 'tabby', 'black-cat']), 0);
    });
  });

  group('inRevealOrder', () {
    test('follows the reveal order, not the start time', () {
      final list = [
        seen('c', 5, order: 1),
        seen('a', 3, order: 3),
        seen('b', 1, order: 2),
      ];
      expect(inRevealOrder(list), ['c', 'b', 'a']);
    });

    test('sightings from before the order was kept come first, by start', () {
      final list = [seen('new', 2, order: 1), seen('old2', 9), seen('old1', 4)];
      expect(inRevealOrder(list), ['old1', 'old2', 'new']);
    });

    test('drought uses the reveal order', () {
      final list = [
        seen('fox', 5, order: 1),
        seen('cat', 1, order: 2),
        seen('fox', 3, order: 3),
        seen('fox', 2, order: 4),
      ];
      expect(droughtSince(inRevealOrder(list)), 2);
    });
  });

  group('droughtBoost', () {
    test('constants', () {
      expect(droughtStep, 100);
      expect(droughtCap, 8.0);
    });

    test('is 1 at zero, 2 at 100 and grows by 1 per 100', () {
      expect(droughtBoost(0), 1);
      expect(droughtBoost(50), 1.5);
      expect(droughtBoost(100), 2);
      expect(droughtBoost(300), 4);
    });

    test('is capped at 8', () {
      expect(droughtBoost(700), 8);
      expect(droughtBoost(701), 8);
      expect(droughtBoost(100000), 8);
    });
  });

  group('colour species', () {
    final catalog = catalogWith(colours: [blue, gold]);

    test('an unmet colour slice grows with the drought', () {
      expect(pickWith(catalog, colour: 0.20).entryId, 'x');
      expect(pickWith(catalog, colour: 0.20, drought: 100).entryId, 'x-blue');
      expect(pickWith(catalog, colour: 0.20, drought: 100).speciesId, 'x');
    });

    test('the slices are scaled in order', () {
      expect(pickWith(catalog, colour: 0.299).entryId, 'x');
      expect(pickWith(catalog, colour: 0.299, drought: 100).entryId, 'x-gold');
      expect(pickWith(catalog, colour: 0.239, drought: 100).entryId, 'x-blue');
      expect(pickWith(catalog, colour: 0.241, drought: 100).entryId, 'x-gold');
      expect(pickWith(catalog, colour: 0.301, drought: 100).entryId, 'x');
    });

    test('a met colour keeps its slice while an unmet one grows', () {
      final met = {'x-blue'};
      expect(
        pickWith(catalog, met: met, colour: 0.13, drought: 700).entryId,
        'x-gold',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.359, drought: 700).entryId,
        'x-gold',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.361, drought: 700).entryId,
        'x',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.119, drought: 700).entryId,
        'x-blue',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.9, drought: 700).entryId,
        'x',
      );
    });

    test('met colours are never boosted', () {
      final met = {'x-blue', 'x-gold'};
      expect(
        pickWith(catalog, met: met, colour: 0.20, drought: 700).entryId,
        'x',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.119, drought: 700).entryId,
        'x-blue',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.149, drought: 700).entryId,
        'x-gold',
      );
      expect(
        pickWith(catalog, met: met, colour: 0.151, drought: 700).entryId,
        'x',
      );
    });

    test('the slices of a species never add up to more than 1', () {
      final big = catalogWith(
        colours: const [
          ColourSpecies(id: 'x-a', name: 'A', shapeSpeciesId: 'x', chance: 0.6),
          ColourSpecies(id: 'x-b', name: 'B', shapeSpeciesId: 'x', chance: 0.3),
        ],
      );
      for (final roll in [0.0, 0.5, 0.999999]) {
        expect(pickWith(big, colour: roll, drought: 700).entryId, 'x-a');
      }
      final split = catalogWith(
        colours: const [
          ColourSpecies(id: 'x-a', name: 'A', shapeSpeciesId: 'x', chance: 0.1),
          ColourSpecies(id: 'x-b', name: 'B', shapeSpeciesId: 'x', chance: 0.5),
        ],
      );
      expect(pickWith(split, colour: 0.79, drought: 700).entryId, 'x-a');
      expect(pickWith(split, colour: 0.81, drought: 700).entryId, 'x-b');
      expect(pickWith(split, colour: 0.999999, drought: 700).entryId, 'x-b');
    });
  });

  group('base legends', () {
    final catalog = defaultCatalog;

    Pick fox(
      double legend, {
      Set<String> met = const {},
      int drought = 0,
      DateTime? start,
    }) => pickFor(
      facts: ActivityFacts.from(
        run('t', start: start ?? DateTime(2026, 11, 4, 23)),
        none,
      ),
      rolls: Rolls(
        visitor: 0.5,
        base: 0,
        species: 0.5,
        colour: 0.5,
        hat: 0.5,
        legend: legend,
      ),
      met: met,
      drought: drought,
      catalog: catalog,
    );

    test('an unmet legend is boosted', () {
      expect(fox(0.05).isLegend, isFalse);
      expect(fox(0.05, drought: 100).isLegend, isFalse);
      expect(fox(0.019, drought: 100).entryId, 'kitsune');
      expect(fox(0.049, drought: 400).entryId, 'kitsune');
      expect(fox(0.079, drought: 700).entryId, 'kitsune');
      expect(fox(0.081, drought: 700).isLegend, isFalse);
    });

    test('the cap holds beyond 700', () {
      expect(fox(0.081, drought: 100000).isLegend, isFalse);
    });

    test('the liked chance is boosted too', () {
      final twilight = DateTime(2026, 11, 4, 18);
      expect(fox(0.10, start: twilight).isLegend, isFalse);
      expect(fox(0.10, start: twilight, drought: 400).isLegend, isFalse);
      expect(fox(0.079, start: twilight, drought: 400).entryId, 'kitsune');
      expect(fox(0.159, start: twilight, drought: 700).entryId, 'kitsune');
      expect(fox(0.161, start: twilight, drought: 700).isLegend, isFalse);
    });

    test('a met legend is not boosted', () {
      final met = {'kitsune'};
      expect(fox(0.05, met: met, drought: 700).isLegend, isFalse);
      expect(fox(0.0099, met: met, drought: 700).entryId, 'kitsune');
      expect(fox(0.011, met: met, drought: 700).isLegend, isFalse);
    });

    test('a regional legend is not boosted', () {
      Pick merlion(double regional, int drought) => pickWith(
        catalog,
        regional: regional,
        drought: drought,
        timeZone: 'Asia/Singapore',
      );
      expect(merlion(0.0019, 0).entryId, 'merlion');
      expect(merlion(0.0019, 700).entryId, 'merlion');
      expect(merlion(0.0021, 700).entryId, isNot('merlion'));
      expect(merlion(0.0021, 100000).entryId, isNot('merlion'));
    });
  });

  group('shape species', () {
    test('keep the x3 discovery whatever the drought', () {
      final other = Species(id: 'y', name: 'Y', baseId: 'a');
      final catalog = Catalog(
        bases: [base],
        species: [
          Species(id: 'x', name: 'X', baseId: 'a'),
          other,
        ],
        hats: const [],
      );
      Pick at(double species, int drought) => pickFor(
        facts: ActivityFacts.from(run('t'), none),
        rolls: Rolls(
          visitor: 0.5,
          base: 0,
          species: species,
          colour: 0.5,
          hat: 0.5,
        ),
        met: const {'x'},
        drought: drought,
        catalog: catalog,
      );
      for (final drought in [0, 700]) {
        expect(at(0.24, drought).speciesId, 'x');
        expect(at(0.26, drought).speciesId, 'y');
      }
    });
  });

  group('determinism', () {
    test('the same activity, history and drought give the same animal', () {
      for (var i = 0; i < 300; i++) {
        final a = pickAnimal(
          activity: run('d$i'),
          met: const {'fennec'},
          drought: 250,
          holidays: none,
        );
        final b = pickAnimal(
          activity: run('d$i'),
          met: const {'fennec'},
          drought: 250,
          holidays: none,
        );
        expect(a, b);
      }
    });

    test('a drought of zero is the plain pick', () {
      for (var i = 0; i < 300; i++) {
        expect(
          pickAnimal(activity: run('z$i'), met: const {}, holidays: none),
          pickAnimal(
            activity: run('z$i'),
            met: const {},
            drought: 0,
            holidays: none,
          ),
        );
      }
    });
  });

  group('over many activities', () {
    test('a long drought makes unmet colours and legends more common', () {
      List<Pick> many(int drought) => [
        for (var i = 0; i < 30000; i++)
          pickAnimal(
            activity: run('m$i'),
            met: const {},
            drought: drought,
            holidays: none,
          ),
      ];
      final calm = many(0);
      final dry = many(700);
      int legends(List<Pick> l) => l.where((p) => p.isLegend).length;
      int colours(List<Pick> l) =>
          l.where((p) => p.entryId != p.speciesId && !p.isLegend).length;
      expect(legends(dry), greaterThan(legends(calm) * 5));
      expect(colours(dry), greaterThan(colours(calm) * 5));
    });
  });
}
