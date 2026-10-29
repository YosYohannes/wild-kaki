import 'weather_state.dart';

const _byCode = <int, Weather>{
  2: Weather.cloudy,
  3: Weather.cloudy,
  45: Weather.cloudy,
  48: Weather.cloudy,
  51: Weather.rain,
  53: Weather.rain,
  55: Weather.rain,
  56: Weather.rain,
  57: Weather.rain,
  61: Weather.rain,
  63: Weather.rain,
  65: Weather.rain,
  66: Weather.rain,
  67: Weather.rain,
  71: Weather.cloudy,
  73: Weather.cloudy,
  75: Weather.cloudy,
  77: Weather.cloudy,
  80: Weather.rain,
  81: Weather.rain,
  82: Weather.rain,
  85: Weather.cloudy,
  86: Weather.cloudy,
  95: Weather.storm,
  96: Weather.storm,
  99: Weather.storm,
};

Weather weatherFromCode(int? code) => _byCode[code] ?? Weather.clear;
