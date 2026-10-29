import 'dart:math' as math;

import 'pixel_buffer.dart';

class Sky {
  const Sky(this.top, this.bottom, this.stars);

  final int top;
  final int bottom;
  final double stars;
}

class _SkyKey {
  _SkyKey(this.hour, this.top, this.bottom, this.stars);

  final double hour;
  final int top;
  final int bottom;
  final double stars;
}

final int _nightTop = rgb(0x0A1620);
final int _nightBottom = rgb(0x1B3427);
final int _dayTop = rgb(0x2B5E52);
final int _dayBottom = rgb(0x3E7A66);

final List<_SkyKey> _skyKeys = [
  _SkyKey(0, _nightTop, _nightBottom, 1),
  _SkyKey(4.75, _nightTop, _nightBottom, 1),
  _SkyKey(5.75, rgb(0x16223C), rgb(0x35405A), 0.75),
  _SkyKey(6.75, rgb(0x3B4A6B), rgb(0xD98A5B), f32(0.3)),
  _SkyKey(9, _dayTop, _dayBottom, 0),
  _SkyKey(16, _dayTop, _dayBottom, 0),
  _SkyKey(18, rgb(0x4A3F6B), rgb(0xE0875A), f32(0.3)),
  _SkyKey(19.1, rgb(0x262448), rgb(0x5A3A55), f32(0.65)),
  _SkyKey(20.5, _nightTop, _nightBottom, 1),
  _SkyKey(24, _nightTop, _nightBottom, 1),
].map((k) => _SkyKey(f32(k.hour), k.top, k.bottom, k.stars)).toList();

double currentHour() {
  final now = DateTime.now();
  return f32(now.hour + f32(now.minute / 60));
}

Sky skyAt(double hour) {
  hour = f32(hour);
  final i = math.max(
    0,
    math.min(
      _skyKeys.length - 2,
      _skyKeys.lastIndexWhere((k) => k.hour <= hour),
    ),
  );
  final a = _skyKeys[i];
  final b = _skyKeys[i + 1];
  final t = f32(f32(hour - a.hour) / f32(b.hour - a.hour))
      .clamp(0.0, 1.0)
      .toDouble();
  return Sky(
    mixColor(a.top, b.top, t),
    mixColor(a.bottom, b.bottom, t),
    f32(a.stars + f32(f32(b.stars - a.stars) * t)),
  );
}
