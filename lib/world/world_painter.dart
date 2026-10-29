import 'dart:math' as math;
import 'dart:ui' as ui;

import 'pixel_buffer.dart';
import 'sky.dart';

class Layout {
  Layout.forRows(this.rows) : k = rows / refRows;

  static const int refRows = 280;
  static const int refGround = 108;
  static const int benchX = 14;
  static const int lampX = 3;
  static const int bushFrom = 52;
  static const int bushTo = 94;
  static final Layout reference = Layout.forRows(refRows);

  final int rows;
  final double k;

  int y(num ref) => roundHalfUp(f32(ref * k));

  int get ground => y(refGround);
  int get benchY => y(128) - 18;
  int get lampY => y(128) - 41;
  int get glowY => lampY + 8;
  int get lanternY => lampY + 5;
  int get riverTopY => y(136);
  int get riverBotY => y(184);
  int bushBase(int lane) => y(129 + lane);
  int foxFeet(int lane) => y(214 + lane);
  List<int> get duckFeet => [y(150), y(163), y(176)];

  int fromGround(int ref) => ref + ground - refGround;

  int riverTop(int x) =>
      riverTopY + roundHalfUp(f32(2 * _sin(f32(x * f32(0.08)))));
  int riverBot(int x) =>
      riverBotY + roundHalfUp(f32(2 * _sin(f32(f32(x * f32(0.06)) + 1))));

  @override
  bool operator ==(Object other) => other is Layout && other.rows == rows;

  @override
  int get hashCode => rows.hashCode;
}

double _sin(double v) => f32(math.sin(v));

const List<List<int>> _bayer = [
  [0, 8, 2, 10],
  [12, 4, 14, 6],
  [3, 11, 1, 9],
  [15, 7, 13, 5],
];

