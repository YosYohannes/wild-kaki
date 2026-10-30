import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/bands.dart';
import 'package:wildkaki/animals/catalog.dart';
import 'package:wildkaki/animals/catalog_data.dart';
import 'package:wildkaki/animals/lookup.dart';
import 'package:wildkaki/animals/notes_data.dart';
import 'package:wildkaki/animals/picker.dart';

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

Species species(String id) => defaultCatalog.speciesById(id)!;

void main() {
  final catalog = defaultCatalog;
  final kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  test('counts', () {
    expect(catalog.bases, hasLength(15));
    expect(catalog.species, hasLength(58));
    expect(catalog.colourSpecies, hasLength(16));
    expect(catalog.legends.where((l) => !l.isRegional), hasLength(15));
    expect(catalog.legends.where((l) => l.isRegional), hasLength(5));
    expect(animalEntries, hasLength(94));
    expect(catalog.hats, hasLength(5));
  });

  test('ids are unique kebab-case', () {
    final baseIds = catalog.bases.map((b) => b.id).toList();
    expect(baseIds.toSet(), hasLength(baseIds.length));
    final entryIds = [
      ...catalog.species.map((s) => s.id),
      ...catalog.colourSpecies.map((c) => c.id),
      ...catalog.legends.map((l) => l.id),
    ];
    expect(entryIds.toSet(), hasLength(entryIds.length));
    final hatIds = catalog.hats.map((h) => h.id).toList();
    expect(hatIds.toSet(), hasLength(5));
    for (final id in [...baseIds, ...entryIds, ...hatIds]) {
      expect(id, matches(kebab));
    }
  });

  test('every species has a base and every base has a species', () {
    for (final s in catalog.species) {
      expect(catalog.baseById(s.baseId), isNotNull, reason: s.id);
    }
    for (final b in catalog.bases) {
      expect(catalog.speciesOf(b.id), isNotEmpty, reason: b.id);
    }
  });

  test('colour species point at their shape species and stay below 100%', () {
    for (final s in catalog.species) {
      var total = 0.0;
      for (final c in s.colours) {
        expect(c.shapeSpeciesId, s.id);
        expect(catalog.speciesById(c.shapeSpeciesId), isNotNull);
        expect(c.chance, greaterThan(0));
        total += c.chance;
      }
      expect(total, lessThan(1), reason: s.id);
    }
  });

  test('affinities are on real band values', () {
    final all = <Band>{
      ...PartOfDay.values,
      ...LengthBand.values,
      ...DistanceBand.values,
      ...SpeedBand.values,
    };
    for (final s in catalog.species) {
      for (final entry in s.affinities.entries) {
        expect(all, contains(entry.key), reason: s.id);
        expect(entry.value, isNot(Affinity.neutral), reason: s.id);
      }
    }
  });

  test('affinity weights', () {
    expect(Affinity.avoids.weight, 0.25);
    expect(Affinity.neutral.weight, 1);
    expect(Affinity.likes.weight, 2);
    expect(Affinity.loves.weight, 4);
  });

  test('frames, head points and hats are present', () {
    for (final b in catalog.bases) {
      expect(b.frames, isNotEmpty);
      expect(b.headPoints, hasLength(b.frames.length));
      for (final f in b.frames) {
        expect(File('assets/sprites/$f.png').existsSync(), isTrue, reason: f);
      }
      for (final p in b.headPoints) {
        expect(p.x, inInclusiveRange(0, 31));
        expect(p.y, inInclusiveRange(0, 31));
      }
      expect(b.arrival, contains('{activity}'));
    }
    for (final h in catalog.hats) {
      expect(File('assets/sprites/${h.sprite}.png').existsSync(), isTrue);
    }
  });

  test('every kind has a home base or falls back to the fox', () {
    expect(catalog.baseById(fallbackBaseId), isNotNull);
    for (final kind in kinds) {
      final homes = catalog.bases.where((b) => b.homeKinds.contains(kind));
      final also = catalog.species.where((s) => s.alsoHomeKinds.contains(kind));
      expect(homes.isNotEmpty || also.isNotEmpty, isTrue, reason: kind);
    }
  });

  test('every shape species is reachable at home by some kind', () {
    for (final s in catalog.species) {
      final base = catalog.baseById(s.baseId)!;
      final reachable = kinds.any(
        (k) => base.homeKinds.contains(k) || s.alsoHomeKinds.contains(k),
      );
      expect(reachable, isTrue, reason: s.id);
    }
  });

  test('home kinds from the doc', () {
    Set<String> homes(String id) => catalog.baseById(id)!.homeKinds;
    expect(homes('dog'), {'Walk'});
    expect(homes('cat'), {'Yoga', 'Workout'});
    expect(homes('fox'), {'Run'});
    expect(homes('hare'), {'Run'});
    expect(homes('mustelid'), {'Hike'});
    expect(homes('small-deer'), {'Hike'});
    expect(homes('squirrel'), {'Hike', 'Climb'});
    expect(homes('songbird'), {'Ride'});
    expect(homes('waterfowl'), {'Swim'});
    expect(homes('otter'), {'Swim'});
    expect(homes('lizard'), {'Climb'});
    for (final id in ['owl', 'bat', 'mouse', 'raccoon']) {
      expect(homes(id), {'Sleep'});
    }
  });

  test('base facts from the doc', () {
    final dog = catalog.baseById('dog')!;
    expect(dog.name, 'Dog');
    expect(dog.habitat, Habitat.meadow);
    expect(dog.bubble, 'woof!');
    expect(dog.arrivalFor('walk'), 'trotted along on your walk');
    expect(catalog.baseById('songbird')!.habitat, Habitat.sky);
    expect(catalog.baseById('owl')!.habitat, Habitat.meadow);
    expect(catalog.baseById('bat')!.habitat, Habitat.sky);
    expect(catalog.baseById('waterfowl')!.habitat, Habitat.river);
    expect(catalog.baseById('otter')!.habitat, Habitat.river);
    expect(catalog.baseById('lizard')!.habitat, Habitat.meadow);
    expect(catalog.baseById('hare')!.bubble, 'thump!');
    expect(catalog.baseById('small-deer')!.name, 'Small deer');
    for (final b in catalog.bases) {
      expect(b.bubble, '${b.sound}!');
      expect(File('assets/sounds/${b.sound}.wav').existsSync(), isTrue);
      expect(b.frames, ['stub_fox_1', 'stub_fox_2']);
      expect(b.headPoints, [(x: 24, y: 16), (x: 24, y: 16)]);
    }
  });

  test('species facts from the doc', () {
    final fennec = species('fennec');
    expect(fennec.baseId, 'fox');
    expect(fennec.affinityFor(SpeedBand.fast), Affinity.loves);
    expect(fennec.affinityFor(PartOfDay.day), Affinity.likes);
    expect(fennec.affinityFor(PartOfDay.night), Affinity.neutral);

    final badger = species('badger');
    expect(badger.affinityFor(PartOfDay.night), Affinity.loves);
    expect(badger.affinityFor(LengthBand.long), Affinity.likes);
    expect(badger.affinityFor(SpeedBand.slow), Affinity.likes);
    expect(badger.affinityFor(SpeedBand.fast), Affinity.avoids);

    final corgi = species('corgi');
    expect(corgi.affinityFor(LengthBand.short), Affinity.loves);
    expect(corgi.affinityFor(LengthBand.long), Affinity.avoids);
    expect(corgi.affinityFor(PartOfDay.day), Affinity.likes);

    final poodle = species('poodle');
    expect(poodle.affinityFor(LengthBand.medium), Affinity.likes);
    expect(poodle.affinityFor(DistanceBand.medium), Affinity.neutral);

    expect(species('pipistrelle').affinityFor(PartOfDay.day), Affinity.loves);
    expect(species('mouse-deer').baseId, 'small-deer');
    expect(species('maine-coon').name, 'Maine Coon');
    expect(species('scottish-fold').baseId, 'cat');

    final kingfisher = species('kingfisher');
    expect(kingfisher.baseId, 'songbird');
    expect(kingfisher.alsoHomeKinds, {'Swim'});
    expect(catalog.species.where((s) => s.alsoHomeKinds.isNotEmpty), [
      kingfisher,
    ]);
  });

  test('colour species from the doc', () {
    expect(species('tabby').colours.map((c) => (c.id, c.chance)), [
      ('black-cat', 0.12),
      ('golden-cat', 0.03),
    ]);
    expect(species('red-fox').colours.map((c) => (c.id, c.chance)), [
      ('silver-fox', 0.12),
      ('arctic-fox', 0.03),
    ]);
    expect(species('duck').colours.map((c) => (c.id, c.chance)), [
      ('mallard', 0.12),
      ('golden-duck', 0.03),
    ]);
    expect(species('hare').colours.single.id, 'snow-hare');
    expect(species('hare').colours.single.chance, 0.03);
    expect(species('shiba').colours.single.id, 'black-shiba');
    expect(species('pigeon').colours.single.id, 'white-pigeon');
    expect(species('hamster').colours.single.id, 'white-hamster');
    expect(species('kingfisher').colours.single.id, 'golden-kingfisher');
    expect(species('tabby').colours.first.name, 'Black cat');
    final withColours = catalog.species.where((s) => s.colours.isNotEmpty);
    expect(withColours, hasLength(13));
  });

  test('species per base', () {
    const counts = {
      'dog': 8,
      'cat': 6,
      'fox': 3,
      'hare': 3,
      'mustelid': 4,
      'small-deer': 2,
      'squirrel': 4,
      'songbird': 8,
      'waterfowl': 4,
      'otter': 2,
      'lizard': 3,
      'owl': 3,
      'bat': 2,
      'mouse': 3,
      'raccoon': 3,
    };
    counts.forEach((id, n) {
      expect(catalog.speciesOf(id), hasLength(n), reason: id);
    });
  });

  test('the five hats', () {
    expect(catalog.hats.map((h) => h.id), [
      'party-hat',
      'sombrero',
      'beanie',
      'top-hat',
      'bowler-hat',
    ]);
    for (final h in catalog.hats) {
      expect(h.sprite, 'hat_${h.id}');
      expect(File('assets/sprites/${h.sprite}.png').existsSync(), isTrue);
    }
  });

  group('legends from the doc', () {
    final lines = File('docs/animals.md').readAsLinesSync();
    final docRows = <(String, List<String>)>[];
    var section = '';
    var inLegends = false;
    for (final line in lines) {
      if (line.startsWith('## ')) inLegends = line == '## Legends';
      if (!inLegends) continue;
      if (line.startsWith('### ')) section = line.substring(4);
      if (!line.startsWith('|') || line.startsWith('|---')) continue;
      final cells = line
          .substring(1, line.length - 1)
          .split('|')
          .map((c) => c.trim())
          .toList();
      if (cells[0] == 'Legend') continue;
      docRows.add((section, cells));
    }
    final baseRows = docRows.where((r) => r.$1 == 'Base legends');
    final regionalRows = docRows.where((r) => r.$1 == 'Regional legends');
    String kebabOf(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    test('the doc lists 15 base and 5 regional legends', () {
      expect(baseRows, hasLength(15));
      expect(regionalRows, hasLength(5));
    });

    test('every base has one base legend, with the band the doc says', () {
      const bands = <String, Band>{
        'Day': PartOfDay.day,
        'Twilight': PartOfDay.twilight,
        'Night': PartOfDay.night,
        'Long': LengthBand.long,
        'Fast': SpeedBand.fast,
      };
      for (final (_, c) in baseRows) {
        final legend = catalog.legends.firstWhere((l) => l.id == kebabOf(c[0]));
        expect(legend.name, c[0]);
        expect(legend.baseId, kebabOf(c[1]));
        expect(legend.likes, bands[c[2]], reason: c[0]);
        expect(legend.isRegional, isFalse);
        expect(catalog.baseLegendOf(legend.baseId), legend);
      }
      for (final b in catalog.bases) {
        expect(catalog.baseLegendOf(b.id), isNotNull, reason: b.id);
      }
    });

    test('regional legends carry the doc time zones', () {
      for (final (_, c) in regionalRows) {
        final legend = catalog.legends.firstWhere((l) => l.id == kebabOf(c[0]));
        expect(legend.name, c[0]);
        expect(legend.baseId, kebabOf(c[1]));
        expect(legend.likes, isNull);
        expect(legend.isRegional, isTrue);
        final prefix = RegExp(r'^every time zone starting with (\S+)$');
        final match = prefix.firstMatch(c[2]);
        if (match != null) {
          expect(legend.regionPrefix, match.group(1));
          expect(legend.regionZones, isEmpty);
        } else {
          expect(legend.regionZones, c[2].split(', ').toSet());
          expect(legend.regionPrefix, isNull);
        }
      }
    });

    test('zones match as the doc says', () {
      Legend? at(String zone) => catalog.regionalLegendFor(zone);
      expect(at('Asia/Singapore')?.id, 'merlion');
      expect(at('Asia/Bangkok')?.id, 'naga');
      expect(at('Europe/London')?.id, 'nessie');
      expect(at('Australia/Sydney'), isNull);
      expect(at('Europe/Berlin'), isNull);
      expect(at('Pacific/Auckland'), isNull);
      expect(at('Antarctica/Australia'), isNull);
      expect(catalog.regionalLegendFor(null), isNull);
    });

    test('legends have a base and a note', () {
      for (final l in catalog.legends) {
        expect(catalog.baseById(l.baseId), isNotNull, reason: l.id);
        expect(entryNotes, contains(l.id));
      }
    });
  });
}
