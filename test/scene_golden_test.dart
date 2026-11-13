import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildkaki/animals/lookup.dart';
import 'package:wildkaki/data/controller.dart';
import 'package:wildkaki/data/health_sync.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/data/store.dart';
import 'package:wildkaki/scene/actors.dart';
import 'package:wildkaki/world/world_painter.dart' show Layout;
import 'package:wildkaki/scene/scene_screen.dart';
import 'package:wildkaki/scene/sounds.dart';
import 'package:wildkaki/scene/sprites.dart';
import 'package:wildkaki/scene/weather_layer.dart';
import 'package:wildkaki/ui/collection_page.dart';
import 'package:wildkaki/ui/dev_tools.dart';
import 'package:wildkaki/ui/recent_page.dart';
import 'package:wildkaki/ui/reveal.dart';
import 'package:wildkaki/ui/settings_page.dart';
import 'package:wildkaki/ui/theme.dart';
import 'package:wildkaki/update/update_service.dart';
import 'package:wildkaki/weather/weather_state.dart';

const _scratch = 'build/test_shots';

class _FakeSource implements OutingSource {
  @override
  Future<SourceStatus> status() async => SourceStatus.available;
  @override
  Future<bool> hasAccess() async => true;
  @override
  Future<bool> requestAccess() async => true;
  @override
  Future<List<Outing>> outingsSince(DateTime since) async => const [];
  @override
  Future<void> openSettings() async {}
  @override
  Future<DateTime> writeFakeRun() async => DateTime.now();

  @override
  Future<DateTime> writeFakeSleep() async => DateTime.now();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = await File(p).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Outing _outing(String id, String kind, DateTime start, double km, int min) =>
    Outing(id: id, kind: kind, start: start, distanceKm: km, minutes: min);

class _UpdatePlatform implements AppPlatform {
  final opened = <String>[];

  @override
  Future<String?> installedVersion() async => '1.0.1';

  @override
  Future<List<String>> abis() async => const [];

  @override
  Future<void> openUrl(String url) async => opened.add(url);
}

Future<WildController> _controller({bool third = false}) async {
  SharedPreferences.setMockInitialValues({});
  final store = await WildStore.open(systemAnimate: true);
  final seen = [
    _outing('a', 'Run', DateTime(2026, 10, 22, 6, 55), 5.2, 31),
    _outing('b', 'Walk', DateTime(2026, 10, 25, 17, 40), 2.4, 35),
  ];
  final waiting = [
    _outing('c', 'Run', DateTime(2026, 10, 27, 7, 12), 3.6, 22),
    _outing('d', 'Climb', DateTime(2026, 10, 28, 9, 5), 1.2, 48),
    if (third) _outing('e', 'Swim', DateTime(2026, 10, 29, 6, 40), 0.8, 30),
  ];
  await store.addWaiting(seen);
  await store.reveal(seen[0], 'red-fox');
  await store.reveal(seen[1], 'red-fox', hat: 'party-hat');
  await store.addWaiting(waiting);
  return WildController(store, _FakeSource());
}

Future<WildController> _controllerWith(List<(String, String?)> animals) async {
  SharedPreferences.setMockInitialValues({});
  final store = await WildStore.open(systemAnimate: true);
  final seen = [
    for (var i = 0; i < animals.length; i++)
      _outing('s$i', 'Swim', DateTime(2026, 10, 20 + i, 7, 0), 1, 30),
  ];
  await store.addWaiting(seen);
  for (var i = 0; i < animals.length; i++) {
    await store.reveal(seen[i], animals[i].$1, hat: animals[i].$2);
  }
  return WildController(store, _FakeSource());
}

final _boundary = GlobalKey();
late SceneSprites _sprites;

Future<void> _show(
  WidgetTester tester,
  WildController controller, {
  double hour = 12,
  bool animate = false,
  Size size = const Size(1080, 2340),
  int seed = 5,
  WeatherState? weather,
  SceneSounds? sounds,
  UpdateService? updates,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 72, bottom: 72);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: !animate);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: wildTheme(),
        home: SceneScreen(
          sounds: sounds ?? _QuietSounds(),
          controller: controller,
          sprites: _sprites,
          hourOverride: hour,
          random: Random(seed),
          weather: weather,
          updates: updates,
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester tester, String name, {String? copy}) async {
  await expectLater(
    find.byKey(_boundary),
    matchesGoldenFile('goldens/$name.png'),
  );
  await tester.runAsync(() async {
    final bytes = await File('test/goldens/$name.png').readAsBytes();
    Directory(_scratch).createSync(recursive: true);
    await File('$_scratch/${copy ?? 'flutter_$name'}.png').writeAsBytes(bytes);
  });
}

Offset _bushTap(WidgetTester tester, int i) {
  final paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(SceneScreen),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  final spot = ((paint.painter as dynamic).bushes as List)[i];
  return Offset((spot.x + 10) * 3.0, (spot.base - 10) * 3.0);
}

SceneState _state(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(SceneScreen),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return (paint.painter as dynamic).state as SceneState;
}

dynamic _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find
        .descendant(
          of: find.byType(SceneScreen),
          matching: find.byType(CustomPaint),
        )
        .first,
  );
  return paint.painter;
}

