import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/world/pixel_buffer.dart';
import 'package:wildkaki/world/sky.dart';
import 'package:wildkaki/world/world_painter.dart';

const _out = 'build/test_shots';

void main() {
  group('Mulberry', () {
    test('seed 7 matches the reference sequence', () {
      final r = Mulberry(7);
      expect(r.next(), 0.011704753153026104);
      expect(r.next(), 0.06195825710892677);
      expect(r.next(), 0.9769076108932495);
      expect(r.next(), 0.699028730392456);
    });

    test('seed 3 matches the reference sequence', () {
      final r = Mulberry(3);
      expect(r.next(), 0.7202267646789551);
      expect(r.next(), 0.03866216167807579);
      expect(r.next(), 0.4561921954154968);
      expect(r.next(), 0.07492800801992416);
    });

    test('below stays in range and is deterministic', () {
      final a = Mulberry(11);
      final b = Mulberry(11);
      for (var i = 0; i < 200; i++) {
        final v = a.below(90);
        expect(v, b.below(90));
        expect(v, inInclusiveRange(0, 89));
      }
    });
  });

  group('colour helpers', () {
    test('rgb sets full alpha', () {
      expect(rgb(0x123456), 0xFF123456);
    });

    test('mixColor endpoints and midpoint', () {
      expect(mixColor(0xFF000000, 0xFFFFFFFF, 0), 0xFF000000);
      expect(mixColor(0xFF000000, 0xFFFFFFFF, 1), 0xFFFFFFFF);
      expect(mixColor(0xFF000000, 0xFF646464, 0.5), 0xFF323232);
      expect(mixColor(0xFF000000, 0xFFFFFFFF, 2), 0xFFFFFFFF);
    });

    test('roundHalfUp rounds ties upward', () {
      expect(roundHalfUp(2.5), 3);
      expect(roundHalfUp(-2.5), -2);
      expect(roundHalfUp(2.4), 2);
    });
  });

  group('sky', () {
    test('key hours', () {
      expect(skyAt(0).top, 0xFF0A1620);
      expect(skyAt(0).bottom, 0xFF1B3427);
      expect(skyAt(0).stars, 1);
      expect(skyAt(12).top, 0xFF2B5E52);
      expect(skyAt(12).bottom, 0xFF3E7A66);
      expect(skyAt(12).stars, 0);
      expect(skyAt(6.75).top, 0xFF3B4A6B);
      expect(skyAt(6.75).bottom, 0xFFD98A5B);
      expect(skyAt(18).top, 0xFF4A3F6B);
      expect(skyAt(18).bottom, 0xFFE0875A);
      expect(skyAt(23).top, 0xFF0A1620);
      expect(skyAt(24).top, 0xFF0A1620);
    });

    test('interpolates between keys', () {
      final s = skyAt(5.25);
      expect(s.top, 0xFF101C2E);
      expect(s.stars, closeTo(0.875, 1e-6));
    });

    test('currentHour is within a day', () {
      expect(currentHour(), inInclusiveRange(0, 24));
    });
  });

  group('paintWorld', () {
    test('noon pixels', () {
      final b = paintWorldBuffer(12, 260);
      expect(b.width, 120);
      expect(b.height, 260);
      expect(b.at(0, 0), 0xFF285850);
      final g = Layout.forRows(260).ground;
      expect(b.at(60, g - 90), 0xFFF6D77A);
      expect(b.at(30, g), 0xFF3A7A45);
    });

    test('night has lit windows and a lamp glow', () {
      final day = paintWorldBuffer(12, 260);
      final night = paintWorldBuffer(23, 260);
      expect(night.at(0, 0), isNot(day.at(0, 0)));
      final glow = Layout.forRows(260).glowY;
      expect(night.at(7, glow), isNot(day.at(7, glow)));
    });

    test('is deterministic', () {
      expect(
        paintWorldBuffer(18.5, 260).pixels,
        paintWorldBuffer(18.5, 260).pixels,
      );
    });

    testWidgets('returns an image 120 wide and rows tall, renders PNGs', (
      tester,
    ) async {
      Directory(_out).createSync(recursive: true);
      await tester.runAsync(() async {
        for (final e in {'day': 12.0, 'dusk': 18.5, 'night': 23.0}.entries) {
          final img = await paintWorld(e.value, 260);
          expect(img.width, 120);
          expect(img.height, 260);

          final rec = ui.PictureRecorder();
          final canvas = ui.Canvas(rec);
          canvas.drawImageRect(
            img,
            ui.Rect.fromLTWH(0, 0, 120, 260),
            ui.Rect.fromLTWH(0, 0, 480, 1040),
            ui.Paint()..filterQuality = ui.FilterQuality.none,
          );
          final big = await rec.endRecording().toImage(480, 1040);
          final data = await big.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/world_${e.key}.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
        }
      });
    });
  });
}
