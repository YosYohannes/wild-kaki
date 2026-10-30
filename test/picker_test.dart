import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/bands.dart';
import 'package:wildkaki/animals/catalog.dart';
import 'package:wildkaki/animals/catalog_data.dart';
import 'package:wildkaki/animals/facts.dart';
import 'package:wildkaki/animals/holidays.dart';
import 'package:wildkaki/animals/picker.dart';
import 'package:wildkaki/animals/rolls.dart';
import 'package:wildkaki/data/model.dart';

const n = 20000;
const none = NoHolidays();

const kinds = [
  'Run',
  'Walk',
  'Hike',
  'Ride',
  'Swim',
  'Climb',
  'Yoga',
  'Workout',
  'Sleep',
];

final saturdayEvening = DateTime(2026, 11, 7, 18);
final weekdayEvening = DateTime(2026, 11, 4, 18);

Outing outing(
  String id, {
  String kind = 'Run',
  DateTime? start,
  double? km = 6,
  int minutes = 30,
}) => Outing(
  id: id,
  kind: kind,
  start: start ?? weekdayEvening,
  distanceKm: km,
  minutes: minutes,
);

List<Pick> picks({
  String kind = 'Run',
  DateTime? start,
  double? km = 6,
  int minutes = 30,
  Set<String> met = const {},
  Catalog? catalog,
  int count = n,
}) => [
  for (var i = 0; i < count; i++)
    pickAnimal(
      activity: outing(
        'a$i',
        kind: kind,
        start: start,
        km: km,
        minutes: minutes,
      ),
      met: met,
      holidays: none,
      catalog: catalog,
    ),
];

Set<String> allEntries(Catalog c) => {
  ...c.species.map((s) => s.id),
  ...c.colourSpecies.map((s) => s.id),
  ...c.legends.where((l) => !l.isRegional).map((l) => l.id),
};

double share(List<Pick> list, bool Function(Pick) test) =>
    list.where(test).length / list.length;

