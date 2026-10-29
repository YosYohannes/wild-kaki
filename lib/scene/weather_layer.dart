import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../weather/weather_state.dart';
import '../world/pixel_buffer.dart';
import '../world/world_painter.dart';

const double fadeSeconds = 0.8;

class WeatherView {
  WeatherView(this.to);

  Weather to;
  Weather? from;
  double fade = 1;

  void change(Weather next, {required bool animate}) {
    if (next == to) return;
    from = animate ? to : null;
    to = next;
    fade = animate ? 0 : 1;
  }

  void step(double dt) {
    if (from == null) return;
    fade += dt / fadeSeconds;
    if (fade >= 1) {
      fade = 1;
      from = null;
    }
  }
}

class _Palette {
  const _Palette(this.light, this.mid, this.dark);

  final int light;
  final int mid;
  final int dark;
}

class _Look {
  const _Look({
    this.tint = 0xFF000000,
    this.tintAlpha = 0,
    this.skyAlpha = 0,
    this.clouds = const [],
    this.day = const _Palette(0, 0, 0),
    this.night = const _Palette(0, 0, 0),
    this.streaks = 0,
    this.slant = 0,
    this.speed = 0,
    this.ripples = 0,
    this.rippleRadius = 0,
    this.rippleMin = 1,
    this.rippleMax = 1,
  });

  final int tint;
  final double tintAlpha;
  final double skyAlpha;
  final List<(int, double, double)> clouds;
  final _Palette day;
  final _Palette night;
  final int streaks;
  final double slant;
  final double speed;
  final int ripples;
  final int rippleRadius;
  final double rippleMin;
  final double rippleMax;
}

final _looks = <Weather, _Look>{
  Weather.clear: const _Look(),
  Weather.cloudy: _Look(
    tint: rgb(0x9AA8A8),
    tintAlpha: 0.14,
    skyAlpha: 0.06,
    clouds: const [
      (1, 0.47, 0.25),
      (0, 0.04, 0.05),
      (2, 0.8, 0.55),
      (1, 0.22, 0.7),
      (0, 0.68, 0.4),
    ],
    day: _Palette(rgb(0xE4EAEC), rgb(0xC4CFD5), rgb(0x9CABB5)),
    night: _Palette(rgb(0x4A5A70), rgb(0x354454), rgb(0x24303D)),
  ),
  Weather.rain: _Look(
    tint: rgb(0x1C2A30),
    tintAlpha: 0.26,
    skyAlpha: 0.12,
    clouds: const [
      (1, 0.0, 0.55),
      (2, 0.17, 0.12),
      (0, 0.34, 0.45),
      (2, 0.46, 0.2),
      (1, 0.62, 0.62),
      (3, 0.78, 0.04),
      (1, 0.9, 0.35),
    ],
    day: _Palette(rgb(0xA3B1BB), rgb(0x7F8E9C), rgb(0x5E6C7A)),
    night: _Palette(rgb(0x3A4858), rgb(0x2A3643), rgb(0x1C2630)),
    streaks: 40,
    slant: 0.34,
    speed: 78,
    ripples: 8,
    rippleRadius: 4,
    rippleMin: 1.5,
    rippleMax: 2.4,
  ),
  Weather.storm: _Look(
    tint: rgb(0x101822),
    tintAlpha: 0.4,
    skyAlpha: 0.22,
    clouds: const [
      (3, 0.0, 0.1),
      (2, 0.17, 0.5),
      (3, 0.33, 0.25),
      (3, 0.52, 0.6),
      (1, 0.66, 0.02),
      (3, 0.76, 0.35),
      (2, 0.9, 0.15),
    ],
    day: _Palette(rgb(0x6C7886), rgb(0x4D5866), rgb(0x364050)),
    night: _Palette(rgb(0x2E3946), rgb(0x212B36), rgb(0x161D27)),
    streaks: 80,
    slant: 0.8,
    speed: 105,
    ripples: 13,
    rippleRadius: 7,
    rippleMin: 0.9,
    rippleMax: 1.5,
  ),
};

