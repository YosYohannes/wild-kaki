import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/animals.dart';
import 'package:wildkaki/animals/rules.dart';
import 'package:wildkaki/data/model.dart';

const _kinds = [
  'Run',
  'Walk',
  'Hike',
  'Ride',
  'Swim',
  'Climb',
  'Yoga',
  'Workout',
  sleepKind,
];

Outing _outing(
  String id, {
  String kind = 'Run',
  double? km = 5,
  int min = 30,
}) => Outing(
  id: id,
  kind: kind,
  start: DateTime(2026, 10, 1, 7),
  distanceKm: km,
  minutes: min,
);

Rule _rule(String id, List<String> animals, {bool Function(Outing)? when}) =>
    Rule(
      id: id,
      description: id,
      matches: when ?? (_) => true,
      animals: animals,
    );

List<int> _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(bytes.sublist(1, 4), 'PNG'.codeUnits, reason: path);
  return [data.getUint32(16), data.getUint32(20)];
}

void main() {
  group('animals', () {
    test('ids are unique and non-empty', () {
      final ids = animals.map((a) => a.id).toList();
      expect(ids.every((id) => id.isNotEmpty), isTrue);
      expect(ids.toSet().length, ids.length);
    });

    test('every frame is a 32x32 sprite asset', () {
      for (final a in animals) {
        expect(a.frames, isNotEmpty, reason: a.id);
        for (final frame in a.frames) {
          final path = 'assets/sprites/$frame.png';
          expect(File(path).existsSync(), isTrue, reason: path);
          expect(_pngSize(path), [32, 32], reason: path);
        }
      }
    });

    test('every reaction has a sound asset and a bubble', () {
      for (final a in animals) {
        final path = 'assets/sounds/${a.reaction.sound}.wav';
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(a.reaction.bubble, isNotEmpty, reason: a.id);
      }
    });

    test(
      'every animal has a name, a note and an arrival with the activity',
      () {
        for (final a in animals) {
          expect(a.name, isNotEmpty, reason: a.id);
          expect(a.note, isNotEmpty, reason: a.id);
          expect(a.arrival, contains('{activity}'), reason: a.id);
        }
      },
    );

    test('animalById falls back to the first animal', () {
      expect(animalById('duck').id, 'duck');
      expect(animalById('nope'), animals.first);
    });

    test('arrivalFor fills in the activity', () {
      expect(animalById('duck').arrivalFor('run'), 'paddled along on your run');
    });
  });

  group('rules', () {
    test('there are rules with unique ids', () {
      expect(rules, isNotEmpty);
      final ids = rules.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every rule picks from registry animals', () {
      final known = animals.map((a) => a.id).toSet();
      for (final r in rules) {
        expect(r.animals, isNotEmpty, reason: r.id);
        expect(known.containsAll(r.animals), isTrue, reason: r.id);
      }
    });

    test('the last rule matches every activity', () {
      for (final kind in _kinds) {
        for (final km in [null, 0.0, 3.2, 42.0]) {
          for (final min in [1, 30, 600]) {
            final o = _outing('x', kind: kind, km: km, min: min);
            expect(rules.last.matches(o), isTrue, reason: '$kind $km $min');
          }
        }
      }
    });

    test('animalIdFor picks a registry animal for every activity', () {
      final known = animals.map((a) => a.id).toSet();
      for (final kind in _kinds) {
        expect(known, contains(animalIdFor(_outing('o1', kind: kind))));
      }
    });
  });

  group('animalIdFor', () {
    final seven = [
      _rule('seven', ['a', 'b', 'c', 'd', 'e', 'f', 'g']),
    ];

    test('is deterministic', () {
      for (var i = 0; i < 50; i++) {
        final o = _outing('id-$i');
        expect(animalIdFor(o, using: seven), animalIdFor(o, using: seven));
      }
    });

    test('is stable across releases (FNV-1a of the outing id)', () {
      expect(animalIdFor(_outing('abc'), using: seven), 'f');
      expect(animalIdFor(_outing('xyz-123'), using: seven), 'c');
    });

    test('spreads two animals fairly evenly', () {
      final two = [
        _rule('two', ['a', 'b']),
      ];
      var a = 0;
      for (var i = 0; i < 2000; i++) {
        if (animalIdFor(_outing('activity-$i'), using: two) == 'a') a++;
      }
      expect(a, inInclusiveRange(900, 1100));
    });

    test('ignores later rules once one matches', () {
      final ordered = [
        _rule('swims', ['duck'], when: (o) => o.kind == 'Swim'),
        _rule('rest', ['fox']),
        _rule('never', ['bird']),
      ];
      expect(animalIdFor(_outing('1', kind: 'Swim'), using: ordered), 'duck');
      for (var i = 0; i < 30; i++) {
        expect(animalIdFor(_outing('r$i'), using: ordered), 'fox');
      }
    });
  });
}
