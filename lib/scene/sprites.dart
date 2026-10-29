import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class SceneSprites {
  SceneSprites._({
    required this.bench,
    required this.lamppost,
    required this.bush,
    required this.bushBlink,
    required this.foxRight,
    required this.foxLeft,
    required this.birdRight,
    required this.birdLeft,
    required this.duckRight,
    required this.duckLeft,
  });

  final ui.Image bench;
  final ui.Image lamppost;
  final ui.Image bush;
  final ui.Image bushBlink;
  final List<ui.Image> foxRight;
  final List<ui.Image> foxLeft;
  final List<ui.Image> birdRight;
  final List<ui.Image> birdLeft;
  final ui.Image duckRight;
  final ui.Image duckLeft;

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
    final foxRight = [await _load('fox_walk_1'), await _load('fox_walk_2')];
    final birdRight = [await _load('bird_1'), await _load('bird_2')];
    final duckRight = await _load('duck');
    return SceneSprites._(
      bench: await _load('bench'),
      lamppost: await _load('lamppost'),
      bush: await _load('bush'),
      bushBlink: await _load('bush_blink'),
      foxRight: foxRight,
      foxLeft: [for (final i in foxRight) await _mirrored(i)],
      birdRight: birdRight,
      birdLeft: [for (final i in birdRight) await _mirrored(i)],
      duckRight: duckRight,
      duckLeft: await _mirrored(duckRight),
    );
  }
}
