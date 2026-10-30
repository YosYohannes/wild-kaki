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
        'Trots along on walks. Loves going far, fond of long outings.',
      );
    });

    test('loves before likes before avoids', () {
      expect(
        text('badger'),
        'Found out on hikes. Loves the night, fond of long outings.',
      );
      expect(
        text('persian'),
        'Joins yoga and workouts. Loves long outings, shy of quick outings.',
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
    bool unlocked(String id, Set<String> met, [String? zone]) =>
        hintUnlocked(entry(id), met: met, timeZone: zone);

    test('nothing unlocks before a first meeting', () {
      for (final e in animalEntries) {
        expect(unlocked(e.id, {}), isFalse, reason: e.id);
      }
    });

    test('shape species unlock on any entry of their base', () {
      expect(unlocked('fennec', {'red-fox'}), isTrue);
      expect(unlocked('fennec', {'arctic-fox'}), isTrue);
      expect(unlocked('hare', {'red-fox'}), isFalse);
      expect(unlocked('fennec', {'fennec'}), isFalse);
    });

    test('colour species unlock on their shape species only', () {
      expect(unlocked('silver-fox', {'red-fox'}), isTrue);
      expect(unlocked('silver-fox', {'fennec'}), isFalse);
      expect(unlocked('silver-fox', {'arctic-fox'}), isFalse);
      expect(unlocked('silver-fox', {'red-fox', 'silver-fox'}), isFalse);
    });

    test('base legends unlock on any entry of their base', () {
      expect(unlocked('kitsune', {'fennec'}), isTrue);
      expect(unlocked('kitsune', {'shiba'}), isFalse);
      expect(unlocked('kitsune', {'fennec', 'kitsune'}), isFalse);
    });

    test('regional legends unlock in their region', () {
      expect(unlocked('merlion', {}), isFalse);
      expect(unlocked('merlion', {}, 'Europe/Berlin'), isFalse);
      expect(unlocked('merlion', {}, 'Asia/Singapore'), isTrue);
      expect(unlocked('merlion', {'merlion'}, 'Asia/Singapore'), isFalse);
    });

    test('hintFor is the text when unlocked and null otherwise', () {
      expect(hintFor(entry('fennec'), met: {}), isNull);
      expect(
        hintFor(entry('fennec'), met: {'red-fox'}),
        'Turns up on runs. Loves speed, fond of daylight.',
      );
    });
  });
}