Future<List<int>> _render(
  WidgetTester? tester,
  WeatherView view,
  double time,
) async {
  Future<List<int>> go() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(360, 780);
    final layout = Layout.forRows(260);
    final layer = WeatherLayer(view);
    if (layer.active) {
      layer.paintTint(canvas, size, layout, 0);
      layer.paintParticles(canvas, size, layout, 0, time);
    }
    final image = await recorder.endRecording().toImage(360, 780);
    return (await image.toByteData())!.buffer.asUint8List().toList();
  }

  return tester == null ? go() : (await tester.runAsync(go))!;
}

Future<double> _coverage(
  WidgetTester tester,
  ui.Image sprite,
  int x,
  int y,
) async {
  return (await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final scene = await boundary.toImage();
    final sceneBytes = (await scene.toByteData())!;
    final spriteBytes = (await sprite.toByteData())!;
    var opaque = 0;
    var same = 0;
    for (var py = 0; py < sprite.height; py++) {
      for (var px = 0; px < sprite.width; px++) {
        final at = (py * sprite.width + px) * 4;
        if (spriteBytes.getUint8(at + 3) == 0) continue;
        opaque++;
        final sx = (x + px) * 3 + 1;
        final sy = (y + py) * 3 + 1;
        if (sx < 0 || sy < 0 || sx >= scene.width || sy >= scene.height) {
          continue;
        }
        final to = (sy * scene.width + sx) * 4;
        var match = true;
        for (var c = 0; c < 4; c++) {
          if (sceneBytes.getUint8(to + c) != spriteBytes.getUint8(at + c)) {
            match = false;
          }
        }
        if (match) same++;
      }
    }
    return same / opaque;
  }))!;
}

class _QuietSounds extends SceneSounds {
  @override
  Future<void> play(String name) async {}
}

class _RecordingSounds extends SceneSounds {
  final played = <String>[];

  @override
  Future<void> play(String name) async => played.add(name);
}