int _quant(int c) {
  int ch(int shift) =>
      math.min(255, roundToInt(f32(((c >> shift) & 0xFF) / 16)) * 16);
  return 0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

class _Tower {
  const _Tower(this.x, this.w, this.top, this.crown, this.wall);

  final int x;
  final int w;
  final int top;
  final String crown;
  final bool wall;

  _Tower shifted(int dy) => _Tower(x, w, top + dy, crown, wall);
}

PixelBuffer paintWorldBuffer(double hour, int rows) {
  hour = f32(hour);
  final layout = Layout.forRows(rows);
  final g = layout.ground;
  final up = layout.fromGround;
  const w = worldW;
  final buf = PixelBuffer(w, rows);
  final sky = skyAt(hour);
  final night = sky.stars;
  final r = Mulberry(7);
  final nightHalf = f32(night * 0.5);
  final nightFore = f32(night * f32(0.55));
  int t(int c, double k) =>
      mixColor(mixColor(c, sky.bottom, k), rgb(0x08121A), nightHalf);
  int f(int c) => mixColor(c, rgb(0x0B1510), nightFore);
  final skyBottom = mixColor(sky.bottom, rgb(0x10222E), f32(night * f32(0.75)));

  for (var y = 0; y < g; y++) {
    final k = f32(y / (g - 2));
    final base = List<double>.generate(3, (i) {
      final shift = 16 - 8 * i;
      final a = (sky.top >> shift) & 0xFF;
      final b = (skyBottom >> shift) & 0xFF;
      return f32(a + f32((b - a) * k));
    });
    for (var x = 0; x < w; x++) {
      final th = f32(f32(_bayer[y & 3][x & 3] + 0.5) / 16);
      final c = List<int>.generate(
        3,
        (i) => math.min(255, f32(f32(base[i] / 8) + th).floor() * 8),
      );
      buf.set(x, y, rgb((c[0] << 16) | (c[1] << 8) | c[2]));
    }
  }

  final stars = Mulberry(3);
  final starAlpha = f32(night * f32(0.85)).clamp(0.0, 1.0).toDouble();
  for (var n = 0; n < 26; n++) {
    final sx = stars.below(w);
    final sy = up(f32(stars.below(90) * 0.5).truncate());
    buf.rect(sx, sy, 1, 1, rgb(0xF3ECDC), starAlpha);
  }

  final day = hour >= 6 && hour <= 18;
  final shifted = hour < 6 ? f32(hour + 24) : hour;
  final p = day
      ? f32(f32(hour - 6) / 12)
      : f32(f32(shifted - 18) / 12).clamp(0.0, 1.0).toDouble();
  final cx = roundToInt(f32(w * f32(f32(0.12) + f32(f32(0.76) * p))));
  final cy = up(roundHalfUp(f32(54 - f32(36 * _sin(f32(piF * p))))));
  final body = day ? rgb(0xF6D77A) : rgb(0xF1E3B8);
  buf.disc(cx, cy, 10, body, f32(0.16));
  buf.disc(cx, cy, 6, body);

  buf.ridge(up(48).toDouble(), 5, 2, f32(1.4), t(rgb(0x2F4F3E), 0.5));
  const farTowers = [
    [62, 6, 50],
    [76, 5, 42],
    [90, 6, 46],
    [101, 5, 36],
    [113, 6, 44],
  ];
  for (final tw in farTowers) {
    buf.rect(
      tw[0],
      up(tw[2]),
      tw[1],
      g - up(tw[2]),
      t(rgb(0x20383A), f32(0.7)),
    );
  }
  buf.ridge(
    up(70).toDouble(),
    5,
    f32(3.4),
    f32(1.4),
    t(rgb(0x1B3427), f32(0.3)),
  );

  const placed = [
    _Tower(70, 12, 40, 'garden', true),
    _Tower(83, 10, 24, 'spire', false),
    _Tower(94, 13, 54, 'stepped', true),
    _Tower(108, 12, 34, 'garden', false),
  ];
  final towers = [for (final tw in placed) tw.shifted(up(0))];
  final windowLit = f32(night * f32(0.55));
  for (final tw in towers) {
    final col = t(rgb(0x20383A), f32(0.28));
    final leaf = t(rgb(0x2F6A45), f32(0.15));
    buf.rect(tw.x, tw.top, tw.w, g - tw.top, col);
    switch (tw.crown) {
      case 'stepped':
        buf.rect(tw.x + 3, tw.top - 5, tw.w - 6, 5, col);
      case 'spire':
        buf.rect(tw.x + tw.w ~/ 2, tw.top - 9, 1, 9, col);
      case 'garden':
        buf.rect(tw.x, tw.top - 1, tw.w, 1, leaf);
        for (var i = 0; i < tw.w; i += 3) {
          buf.rect(tw.x + i, tw.top - 2, 2, 1, leaf);
        }
        buf.rect(tw.x + tw.w - 4, tw.top - 5, 1, 4, t(rgb(0x12261C), f32(0.2)));
        buf.disc(tw.x + tw.w - 4, tw.top - 7, 2, t(rgb(0x1C4630), f32(0.15)));
    }
    for (var wy = tw.top + 3; wy < g - 6; wy += 4) {
      for (var wx = tw.x + 2; wx < tw.x + tw.w - 1; wx += 3) {
        buf.rect(
          wx,
          wy,
          1,
          2,
          r.next() < windowLit ? rgb(0xFFD98A) : t(rgb(0x2F5A52), f32(0.35)),
        );
      }
    }
    if (tw.wall) {
      final ly = tw.top + roundToInt(f32((g - tw.top) * f32(0.3)));
      buf.rect(tw.x, ly, tw.w, 1, leaf);
      buf.rect(tw.x + 2, ly + 1, 1, 4, leaf);
    }
  }

  final leaf = t(rgb(0x1C4630), f32(0.2));
  final light = t(rgb(0x2A5A3A), f32(0.2));
  final trunk = t(rgb(0x12261C), f32(0.2));
  void tree(int tx, int top, double k) {
    int s(int v) => roundToInt(f32(v * k));
    buf.rect(tx - 1, top + s(18), 3, g - top - s(18), trunk);
    buf.rect(tx - 3, g - 4, 7, 4, trunk);
    buf.blob(tx, top + s(10), s(12), s(10), leaf);
    buf.blob(tx - s(8), top + s(14), s(8), s(7), leaf);
    buf.blob(tx + s(8), top + s(13), s(9), s(7), leaf);
    buf.blob(tx - 2, top + s(6), s(7), s(5), light);
  }

  tree(22, up(50), 1);
  tree(47, up(68), 0.75);
  for (var x = 0; x < w; x++) {
    final wave = f32(2 * _sin(f32(x * f32(0.35))));
    final y = g - 8 + roundHalfUp(f32(wave + f32(r.next() * 2)));
    buf.rect(x, y, 1, g + 4 - y, leaf);
  }

  final stripeA = f(rgb(0x2B6038));
  final stripeB = f(rgb(0x2F6A3F));
  for (var y = g; y < rows; y += 8) {
    buf.rect(
      0,
      y,
      w,
      math.min(8, rows - y),
      ((y - g) ~/ 8) % 2 != 0 ? stripeA : stripeB,
    );
  }
  buf.rect(0, g, w, 3, f(rgb(0x3A7A45)));
  final span = math.max(rows - g - 12, 60);
  final dark = f(rgb(0x1F4A30));
  final bright = f(rgb(0x47904F));
  final specks = 220 * span ~/ 148;
  for (var n = 0; n < specks; n++) {
    final x = r.below(w);
    final y = g + 4 + r.below(span);
    buf.rect(x, y, 1, 1, r.next() < 0.5 ? dark : bright);
  }

  final waterTop = mixColor(rgb(0x58A8C0), sky.bottom, f32(0.2));
  final waterBottom = mixColor(rgb(0x2F7A94), sky.bottom, f32(0.2));
  final bank = f(rgb(0xA89A68));
  for (var x = 0; x < w; x++) {
    final top = layout.riverTop(x);
    final bot = layout.riverBot(x);
    buf.rect(x, top - 3, 1, bot - top + 6, bank);
    for (var yy = top; yy < bot; yy++) {
      buf.rect(
        x,
        yy,
        1,
        1,
        f(
          _quant(
            mixColor(waterTop, waterBottom, f32((yy - top) / (bot - top))),
          ),
        ),
      );
    }
  }
  final glint = f(rgb(0x9FD0E0));
  for (var n = 0; n < 64; n++) {
    final x = r.below(w - 6);
    final yy =
        layout.riverTopY + 3 + r.below(layout.riverBotY - layout.riverTopY - 6);
    if (yy > layout.riverTop(x) + 1 && yy < layout.riverBot(x) - 1) {
      buf.rect(x, yy, 3 + r.below(4), 1, glint);
    }
  }

  if (night > f32(0.05)) {
    buf.disc(7, layout.glowY, 14, rgb(0xFFD98A), f32(f32(0.07) * night));
    buf.disc(7, layout.glowY, 8, rgb(0xFFD98A), f32(f32(0.12) * night));
  }
  return buf;
}

Future<ui.Image> paintWorld(double hour, int rows) =>
    paintWorldBuffer(hour, rows).toImage();
