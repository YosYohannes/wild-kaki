import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../animals/lookup.dart';
import '../data/controller.dart';
import '../scene/actors.dart';
import '../scene/sprites.dart';
import '../weather/weather_state.dart';
import 'wallpaper_export.dart';

abstract class WallpaperHost {
  Future<String?> directory();
  Future<bool> isActive();
  Future<bool> openChooser();
  Future<bool> backgroundAllowed();
  Future<bool> requestBackground();
}

class PlatformWallpaperHost implements WallpaperHost {
  static const _channel = MethodChannel('app.wildkaki/wallpaper');

  Future<T?> _call<T>(String method) async {
    try {
      return await _channel.invokeMethod<T>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<String?> directory() => _call<String>('dir');

  @override
  Future<bool> isActive() async => await _call<bool>('active') ?? false;

  @override
  Future<bool> openChooser() async => await _call<bool>('set') ?? false;

  @override
  Future<bool> backgroundAllowed() async =>
      await _call<bool>('backgroundAllowed') ?? false;

  @override
  Future<bool> requestBackground() async =>
      await _call<bool>('requestBackground') ?? false;
}

ui.Size _deviceScreen() =>
    ui.PlatformDispatcher.instance.views.first.physicalSize;

class WallpaperSync {
  WallpaperSync({
    required this.controller,
    required this.weather,
    required this.sprites,
    WallpaperHost? host,
    ui.Size Function()? screen,
    this.debounce = const Duration(seconds: 3),
  }) : host = host ?? PlatformWallpaperHost(),
       _screen = screen ?? _deviceScreen;

  final WildController controller;
  final WeatherState weather;
  final SceneSprites sprites;
  final WallpaperHost host;
  final ui.Size Function() _screen;
  final Duration debounce;

  Timer? _timer;
  String? _last;
  String? _lastBackdrops;
  bool _running = false;

  void attach() {
    controller.addListener(schedule);
    weather.addListener(schedule);
  }

  void detach() {
    controller.removeListener(schedule);
    weather.removeListener(schedule);
    _timer?.cancel();
  }

  void schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(update()));
  }

  Map<String, Object?> _manifest() {
    final size = _screen();
    return wallpaperManifest(
      rows: wallpaperRows(size.width, size.height),
      animate: controller.prefs.animate,
      weather: weather.value,
      waiting: controller.home.waiting.length,
      animals: [
        for (final s in controller.home.sightings.take(maxFoxes))
          (
            outingId: s.outing.id,
            entryId: entryOrDefault(s.animal).id,
            hatId: s.hat,
          ),
      ],
    );
  }

  Future<void> update({bool force = false}) async {
    if (_running) return;
    _running = true;
    try {
      if (!force && !await host.isActive()) return;
      final path = await host.directory();
      if (path == null) return;
      final manifest = _manifest();
      final signature = jsonEncode(manifest);
      if (!force && signature == _last) return;
      final backdrops = '${manifest['rows']}|${weather.value}';
      await exportWallpaper(
        dir: Directory(path),
        manifest: manifest,
        weather: weather.value,
        sprites: sprites,
        backdrops: force || backdrops != _lastBackdrops,
      );
      _last = signature;
      _lastBackdrops = backdrops;
    } on Object {
      return;
    } finally {
      _running = false;
    }
  }

  Future<bool> backgroundAllowed() => host.backgroundAllowed();

  Future<bool> requestBackground() => host.requestBackground();

  Future<bool> choose() async {
    await update(force: true);
    return host.openChooser();
  }
}