void main() {
  setUpAll(() async {
    await _loadFont('Tiny5', ['assets/fonts/tiny5.ttf']);
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/yos/flutter';
    final dir = '$root/bin/cache/artifacts/material_fonts';
    await _loadFont('Roboto', [
      '$dir/Roboto-Regular.ttf',
      '$dir/Roboto-Italic.ttf',
    ]);
  });

  testWidgets('scene by day', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c, hour: 12);
    expect(find.text('synced just now'), findsOneWidget);
    await _shot(tester, 'scene_day');
    await tester.pumpWidget(const SizedBox());
  });

  for (final (label, hour) in [('day', 12.0), ('night', 23.0)]) {
    for (final w in Weather.values) {
      testWidgets('scene $label in $w weather', (tester) async {
        _sprites = (await tester.runAsync(SceneSprites.load))!;
        final c = (await tester.runAsync(_controller))!;
        final state = WeatherState()..override = w;
        await _show(tester, c, hour: hour, weather: state);
        final name = w == Weather.clear
            ? 'scene_$label'
            : 'scene_weather_${label}_${w.name}';
        await _shot(tester, name, copy: 'weather_${label}_${w.name}');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('clear weather draws no overlay or particles', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c, weather: WeatherState());
    final layer = (_painter(tester)).weather as WeatherLayer;
    expect(layer.active, isFalse);
    final blank = await _render(tester, WeatherView(Weather.clear), 0);
    expect(blank.every((b) => b == 0), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('override wins over the live weather', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    final state = WeatherState()..live = Weather.rain;
    await _show(tester, c, weather: state);
    Weather shown() => (_painter(tester).weather as WeatherLayer).view.to;
    expect(shown(), Weather.rain);
    state.override = Weather.clear;
    await tester.pump();
    expect(shown(), Weather.clear);
    state.live = Weather.storm;
    await tester.pump();
    expect(shown(), Weather.clear);
    state.override = null;
    await tester.pump();
    expect(shown(), Weather.storm);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('particles stay still without motion and move with it', (
    tester,
  ) async {
    for (final w in [Weather.cloudy, Weather.rain, Weather.storm]) {
      final view = WeatherView(w);
      final still = await _render(tester, view, 0);
      expect(still.any((b) => b != 0), isTrue);
      expect(await _render(tester, view, 0), still);
      expect(await _render(tester, view, 1.5), isNot(still));
    }
  });

  testWidgets('with animation off the weather frame does not change', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c, weather: WeatherState()..override = Weather.storm);
    Future<List<int>> frame() async => (await tester.runAsync(() async {
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      return (await image.toByteData())!.buffer.asUint8List().toList();
    }))!;
    final first = await frame();
    await tester.pump(const Duration(seconds: 2));
    expect(await frame(), first);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with animation on the rain moves', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(
      tester,
      c,
      animate: true,
      weather: WeatherState()..override = Weather.rain,
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final layer = _painter(tester).weather as WeatherLayer;
    expect(layer.active, isTrue);
    final state = _state(tester);
    expect(state.clock, greaterThan(0.3));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('changing the weather cross-fades', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    final state = WeatherState();
    await _show(tester, c, animate: true, weather: state);
    final view = (_painter(tester).weather as WeatherLayer).view;
    state.override = Weather.rain;
    await tester.pump();
    expect(view.from, Weather.clear);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(view.fade, inInclusiveRange(0.2, 0.9));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(view.from, isNull);
    expect(view.to, Weather.rain);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the developer tools set the weather override', (tester) async {
    final state = WeatherState()..live = Weather.cloudy;
    await tester.pumpWidget(
      MaterialApp(
        theme: wildTheme(),
        home: DevToolsPage(
          weather: state,
          onBack: () {},
          onFakeRun: () async => '',
          onFakeSleep: () async => '',
        ),
      ),
    );
    expect(find.text('live: cloudy, showing: cloudy'), findsOneWidget);
    for (final w in Weather.values) {
      await tester.tap(
        find.text('${w.name[0].toUpperCase()}${w.name.substring(1)}'),
      );
      await tester.pump();
      expect(state.override, w);
      expect(state.value, w);
    }
    await tester.tap(find.text('Rain'));
    await tester.pump();
    expect(find.text('live: cloudy, showing: rain'), findsOneWidget);
    await tester.tap(find.text('Auto'));
    await tester.pump();
    expect(state.override, isNull);
    expect(state.value, Weather.cloudy);
  });

  testWidgets('scene with three bushes waiting', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(() => _controller(third: true)))!;
    await _show(tester, c, hour: 12);
    expect(c.home.waiting, hasLength(3));
    await _shot(tester, 'scene_three_bushes');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scene by night', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c, hour: 23);
    await _shot(tester, 'scene_night');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a new version shows a banner that Later hides', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    final platform = _UpdatePlatform();
    final updates = UpdateService(
      enabled: () => c.prefs.checkUpdates,
      repo: 'x/y',
      platform: platform,
      fetch: (_) async =>
          '{"tag_name":"v9.0.0","html_url":"https://example.com/release"}',
    );
    await tester.runAsync(updates.refresh);
    await _show(tester, c, updates: updates);
    expect(find.text('Version 9.0.0 is ready'), findsOneWidget);
    await _shot(tester, 'scene_update');

    await tester.tap(find.text('Update'));
    expect(platform.opened, ['https://example.com/release']);

    await c.updatePrefs(c.prefs.copyWith(checkUpdates: false));
    await tester.pump();
    expect(find.text('Version 9.0.0 is ready'), findsNothing);
    await c.updatePrefs(c.prefs.copyWith(checkUpdates: true));
    await tester.pump();

    await tester.tap(find.text('Later'));
    await tester.pump();
    expect(find.text('Version 9.0.0 is ready'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scene on a short screen', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c, hour: 12, size: const Size(1080, 1920), seed: 3);
    await _shot(tester, 'scene_short');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a bush reveals, closing moves it to sightings', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c);
    expect(c.home.waiting, hasLength(2));
    expect(c.home.sightings, hasLength(2));
    final waiting = c.home.waiting.first;
    final pick = c.previewPick(waiting);
    final before = c.home.sightings.where((s) => s.animal == pick.entryId);

    await tester.tapAt(_bushTap(tester, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    expect(
      find.text(
        before.isEmpty
            ? 'New in your collection'
            : 'Met ${before.length + 1} times',
      ),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(c.home.waiting, hasLength(1));
    expect(c.home.sightings, hasLength(3));
    expect(
      c.home.sightings.firstWhere((s) => s.outing.id == waiting.id).animal,
      pick.entryId,
    );
    expect(
      c.home.sightings.firstWhere((s) => s.outing.id == waiting.id).hat,
      pick.hatId,
    );
    expect(find.bySemanticsLabel('Close'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('every sighting walks the meadow, wearing its hat', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c);
    final foxes = (_state(tester)).foxes;
    expect(foxes, hasLength(2));
    expect(foxes.map((f) => f.entryId), everyElement('red-fox'));
    expect(foxes.map((f) => f.hatId), unorderedEquals(['party-hat', null]));
    expect(
      foxes.map((f) => entryOrDefault(f.entryId).frames),
      everyElement(['red-fox_1', 'red-fox_2']),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('swimmers and bats take their lanes, wearing their hats', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(
      () => _controllerWith([
        ('sparrow', 'party-hat'),
        ('duck', 'beanie'),
        ('vampire', 'top-hat'),
        ('sparrow', 'bowler-hat'),
        ('barn-owl', null),
        ('nessie', null),
      ]),
    ))!;
    await _show(tester, c, seed: 7);
    final state = _state(tester);
    expect(
      state.swimmers.map((s) => s.entryId),
      unorderedEquals(['duck', 'nessie']),
    );
    expect(
      state.swimmers.map((s) => s.hatId),
      unorderedEquals(['beanie', null]),
    );
    expect(
      state.flyers.map((f) => f.entryId),
      unorderedEquals(['vampire', 'sparrow']),
    );
    expect(
      state.flyers.map((f) => f.hatId),
      unorderedEquals(['top-hat', 'bowler-hat']),
    );
    expect(
      state.foxes.map((f) => f.entryId),
      unorderedEquals(['sparrow', 'barn-owl']),
    );
    expect(
      state.foxes.map((f) => f.hatId),
      unorderedEquals(['party-hat', null]),
    );
    await _shot(tester, 'scene_habitats');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a sky songbird draws its fly frames, a ground one stands', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(
      () => _controllerWith([
        ('sparrow', null),
        ('otter', null),
        ('otter', null),
        ('sparrow', null),
      ]),
    ))!;
    await _show(tester, c, seed: 7);
    final state = _state(tester);
    final sky = state.flyers.single;
    final ground = state.foxes.singleWhere((f) => f.entryId == 'sparrow');
    final skyEntry = entryOrDefault(sky.entryId);
    final groundEntry = entryOrDefault(ground.entryId);
    ui.Image named(String n, bool left) => _sprites.named(n, mirrored: left);

    final flying = named(skyEntry.flyFrames[sky.frame], sky.dir < 0);
    final standing = named(skyEntry.frames[sky.frame], sky.dir < 0);
    expect(await _coverage(tester, flying, sky.x.round(), sky.y), 1);
    expect(
      await _coverage(tester, standing, sky.x.round(), sky.y),
      lessThan(0.9),
    );

    final walking = named(groundEntry.frames[ground.frame], ground.dir < 0);
    final wings = named(groundEntry.flyFrames[ground.frame], ground.dir < 0);
    final gx = ground.x.round();
    final gy = ground.feet - 32;
    expect(await _coverage(tester, walking, gx, gy), 1);
    expect(await _coverage(tester, wings, gx, gy), lessThan(0.9));

    await tester.tapAt(Offset((gx + 16) * 3.0, (ground.feet - 8) * 3.0));
    await tester.pump();
    expect(state.foxes.where((f) => f.entryId == 'sparrow'), isEmpty);
    expect(state.flyers, hasLength(2));
    expect(state.flyers.last.rising, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping a swimmer or a bat reacts like a meadow animal', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(
      () => _controllerWith([('otter', null), ('vampire', 'top-hat')]),
    ))!;
    final sounds = _RecordingSounds();
    await _show(tester, c, seed: 7, sounds: sounds);
    final state = _state(tester);
    final swimmer = state.swimmers.single;
    final flyer = state.flyers.single;
    expect(swimmer.alarm, 0);
    expect(flyer.alarm, 0);

    await tester.tapAt(Offset((swimmer.x + 16) * 3, (swimmer.feet - 12) * 3));
    await tester.pump();
    expect(swimmer.alarm, greaterThan(0));
    expect(swimmer.bubble, greaterThan(0));
    expect(flyer.alarm, 0);
    expect(sounds.played, ['squeak']);

    await tester.tapAt(Offset((flyer.x + 16) * 3, (flyer.y + 22) * 3));
    await tester.pump();
    expect(flyer.alarm, greaterThan(0));
    expect(flyer.bubble, greaterThan(0));
    expect(sounds.played, ['squeak', 'eek']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the bench opens the collection, back returns', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c);
    await tester.tapAt(const Offset(30 * 3.0, 120 * 3.0));
    await tester.pump();
    expect(find.byType(CollectionPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Red fox'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('new-dot')), findsOneWidget);
    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position
        .pixels;
    final scrolled = offset();
    expect(scrolled, greaterThan(0));
    await tester.tap(find.text('Red fox'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(c.home.opened, contains('red-fox'));
    expect(find.text('Met 2 times'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(CollectionPage), findsOneWidget);
    expect(offset(), scrolled);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(CollectionPage), findsNothing);

    await tester.tapAt(const Offset(30 * 3.0, 120 * 3.0));
    await tester.pump();
    expect(offset(), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closing the card removes the bush at once and unlocks taps', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c, animate: true);
    expect(c.home.waiting, hasLength(2));
    await tester.tapAt(_bushTap(tester, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(RevealOverlay), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump();
    expect(find.byType(RevealOverlay), findsNothing);
    final bushes =
        (tester
                        .widget<CustomPaint>(
                          find
                              .descendant(
                                of: find.byType(SceneScreen),
                                matching: find.byType(CustomPaint),
                              )
                              .first,
                        )
                        .painter
                    as dynamic)
                .bushes
            as List;
    expect(bushes, hasLength(1));

    await tester.tapAt(_bushTap(tester, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(RevealOverlay), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the lamppost opens the recent page, back returns', (
    tester,
  ) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c);
    await tester.tapAt(const Offset(7 * 3.0, 101 * 3.0));
    await tester.pump();
    expect(find.byType(RecentPage), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pump();
    expect(find.byType(SettingsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RecentPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RecentPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
