import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/boosts.dart';
import 'package:wildkaki/animals/catalog_data.dart';
import 'package:wildkaki/animals/facts.dart';
import 'package:wildkaki/animals/holidays.dart';
import 'package:wildkaki/animals/picker.dart';
import 'package:wildkaki/animals/rolls.dart';
import 'package:wildkaki/data/model.dart';

const none = NoHolidays();
final bedtime = DateTime(2026, 11, 4, 23);

Outing at(String id, DateTime start, {String kind = 'Run'}) =>
    Outing(id: id, kind: kind, start: start, distanceKm: 5, minutes: 30);

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
}
