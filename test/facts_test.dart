import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/bands.dart';
import 'package:wildkaki/animals/facts.dart';
import 'package:wildkaki/animals/holidays.dart';
import 'package:wildkaki/animals/holidays_sg.dart';
import 'package:wildkaki/data/model.dart';

Outing outing({
  String kind = 'Run',
  DateTime? start,
  double? km,
  int minutes = 30,
}) => Outing(
  id: 'x',
  kind: kind,
  start: start ?? DateTime(2026, 11, 4, 10),
  distanceKm: km,
  minutes: minutes,
);

ActivityFacts facts(Outing o, [HolidayProvider h = const NoHolidays()]) =>
    ActivityFacts.from(o, h);

void main() {
  group('partOfDay', () {
    const edges = {
      '04:59': PartOfDay.night,
      '05:00': PartOfDay.twilight,
      '06:59': PartOfDay.twilight,
      '07:00': PartOfDay.day,
      '16:59': PartOfDay.day,
      '17:00': PartOfDay.twilight,
      '20:59': PartOfDay.twilight,
      '21:00': PartOfDay.night,
      '00:00': PartOfDay.night,
    };
    edges.forEach((time, expected) {
      test('$time is $expected', () {
        final parts = time.split(':').map(int.parse).toList();
        final start = DateTime(2026, 11, 4, parts[0], parts[1]);
        expect(facts(outing(start: start)).partOfDay, expected);
      });
    });

    test('sleep uses the bedtime', () {
      final bedtime = DateTime(2026, 11, 4, 23, 30);
      expect(
        facts(outing(kind: 'Sleep', start: bedtime, minutes: 450)).partOfDay,
        PartOfDay.night,
      );
      final nap = DateTime(2026, 11, 4, 13);
      expect(
        facts(outing(kind: 'Sleep', start: nap, minutes: 60)).partOfDay,
        PartOfDay.day,
      );
    });

    test('a UTC start is read in the local zone', () {
      final local = DateTime(2026, 11, 4, 12);
      expect(
        facts(outing(start: local.toUtc())).partOfDay,
        facts(outing(start: local)).partOfDay,
      );
    });
  });

  group('lengthBand', () {
    const cuts = {
      'Run': [15, 30, 60],
      'Walk': [15, 40, 90],
      'Hike': [30, 90, 180],
      'Ride': [20, 45, 120],
      'Swim': [15, 30, 60],
      'Climb': [20, 45, 90],
      'Yoga': [15, 30, 60],
      'Workout': [15, 30, 60],
      'Sleep': [240, 360, 540],
      'Unknown': [15, 30, 60],
      'Kayak': [15, 30, 60],
    };
    cuts.forEach((kind, c) {
      test('$kind cut-offs', () {
        LengthBand at(int m) =>
            facts(outing(kind: kind, minutes: m)).lengthBand;
        expect(at(c[0] - 1), LengthBand.brief);
        expect(at(c[0]), LengthBand.short);
        expect(at(c[1] - 1), LengthBand.short);
        expect(at(c[1]), LengthBand.medium);
        expect(at(c[2] - 1), LengthBand.medium);
        expect(at(c[2]), LengthBand.long);
        expect(at(c[2] + 1000), LengthBand.long);
      });
    });

    test('zero or negative minutes count as 1', () {
      expect(facts(outing(minutes: 0)).lengthBand, LengthBand.brief);
      expect(facts(outing(minutes: -5)).lengthBand, LengthBand.brief);
    });
  });

  group('distanceBand', () {
    const cuts = {
      'Run': [3.0, 8.0, 21.0],
      'Walk': [2.0, 5.0, 12.0],
      'Hike': [4.0, 10.0, 20.0],
      'Ride': [8.0, 25.0, 60.0],
      'Swim': [0.5, 1.5, 4.0],
    };
    cuts.forEach((kind, c) {
      test('$kind cut-offs', () {
        DistanceBand? at(double km) =>
            facts(outing(kind: kind, km: km, minutes: 600)).distanceBand;
        expect(at(c[0] - 0.01), DistanceBand.near);
        expect(at(c[0]), DistanceBand.medium);
        expect(at(c[1] - 0.01), DistanceBand.medium);
        expect(at(c[1]), DistanceBand.far);
        expect(at(c[2] - 0.01), DistanceBand.far);
        expect(at(c[2]), DistanceBand.epic);
      });
    });

    test('unknown for kinds without a table, even with a distance', () {
      for (final kind in ['Climb', 'Yoga', 'Workout', 'Sleep', 'Kayak']) {
        final f = facts(outing(kind: kind, km: 10, minutes: 60));
        expect(f.distanceBand, isNull, reason: kind);
        expect(f.speedBand, isNull, reason: kind);
      }
    });

    test('missing and zero distance are unknown', () {
      expect(facts(outing(km: null)).distanceBand, isNull);
      expect(facts(outing(km: 0)).distanceBand, isNull);
      expect(facts(outing(km: 0)).speedBand, isNull);
      expect(facts(outing(km: null)).speedBand, isNull);
    });
  });

  group('speedBand', () {
    const cuts = {
      'Run': [8.0, 12.0],
      'Walk': [3.5, 5.5],
      'Hike': [2.5, 4.5],
      'Ride': [14.0, 22.0],
      'Swim': [1.5, 2.5],
    };
    cuts.forEach((kind, c) {
      test('$kind cut-offs', () {
        SpeedBand? at(double kmh) =>
            facts(outing(kind: kind, km: kmh, minutes: 60)).speedBand;
        expect(at(c[0] - 0.1), SpeedBand.slow);
        expect(at(c[0]), SpeedBand.steady);
        expect(at(c[1] - 0.1), SpeedBand.steady);
        expect(at(c[1]), SpeedBand.fast);
      });
    });

    test('uses distance over duration', () {
      expect(facts(outing(km: 6, minutes: 30)).speedBand, SpeedBand.fast);
      expect(facts(outing(km: 6, minutes: 60)).speedBand, SpeedBand.slow);
    });

    test('under 5 minutes is unknown but the distance band stays', () {
      final short = facts(outing(km: 0.5, minutes: 4));
      expect(short.speedBand, isNull);
      expect(short.distanceBand, DistanceBand.near);
      expect(facts(outing(km: 0.5, minutes: 5)).speedBand, SpeedBand.slow);
      expect(facts(outing(km: 1, minutes: 0)).speedBand, isNull);
    });
  });

  group('dayOff', () {
    final saturday = DateTime(2026, 11, 7, 9);
    final sunday = DateTime(2026, 11, 8, 9);
    final monday = DateTime(2026, 11, 2, 9);

    test('weekends count', () {
      expect(facts(outing(start: saturday)).dayOff, isTrue);
      expect(facts(outing(start: sunday)).dayOff, isTrue);
      expect(facts(outing(start: monday)).dayOff, isFalse);
    });

    test('a bundled Singapore holiday counts', () {
      final cny = DateTime(2026, 2, 17, 9);
      expect(facts(outing(start: cny), singapore).dayOff, isTrue);
      expect(facts(outing(start: cny)).dayOff, isFalse);
    });

    test('an in-lieu Monday counts', () {
      final lieu = DateTime(2026, 6, 1, 9);
      expect(facts(outing(start: lieu), singapore).dayOff, isTrue);
      expect(
        facts(outing(start: DateTime(2026, 6, 2, 9)), singapore).dayOff,
        isFalse,
      );
    });

    test('the holiday is read on the local date', () {
      final lateNight = DateTime(2026, 2, 17, 23, 30);
      expect(facts(outing(start: lateNight), singapore).dayOff, isTrue);
      final eve = DateTime(2026, 2, 16, 23, 30);
      expect(facts(outing(start: eve), singapore).dayOff, isFalse);
    });

    test('other regions have only weekends', () {
      expect(holidaysForRegion('SG'), same(singapore));
      expect(holidaysForRegion('sg'), same(singapore));
      for (final region in ['US', 'GB', '', null]) {
        expect(
          holidaysForRegion(region).isPublicHoliday(DateTime(2026, 2, 17)),
          isFalse,
        );
      }
    });
  });

  group('singapore holiday list', () {
    final dates = [for (final (d, _) in singaporeHolidays) DateTime.parse(d)];

    test('covers only 2026 and 2027, sorted, without duplicates', () {
      expect(dates.map((d) => d.year).toSet(), {2026, 2027});
      expect(dates.toSet(), hasLength(dates.length));
      final sorted = [...dates]..sort();
      expect(dates, sorted);
    });

    test('every holiday on a Sunday has its Monday in lieu', () {
      for (final d in dates.where((d) => d.weekday == DateTime.sunday)) {
        final monday = DateTime(d.year, d.month, d.day + 1);
        expect(dates, contains(monday), reason: '$d');
      }
    });

    test('has the fixed-date holidays', () {
      for (final year in [2026, 2027]) {
        for (final md in ['01-01', '05-01', '08-09', '12-25']) {
          expect(singaporeHolidays.map((h) => h.$1), contains('$year-$md'));
        }
      }
    });
  });
}
