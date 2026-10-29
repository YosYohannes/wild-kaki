import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildkaki/animals/holidays_live.dart';

String body(List<Map<String, Object?>> entries) => jsonEncode(entries);

Map<String, Object?> entry(
  String date, {
  bool global = true,
  List<String> types = const ['Public'],
}) => {
  'date': date,
  'name': 'x',
  'countryCode': 'XX',
  'global': global,
  'counties': null,
  'types': types,
};

class Net {
  Net(this.responses);

  final Map<String, String> responses;
  final List<String> calls = [];
  bool fail = false;

  Future<String> call(Uri url) async {
    calls.add(url.toString());
    if (fail) throw Exception('offline');
    return responses[url.path.split('/').skip(4).join('/')] ??
        (throw Exception('404'));
  }
}

String url(int year, String cc) =>
    'https://date.nager.at/api/v3/PublicHolidays/$year/$cc';

void main() {
  late DateTime now;
  late Net net;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 29, 9);
    net = Net({
      '2026/MY': body([entry('2026-08-31')]),
      '2027/MY': body([entry('2027-01-01')]),
      '2026/SG': body([entry('2026-12-25')]),
      '2027/SG': body([entry('2027-01-01')]),
    });
  });

  Future<HolidayService> open(String? cc) =>
      HolidayService.open(countryCode: cc, fetch: net.call, clock: () => now);

  test('parsing keeps only global Public entries', () {
    final dates = parseNagerHolidays(
      body([
        entry('2026-01-01'),
        entry('2026-02-02', global: false),
        entry('2026-03-03', types: ['Bank', 'Optional']),
        entry('2026-04-04', types: ['Bank', 'Public']),
        entry('2026-01-01'),
      ]),
    );
    expect(dates, ['2026-01-01', '2026-04-04']);
  });

  test('refresh fetches this and next year and the lookup uses them', () async {
    final s = await open('my');
    expect(s.isPublicHoliday(DateTime(2026, 8, 31)), isFalse);
    await s.refresh();
    expect(net.calls, [url(2026, 'MY'), url(2027, 'MY')]);
    expect(s.isPublicHoliday(DateTime(2026, 8, 31)), isTrue);
    expect(s.isPublicHoliday(DateTime(2027, 1, 1, 23, 59)), isTrue);
    expect(s.isPublicHoliday(DateTime(2026, 9, 1)), isFalse);
  });

  test('cache survives a re-open', () async {
    await (await open('MY')).refresh();
    net.calls.clear();
    final again = await open('MY');
    expect(again.isPublicHoliday(DateTime(2026, 8, 31)), isTrue);
    await again.refresh();
    expect(net.calls, isEmpty);
  });

  test('refresh refetches when older than 30 days', () async {
    await (await open('MY')).refresh();
    net.calls.clear();
    now = now.add(const Duration(days: 29));
    await (await open('MY')).refresh();
    expect(net.calls, isEmpty);
    now = now.add(const Duration(days: 2));
    await (await open('MY')).refresh();
    expect(net.calls, [url(2026, 'MY'), url(2027, 'MY')]);
  });

  test('refresh fetches only the missing next year', () async {
    final first = await open('MY');
    await first.refresh();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('holidays.MY.2027');
    net.calls.clear();
    await (await open('MY')).refresh();
    expect(net.calls, [url(2027, 'MY')]);
  });

  test('a failed fetch keeps the old cache and does not throw', () async {
    await (await open('MY')).refresh();
    now = now.add(const Duration(days: 40));
    net.calls.clear();
    net.fail = true;
    final s = await open('MY');
    await s.refresh();
    expect(net.calls, hasLength(2));
    expect(s.isPublicHoliday(DateTime(2026, 8, 31)), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('holidays.MY.2026'), contains('2026-08-31'));
  });

  test('garbage responses are ignored', () async {
    net.responses['2026/MY'] = 'not json';
    net.responses['2027/MY'] = '[]';
    final s = await open('MY');
    await s.refresh();
    expect(s.isPublicHoliday(DateTime(2026, 8, 31)), isFalse);
    expect(
      (await SharedPreferences.getInstance()).getKeys().where(
        (k) => k.startsWith('holidays.'),
      ),
      isEmpty,
    );
  });

  test(
    'falls back to the bundled Singapore list with an empty cache',
    () async {
      final s = await open('SG');
      expect(s.isPublicHoliday(DateTime(2026, 8, 10)), isTrue);
      expect(s.isPublicHoliday(DateTime(2026, 8, 11)), isFalse);
    },
  );

  test('fetched Singapore data wins over the bundled list', () async {
    final s = await open('SG');
    await s.refresh();
    expect(s.isPublicHoliday(DateTime(2026, 12, 25)), isTrue);
    expect(s.isPublicHoliday(DateTime(2026, 8, 10)), isFalse);
  });

  test('other countries without data have no holidays', () async {
    final s = await open('MY');
    expect(s.isPublicHoliday(DateTime(2026, 8, 31)), isFalse);
    expect(s.isPublicHoliday(DateTime(2026, 8, 10)), isFalse);
  });

  test('no country code means no holidays and no requests', () async {
    for (final cc in ['']) {
      final s = await open(cc);
      await s.refresh();
      expect(s.isPublicHoliday(DateTime(2026, 8, 10)), isFalse);
    }
    expect(net.calls, isEmpty);
  });

  test('concurrent refreshes share one fetch', () async {
    final s = await open('MY');
    await Future.wait([s.refresh(), s.refresh()]);
    expect(net.calls, hasLength(2));
  });
}
