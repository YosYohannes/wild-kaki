import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

class _Wav {
  _Wav(this.rate, this.channels, this.bits, this.samples);
  final int rate;
  final int channels;
  final int bits;
  final List<int> samples;
  double get seconds => samples.length / channels / rate;
  double get peak =>
      samples.fold<int>(0, (m, s) => s.abs() > m ? s.abs() : m) / 32768;
}

_Wav _parse(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  String tag(int o) => String.fromCharCodes(bytes.sublist(o, o + 4));
  expect(tag(0), 'RIFF');
  expect(tag(8), 'WAVE');
  var o = 12;
  int rate = 0, channels = 0, bits = 0;
  while (o + 8 <= bytes.length) {
    final size = d.getUint32(o + 4, Endian.little);
    if (tag(o) == 'fmt ') {
      channels = d.getUint16(o + 10, Endian.little);
      rate = d.getUint32(o + 12, Endian.little);
      bits = d.getUint16(o + 22, Endian.little);
    } else if (tag(o) == 'data') {
      final n = size ~/ 2;
      final samples = [
        for (var i = 0; i < n; i++) d.getInt16(o + 8 + i * 2, Endian.little),
      ];
      return _Wav(rate, channels, bits, samples);
    }
    o += 8 + size + (size & 1);
  }
  fail('no data chunk');
}

List<String> _docSounds() {
  final lines = File('docs/animals.md').readAsLinesSync();
  final start = lines.indexOf('## Bases');
  final names = <String>[];
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('## ')) break;
    if (!line.startsWith('|')) continue;
    final cells = line.split('|').map((c) => c.trim()).toList();
    final sound = cells[4];
    if (cells[1] == 'Base' || sound.startsWith('-')) continue;
    names.add(sound);
  }
  return names;
}

void main() {
  final files =
      Directory('assets/sounds')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('every base in docs/animals.md has a sound file', () {
    final names = _docSounds();
    expect(names.length, 15);
    for (final name in names) {
      expect(
        File('assets/sounds/$name.wav').existsSync(),
        isTrue,
        reason: '$name.wav missing',
      );
    }
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    test('$name is a short 22050 Hz mono 16-bit blip', () {
      final wav = _parse(file.readAsBytesSync());
      expect(wav.rate, 22050);
      expect(wav.channels, 1);
      expect(wav.bits, 16);
      expect(wav.seconds, inInclusiveRange(0.05, 0.6));
      expect(wav.peak, lessThan(0.9));
      expect(wav.peak, greaterThan(0.05));
    });
  }

  test('no two sound files are identical', () {
    final seen = <String, String>{};
    for (final file in files) {
      final key = file.readAsBytesSync().join(',');
      final other = seen[key];
      expect(other, isNull, reason: '${file.path} equals $other');
      seen[key] = file.path;
    }
  });
}
