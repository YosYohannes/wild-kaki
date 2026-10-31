import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../animals/lookup.dart';
import '../scene/actors.dart';
import '../scene/sprites.dart';
import '../scene/weather_layer.dart';
import '../weather/weather_state.dart';
import '../world/pixel_buffer.dart';
import '../world/sky.dart';
import '../world/world_painter.dart';

const wallpaperHours = 24;
const _manifestName = 'manifest.json';

String backdropName(int hour) => 'bg_${hour.toString().padLeft(2, '0')}.png';

int wallpaperRows(double width, double height) =>
    (height / (width / worldW)).ceil();

Map<String, Object?> wallpaperManifest({
  required int rows,
  required bool animate,
  required Weather weather,
  required List<MeadowAnimal> animals,
}) {
  final rain = rainSpecFor(weather);
  return {
    'version': 1,
    'worldW': worldW,
    'rows': rows,
    'k': Layout.forRows(rows).k,
    'animate': animate,
    'waterline': Swimmer.waterline,
    'lanes': {
      'meadow': [meadowFeetRef, meadowFeetSpan],
      'river': [riverFeetRef, riverFeetSpan],
      'sky': [skyTopRef, skyTopSpan],
    },
    'backdrops': [for (var h = 0; h < wallpaperHours; h++) backdropName(h)],
    'night': [
      for (var h = 0; h < wallpaperHours; h++) skyAt(h.toDouble()).stars,
    ],
    'rain': rain == null
        ? null
        : {
            'slant': rain.slant,
            'speed': rain.speed,
            'dayColor': rainDayColor,
            'nightColor': rainNightColor,
            'drops': [
              for (final (x, y, v) in rain.drops) [x, y, v],
            ],
          },
    'animals': [for (final a in animals.take(maxFoxes)) _animalJson(a)],
  };
}

Map<String, Object?> _animalJson(MeadowAnimal a) {
  final entry = entryOrDefault(a.entryId);
  final lane = laneOf(entry.base, a.outingId);
  final flying = lane == Lane.sky;
  final frames = flying ? entry.flyFrames : entry.frames;
  final heads = flying ? entry.flyHeadPoints : entry.headPoints;
  return {
    'lane': lane.name,
    'frames': frames,
    'heads': [
      for (final h in heads) [h.x, h.y],
    ],
    'hat': hatById(a.hatId)?.sprite,
  };
}

Future<Uint8List> renderBackdrop({
  required double hour,
  required int rows,
  required Weather weather,
  required SceneSprites sprites,
}) async {
  final world = await paintWorld(hour, rows);
  final layout = Layout.forRows(rows);
  final night = skyAt(hour).stars;
  final layer = WeatherLayer(WeatherView(weather));
  final size = ui.Size(worldW.toDouble(), rows.toDouble());
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final plain = ui.Paint()
    ..filterQuality = ui.FilterQuality.none
    ..isAntiAlias = false;
  canvas.drawImage(world, ui.Offset.zero, plain);
  world.dispose();

  final wet = layer.active;
  if (wet) {
    layer.paintTint(canvas, size, layout, night);
    layer.paintClouds(canvas, size, layout, night, 0);
  }
  ui.Color? dimColor;
  if (night > 0.01) {
    dimColor = const ui.Color(0xFF0B1510).withValues(alpha: night * 0.55);
  }
  final wetDim = wet ? layer.dim(night) : null;
  if (wetDim != null) {
    dimColor = dimColor == null ? wetDim : combineDim(dimColor, wetDim);
  }
  final dim = dimColor == null
      ? plain
      : (ui.Paint()
          ..filterQuality = ui.FilterQuality.none
          ..isAntiAlias = false
          ..colorFilter = ui.ColorFilter.mode(dimColor, ui.BlendMode.srcATop));
  canvas.drawImage(
    sprites.bench,
    ui.Offset(Layout.benchX.toDouble(), layout.benchY.toDouble()),
    dim,
  );
  canvas.drawImage(
    sprites.lamppost,
    ui.Offset(Layout.lampX.toDouble(), layout.lampY.toDouble()),
    dim,
  );
  if (night > 0.05) {
    canvas.drawRect(
      ui.Rect.fromLTWH(4, layout.lanternY.toDouble(), 6, 6),
      ui.Paint()
        ..color = const ui.Color(0xFFFFE9A0)
            .withValues(alpha: night.clamp(0.0, 1.0)),
    );
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(worldW, rows);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

Future<void> exportWallpaper({
  required Directory dir,
  required Map<String, Object?> manifest,
  required Weather weather,
  required SceneSprites sprites,
}) async {
  await dir.create(recursive: true);
  final rows = manifest['rows'] as int;
  for (var h = 0; h < wallpaperHours; h++) {
    final png = await renderBackdrop(
      hour: h.toDouble(),
      rows: rows,
      weather: weather,
      sprites: sprites,
    );
    await File('${dir.path}/${backdropName(h)}').writeAsBytes(png, flush: true);
  }
  final temp = File('${dir.path}/$_manifestName.tmp');
  await temp.writeAsString(
    jsonEncode({
      ...manifest,
      'writtenAt': DateTime.now().millisecondsSinceEpoch,
    }),
    flush: true,
  );
  await temp.rename('${dir.path}/$_manifestName');
}
