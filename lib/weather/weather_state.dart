import 'package:flutter/foundation.dart';

enum Weather { clear, cloudy, rain, storm }

class WeatherState extends ValueNotifier<Weather> {
  WeatherState() : super(Weather.clear);

  Weather _live = Weather.clear;
  Weather? _override;

  Weather get live => _live;
  Weather? get override => _override;

  set live(Weather weather) {
    _live = weather;
    value = _override ?? _live;
  }

  set override(Weather? weather) {
    _override = weather;
    value = _override ?? _live;
  }
}
