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
final bedtime = DateTime(2026, 11, 4, 23);

Outing at(String id, DateTime start, {String kind = 'Run', int? minutes}) =>
    Outing(
      id: id,
      kind: kind,
      start: start,
      distanceKm: 5,
      minutes: minutes ?? (kind == sleepKind ? 480 : 30),
    );

final sleepHomeBases = {
  for (final b in defaultCatalog.bases)
    if (b.homeKinds.contains(sleepKind)) b.id,
};

Pick pickWithVisitorRoll(
  double visitor, {
  required String kind,
  required int recent,
  double regional = 1,
  String? timeZone,
}) => pickFor(
  facts: ActivityFacts.from(at('t', bedtime, kind: kind), none),
  rolls: Rolls(
    visitor: visitor,
    base: 0,
    species: 0.5,
    colour: 0.5,
    hat: 0.5,
    regional: regional,
  ),
  met: const {},
  catalog: defaultCatalog,
  recentExercise: recent,
  timeZone: timeZone,
);

void main() {
  final sleep = at('sleep', bedtime, kind: sleepKind);

  group('recentExercise', () {
    int count(List<Outing> known) => recentExercise(sleep, known);

    test('counts exercise that started in the 7 days before bedtime', () {
      expect(count(const []), 0);
      expect(count([at('a', bedtime.subtract(const Duration(days: 3)))]), 1);
    });

    test('the window edges', () {
      final week = bedtime.subtract(const Duration(days: 7));
      expect(count([at('on', week)]), 1);
      expect(
        count([at('before', week.subtract(const Duration(minutes: 1)))]),
        0,
      );
      expect(count([at('after', week.add(const Duration(minutes: 1)))]), 1);
      expect(
        count([at('late', bedtime.subtract(const Duration(minutes: 1)))]),
        1,
      );
    });

    test('exercise at or after bedtime does not count', () {
      expect(count([at('same', bedtime)]), 0);
      expect(count([at('later', bedtime.add(const Duration(hours: 5)))]), 0);
    });

    test('other sleeps do not count', () {
      final other = at(
        'nap',
        bedtime.subtract(const Duration(days: 1)),
        kind: sleepKind,
      );
      expect(count([other]), 0);
    });

    test('every kind of exercise counts', () {
      final known = [
        for (final (i, kind) in ['Run', 'Walk', 'Yoga', 'Workout'].indexed)
          at('k$i', bedtime.subtract(Duration(days: i + 1)), kind: kind),
      ];
      expect(count(known), 4);
    });
  });

  group('sleepVisitorScale', () {
    test('is 0, 1/3, 2/3 and 1', () {
      expect(sleepVisitorScale(0), 0);
      expect(sleepVisitorScale(1), 1 / 3);
      expect(sleepVisitorScale(2), 2 / 3);
      expect(sleepVisitorScale(3), 1);
    });

    test('stays at 1 beyond three', () {
      expect(sleepVisitorScale(4), 1);
      expect(sleepVisitorScale(50), 1);
    });
  });

  group('visitor share for sleep', () {
    bool visitor(Pick p) => !sleepHomeBases.contains(p.baseId);

    test('the share is 15 percent', () {
      expect(visitorShare, 0.15);
    });

    test('the roll decides at visitorShare × f for sleep', () {
      for (final (n, f) in [(1, 1 / 3), (2, 2 / 3), (3, 1.0), (7, 1.0)]) {
        final edge = visitorShare * f;
        expect(
          visitor(pickWithVisitorRoll(edge - 1e-6, kind: sleepKind, recent: n)),
          isTrue,
          reason: 'n=$n below',
        );
        expect(
          visitor(pickWithVisitorRoll(edge + 1e-6, kind: sleepKind, recent: n)),
          isFalse,
          reason: 'n=$n above',
        );
      }
    });

    test('with no exercise a sleep never brings a visitor', () {
      for (final roll in [0.0, 0.001, 0.07, 0.14, 0.1499]) {
        expect(
          visitor(pickWithVisitorRoll(roll, kind: sleepKind, recent: 0)),
          isFalse,
          reason: '$roll',
        );
      }
      for (var i = 0; i < 3000; i++) {
        final p = pickAnimal(
          activity: at('z$i', bedtime, kind: sleepKind),
          met: const {},
          recentExercise: 0,
          holidays: none,
        );
        expect(sleepHomeBases, contains(p.baseId));
      }
    });

    test('exercise keeps the full share whatever the week looked like', () {
      for (final kind in ['Run', 'Walk', 'Yoga']) {
        final homeIds = {
          for (final b in defaultCatalog.bases)
            if (b.homeKinds.contains(kind)) b.id,
        };
        for (final n in [0, 1, 3]) {
          final p = pickWithVisitorRoll(0.1499, kind: kind, recent: n);
          expect(homeIds, isNot(contains(p.baseId)), reason: '$kind $n');
          final q = pickWithVisitorRoll(0.1501, kind: kind, recent: n);
          expect(homeIds, contains(q.baseId), reason: '$kind $n');
        }
      }
    });

    test('a regional legend still rolls first for a sleep with f = 0', () {
      final p = pickWithVisitorRoll(
        0.5,
        kind: sleepKind,
        recent: 0,
        regional: 0.0019,
        timeZone: 'Asia/Singapore',
      );
      expect(p.entryId, 'merlion');
    });

    test('over many sleeps the share follows n', () {
      double rate(int n) {
        var visitors = 0;
        const count = 20000;
        for (var i = 0; i < count; i++) {
          final p = pickAnimal(
            activity: at('s$i', bedtime, kind: sleepKind),
            met: const {},
            recentExercise: n,
            holidays: none,
          );
          if (visitor(p)) visitors++;
        }
        return visitors / count;
      }

      expect(rate(0), 0);
      expect(rate(1), closeTo(0.05, 0.01));
      expect(rate(2), closeTo(0.10, 0.012));
      expect(rate(3), closeTo(0.15, 0.012));
    });

    test('the same activity and the same week give the same animal', () {
      for (var i = 0; i < 300; i++) {
        Pick pick() => pickAnimal(
          activity: at('d$i', bedtime, kind: sleepKind),
          met: const {'barn-owl'},
          drought: 120,
          recentExercise: 2,
          holidays: none,
        );
        expect(pick(), pick());
      }
    });
  });

  group('short sleep', () {
    const fillers = 197;

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

    Species pad(int i) => Species(id: 'f$i', name: 'F', baseId: 'pad');

    Catalog colourCatalog(Set<String> kinds) => Catalog(
      bases: [baseOf('a', kinds), baseOf('pad', {})],
      species: [
        const Species(
          id: 'x',
          name: 'X',
          baseId: 'a',
          colours: [
            ColourSpecies(
              id: 'x-gold',
              name: 'Gold',
              shapeSpeciesId: 'x',
              chance: 0.03,
            ),
          ],
        ),
        for (var i = 0; i < fillers; i++) pad(i),
      ],
      legends: const [Legend(id: 'a-leg', name: 'Leg', baseId: 'a')],
      hats: const [],
    );

    Catalog pairCatalog(Set<String> kinds) => Catalog(
      bases: [baseOf('a', kinds), baseOf('b', kinds), baseOf('pad', {})],
      species: [
        const Species(id: 'a1', name: 'A', baseId: 'a'),
        const Species(
          id: 'b1',
          name: 'B',
          baseId: 'b',
          colours: [
            ColourSpecies(
              id: 'b1-c',
              name: 'C',
              shapeSpeciesId: 'b1',
              chance: 0.1,
            ),
          ],
        ),
        for (var i = 0; i < 195; i++) pad(i),
      ],
      legends: const [
        Legend(id: 'a-leg', name: 'A', baseId: 'a'),
        Legend(id: 'b-leg', name: 'B', baseId: 'b'),
      ],
      hats: const [],
    );

    Pick at6(
      Catalog catalog, {
      required int minutes,
      String kind = sleepKind,
      Set<String> met = const {},
      int drought = 0,
      int recent = 3,
      double visitor = 0.5,
      double base = 0,
      double species = 0,
      double colour = 0.5,
      double legend = 0.5,
      double regional = 1,
      String? timeZone,
    }) => pickFor(
      facts: ActivityFacts.from(
        Outing(
          id: 't',
          kind: kind,
          start: bedtime,
          distanceKm: null,
          minutes: minutes,
        ),
        none,
      ),
      rolls: Rolls(
        visitor: visitor,
        base: base,
        species: species,
        colour: colour,
        hat: 0.5,
        regional: regional,
        legend: legend,
      ),
      met: met,
      drought: drought,
      recentExercise: recent,
      catalog: catalog,
      timeZone: timeZone,
    );

    Set<String> fillersMet(int count, [Set<String> extra = const {}]) => {
      ...extra,
      for (var i = 0; i < count - extra.length; i++) 'f$i',
    };

    test('under 360 minutes is short, 360 is not', () {
      bool short(int minutes, {String kind = sleepKind}) => ActivityFacts.from(
        Outing(
          id: 't',
          kind: kind,
          start: bedtime,
          distanceKm: null,
          minutes: minutes,
        ),
        none,
      ).isShortSleep;
      expect(short(1), isTrue);
      expect(short(239), isTrue);
      expect(short(240), isTrue);
      expect(short(359), isTrue);
      expect(short(360), isFalse);
      expect(short(540), isFalse);
      expect(short(10, kind: 'Run'), isFalse);
      expect(short(10, kind: 'Yoga'), isFalse);
    });

    test('an unmet species is not favoured', () {
      final catalog = Catalog(
        bases: [
          baseOf('a', {sleepKind}),
        ],
        species: const [
          Species(id: 'x', name: 'X', baseId: 'a'),
          Species(id: 'y', name: 'Y', baseId: 'a'),
        ],
        hats: const [],
      );
      for (final (minutes, expected) in [(359, 'x'), (360, 'y')]) {
        final p = at6(catalog, minutes: minutes, met: {'x'}, species: 0.4);
        expect(p.speciesId, expected, reason: '$minutes');
      }
      expect(
        at6(catalog, minutes: 359, met: {'x'}, species: 0.49).speciesId,
        'x',
      );
      expect(
        at6(catalog, minutes: 359, met: {'x'}, species: 0.51).speciesId,
        'y',
      );
      expect(
        at6(catalog, minutes: 360, met: {'x'}, species: 0.24).speciesId,
        'x',
      );
      expect(
        at6(catalog, minutes: 360, met: {'x'}, species: 0.26).speciesId,
        'y',
      );
    });

    test('an unmet base is not favoured', () {
      final catalog = pairCatalog({sleepKind});
      final met = {'a1', 'a-leg', 'b-leg'};
      expect(at6(catalog, minutes: 300, met: met, base: 0.4).baseId, 'a');
      expect(at6(catalog, minutes: 480, met: met, base: 0.4).baseId, 'b');
    });

    test('a short sleep never brings a visitor even after a busy week', () {
      final homeless = Catalog(
        bases: [
          baseOf('h', {sleepKind}),
          baseOf('v', {}),
        ],
        species: const [
          Species(id: 'h1', name: 'H', baseId: 'h'),
          Species(id: 'v1', name: 'V', baseId: 'v'),
        ],
        hats: const [],
      );
      for (final v in [0.0, 0.05, 0.1499]) {
        expect(
          at6(homeless, minutes: 359, visitor: v).baseId,
          'h',
          reason: '$v',
        );
        expect(
          at6(homeless, minutes: 360, visitor: v).baseId,
          'v',
          reason: '$v',
        );
      }
      for (var i = 0; i < 3000; i++) {
        final p = pickAnimal(
          activity: at('q$i', bedtime, kind: sleepKind, minutes: 300),
          met: const {},
          recentExercise: 7,
          holidays: none,
        );
        expect(sleepHomeBases, contains(p.baseId));
      }
    });

    test('no drought boost', () {
      final catalog = colourCatalog({sleepKind});
      expect(
        at6(catalog, minutes: 359, drought: 700, colour: 0.1).entryId,
        'x',
      );
      expect(
        at6(catalog, minutes: 360, drought: 700, colour: 0.1).entryId,
        'x-gold',
      );
      expect(
        at6(catalog, minutes: 359, drought: 700, legend: 0.05).isLegend,
        isFalse,
      );
      expect(
        at6(catalog, minutes: 360, drought: 700, legend: 0.05).entryId,
        'a-leg',
      );
    });

    test('no completion tier', () {
      final catalog = colourCatalog({sleepKind});
      final met = fillersMet(196);
      expect(at6(catalog, minutes: 359, met: met, colour: 0.1).entryId, 'x');
      expect(
        at6(catalog, minutes: 480, met: met, colour: 0.1).entryId,
        'x-gold',
      );
      expect(
        at6(catalog, minutes: 359, met: met, legend: 0.1).isLegend,
        isFalse,
      );
      expect(
        at6(catalog, minutes: 480, met: met, legend: 0.1).entryId,
        'a-leg',
      );
    });

    test('no family pull', () {
      final catalog = pairCatalog({sleepKind});
      final met = {
        'a1',
        'a-leg',
        'b-leg',
        'b1',
        for (var i = 0; i < 195; i++) 'f$i',
      };
      expect(at6(catalog, minutes: 359, met: met, base: 0.4).baseId, 'a');
      expect(at6(catalog, minutes: 359, met: met, base: 0.51).baseId, 'b');
      expect(at6(catalog, minutes: 480, met: met, base: 0.4).baseId, 'b');
      expect(at6(catalog, minutes: 480, met: met, base: 0.03).baseId, 'a');
    });

    test('base legends keep their plain chance', () {
      final catalog = colourCatalog({sleepKind});
      for (final drought in [0, 700]) {
        expect(
          at6(catalog, minutes: 300, drought: drought, legend: 0.0099).entryId,
          'a-leg',
        );
        expect(
          at6(catalog, minutes: 300, drought: drought, legend: 0.011).isLegend,
          isFalse,
        );
      }
    });

    test('a regional legend still rolls first', () {
      final p = at6(
        defaultCatalog,
        minutes: 120,
        regional: 0.0019,
        timeZone: 'Asia/Singapore',
      );
      expect(p.entryId, 'merlion');
    });

    test('exercise keeps every help, whatever its length', () {
      final colour = colourCatalog({'Run'});
      expect(
        at6(colour, kind: 'Run', minutes: 5, drought: 700, colour: 0.1).entryId,
        'x-gold',
      );
      expect(
        at6(
          colour,
          kind: 'Run',
          minutes: 5,
          drought: 700,
          legend: 0.05,
        ).entryId,
        'a-leg',
      );
      final pair = Catalog(
        bases: [
          baseOf('a', {'Run'}),
        ],
        species: const [
          Species(id: 'x', name: 'X', baseId: 'a'),
          Species(id: 'y', name: 'Y', baseId: 'a'),
        ],
        hats: const [],
      );
      expect(
        at6(pair, kind: 'Run', minutes: 5, met: {'x'}, species: 0.4).speciesId,
        'y',
      );
      expect(
        at6(pair, kind: 'Run', minutes: 5, met: {'x'}, species: 0.26).speciesId,
        'y',
      );
      final homeless = Catalog(
        bases: [
          baseOf('h', {'Run'}),
          baseOf('v', {}),
        ],
        species: const [
          Species(id: 'h1', name: 'H', baseId: 'h'),
          Species(id: 'v1', name: 'V', baseId: 'v'),
        ],
        hats: const [],
      );
      expect(at6(homeless, kind: 'Run', minutes: 5, visitor: 0.1).baseId, 'v');
    });

    test('a 6 hour sleep keeps the help', () {
      final catalog = colourCatalog({sleepKind});
      expect(
        at6(catalog, minutes: 360, drought: 700, colour: 0.1).entryId,
        'x-gold',
      );
    });

    test('the same short sleep gives the same animal', () {
      for (var i = 0; i < 300; i++) {
        Pick pick() => pickAnimal(
          activity: at('sh$i', bedtime, kind: sleepKind, minutes: 200),
          met: const {'barn-owl'},
          drought: 400,
          recentExercise: 3,
          holidays: none,
        );
        expect(pick(), pick());
      }
    });
  });
}
