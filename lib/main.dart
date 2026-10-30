import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animals/holidays_live.dart';
import 'animals/zone.dart';
import 'data/controller.dart';
import 'scene/scene_screen.dart';
import 'scene/sprites.dart';
import 'ui/theme.dart';
import 'update/update_service.dart';
import 'weather/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final holidays = await HolidayService.open();
  final weather = await WeatherService.open();
  final phoneZone = PhoneTimeZone();
  await phoneZone.refresh();
  final controller = await WildController.create(
    holidays: holidays,
    timeZone: () => phoneZone.zone,
    systemAnimate: !WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations,
  );
  final updates = UpdateService(enabled: () => controller.prefs.checkUpdates);
  final sprites = await SceneSprites.load();
  runApp(
    WildKakiApp(
      controller: controller,
      holidays: holidays,
      phoneZone: phoneZone,
      weather: weather,
      updates: updates,
      sprites: sprites,
    ),
  );
}

class WildKakiApp extends StatefulWidget {
  const WildKakiApp({
    super.key,
    required this.controller,
    required this.holidays,
    required this.phoneZone,
    required this.weather,
    required this.updates,
    required this.sprites,
  });

  final WildController controller;
  final HolidayService holidays;
  final PhoneTimeZone phoneZone;
  final WeatherService weather;
  final UpdateService updates;
  final SceneSprites sprites;

  @override
  State<WildKakiApp> createState() => _WildKakiAppState();
}

class _WildKakiAppState extends State<WildKakiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.syncQuietly();
    unawaited(widget.holidays.refresh());
    unawaited(widget.weather.refresh());
    unawaited(widget.updates.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.phoneZone.refresh());
      widget.controller.syncQuietly();
      unawaited(widget.holidays.refresh());
      unawaited(widget.weather.refresh());
      unawaited(widget.updates.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WildKaki',
      debugShowCheckedModeBanner: false,
      theme: wildTheme(),
      home: ColoredBox(
        color: Wild.night,
        child: SceneScreen(
          controller: widget.controller,
          sprites: widget.sprites,
          weather: widget.weather.state,
          updates: widget.updates,
        ),
      ),
    );
  }
}
