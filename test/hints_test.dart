import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/catalog.dart';
import 'package:wildkaki/animals/catalog_data.dart';
import 'package:wildkaki/animals/hints.dart';
import 'package:wildkaki/animals/hints_data.dart';
import 'package:wildkaki/animals/lookup.dart';

AnimalEntry entry(String id) => findEntry(id)!;

String text(String id) => hintText(entry(id));

void main() {
  group('habit lines', () {
    test('kind phrase, then strongest affinities first', () {
      expect(
        text('fennec'),
        'Turns up on runs. Loves speed, fond of daylight.',
      );
    });

    test('two home kinds join with and', () {
      expect(text('red-squirrel'), contains('Found out on hikes and climbs'));
      expect(
        text('flying-squirrel'),
        startsWith('Found out on hikes and climbs.'),
      );
      expect(text('tabby'), startsWith('Joins yoga and workouts.'));
    });

    test('also-home kinds are added', () {
      expect(text('kingfisher'), contains('rides and swims'));
      expect(text('kingfisher'), startsWith('Flies over rides and swims.'));
    });

    test('at most two affinity phrases', () {
      expect(
        text('duck'),
        'Paddles by on swims. Fond of an easy pace and staying close.',
      );
      expect(
        text('husky'),
        'Trots along on walks. Loves going far, fond of long activities.',
      );
    });

    test('loves before likes before avoids', () {
      expect(
        text('badger'),
        'Found out on hikes. Loves the night, fond of long activities.',
      );
      expect(
        text('persian'),
        'Joins yoga and workouts. Loves long activities, shy of quick activities.',
      );
    });

    test('Sleep species use the sleep words', () {
      expect(
        text('pipistrelle'),
        'Comes while you sleep. Loves daytime naps, fond of short naps.',
      );
      expect(
        text('tawny-owl'),
        'Comes while you sleep. Fond of dusk and dawn, and a good night\'s sleep.',
      );
      expect(text('dormouse'), 'Comes while you sleep. Loves long lie-ins.');
    });

    test('a species with no affinities is not fussy', () {
      final base = defaultCatalog.baseById('fox')!;
      final shape = const Species(id: 'plain', name: 'Plain', baseId: 'fox');
      final plain = AnimalEntry(
        id: shape.id,
        name: shape.name,
        base: base,
        shape: shape,
      );
      expect(hintText(plain), 'Turns up on runs. Not fussy about when or how.');
    });

    test('every shape species has a habit line', () {
      for (final e in animalEntries) {
        if (e.shape != null && !e.isColour) {
          expect(hintText(e), endsWith('.'), reason: e.id);
        }
      }
    });
  });

  group('colour coats', () {
    test('by chance', () {
      expect(text('silver-fox'), 'An uncommon coat of the Red fox');
      expect(text('arctic-fox'), 'A very rare coat of the Red fox');
      expect(text('golden-cat'), 'A very rare coat of the Tabby');
    });
  });

  group('riddles', () {
    test('legends show their riddle', () {
      expect(
        text('kitsune'),
        'At dusk, a white fox with more tails than it needs.',
      );
      expect(
        text('nessie'),
        'A long neck, a blurry photo, a loch somewhere near.',
      );
    });

    test('every legend has a riddle', () {
      for (final l in defaultCatalog.legends) {
        expect(legendRiddles[l.id], isNotEmpty, reason: l.id);
      }
      expect(legendRiddles, hasLength(defaultCatalog.legends.length));
    });
  });

  group('unlock rules', () {
    bool unlocked(
      String id,
      Set<String> met, {
      Set<String> hinted = const {},
      String? zone,
    }) => hintUnlocked(entry(id), met: met, hinted: hinted, timeZone: zone);

    test('nothing unlocks without a hint', () {
      for (final e in animalEntries) {
        expect(unlocked(e.id, {'red-fox', 'shiba'}), isFalse, reason: e.id);
      }
    });

    test('meeting an animal does not unlock its family', () {
      expect(unlocked('fennec', {'red-fox'}), isFalse);
      expect(unlocked('silver-fox', {'red-fox'}), isFalse);
      expect(unlocked('kitsune', {'fennec'}), isFalse);
    });

    test('a hinted entry unlocks until it is met', () {
      for (final id in ['fennec', 'silver-fox', 'kitsune']) {
        expect(unlocked(id, {}, hinted: {id}), isTrue, reason: id);
        expect(unlocked(id, {id}, hinted: {id}), isFalse, reason: id);
      }
      expect(unlocked('hare', {}, hinted: {'fennec'}), isFalse);
    });

    test('regional legends unlock in their region', () {
      expect(unlocked('merlion', {}), isFalse);
      expect(unlocked('merlion', {}, zone: 'Europe/Berlin'), isFalse);
      expect(unlocked('merlion', {}, zone: 'Asia/Singapore'), isTrue);
      expect(unlocked('merlion', {'merlion'}, zone: 'Asia/Singapore'), isFalse);
    });

    test('hintFor is the text when unlocked and null otherwise', () {
      expect(hintFor(entry('fennec'), met: {}), isNull);
      expect(
        hintFor(entry('fennec'), met: {}, hinted: {'fennec'}),
        'Turns up on runs. Loves speed, fond of daylight.',
      );
    });
  });

  group('duplicate hints', () {
    String? pick(
      double roll, {
      Set<String> met = const {'red-fox'},
      Set<String> hinted = const {},
    }) => duplicateHint(met: met, hinted: hinted, roll: roll);

    test('the roll chooses among everything still open', () {
      final seen = {for (var i = 0; i < 100; i++) pick(i / 100)};
      expect(seen.length, greaterThan(40));
      expect(pick(0.3), pick(0.3));
    });

    test('never met, hinted or regional entries', () {
      const met = {'red-fox', 'fennec'};
      const hinted = {'kitsune', 'hare'};
      for (var i = 0; i < 400; i++) {
        final id = pick(i / 400, met: met, hinted: hinted)!;
        final e = entry(id);
        expect(met.contains(id) || hinted.contains(id), isFalse, reason: id);
        expect(e.legend?.isRegional ?? false, isFalse, reason: id);
      }
    });

    test('a colour waits for its plain species to be met', () {
      final ids = {
        for (var i = 0; i < 2000; i++) pick(i / 2000, met: {'fennec'}),
      };
      expect(ids, contains('red-fox'));
      expect(ids, isNot(contains('silver-fox')));
      final withFox = {
        for (var i = 0; i < 2000; i++) pick(i / 2000, met: {'red-fox'}),
      };
      expect(
        withFox.where((id) => entry(id!).colour != null),
        everyElement(
          predicate<String?>((id) => entry(id!).shape!.id == 'red-fox'),
        ),
      );
    });

    test('nothing is left to hint at', () {
      final all = {for (final e in animalEntries) e.id};
      expect(pick(0.5, met: all), isNull);
      final regional = {
        for (final e in animalEntries)
          if (!(e.legend?.isRegional ?? false)) e.id,
      };
      expect(pick(0.5, met: regional), isNull);
    });

    test('roll 1 stays in range', () {
      expect(pick(1), isNotNull);
      expect(pick(0.999999999), isNotNull);
    });
  });
}
