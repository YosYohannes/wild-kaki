import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weather_codes.dart';
import 'weather_state.dart';
import 'zone_places.dart';

typedef WeatherFetch = Future<String> Function(Uri url);

const weatherCacheKey = 'weather.last';
const _freshFor = Duration(minutes: 20);
const _staleAfter = Duration(hours: 2);
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

Future<String?> deviceTimeZone() async {
  try {
    return await const MethodChannel('app.wildkaki/health')
        .invokeMethod<String>('timeZone');
  } catch (_) {
    return null;
  }
}

Uri weatherUrl(Place place) => Uri.https('api.open-meteo.com', '/v1/forecast', {
  'latitude': place.latitude.toString(),
  'longitude': place.longitude.toString(),
  'current': 'weather_code',
  'timezone': 'auto',
});

int? parseWeatherCode(String body) {
  final current = (jsonDecode(body) as Map)['current'];
  if (current is! Map) return null;
  final code = current['weather_code'];
  return code is int ? code : null;
}

class WeatherService {
  WeatherService._(
    this.state,
    this._prefs,
    this._place,
    this._fetch,
    this._clock,
  );

  static Future<WeatherService> open({
    WeatherState? state,
    String? timeZone,
    bool readTimeZone = true,
    SharedPreferences? prefs,
    WeatherFetch? fetch,
    DateTime Function()? clock,
  }) async {
    final zone = timeZone ?? (readTimeZone ? await deviceTimeZone() : null);
    final service = WeatherService._(
      state ?? WeatherState(),
      prefs ?? await SharedPreferences.getInstance(),
      placeForZone(zone),
      fetch ?? _httpGet,
      clock ?? DateTime.now,
    );
    service._load();
    return service;
  }

  final WeatherState state;
  final SharedPreferences _prefs;
  final Place? _place;
  final WeatherFetch _fetch;
  final DateTime Function() _clock;
  int? _code;
  DateTime? _fetchedAt;
  Future<void>? _running;

  void _load() {
    final raw = _prefs.getString(weatherCacheKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map;
      _code = data['code'] as int;
      _fetchedAt = DateTime.fromMillisecondsSinceEpoch(
        data['fetchedAt'] as int,
      );
      _publish();
    } catch (_) {
      _code = null;
      _fetchedAt = null;
    }
  }

  void _publish() {
    final at = _fetchedAt;
    final usable = at != null && _clock().difference(at) <= _staleAfter;
    state.live = usable ? weatherFromCode(_code) : Weather.clear;
  }

  Future<void> refresh() => _running ??= _refresh().whenComplete(() {
    _running = null;
  });

  Future<void> _refresh() async {
    final place = _place;
    if (place == null) return;
    final now = _clock();
    final at = _fetchedAt;
    if (at != null && now.difference(at) < _freshFor) {
      _publish();
      return;
    }
    try {
      final code = parseWeatherCode(await _fetch(weatherUrl(place)));
      if (code == null) throw const FormatException('no weather_code');
      _code = code;
      _fetchedAt = now;
      await _prefs.setString(
        weatherCacheKey,
        jsonEncode({'code': code, 'fetchedAt': now.millisecondsSinceEpoch}),
      );
    } catch (_) {}
    _publish();
  }
}
