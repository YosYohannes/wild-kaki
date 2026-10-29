import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'holidays.dart';

typedef HolidayFetch = Future<String> Function(Uri url);

const _maxAge = Duration(days: 30);
const _timeout = Duration(seconds: 10);

Future<String> _httpGet(Uri url) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.getUrl(url).timeout(_timeout);
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != 200) {
      throw HttpException('status ${response.statusCode}', uri: url);
    }
    return await response.transform(utf8.decoder).join().timeout(_timeout);
  } finally {
    client.close(force: true);
  }
}

List<String> parseNagerHolidays(String body) {
  final dates = <String>{};
  for (final entry in jsonDecode(body) as List) {
    if (entry is! Map) continue;
    final types = entry['types'];
    if (entry['global'] != true || types is! List) continue;
    if (!types.contains('Public')) continue;
    final date = entry['date'];
    if (date is String && date.length == 10) dates.add(date);
  }
  return dates.toList()..sort();
}

class HolidayService implements HolidayProvider {
  HolidayService._(this._prefs, this._country, this._fetch, this._clock);

  static Future<HolidayService> open({
    String? countryCode,
    SharedPreferences? prefs,
    HolidayFetch? fetch,
    DateTime Function()? clock,
  }) async {
    final service = HolidayService._(
      prefs ?? await SharedPreferences.getInstance(),
      (countryCode ?? PlatformDispatcher.instance.locale.countryCode ?? '')
          .toUpperCase(),
      fetch ?? _httpGet,
      clock ?? DateTime.now,
    );
    service._load();
    return service;
  }

  final SharedPreferences _prefs;
  final String _country;
  final HolidayFetch _fetch;
  final DateTime Function() _clock;
  final Map<int, Set<String>> _byYear = {};
  final Map<int, DateTime> _fetchedAt = {};
  Future<void>? _running;

  String _key(int year) => 'holidays.$_country.$year';

  void _load() {
    if (_country.isEmpty) return;
    final prefix = 'holidays.$_country.';
    for (final key in _prefs.getKeys().where((k) => k.startsWith(prefix))) {
      final year = int.tryParse(key.substring(prefix.length));
      final raw = _prefs.getString(key);
      if (year == null || raw == null) continue;
      try {
        final data = jsonDecode(raw) as Map;
        _byYear[year] = (data['dates'] as List).cast<String>().toSet();
        _fetchedAt[year] = DateTime.fromMillisecondsSinceEpoch(
          data['fetchedAt'] as int,
        );
      } catch (_) {
        _byYear.remove(year);
        _fetchedAt.remove(year);
      }
    }
  }

  @override
  bool isPublicHoliday(DateTime localDate) {
    if (_country.isEmpty) return false;
    final fetched = _byYear[localDate.year];
    if (fetched != null) return fetched.contains(isoDate(localDate));
    return holidaysForRegion(_country).isPublicHoliday(localDate);
  }

  Future<void> refresh() => _running ??= _refresh().whenComplete(() {
    _running = null;
  });

  Future<void> _refresh() async {
    if (_country.isEmpty) return;
    final now = _clock();
    for (final year in [now.year, now.year + 1]) {
      final at = _fetchedAt[year];
      if (at != null && now.difference(at) < _maxAge) continue;
      try {
        final body = await _fetch(
          Uri.parse(
            'https://date.nager.at/api/v3/PublicHolidays/$year/$_country',
          ),
        );
        final dates = parseNagerHolidays(body);
        if (dates.isEmpty) continue;
        await _prefs.setString(
          _key(year),
          jsonEncode({'fetchedAt': now.millisecondsSinceEpoch, 'dates': dates}),
        );
        _byYear[year] = dates.toSet();
        _fetchedAt[year] = now;
      } catch (_) {}
    }
  }
}
