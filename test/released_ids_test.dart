import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/lookup.dart';

// Every animal id shipped in a release. Ids are stored on the phone, so one
// that disappears must be mapped to its replacement in renamedEntries.
const _released = [
  'shiba',
  'black-shiba',
  'corgi',
  'dachshund',
  'beagle',
  'poodle',
  'golden-poodle',
  'pug',
  'husky',
  'terrier',
  'cerberus-pup',
  'tabby',
  'black-cat',
  'golden-cat',
  'siamese',
  'persian',
  'maine-coon',
  'scottish-fold',
  'sphynx',
  'nekomata',
  'red-fox',
  'silver-fox',
  'arctic-fox',
  'fennec',
  'grey-fox',
  'kitsune',
  'hare',
  'snow-hare',
  'rabbit',
  'jackrabbit',
  'moon-rabbit',
  'badger',
  'albino-badger',
  'stoat',
  'weasel',
  'ferret',
  'kamaitachi',
  'muntjac',
  'mouse-deer',
  'unicorn',
  'qilin',
  'red-squirrel',
  'black-squirrel',
  'grey-squirrel',
  'chipmunk',
  'flying-squirrel',
  'ratatoskr',
  'sparrow',
  'robin',
  'myna',
  'pigeon',
  'white-pigeon',
  'crow',
  'swallow',
  'magpie',
  'kingfisher',
  'golden-kingfisher',
  'phoenix',
  'garuda',
  'duck',
  'mallard',
  'golden-duck',
  'goose',
  'moorhen',
  'grebe',
  'hamsa',
  'nessie',
  'otter',
  'beaver',
  'kappa',
  'merlion',
  'gecko',
  'golden-gecko',
  'chameleon',
  'iguana',
  'dragon',
  'naga',
  'barn-owl',
  'snowy-owl',
  'tawny-owl',
  'eagle-owl',
  'owl-of-athena',
  'fruit-bat',
  'pipistrelle',
  'vampire',
  'mouse',
  'dormouse',
  'hamster',
  'white-hamster',
  'rat-king',
  'raccoon',
  'red-panda',
  'tanuki',
  'bake-danuki',
];

void main() {
  test('every released id still resolves to itself or a renamed entry', () {
    for (final id in _released) {
      final now = renamedEntries[id] ?? id;
      expect(findEntry(now), isNotNull, reason: '$id was removed');
      expect(legacyEntryId(id), now, reason: id);
    }
  });

  test('a renamed id is no longer a current entry', () {
    for (final e in renamedEntries.entries) {
      expect(findEntry(e.key), isNull, reason: e.key);
      expect(findEntry(e.value), isNotNull, reason: e.value);
    }
  });

  test('released ids are unique and none were forgotten', () {
    expect(_released.toSet(), hasLength(_released.length));
    final missing = [
      for (final e in animalEntries)
        if (!_released.contains(e.id) && !_unreleased.contains(e.id)) e.id,
    ];
    expect(missing, isEmpty, reason: 'add new ids to _released at release');
  });

  test('an id the app does not know falls back to the red fox', () {
    expect(legacyEntryId('no-such-animal'), 'red-fox');
    expect(legacyEntryId(''), 'red-fox');
  });
}

// New ids added since the last release; move them into _released when
// releasing.
const _unreleased = <String>[];