void main() {
  final catalog = defaultCatalog;
  final everything = allEntries(catalog);
  final halfMet = {
    for (final (i, s) in catalog.species.indexed)
      if (i.isEven) s.id,
  };

  group('determinism', () {
    test('same input gives the same pick', () {
      final a = pickAnimal(
        activity: outing('same'),
        met: {'fennec'},
        holidays: none,
      );
      final b = pickAnimal(
        activity: outing('same'),
        met: {'fennec'},
        holidays: none,
      );
      expect(a, b);
    });

    test('pinned example picks', () {
      Pick pick(String id, {String kind = 'Run', DateTime? start}) =>
          pickAnimal(
            activity: outing(id, kind: kind, start: start),
            met: const {},
            holidays: none,
          );
      expect(
        pick('a0'),
        const Pick(
          baseId: 'hare',
          speciesId: 'rabbit',
          entryId: 'rabbit',
          hatId: null,
        ),
      );
      expect(
        pick('a1'),
        const Pick(
          baseId: 'fox',
          speciesId: 'red-fox',
          entryId: 'red-fox',
          hatId: null,
        ),
      );
      expect(
        pick('a0', kind: 'Swim', start: saturdayEvening),
        const Pick(
          baseId: 'otter',
          speciesId: 'beaver',
          entryId: 'beaver',
          hatId: 'bowler-hat',
        ),
      );
    });
  });

  group('home and visitor', () {
    bool isVisitor(Pick p) => p.baseId != 'fox' && p.baseId != 'hare';

    test('85 percent home with nothing met', () {
      expect(share(picks(), isVisitor), closeTo(0.15, 0.015));
    });

    test('the split never changes with discovery', () {
      final empty = picks();
      final all = picks(met: everything);
      final half = picks(met: halfMet);
      expect(share(all, isVisitor), closeTo(0.15, 0.015));
      expect(share(half, isVisitor), closeTo(0.15, 0.015));
      for (var i = 0; i < n; i++) {
        expect(isVisitor(all[i]), isVisitor(empty[i]));
        expect(isVisitor(half[i]), isVisitor(empty[i]));
      }
    });

    test('with everything unmet the two Run bases are 42.5 percent each', () {
      final list = picks();
      expect(share(list, (p) => p.baseId == 'fox'), closeTo(0.425, 0.02));
      expect(share(list, (p) => p.baseId == 'hare'), closeTo(0.425, 0.02));
    });

    test('with everything met the split of the doc holds too', () {
      final list = picks(met: everything);
      expect(share(list, (p) => p.baseId == 'fox'), closeTo(0.425, 0.02));
      expect(share(list, (p) => p.baseId == 'hare'), closeTo(0.425, 0.02));
      final others = catalog.bases.where(
        (b) => b.id != 'fox' && b.id != 'hare',
      );
      for (final b in others) {
        expect(
          share(list, (p) => p.baseId == b.id),
          closeTo(0.15 / 13, 0.006),
          reason: b.id,
        );
      }
    });

    test('a visitor is never a home base', () {
      for (final kind in ['Walk', 'Hike', 'Swim', 'Sleep']) {
        final homeIds = {
          for (final b in catalog.bases)
            if (b.homeKinds.contains(kind)) b.id,
          for (final s in catalog.species)
            if (s.alsoHomeKinds.contains(kind)) s.baseId,
        };
        final list = picks(kind: kind, count: 2000);
        final visitors = list.where((p) => !homeIds.contains(p.baseId));
        expect(visitors.length / 2000, closeTo(0.15, 0.03), reason: kind);
      }
    });

    test('Swim brings only the Kingfisher from the songbird base at home', () {
      final list = picks(kind: 'Swim', count: 5000);
      final songbirds = list.where((p) => p.baseId == 'songbird');
      final kingfisherShare =
          songbirds.where((p) => p.speciesId == 'kingfisher').length /
          songbirds.length;
      expect(kingfisherShare, greaterThan(0.85));
      expect(share(list, (p) => p.baseId == 'songbird'), closeTo(0.30, 0.03));
    });

    test('Ride allows every songbird species', () {
      final seen = {
        for (final p in picks(kind: 'Ride', count: 5000))
          if (p.baseId == 'songbird' && !p.isLegend) p.speciesId,
      };
      expect(seen, hasLength(8));
    });

    test('unknown kinds and Workout use the fox or cat bases', () {
      final unknownHome = picks(
        kind: 'Kayak',
        count: 4000,
      ).where((p) => p.baseId == 'fox');
      expect(unknownHome.length / 4000, closeTo(0.85, 0.03));
      final workout = picks(kind: 'Workout', count: 4000);
      expect(share(workout, (p) => p.baseId == 'cat'), closeTo(0.85, 0.03));
    });
  });

  group('discovery', () {
    const oneSpecies = [Hat(id: 'h', name: 'H', sprite: 'stub_hat')];

    Base base(String id, Set<String> kinds) => Base(
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

    test('an unmet base is three times as likely as a met one', () {
      final custom = Catalog(
        bases: [
          base('a', {'Run'}),
          base('b', {'Run'}),
          base('c', {}),
        ],
        species: const [
          Species(id: 'a1', name: 'A1', baseId: 'a'),
          Species(id: 'b1', name: 'B1', baseId: 'b'),
          Species(id: 'c1', name: 'C1', baseId: 'c'),
        ],
        hats: oneSpecies,
      );
      final list = picks(met: {'a1'}, catalog: custom);
      final a = list.where((p) => p.baseId == 'a').length;
      final b = list.where((p) => p.baseId == 'b').length;
      expect(b / a, closeTo(3, 0.25));
      expect(a / n, closeTo(0.85 * 0.25, 0.015));
      expect(share(list, (p) => p.baseId == 'c'), closeTo(0.15, 0.015));
    });

    test('an unmet species is three times as likely as a met one', () {
      final custom = Catalog(
        bases: [
          base('a', {'Run'}),
        ],
        species: const [
          Species(id: 'x', name: 'X', baseId: 'a'),
          Species(id: 'y', name: 'Y', baseId: 'a'),
        ],
        hats: oneSpecies,
      );
      final list = picks(met: {'x'}, catalog: custom);
      final x = list.where((p) => p.speciesId == 'x').length;
      final y = list.where((p) => p.speciesId == 'y').length;
      expect(y / x, closeTo(3, 0.2));
    });

    test('a shape species is met when one of its colour species is met', () {
      final custom = Catalog(
        bases: [
          base('a', {'Run'}),
          base('b', {'Run'}),
        ],
        species: const [
          Species(
            id: 'a1',
            name: 'A1',
            baseId: 'a',
            colours: [
              ColourSpecies(
                id: 'a1-gold',
                name: 'Gold',
                shapeSpeciesId: 'a1',
                chance: 0.03,
              ),
            ],
          ),
          Species(id: 'b1', name: 'B1', baseId: 'b'),
        ],
        hats: oneSpecies,
      );
      final list = picks(met: {'a1-gold'}, catalog: custom);
      final a = list.where((p) => p.baseId == 'a').length;
      final b = list.where((p) => p.baseId == 'b').length;
      expect(b / a, closeTo(3, 0.25));
    });

    test('unmet colour species do not make a base unmet', () {
      final tabbyOnly = {for (final s in catalog.speciesOf('cat')) s.id};
      final list = picks(kind: 'Yoga', met: tabbyOnly);
      expect(share(list, (p) => p.baseId == 'cat'), closeTo(0.85, 0.015));
    });

    test('a visitor base keeps its place and is three times as likely', () {
      final allButSongbird = {
        for (final s in catalog.species)
          if (s.baseId != 'songbird') s.id,
      };
      final list = picks(met: allButSongbird);
      final songbird = share(list, (p) => p.baseId == 'songbird');
      final other = share(list, (p) => p.baseId == 'owl');
      expect(songbird, closeTo(0.15 * 3 / 14, 0.008));
      expect(other, closeTo(0.15 / 14, 0.005));
    });
  });

  group('affinities shape the species', () {
    double weight(Species s, ActivityFacts f) =>
        f.bands.map((b) => s.affinityFor(b).weight).fold(1.0, (a, b) => a * b);

    final example = outing('x', start: saturdayEvening, km: 6, minutes: 30);
    final facts = ActivityFacts.from(example, none);

    test('the doc example is Twilight, Medium, Medium, Fast', () {
      expect(facts.partOfDay, PartOfDay.twilight);
      expect(facts.lengthBand, LengthBand.medium);
      expect(facts.distanceBand, DistanceBand.medium);
      expect(facts.speedBand, SpeedBand.fast);
      expect(facts.dayOff, isTrue);
    });

    test('the doc worked example, everything met', () {
      final list = picks(start: saturdayEvening, met: everything);
      double expected(String baseId, String speciesId) {
        final all = catalog.speciesOf(baseId);
        final total = all.map((s) => weight(s, facts)).reduce((a, b) => a + b);
        return 0.425 * weight(catalog.speciesById(speciesId)!, facts) / total;
      }

      for (final (base, sp, doc) in [
        ('fox', 'fennec', 0.24),
        ('fox', 'red-fox', 0.12),
        ('fox', 'grey-fox', 0.06),
        ('hare', 'hare', 0.24),
        ('hare', 'rabbit', 0.12),
        ('hare', 'jackrabbit', 0.06),
      ]) {
        final measured = share(list, (p) => p.speciesId == sp);
        expect(measured, closeTo(expected(base, sp), 0.015), reason: sp);
        expect(expected(base, sp), closeTo(doc, 0.005), reason: sp);
      }
      expect(
        share(list, (p) => p.entryId == 'silver-fox'),
        closeTo(0.425 * 2 / 7 * 0.12, 0.005),
      );
      expect(
        share(list, (p) => p.entryId == 'arctic-fox'),
        closeTo(0.425 * 2 / 7 * 0.03, 0.003),
      );
      expect(
        share(list, (p) => p.entryId == 'snow-hare'),
        closeTo(0.425 * 4 / 7 * 0.03, 0.004),
      );
    });

    test('avoids and neutral weights', () {
      final list = picks(
        kind: 'Walk',
        start: DateTime(2026, 11, 4, 10),
        km: 5,
        minutes: 120,
        met: everything,
      );
      final f = ActivityFacts.from(
        outing(
          'x',
          kind: 'Walk',
          start: DateTime(2026, 11, 4, 10),
          km: 5,
          minutes: 120,
        ),
        none,
      );
      final dogs = catalog.speciesOf('dog');
      final total = dogs.map((s) => weight(s, f)).reduce((a, b) => a + b);
      for (final s in dogs) {
        final expected =
            0.85 *
            weight(s, f) /
            total *
            (1 - s.colours.fold(0.0, (a, c) => a + c.chance));
        expect(
          share(list, (p) => p.entryId == s.id),
          closeTo(expected, 0.012),
          reason: s.id,
        );
      }
    });

    test('unknown bands are neutral', () {
      final list = picks(
        kind: 'Yoga',
        km: null,
        minutes: 45,
        start: DateTime(2026, 11, 4, 10),
        met: everything,
      );
      final f = ActivityFacts.from(
        outing(
          'x',
          kind: 'Yoga',
          km: null,
          minutes: 45,
          start: DateTime(2026, 11, 4, 10),
        ),
        none,
      );
      final cats = catalog.speciesOf('cat');
      final total = cats.map((s) => weight(s, f)).reduce((a, b) => a + b);
      final tabby = cats.firstWhere((s) => s.id == 'tabby');
      expect(
        share(list, (p) => p.speciesId == 'tabby'),
        closeTo(0.85 * weight(tabby, f) / total, 0.012),
      );
    });
  });

  group('colour', () {
    test('Tabby turns into Black cat 12 percent and Golden cat 3 percent', () {
      final list = picks(kind: 'Yoga', km: null, count: 40000, met: everything);
      final tabbies = list.where((p) => p.speciesId == 'tabby').toList();
      expect(tabbies.length, greaterThan(3000));
      expect(
        share(tabbies, (p) => p.entryId == 'black-cat'),
        closeTo(0.12, 0.02),
      );
      expect(
        share(tabbies, (p) => p.entryId == 'golden-cat'),
        closeTo(0.03, 0.01),
      );
      expect(share(tabbies, (p) => p.entryId == 'tabby'), closeTo(0.85, 0.02));
    });

    test('the colour is chosen by slices of the roll', () {
      for (final p in picks(count: 3000, met: everything)) {
        if (p.isLegend) continue;
        final colours = catalog
            .speciesById(p.speciesId)!
            .colours
            .map((c) => c.id);
        expect([p.speciesId, ...colours], contains(p.entryId));
      }
    });

    test('discovery does not touch the colour chance', () {
      final unmet = picks(kind: 'Yoga', km: null, count: 40000);
      final tabbies = unmet.where((p) => p.speciesId == 'tabby').toList();
      expect(
        share(tabbies, (p) => p.entryId == 'golden-cat'),
        closeTo(0.03, 0.01),
      );
    });
  });

  group('hat', () {
    test('no hat on a weekday', () {
      expect(picks(count: 2000).every((p) => p.hatId == null), isTrue);
    });

    test('five hats, 20 percent each, on a Saturday', () {
      final list = picks(start: saturdayEvening);
      expect(list.every((p) => p.hatId != null), isTrue);
      for (final hat in catalog.hats) {
        expect(
          share(list, (p) => p.hatId == hat.id),
          closeTo(0.2, 0.015),
          reason: hat.id,
        );
      }
    });

    test('a public holiday gives a hat when the provider says so', () {
      final cny = DateTime(2026, 2, 17, 10);
      final p = pickAnimal(
        activity: outing('a1', start: cny),
        met: const {},
        holidays: singapore,
      );
      expect(p.hatId, isNotNull);
      final q = pickAnimal(
        activity: outing('a1', start: cny),
        met: const {},
        holidays: none,
      );
      expect(q.hatId, isNull);
    });

    test('the hat never changes which animal is picked', () {
      final weekday = picks(count: 500);
      final saturday = picks(count: 500, start: DateTime(2026, 11, 7, 18));
      for (var i = 0; i < 500; i++) {
        expect(saturday[i].entryId, weekday[i].entryId);
      }
    });
  });

  group('fuzz', () {
    test('no pick fails for random facts and met sets', () {
      final random = Random(7);
      const kinds = [
        'Run',
        'Walk',
        'Hike',
        'Ride',
        'Swim',
        'Climb',
        'Yoga',
        'Workout',
        'Sleep',
        'Kayak',
        '',
      ];
      final entries = everything.toList();
      for (var i = 0; i < 5000; i++) {
        final kind = kinds[random.nextInt(kinds.length)];
        final start = DateTime(
          2026,
          1,
          1,
        ).add(Duration(minutes: random.nextInt(2 * 365 * 24 * 60)));
        final km = switch (random.nextInt(4)) {
          0 => null,
          1 => 0.0,
          _ => random.nextDouble() * 80,
        };
        final minutes = random.nextInt(700) - 5;
        final met = {
          for (final e in entries)
            if (random.nextDouble() < random.nextDouble()) e,
        };
        final activity = Outing(
          id: 'fuzz-${random.nextInt(1 << 30)}',
          kind: kind,
          start: start,
          distanceKm: km,
          minutes: minutes,
        );
        final pick = pickAnimal(
          activity: activity,
          met: met,
          holidays: singapore,
        );
        final facts = ActivityFacts.from(activity, singapore);
        expect(catalog.baseById(pick.baseId), isNotNull);
        if (pick.isLegend) {
          final legend = catalog.legends.firstWhere(
            (l) => l.id == pick.entryId,
          );
          expect(legend.baseId, pick.baseId);
        } else {
          final s = catalog.speciesById(pick.speciesId)!;
          expect(s.baseId, pick.baseId);
          expect(
            pick.entryId == s.id || s.colours.any((c) => c.id == pick.entryId),
            isTrue,
          );
        }
        expect(pick.hatId != null, facts.dayOff);
        if (pick.hatId != null) {
          expect(catalog.hats.map((h) => h.id), contains(pick.hatId));
        }
      }
    });
  });

  group('legends', () {
    String? idWhere(bool Function(String) test, [String prefix = 'leg']) {
      for (var i = 0; i < 200000; i++) {
        if (test('$prefix-$i')) return '$prefix-$i';
      }
      return null;
    }

    Pick pickIn(
      String id,
      String? zone, {
      String kind = 'Run',
      DateTime? start,
    }) => pickAnimal(
      activity: outing(id, kind: kind, start: start),
      met: const {},
      holidays: none,
      timeZone: zone,
    );

    test('the chances', () {
      expect(regionalLegendChance, 0.002);
      expect(legendChance, 0.01);
      expect(likedLegendChance, 0.02);
    });

    test('a regional legend appears only in its zone', () {
      final id = idWhere((id) => roll('regional', id) < regionalLegendChance)!;
      final inSingapore = pickIn(id, 'Asia/Singapore');
      expect(inSingapore.entryId, 'merlion');
      expect(inSingapore.baseId, 'otter');
      expect(inSingapore.isLegend, isTrue);
      expect(pickIn(id, 'Europe/Berlin').entryId, isNot('merlion'));
      expect(pickIn(id, null).entryId, isNot('merlion'));
      expect(pickIn(id, 'Asia/Bangkok').entryId, 'naga');
      expect(pickIn(id, 'Europe/London').entryId, 'nessie');
    });

    test('the regional legend comes before the kind and the base', () {
      final id = idWhere((id) => roll('regional', id) < regionalLegendChance)!;
      for (final kind in kinds) {
        expect(pickIn(id, 'Europe/London', kind: kind).entryId, 'nessie');
      }
    });

    test('an id over the regional chance does not get one', () {
      final id = idWhere((id) => roll('regional', id) >= regionalLegendChance)!;
      final inSingapore = pickIn(id, 'Asia/Singapore');
      expect(inSingapore.entryId, isNot('merlion'));
    });

    test('regional legends come about 1 in 500 in their zone', () {
      var hits = 0;
      for (var i = 0; i < 100000; i++) {
        if (pickIn('r$i', 'Asia/Singapore').entryId == 'merlion') hits++;
      }
      expect(hits / 100000, closeTo(0.002, 0.001));
    });

    test('a base legend comes about 1 percent of the time', () {
      final list = picks(kind: 'Run', start: weekdayEvening);
      final legends = list.where((p) => p.isLegend).toList();
      expect(legends.length / n, closeTo(0.01, 0.005));
      for (final p in legends) {
        final legend = catalog.legends.firstWhere((l) => l.id == p.entryId);
        expect(legend.isRegional, isFalse);
        expect(legend.baseId, p.baseId);
        expect(p.speciesId, p.entryId);
      }
    });

    test('a base legend comes about 2 percent when the liked band matches', () {
      final twilight = picks(kind: 'Run', start: weekdayEvening);
      final foxes = twilight.where((p) => p.baseId == 'fox').toList();
      expect(share(foxes, (p) => p.entryId == 'kitsune'), closeTo(0.02, 0.008));
      final night = picks(kind: 'Run', start: DateTime(2026, 11, 4, 23));
      final nightFoxes = night.where((p) => p.baseId == 'fox').toList();
      expect(
        share(nightFoxes, (p) => p.entryId == 'kitsune'),
        closeTo(0.01, 0.006),
      );
    });

    test('the legend roll decides at the exact thresholds', () {
      final base = catalog.baseById('fox')!;
      final facts = ActivityFacts.from(
        outing('t', start: weekdayEvening),
        none,
      );
      expect(facts.partOfDay, PartOfDay.twilight);
      Pick at(double legend, ActivityFacts f) => pickFor(
        facts: f,
        rolls: Rolls(
          visitor: 0.5,
          base: 0,
          species: 0.5,
          colour: 0.5,
          hat: 0.5,
          legend: legend,
        ),
        met: const {},
        catalog: catalog,
      );
      expect(base.id, 'fox');
      expect(at(0.0199, facts).entryId, 'kitsune');
      expect(at(0.02, facts).isLegend, isFalse);
      final night = ActivityFacts.from(
        outing('t', start: DateTime(2026, 11, 4, 23)),
        none,
      );
      expect(at(0.0099, night).entryId, 'kitsune');
      expect(at(0.01, night).isLegend, isFalse);
    });

    test('legends get no discovery multiplier', () {
      final unmet = picks(kind: 'Run', count: 20000);
      final met = picks(kind: 'Run', count: 20000, met: everything);
      expect(
        share(unmet, (p) => p.isLegend),
        closeTo(share(met, (p) => p.isLegend), 0.004),
      );
    });

    test('legends wear a hat on a day off and none on a weekday', () {
      final off = picks(
        start: saturdayEvening,
        count: 20000,
      ).where((p) => p.isLegend).toList();
      expect(off, isNotEmpty);
      expect(
        off.every((p) => catalog.hats.any((h) => h.id == p.hatId)),
        isTrue,
      );
      final id = idWhere((id) => roll('regional', id) < regionalLegendChance)!;
      expect(
        pickIn(id, 'Asia/Singapore', start: saturdayEvening).hatId,
        isNotNull,
      );
      expect(pickIn(id, 'Asia/Singapore').hatId, isNull);
      final weekday = picks(count: 20000).where((p) => p.isLegend);
      expect(weekday.every((p) => p.hatId == null), isTrue);
    });
  });

  group('picks without a legend are the picks from before legends', () {
    const pinned = [
      ('base-0', 'Run', true, 'hare', 'jackrabbit', 'jackrabbit', 'beanie'),
      ('base-1', 'Walk', false, 'dog', 'dachshund', 'dachshund', null),
      (
        'base-2',
        'Hike',
        false,
        'squirrel',
        'flying-squirrel',
        'flying-squirrel',
        null,
      ),
      ('base-3', 'Ride', true, 'songbird', 'pigeon', 'pigeon', 'bowler-hat'),
      ('base-4', 'Swim', false, 'waterfowl', 'moorhen', 'moorhen', null),
      (
        'base-5',
        'Climb',
        false,
        'small-deer',
        'mouse-deer',
        'mouse-deer',
        null,
      ),
      ('base-6', 'Yoga', true, 'cat', 'tabby', 'tabby', 'beanie'),
      ('base-7', 'Workout', false, 'cat', 'siamese', 'siamese', null),
      ('base-8', 'Sleep', false, 'mouse', 'hamster', 'hamster', null),
      ('base-9', 'Run', true, 'fox', 'fennec', 'fennec', 'party-hat'),
      ('base-10', 'Walk', false, 'dog', 'husky', 'husky', null),
      (
        'base-11',
        'Hike',
        false,
        'squirrel',
        'flying-squirrel',
        'flying-squirrel',
        null,
      ),
      ('base-12', 'Ride', true, 'songbird', 'crow', 'crow', 'top-hat'),
      ('base-13', 'Swim', false, 'waterfowl', 'grebe', 'grebe', null),
      (
        'base-14',
        'Climb',
        false,
        'squirrel',
        'flying-squirrel',
        'flying-squirrel',
        null,
      ),
      ('base-15', 'Yoga', true, 'cat', 'tabby', 'tabby', 'sombrero'),
      ('base-16', 'Workout', false, 'otter', 'beaver', 'beaver', null),
      ('base-17', 'Sleep', false, 'mouse', 'hamster', 'hamster', null),
      ('base-18', 'Run', true, 'fox', 'grey-fox', 'grey-fox', 'sombrero'),
      ('base-19', 'Walk', false, 'dog', 'husky', 'husky', null),
      (
        'base-20',
        'Hike',
        false,
        'squirrel',
        'flying-squirrel',
        'flying-squirrel',
        null,
      ),
      (
        'base-21',
        'Ride',
        true,
        'squirrel',
        'flying-squirrel',
        'flying-squirrel',
        'sombrero',
      ),
      ('base-22', 'Swim', false, 'otter', 'beaver', 'beaver', null),
      ('base-23', 'Climb', false, 'fox', 'grey-fox', 'grey-fox', null),
      ('base-24', 'Yoga', true, 'cat', 'tabby', 'tabby', 'party-hat'),
      (
        'base-25',
        'Workout',
        false,
        'cat',
        'scottish-fold',
        'scottish-fold',
        null,
      ),
      ('base-26', 'Sleep', false, 'owl', 'barn-owl', 'barn-owl', null),
      ('base-27', 'Run', true, 'fox', 'fennec', 'fennec', 'beanie'),
      ('base-28', 'Walk', false, 'dog', 'terrier', 'terrier', null),
      (
        'base-29',
        'Hike',
        false,
        'squirrel',
        'flying-squirrel',
        'flying-squirrel',
        null,
      ),
      ('base-30', 'Ride', true, 'songbird', 'robin', 'robin', 'beanie'),
      ('base-31', 'Swim', false, 'songbird', 'kingfisher', 'kingfisher', null),
      ('base-32', 'Climb', false, 'lizard', 'chameleon', 'chameleon', null),
      (
        'base-33',
        'Yoga',
        true,
        'cat',
        'scottish-fold',
        'scottish-fold',
        'bowler-hat',
      ),
      (
        'base-34',
        'Workout',
        false,
        'cat',
        'scottish-fold',
        'scottish-fold',
        null,
      ),
      ('base-35', 'Sleep', false, 'bat', 'fruit-bat', 'fruit-bat', null),
    ];

    test('a pinned sample of ids', () {
      for (final (id, kind, saturday, baseId, speciesId, entryId, hatId)
          in pinned) {
        final start = saturday ? saturdayEvening : DateTime(2026, 11, 4, 22);
        final p = pickAnimal(
          activity: outing(id, kind: kind, start: start),
          met: const {},
          holidays: none,
        );
        expect(
          p,
          Pick(
            baseId: baseId,
            speciesId: speciesId,
            entryId: entryId,
            hatId: hatId,
          ),
          reason: id,
        );
      }
    });

    test(
      'with the legend and regional rolls out of range the pick is the same',
      () {
        for (var i = 0; i < 5000; i++) {
          final id = 'same-$i';
          final all = Rolls.of(id);
          if (all.legend < likedLegendChance) continue;
          final facts = ActivityFacts.from(
            outing(id, kind: kinds[i % kinds.length], start: saturdayEvening),
            none,
          );
          final before = Rolls(
            visitor: all.visitor,
            base: all.base,
            species: all.species,
            colour: all.colour,
            hat: all.hat,
          );
          final met = i.isEven ? halfMet : const <String>{};
          expect(
            pickFor(
              facts: facts,
              rolls: all,
              met: met,
              catalog: catalog,
              timeZone: 'Europe/Berlin',
            ),
            pickFor(facts: facts, rolls: before, met: met, catalog: catalog),
            reason: id,
          );
        }
      },
    );
  });
}
