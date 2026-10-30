import '../weather/weather_service.dart';

typedef TimeZoneProvider = String? Function();

class PhoneTimeZone {
  PhoneTimeZone([this._read = deviceTimeZone]);

  final Future<String?> Function() _read;
  String? _zone;

  String? get zone => _zone;

  Future<void> refresh() async {
    _zone = await _read() ?? _zone;
  }
}
