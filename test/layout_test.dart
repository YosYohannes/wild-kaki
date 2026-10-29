import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/world/pixel_buffer.dart';
import 'package:wildkaki/world/world_painter.dart';

int _fnv(List<int> px) {
  var h = 0x811C9DC5;
  for (final p in px) {
    h = ((h ^ p) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

int _sum(List<int> px) => px.fold(0, (a, b) => a + b);

void main() {
  group('reference layout (280 rows)', () {
    final l = Layout.forRows(280);

    test('matches the original constants', () {
      expect(l.ground, 108);
      expect(l.benchY, 110);
      expect(l.lampY, 87);
      expect(l.glowY, 95);
      expect(l.lanternY, 92);
      expect(l.riverTopY, 136);
      expect(l.riverBotY, 184);
      expect(l.riverTop(0), 136);
      expect(l.riverBot(0), 184 + roundHalfUp(2 * 0.8414709848));
      expect([for (var i = 0; i < 3; i++) l.bushBase(i)], [129, 130, 131]);
      expect(l.duckFeet, [150, 163, 176]);
      expect(l.foxFeet(0), 214);
      expect(l.foxFeet(21), 235);
      expect(Layout.benchX, 14);
      expect(Layout.lampX, 3);
      expect(Layout.bushFrom, 52);
      expect(Layout.bushTo, 94);
      for (var x = 0; x < worldW; x++) {
        expect(l.riverBot(x) - l.riverTop(x), greaterThan(40));
      }
    });

    test('world pixels are unchanged', () {
      final noon = paintWorldBuffer(12, 280).pixels;
      final night = paintWorldBuffer(23, 280).pixels;
      expect(_fnv(noon), 431226527);
      expect(_sum(noon), 143864287860014);
      expect(_fnv(night), 1821486636);
      expect(_sum(night), 143809909622075);
    });
  });

  for (final rows in [213, 330]) {
    test('zones scale with the height at $rows rows', () {
      final l = Layout.forRows(rows);
      final k = rows / 280;
      expect(l.ground, (108 * k).round());
      expect(l.riverTopY, (136 * k).round());
      expect(l.riverBotY, (184 * k).round());
      expect(l.benchY, (128 * k).round() - 18);
      expect(l.lampY, (128 * k).round() - 41);
      expect(l.ground, lessThan(l.riverTopY - 3));
      expect(l.riverBotY + 3, lessThan(l.foxFeet(0)));
      for (var x = 0; x < worldW; x++) {
        expect(l.riverTop(x) - 3, greaterThanOrEqualTo(0));
        expect(l.riverBot(x) + 3, lessThan(rows));
        expect(l.riverTop(x), lessThan(l.riverBot(x)));
        expect(l.riverTop(x) - l.riverTopY, inInclusiveRange(-2, 2));
        expect(l.riverBot(x) - l.riverBotY, inInclusiveRange(-2, 2));
      }
      for (var i = 0; i < 22; i++) {
        expect(l.foxFeet(i), lessThan(rows));
        expect(l.foxFeet(i), greaterThan(l.riverBotY + 3));
      }
      for (final d in l.duckFeet) {
        expect(d, greaterThan(l.riverTopY));
        expect(d, lessThan(l.riverBotY + 8));
      }
    });

    test('world renders at $rows rows with the river on screen', () {
      final l = Layout.forRows(rows);
      final b = paintWorldBuffer(12, rows);
      expect(b.height, rows);
      final bank = b.at(60, l.riverTop(60) - 2);
      final water = b.at(60, l.riverTop(60) + 2);
      expect(bank, isNot(water));
      expect(b.at(30, l.ground), 0xFF3A7A45);
    });
  }

  for (final rows in [213, 260, 280, 330]) {
    test('bench and lamppost stand on the bank at $rows rows', () {
      final l = Layout.forRows(rows);
      expect(l.benchY + 18, lessThan(l.riverTopY - 1));
      expect(l.lampY + 41, lessThan(l.riverTopY - 1));
      expect(l.benchY + 18, l.lampY + 41);
    });
  }
}
