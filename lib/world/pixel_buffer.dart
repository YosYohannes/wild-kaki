import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

const int worldW = 120;

final Float32List _single = Float32List(1);

/// Rounds to the nearest 32-bit float so arithmetic matches the original Float maths.
double f32(double v) {
  _single[0] = v;
  return _single[0];
}

final double piF = f32(math.pi);

int rgb(int hex) => 0xFF000000 | hex;

int roundHalfUp(double v) => f32(v + 0.5).floor();

int roundToInt(double v) => (v + 0.5).floor();

int mixColor(int a, int b, double t) {
  final k = f32(t).clamp(0.0, 1.0).toDouble();
  int ch(int shift) {
    final x = (a >> shift) & 0xFF;
    final y = (b >> shift) & 0xFF;
    return roundToInt(f32(x + f32((y - x) * k)));
  }

  return 0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

class Mulberry {
  Mulberry(int seed) : _s = seed & _mask;

  static const int _mask = 0xFFFFFFFF;
  int _s;

  double next() {
    _s = (_s + 0x6D2B79F5) & _mask;
    var t = ((_s ^ (_s >> 15)) * (1 | _s)) & _mask;
    t = ((t + (((t ^ (t >> 7)) * (61 | t)) & _mask)) & _mask) ^ t;
    return f32(((t ^ (t >> 14)) & _mask).toDouble()) / 4294967296.0;
  }

  int below(int n) => f32(next() * n).truncate();
}

class PixelBuffer {
  PixelBuffer(this.width, this.height) : pixels = Uint32List(width * height);

  final int width;
  final int height;
  final Uint32List pixels;

  int at(int x, int y) => pixels[y * width + x];

  void set(int x, int y, int color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      pixels[y * width + x] = color;
    }
  }

  void rect(int x, int y, int w, int h, int color, [double alpha = 1]) {
    final x1 = math.min(width, x + w);
    final y1 = math.min(height, y + h);
    for (var yy = math.max(0, y); yy < y1; yy++) {
      for (var xx = math.max(0, x); xx < x1; xx++) {
        final i = yy * width + xx;
        pixels[i] = alpha >= 1 ? color : mixColor(pixels[i], color, alpha);
      }
    }
  }

  void disc(int cx, int cy, int r, int color, [double alpha = 1]) {
    for (var y = -r; y <= r; y++) {
      for (var x = -r; x <= r; x++) {
        if (x * x + y * y <= r * r + r * 0.6) {
          rect(cx + x, cy + y, 1, 1, color, alpha);
        }
      }
    }
  }

  void blob(int cx, int cy, int rx, int ry, int color) {
    for (var y = -ry; y <= ry; y++) {
      for (var x = -rx; x <= rx; x++) {
        if (math.pow(x / rx, 2) + math.pow(y / ry, 2) <= 1.0) {
          rect(cx + x, cy + y, 1, 1, color);
        }
      }
    }
  }

  void ridge(double base, double amp, double phase, double freq, int color) {
    for (var x = 0; x < width; x++) {
      final angle = f32(
        f32(f32(f32(f32(x / worldW) * 2) * piF) * freq) + phase,
      );
      final y = roundHalfUp(f32(base + f32(amp * f32(math.sin(angle)))));
      rect(x, y, 1, height - y, color);
    }
  }

  Future<ui.Image> toImage() {
    final bytes = Uint8List(width * height * 4);
    for (var i = 0; i < pixels.length; i++) {
      final p = pixels[i];
      bytes[i * 4] = (p >> 16) & 0xFF;
      bytes[i * 4 + 1] = (p >> 8) & 0xFF;
      bytes[i * 4 + 2] = p & 0xFF;
      bytes[i * 4 + 3] = (p >> 24) & 0xFF;
    }
    return _decode(bytes, width, height);
  }
}

Future<ui.Image> _decode(Uint8List bytes, int w, int h) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    bytes,
    w,
    h,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}
