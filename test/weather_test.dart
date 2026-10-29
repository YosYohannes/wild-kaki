import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildkaki/weather/weather_codes.dart';
import 'package:wildkaki/weather/weather_service.dart';
import 'package:wildkaki/weather/weather_state.dart';
import 'package:wildkaki/weather/zone_places.dart';

String body(Object? code) => jsonEncode({
  'current': {'weather_code': code},
});

class Net {
  Net(this.response);

  String response;
  bool fail = false;
  final List<Uri> calls = [];

  Future<String> call(Uri url) async {
    calls.add(url);
    if (fail) throw Exception('offline');
    return response;
  }
}

class Clock {
  DateTime now = DateTime(2026, 10, 29, 12);
  DateTime call() => now;
}

Future<WeatherService> open(
  Net net,
  Clock clock, {
  String? zone = 'Asia/Singapore',
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  return WeatherService.open(
    timeZone: zone,
    readTimeZone: false,
    prefs: await SharedPreferences.getInstance(),
    fetch: net.call,
    clock: clock.call,
  );
}

void main() {
  test('weather codes 0-99', () {
    const cloudy = {2, 3, 45, 48, 71, 73, 75, 77, 85, 86};
    const rain = {51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82};
    const storm = {95, 96, 99};
    for (var code = 0; code <= 99; code++) {
      final expected = storm.contains(code)
          ? Weather.storm
          : rain.contains(code)
          ? Weather.rain
          : cloudy.contains(code)
          ? Weather.cloudy
          : Weather.clear;
      expect(weatherFromCode(code), expected, reason: 'code $code');
    }
    expect(weatherFromCode(null), Weather.clear);
    expect(weatherFromCode(1234), Weather.clear);
    expect(weatherFromCode(-1), Weather.clear);
  });

  group('zone places', () {
    test('lookup', () {
      final singapore = placeForZone('Asia/Singapore')!;
      expect(singapore.latitude, 1.35);
      expect(singapore.longitude, 103.82);
      expect(placeForZone('Asia/Kuala_Lumpur'), isNotNull);
      expect(placeForZone('America/New_York'), isNotNull);
      expect(placeForZone('Mars/Olympus'), isNull);
      expect(placeForZone(null), isNull);
      expect(placeForZone('GMT+08:00'), isNull);
    });

    test('table is sane', () {
      expect(zonePlaces.length, greaterThan(300));
      zonePlaces.forEach((zone, place) {
        expect(zone, isNotEmpty);
        expect(place.latitude, inInclusiveRange(-90, 90), reason: zone);
        expect(place.longitude, inInclusiveRange(-180, 180), reason: zone);
        expect(place.city, isNotEmpty, reason: zone);
      });
    });
  });

  group('service', () {
    test('url carries only the rounded city coordinates', () async {
      final net = Net(body(0));
      final service = await open(net, Clock());
      await service.refresh();
      final url = net.calls.single;
      expect(url.host, 'api.open-meteo.com');
      expect(url.path, '/v1/forecast');
      expect(url.queryParameters, {
        'latitude': '1.35',
        'longitude': '103.82',
        'current': 'weather_code',
        'timezone': 'auto',
      });
    });

    for (final (code, weather) in [
      (0, Weather.clear),
      (3, Weather.cloudy),
      (63, Weather.rain),
      (95, Weather.storm),
    ]) {
      test('code $code gives ${weather.name}', () async {
        final service = await open(Net(body(code)), Clock());
        await service.refresh();
        expect(service.state.live, weather);
        expect(service.state.value, weather);
      });
    }

    test('failure with nothing known is clear', () async {
      final net = Net(body(95))..fail = true;
      final service = await open(net, Clock());
      await service.refresh();
      expect(service.state.value, Weather.clear);
    });

    test('unknown or missing zone never fetches', () async {
      for (final zone in <String?>['Mars/Olympus', null]) {
        final net = Net(body(95));
        final service = await open(net, Clock(), zone: zone);
        await service.refresh();
        expect(net.calls, isEmpty);
        expect(service.state.value, Weather.clear);
      }
    });

    test('malformed bodies are ignored', () async {
      for (final response in [
        'not json',
        '[]',
        '{}',
        '{"current": 5}',
        body('95'),
        body(null),
        body(3.5),
      ]) {
        final net = Net(response);
        final clock = Clock();
        final service = await open(net, clock);
        await service.refresh();
        expect(service.state.value, Weather.clear, reason: response);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(weatherCacheKey), isNull, reason: response);
      }
    });

    test('a failure keeps the last known value', () async {
      final net = Net(body(95));
      final clock = Clock();
      final service = await open(net, clock);
      await service.refresh();
      net.fail = true;
      clock.now = clock.now.add(const Duration(minutes: 30));
      await service.refresh();
      expect(net.calls, hasLength(2));
      expect(service.state.live, Weather.storm);
    });

    test('a malformed refresh keeps the last known value', () async {
      final net = Net(body(63));
      final clock = Clock();
      final service = await open(net, clock);
      await service.refresh();
      net.response = 'garbage';
      clock.now = clock.now.add(const Duration(minutes: 30));
      await service.refresh();
      expect(service.state.live, Weather.rain);
    });

    test('fresh cache skips the network, an old one refetches', () async {
      final net = Net(body(3));
      final clock = Clock();
      final service = await open(net, clock);
      await service.refresh();
      clock.now = clock.now.add(const Duration(minutes: 19));
      await service.refresh();
      expect(net.calls, hasLength(1));
      clock.now = clock.now.add(const Duration(minutes: 2));
      net.response = body(61);
      await service.refresh();
      expect(net.calls, hasLength(2));
      expect(service.state.live, Weather.rain);
    });

    test('the cache survives a restart and is not refetched', () async {
      final net = Net(body(95));
      final clock = Clock();
      final first = await open(net, clock);
      await first.refresh();
      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString(weatherCacheKey)!) as Map;
      expect(stored['code'], 95);

      final net2 = Net(body(0));
      clock.now = clock.now.add(const Duration(minutes: 5));
      final second = await open(
        net2,
        clock,
        prefs: {weatherCacheKey: prefs.getString(weatherCacheKey)!},
      );
      expect(second.state.live, Weather.storm);
      await second.refresh();
      expect(net2.calls, isEmpty);
      expect(second.state.live, Weather.storm);
    });

    test('a value older than 2 hours is clear', () async {
      final net = Net(body(95));
      final clock = Clock();
      final service = await open(net, clock);
      await service.refresh();
      net.fail = true;
      clock.now = clock.now.add(const Duration(hours: 1, minutes: 59));
      await service.refresh();
      expect(service.state.live, Weather.storm);
      clock.now = clock.now.add(const Duration(minutes: 2));
      await service.refresh();
      expect(service.state.live, Weather.clear);
    });

    test('a stale stored value loads as clear', () async {
      final clock = Clock();
      final old = clock.now.subtract(const Duration(hours: 3));
      final service = await open(
        Net(body(0))..fail = true,
        clock,
        prefs: {
          weatherCacheKey: jsonEncode({
            'code': 95,
            'fetchedAt': old.millisecondsSinceEpoch,
          }),
        },
      );
      expect(service.state.value, Weather.clear);
    });

    test('a corrupt stored value is ignored', () async {
      final service = await open(
        Net(body(0)),
        Clock(),
        prefs: {weatherCacheKey: '{oops'},
      );
      expect(service.state.value, Weather.clear);
    });

    test('concurrent refreshes share one request', () async {
      final net = Net(body(3));
      final service = await open(net, Clock());
      await Future.wait([service.refresh(), service.refresh()]);
      expect(net.calls, hasLength(1));
    });
  });

  group('state', () {
    test('live notifies listeners', () {
      final state = WeatherState();
      var calls = 0;
      state.addListener(() => calls++);
      state.live = Weather.rain;
      expect(state.value, Weather.rain);
      expect(calls, 1);
    });

    test('override wins over live and clears back', () {
      final state = WeatherState()..live = Weather.rain;
      state.override = Weather.storm;
      expect(state.value, Weather.storm);
      state.live = Weather.cloudy;
      expect(state.value, Weather.storm);
      expect(state.live, Weather.cloudy);
      state.override = null;
      expect(state.value, Weather.cloudy);
    });
  });
}
