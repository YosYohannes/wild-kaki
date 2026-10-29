import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/animals.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/ui/animal_page.dart';
import 'package:wildkaki/ui/collection_page.dart';
import 'package:wildkaki/ui/recent_page.dart';
import 'package:wildkaki/ui/settings_page.dart';
import 'package:wildkaki/ui/theme.dart';

const _scratch =
    '/tmp/claude-1000/-home-yos-Desktop-wild-kaki/b522a0f8-ab30-4973-b0c2-dccd1164ca20/scratchpad';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = await File(p).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont('Tiny5', ['assets/fonts/tiny5.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/yos/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  await _loadFont('Roboto', [
    '$dir/Roboto-Regular.ttf',
    '$dir/Roboto-Italic.ttf',
  ]);
}

Outing _outing(String id, String kind, DateTime start, double km, int min) =>
    Outing(id: id, kind: kind, start: start, distanceKm: km, minutes: min);

final _meetings = [
  Sighting(_outing('a', 'Run', DateTime(2025, 10, 22, 6, 55), 5.2, 31), 'fox'),
  Sighting(
    _outing('b', 'Walk', DateTime(2025, 10, 25, 17, 40), 2.4, 35),
    'fox',
  ),
  Sighting(_outing('c', 'Run', DateTime(2025, 10, 28, 7, 12), 3.6, 22), 'fox'),
];

const _allPrefs = Prefs(miles: false, animate: true);

final _boundary = GlobalKey();

Future<void> _show(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(720, 1440);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 56);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: wildTheme(),
        home: page,
      ),
    ),
  );
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
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

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('collection grid shows the new dot', (tester) async {
    var opened = '';
    await _show(
      tester,
      CollectionPage(
        sightings: _meetings,
        opened: const {},
        onSettings: () {},
        onClose: () {},
        onOpen: (a) => opened = a,
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Fox'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(2));
    expect(find.text('?'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('new-dot')), findsOneWidget);
    await _shot(tester, 'collection');
    await tester.tap(find.text('???').first);
    expect(opened, '');
    await tester.tap(find.text('Fox'));
    expect(opened, 'fox');
    await _leave(tester);
  });

  testWidgets('collection hides the dot once opened and the fox when unmet', (
    tester,
  ) async {
    await _show(
      tester,
      CollectionPage(
        sightings: _meetings,
        opened: const {'fox'},
        onSettings: () {},
        onClose: () {},
        onOpen: (_) {},
      ),
    );
    expect(find.byKey(const ValueKey('new-dot')), findsNothing);
    await _show(
      tester,
      CollectionPage(
        sightings: const [],
        opened: const {},
        onSettings: () {},
        onClose: () {},
        onOpen: (_) {},
      ),
    );
    expect(find.text('Fox'), findsNothing);
    expect(find.text('???'), findsNWidgets(3));
    await _leave(tester);
  });

  testWidgets('animal page lists meetings newest first, oldest is first met', (
    tester,
  ) async {
    await _show(
      tester,
      AnimalPage(
        animal: animalById('fox'),
        meetings: _meetings,
        miles: false,
        onClose: () {},
      ),
    );
    expect(find.text('Met 3 times'), findsOneWidget);
    expect(find.text('first met', findRichText: true), findsOneWidget);
    expect(find.text('Run · 3.6 km · 22 min'), findsOneWidget);
    await _shot(tester, 'animal');
    await _leave(tester);
  });

  testWidgets('animal page shows a non-fox animal with its own frames', (
    tester,
  ) async {
    final duck = Sighting(
      _outing('d', 'Run', DateTime(2025, 10, 29, 7), 4, 25),
      'duck',
    );
    await _show(
      tester,
      AnimalPage(
        animal: animalById('duck'),
        meetings: [duck],
        miles: false,
        onClose: () {},
      ),
    );
    expect(find.text('Duck'), findsOneWidget);
    expect(find.text(animalById('duck').note), findsOneWidget);
    expect(find.text('Met once'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/sprites/duck.png');
    await _leave(tester);
  });

  testWidgets('settings default and start over confirm', (tester) async {
    Prefs prefs = _allPrefs;
    var started = 0;
    late StateSetter set;
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return SettingsPage(
            prefs: prefs,
            onPrefs: (p) => set(() => prefs = p),
            onBack: () {},
            onManage: () {},
            onStartOver: () => started++,
          );
        },
      ),
    );
    await _shot(tester, 'settings');

    await tester.tap(find.text('mi'));
    await tester.pump();
    expect(prefs.miles, isTrue);
    await tester.tap(find.text('km'));
    await tester.pump();
    expect(prefs.miles, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    await tester.tap(find.text('Start over').last);
    await tester.pump();
    expect(find.text('Forget every animal?'), findsOneWidget);
    await _shot(tester, 'settings_confirm');

    await tester.tap(find.byKey(const ValueKey('keep-animals')));
    await tester.pump();
    expect(find.text('Forget every animal?'), findsNothing);
    expect(started, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    await tester.tap(find.text('Start over').last);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-start-over')));
    await tester.pump();
    expect(started, 1);
    await _leave(tester);
  });

  testWidgets('recent page lists waiting and revealed activities', (
    tester,
  ) async {
    var opened = '';
    await _show(
      tester,
      RecentPage(
        waiting: [
          _outing('w', 'Climb', DateTime(2025, 10, 29, 8, 5), 0, 48),
          Outing(
            id: 's',
            kind: sleepKind,
            start: DateTime(2025, 10, 28, 23, 10),
            distanceKm: null,
            minutes: 440,
          ),
        ],
        sightings: _meetings,
        miles: false,
        onClose: () {},
        onSettings: () => opened = 'settings',
        now: DateTime(2025, 10, 30, 9),
      ),
    );
    expect(find.text('waiting in the bushes'), findsNWidgets(2));
    expect(find.text('Recent'), findsOneWidget);
    await _shot(tester, 'recent');
    await tester.tap(find.bySemanticsLabel('Settings'));
    expect(opened, 'settings');
    await _leave(tester);
  });

  testWidgets('recent page has an empty state', (tester) async {
    await _show(
      tester,
      RecentPage(
        waiting: const [],
        sightings: const [],
        miles: false,
        onClose: () {},
        onSettings: () {},
      ),
    );
    expect(find.textContaining('Nothing in the last week'), findsOneWidget);
    await _leave(tester);
  });

  testWidgets('recent page hides revealed activities older than a week', (
    tester,
  ) async {
    final now = DateTime(2025, 11, 5, 9);
    await _show(
      tester,
      RecentPage(
        waiting: [_outing('old', 'Run', DateTime(2025, 10, 1, 7), 3, 20)],
        sightings: [
          Sighting(
            _outing('a', 'Run', DateTime(2025, 10, 22, 6, 55), 5.2, 31),
            'fox',
          ),
          Sighting(
            _outing('b', 'Walk', DateTime(2025, 10, 30, 17, 40), 2.4, 35),
            'fox',
          ),
        ],
        miles: false,
        onClose: () {},
        onSettings: () {},
        now: now,
      ),
    );
    expect(find.text('Thu 30 Oct, 17:40'), findsOneWidget);
    expect(find.text('Wed 22 Oct, 6:55'), findsNothing);
    expect(find.text('waiting in the bushes'), findsOneWidget);
    await _leave(tester);
  });
}
