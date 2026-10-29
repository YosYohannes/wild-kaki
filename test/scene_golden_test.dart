import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildkaki/data/controller.dart';
import 'package:wildkaki/data/health_sync.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/data/store.dart';
import 'package:wildkaki/scene/scene_screen.dart';
import 'package:wildkaki/scene/sounds.dart';
import 'package:wildkaki/scene/sprites.dart';
import 'package:wildkaki/ui/collection_page.dart';
import 'package:wildkaki/ui/recent_page.dart';
import 'package:wildkaki/ui/settings_page.dart';
import 'package:wildkaki/ui/theme.dart';

const _scratch =
    '/tmp/claude-1000/-home-yos-Desktop-wild-kaki/b522a0f8-ab30-4973-b0c2-dccd1164ca20/scratchpad';

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
  for (final o in seen) {
    await store.reveal(o, 'fox');
  }
  await store.addWaiting(waiting);
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
          sounds: _QuietSounds(),
          controller: controller,
          sprites: _sprites,
          hourOverride: hour,
          random: Random(seed),
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

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byKey(_boundary),
    matchesGoldenFile('goldens/$name.png'),
  );
  await tester.runAsync(() async {
    final bytes = await File('test/goldens/$name.png').readAsBytes();
    if (Directory(_scratch).existsSync()) {
      await File('$_scratch/flutter_$name.png').writeAsBytes(bytes);
    }
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

class _QuietSounds extends SceneSounds {
  @override
  Future<void> play(String name) async {}
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

    await tester.tapAt(_bushTap(tester, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    expect(find.text('Met 3 times'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(c.home.waiting, hasLength(1));
    expect(c.home.sightings, hasLength(3));
    expect(find.bySemanticsLabel('Close'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the bench opens the collection, back returns', (tester) async {
    _sprites = (await tester.runAsync(SceneSprites.load))!;
    final c = (await tester.runAsync(_controller))!;
    await _show(tester, c);
    await tester.tapAt(const Offset(30 * 3.0, 120 * 3.0));
    await tester.pump();
    expect(find.byType(CollectionPage), findsOneWidget);
    expect(find.byKey(const ValueKey('new-dot')), findsOneWidget);
    await tester.tap(find.text('Fox'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(c.home.opened, contains('fox'));
    expect(find.text('Met 2 times'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(CollectionPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(CollectionPage), findsNothing);
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
