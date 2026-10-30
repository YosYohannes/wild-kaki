import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../animals/art_data.dart';
import '../animals/catalog_data.dart';
import '../animals/lookup.dart';

class SceneSprites {
  SceneSprites._({
    required this.bench,
    required this.lamppost,
    required this.bush,
    required this.bushBlink,
    required this.right,
    required this.left,
  });

  final ui.Image bench;
  final ui.Image lamppost;
  final ui.Image bush;
  final ui.Image bushBlink;
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
      ...spriteNamesUsed(entryArt),
      for (final h in defaultCatalog.hats) h.sprite,
    }.toList();
    final loaded = await Future.wait(names.map(_load));
    final right = {for (var i = 0; i < names.length; i++) names[i]: loaded[i]};
    final mirroredList = await Future.wait(loaded.map(_mirrored));
    final left = {
      for (var i = 0; i < names.length; i++) names[i]: mirroredList[i],
    };
    return SceneSprites._(
      bench: await _load('bench'),
      lamppost: await _load('lamppost'),
      bush: await _load('bush'),
      bushBlink: await _load('bush_blink'),
      right: right,
      left: left,
    );
  }
}