class _Shape {
  _Shape(List<(int, int)> domes) {
    var left = 1 << 30;
    var right = 0;
    var top = 0;
    for (final (cx, r) in domes) {
      left = math.min(left, cx - r);
      right = math.max(right, cx + r);
      top = math.max(top, r);
    }
    w = right - left + 1;
    h = top + 1;
    final cells = List.generate(h, (_) => List.filled(w, false));
    for (final (cx, r) in domes) {
      for (var y = 0; y < h; y++) {
        final dy = h - 1 - y;
        if (dy > r) continue;
        final half = math.sqrt((r + 0.5) * (r + 0.5) - dy * dy).floor();
        for (var x = cx - half; x <= cx + half; x++) {
          cells[y][x - left] = true;
        }
      }
    }
    final darkRows = h >= 8 ? 2 : 1;
    for (var y = 0; y < h; y++) {
      var x = 0;
      while (x < w) {
        if (!cells[y][x]) {
          x++;
          continue;
        }
        int tone(int xx) {
          if (y >= h - darkRows) return 2;
          return y == 0 || !cells[y - 1][xx] ? 0 : 1;
        }

        final t = tone(x);
        var e = x + 1;
        while (e < w && cells[y][e] && tone(e) == t) {
          e++;
        }
        runs.add((x, y, e - x, t));
        x = e;
      }
    }
  }

  late final int w;
  late final int h;
  final runs = <(int, int, int, int)>[];
}

final _shapes = [
  _Shape([(5, 4), (11, 6), (17, 4)]),
  _Shape([(7, 5), (15, 8), (24, 6), (31, 4)]),
  _Shape([(8, 6), (18, 10), (30, 8), (40, 6), (46, 4)]),
  _Shape([(10, 8), (24, 12), (40, 10), (54, 7), (62, 5)]),
];

class _Cloud {
  _Cloud(this.shape, this.x0, this.lane, this.speed);

  final _Shape shape;
  final double x0;
  final double lane;
  final double speed;
}

class _Streak {
  _Streak(this.x0, this.y0, this.speed);

  final double x0;
  final double y0;
  final double speed;
}

final _cloudSets = <Weather, List<_Cloud>>{};
final _streakSets = <Weather, List<_Streak>>{};
final _rings = <int, List<(int, int)>>{};

List<_Cloud> _cloudsFor(Weather w, _Look look) => _cloudSets.putIfAbsent(w, () {
  final r = Mulberry(40 + w.index);
  return [
    for (final (shape, x0, lane) in look.clouds)
      _Cloud(_shapes[shape], x0, lane, 1.2 + r.next() * 1.6),
  ];
});

List<_Streak> _streaksFor(Weather w, _Look look) =>
    _streakSets.putIfAbsent(w, () {
      final r = Mulberry(90 + w.index);
      return [
        for (var i = 0; i < look.streaks; i++)
          _Streak(r.next(), r.next(), 0.85 + r.next() * 0.3),
      ];
    });

List<(int, int)> _ring(int r) => _rings.putIfAbsent(r, () {
  if (r == 0) return const [(0, 0)];
  final ry = (r * 0.45).round();
  final seen = <(int, int)>{};
  for (var i = 0; i < 48; i++) {
    final a = i / 48 * 2 * math.pi;
    seen.add(((r * math.cos(a)).round(), (ry * math.sin(a)).round()));
  }
  return seen.toList();
});

int _mix(int a, int b, double t) => mixColor(a, b, t);

class WeatherLayer {
  WeatherLayer(this.view);

  final WeatherView view;

  static final _fill = Paint()..isAntiAlias = false;

  bool get active => view.to != Weather.clear || view.from != null;

  double _opacity(Weather w) {
    final from = view.from;
    if (from == null) return w == view.to ? 1 : 0;
    var o = 0.0;
    if (w == view.to) o += view.fade;
    if (w == from) o += 1 - view.fade;
    return o;
  }

  (Color, double, double)? _blend(double night) {
    final a = _looks[view.from ?? view.to]!;
    final b = _looks[view.to]!;
    final t = view.from == null ? 1.0 : view.fade;
    final alpha = a.tintAlpha + (b.tintAlpha - a.tintAlpha) * t;
    final sky = a.skyAlpha + (b.skyAlpha - a.skyAlpha) * t;
    if (alpha <= 0.001) return null;
    final int rgbValue;
    if (a.tintAlpha == 0) {
      rgbValue = b.tint;
    } else if (b.tintAlpha == 0) {
      rgbValue = a.tint;
    } else {
      rgbValue = _mix(a.tint, b.tint, t);
    }
    final k = 1 - 0.35 * night;
    return (Color(rgbValue), alpha * k, sky * k);
  }

  Color? dim(double night) {
    final t = _blend(night);
    return t?.$1.withValues(alpha: t.$2);
  }

