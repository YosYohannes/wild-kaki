import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../animals/catalog_data.dart';

class SceneSprites {
  SceneSprites._({
    required this.bench,
    required this.lamppost,
    required this.bush,
    required this.bushBlink,
    required this.right,
    required this.left,
    required this.birdRight,
    required this.birdLeft,
    required this.duckRight,
    required this.duckLeft,
  });

  final ui.Image bench;
  final ui.Image lamppost;
  final ui.Image bush;
  final ui.Image bushBlink;
  final List<ui.Image> birdRight;
  final List<ui.Image> birdLeft;
  final ui.Image duckRight;
  final ui.Image duckLeft;
  final Map<String, ui.Image> right;
  final Map<String, ui.Image> left;

  ui.Image named(String name, {bool mirrored = false}) =>
      (mirrored ? left : right)[name]!;

  static Future<ui.Image> _load(String name) async {
    final data = await rootBundle.load('assets/sprites/$name.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<ui.Image> _mirrored(ui.Image src) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.translate(src.width.toDouble(), 0);
    canvas.scale(-1, 1);
    canvas.drawImage(
      src,
      ui.Offset.zero,
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
    final picture = recorder.endRecording();
    final image = picture.toImage(src.width, src.height);
    picture.dispose();
    return image;
  }

  static Future<SceneSprites> load() async {
    final names = {
      for (final b in defaultCatalog.bases) ...b.frames,
      for (final h in defaultCatalog.hats) h.sprite,
    };
    final right = {for (final n in names) n: await _load(n)};
    final birdRight = [await _load('bird_1'), await _load('bird_2')];
    final duckRight = await _load('duck');
    return SceneSprites._(
      bench: await _load('bench'),
      lamppost: await _load('lamppost'),
      bush: await _load('bush'),
      bushBlink: await _load('bush_blink'),
      right: right,
      left: {for (final e in right.entries) e.key: await _mirrored(e.value)},
      birdRight: birdRight,
      birdLeft: [for (final i in birdRight) await _mirrored(i)],
      duckRight: duckRight,
      duckLeft: await _mirrored(duckRight),
    );
  }
}