  void paintTint(Canvas canvas, Size size, Layout layout, double night) {
    final t = _blend(night);
    if (t == null) return;
    canvas.drawRect(
      Offset.zero & size,
      _fill..color = t.$1.withValues(alpha: t.$2),
    );
    final s = size.width / worldW;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, (layout.ground * s).roundToDouble()),
      _fill..color = t.$1.withValues(alpha: t.$3),
    );
  }

  void paintParticles(
    Canvas canvas,
    Size size,
    Layout layout,
    double night,
    double time,
  ) {
    final from = view.from;
    if (from != null) _layer(canvas, size, layout, night, time, from);
    _layer(canvas, size, layout, night, time, view.to);
  }

  void _layer(
    Canvas canvas,
    Size size,
    Layout layout,
    double night,
    double time,
    Weather w,
  ) {
    final look = _looks[w]!;
    if (look.clouds.isEmpty) return;
    final opacity = _opacity(w);
    if (opacity <= 0) return;
    final s = size.width / worldW;
    final fading = opacity < 1;
    if (fading) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }
    if (look.ripples > 0) _ripples(canvas, s, layout, night, time, look);
    _clouds(canvas, s, layout, night, time, w, look);
    if (look.streaks > 0) {
      _rain(canvas, size, s, night, time, w, look);
    }
    if (fading) canvas.restore();
  }

  void _px(Canvas canvas, double s, int x, int y, int w, int h) {
    canvas.drawRect(
      Rect.fromLTRB(
        (x * s).roundToDouble(),
        (y * s).roundToDouble(),
        ((x + w) * s).roundToDouble(),
        ((y + h) * s).roundToDouble(),
      ),
      _fill,
    );
  }

  void _clouds(
    Canvas canvas,
    double s,
    Layout layout,
    double night,
    double time,
    Weather w,
    _Look look,
  ) {
    final tones = [
      _mix(look.day.light, look.night.light, night),
      _mix(look.day.mid, look.night.mid, night),
      _mix(look.day.dark, look.night.dark, night),
    ];
    final colors = [for (final c in tones) Color(c)];
    for (final c in _cloudsFor(w, look)) {
      final cycle = worldW + c.shape.w + 8;
      final x = ((c.x0 * cycle + c.speed * time) % cycle).floor() - c.shape.w;
      final y =
          3 + (c.lane * math.max(0, layout.ground - 52 - c.shape.h)).floor();
      for (final (rx, ry, rw, tone) in c.shape.runs) {
        _fill.color = colors[tone];
        _px(canvas, s, x + rx, y + ry, rw, 1);
      }
    }
  }

  void _rain(
    Canvas canvas,
    Size size,
    double s,
    double night,
    double time,
    Weather w,
    _Look look,
  ) {
    final rows = (size.height / s).ceil();
    final span = rows + 3;
    final color = Color(_mix(rgb(0xB8CCDA), rgb(0x7C93A8), night * 0.7));
    _fill.color = color.withValues(alpha: 0.8);
    final lean = [for (var i = 0; i < 3; i++) (i * look.slant).round()];
    for (final d in _streaksFor(w, look)) {
      final v = look.speed * d.speed;
      final y = ((d.y0 * span + v * time) % span).floor() - 3;
      final x = ((d.x0 * worldW + v * look.slant * time) % worldW).floor();
      for (var i = 0; i < 3; i++) {
        _px(canvas, s, x + lean[i], y + i, 1, 1);
      }
    }
  }

  void _ripples(
    Canvas canvas,
    double s,
    Layout layout,
    double night,
    double time,
    _Look look,
  ) {
    final bright = _mix(rgb(0xDCF0F6), rgb(0x7FA0B0), night * 0.6);
    for (var i = 0; i < look.ripples; i++) {
      final h = Mulberry(500 + i * 17 + look.rippleRadius);
      final period =
          look.rippleMin + h.next() * (look.rippleMax - look.rippleMin);
      final phase = h.next();
      final u = time / period + phase;
      final cycle = u.floor();
      final p = u - cycle;
      final at = Mulberry(i * 7919 + cycle * 104729 + look.rippleRadius);
      final x = 6 + at.below(worldW - 12);
      final top = layout.riverTop(x) + 3;
      final bot = layout.riverBot(x) - 3;
      final y = top + at.below(math.max(1, bot - top));
      final r = (p * (look.rippleRadius + 1)).floor();
      _fill.color = Color(bright).withValues(alpha: 0.9 * (1 - p));
      for (final (dx, dy) in _ring(r)) {
        _px(canvas, s, x + dx, y + dy, 1, 1);
      }
    }
  }
}

ui.Color combineDim(ui.Color night, ui.Color weather) {
  final a = weather.a + night.a * (1 - weather.a);
  double c(double w, double n) =>
      (w * weather.a + n * night.a * (1 - weather.a)) / a;
  return ui.Color.from(
    alpha: a,
    red: c(weather.r, night.r),
    green: c(weather.g, night.g),
    blue: c(weather.b, night.b),
  );
}
