import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/hints.dart';
import 'package:wildkaki/animals/hints_data.dart';
import 'package:wildkaki/animals/lookup.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/ui/animal_page.dart';
import 'package:wildkaki/ui/animal_sprite.dart';
import 'package:wildkaki/ui/collection_page.dart';
import 'package:wildkaki/ui/recent_page.dart';
import 'package:wildkaki/ui/settings_page.dart';
import 'package:wildkaki/ui/theme.dart';

const _scratch = 'build/test_shots';

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
  Sighting(
    _outing('a', 'Run', DateTime(2025, 10, 22, 6, 55), 5.2, 31),
    'red-fox',
  ),
  Sighting(
    _outing('b', 'Walk', DateTime(2025, 10, 25, 17, 40), 2.4, 35),
    'red-fox',
  ),
  Sighting(
    _outing('c', 'Run', DateTime(2025, 10, 28, 7, 12), 3.6, 22),
    'red-fox',
  ),
];

final _recentSightings = [
  for (final s in _meetings) Sighting(s.outing, 'red-fox'),
];

final _collected = [
  ..._meetings,
  Sighting(
    _outing('g', 'Walk', DateTime(2025, 10, 29, 7), 2, 25),
    'shiba',
    hint: 'corgi',
  ),
  Sighting(
    _outing('d', 'Walk', DateTime(2025, 10, 29, 8), 1.8, 20),
    'tabby',
    hint: 'husky',
  ),
  Sighting(_outing('e', 'Run', DateTime(2025, 10, 29, 9), 6, 40), 'black-cat'),
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
  await _settleImages(tester);
}

Future<void> _settleImages(WidgetTester tester) async {
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
    Directory(_scratch).createSync(recursive: true);
    await File('$_scratch/flutter_$name.png').writeAsBytes(bytes);
  });
}

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('collection grid shows found animals and the new dot', (
    tester,
  ) async {
    var opened = '';
    await _show(
      tester,
      CollectionPage(
        sightings: _collected,
        opened: const {'shiba', 'tabby'},
        onSettings: () {},
        onClose: () {},
        onOpen: (a) => opened = a,
      ),
    );
    expect(animalEntries, hasLength(94));
    expect(find.text('Shiba'), findsOneWidget);
    expect(find.text('Tabby'), findsOneWidget);
    expect(find.text('Black cat'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-dot')), findsOneWidget);
    await _shot(tester, 'collection');
    await tester.tap(find.text('???').first);
    await tester.pump();
    expect(opened, '');
    await tester.tap(find.byKey(const ValueKey('hint-close')));
    await tester.pump();
    await tester.tap(find.text('Black cat'));
    expect(opened, 'black-cat');
    await tester.tap(find.text('Shiba'));
    expect(opened, 'shiba');
    await _leave(tester);
  });

  testWidgets('unmet tiles with a hint show a silhouette and open a card', (
    tester,
  ) async {
    var opened = '';
    await _show(
      tester,
      CollectionPage(
        sightings: _collected,
        opened: const {'shiba', 'tabby'},
        onSettings: () {},
        onClose: () {},
        onOpen: (a) => opened = a,
      ),
    );
    final silhouette = find.byKey(const ValueKey('silhouette-corgi'));
    expect(silhouette, findsOneWidget);
    expect(
      tester.widget<ColorFiltered>(silhouette).colorFilter,
      ColorFilter.mode(Wild.ink.withValues(alpha: 0.75), BlendMode.srcIn),
    );
    expect(find.byKey(const ValueKey('silhouette-husky')), findsOneWidget);
    expect(find.byKey(const ValueKey('silhouette-hare')), findsNothing);
    expect(find.byKey(const ValueKey('silhouette-shiba')), findsNothing);
    expect(find.bySemanticsLabel('Not met yet, hint available'), findsWidgets);
    expect(find.bySemanticsLabel('Not met yet'), findsWidgets);

    expect(find.byKey(const ValueKey('hint-card')), findsNothing);
    await tester.tap(silhouette);
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-card')), findsOneWidget);
    expect(find.text(hintText(findEntry('corgi')!)), findsOneWidget);
    expect(find.text('Corgi'), findsNothing);
    expect(opened, '');
    await _settleImages(tester);
    await _shot(tester, 'collection_hint');

    await tester.tap(find.byKey(const ValueKey('hint-close')));
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-card')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('silhouette-corgi')));
    await tester.pump();
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const ValueKey('hint-scrim'))) +
          const Offset(20, 100),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-card')), findsNothing);

    await tester.tap(find.text('Shiba'));
    expect(opened, 'shiba');
    await _leave(tester);
  });

  testWidgets('an unmet tile with no hint opens the locked card', (
    tester,
  ) async {
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
    expect(find.byType(ColorFiltered), findsNothing);
    expect(find.bySemanticsLabel('Not met yet, hint available'), findsNothing);
    await tester.tap(find.text('???').first);
    await tester.pump();
    expect(find.text('Not met yet. Anything can turn up.'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hint-close')));
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-card')), findsNothing);
    await _leave(tester);
  });

  testWidgets(
    'a regional legend shows a silhouette and its riddle in its zone',
    (tester) async {
      await _show(
        tester,
        CollectionPage(
          sightings: const [],
          opened: const {},
          timeZone: 'Asia/Singapore',
          onSettings: () {},
          onClose: () {},
          onOpen: (_) {},
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('silhouette-merlion')),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.byKey(const ValueKey('silhouette-merlion')));
      await tester.pump();
      expect(find.text(legendRiddles['merlion']!), findsOneWidget);
      await _leave(tester);
    },
  );

  testWidgets('collection scrolls to the last entry', (tester) async {
    final last = animalEntries.last;
    final all = [
      for (final e in animalEntries)
        Sighting(
          _outing(e.id, 'Run', DateTime(2025, 10, 22, 6, 55), 5, 30),
          e.id,
        ),
    ];
    await _show(
      tester,
      CollectionPage(
        sightings: all,
        opened: const {},
        onSettings: () {},
        onClose: () {},
        onOpen: (_) {},
      ),
    );
    expect(find.text('???'), findsNothing);
    expect(find.byKey(const ValueKey('new-dot')), findsWidgets);
    await tester.drag(find.byType(GridView), const Offset(0, -20000));
    await tester.pump();
    expect(find.text(last.name), findsOneWidget);
    await _settleImages(tester);
    await _shot(tester, 'collection_end');
    final longest = animalEntries.reduce(
      (a, b) => a.name.length >= b.name.length ? a : b,
    );
    await tester.scrollUntilVisible(
      find.text(longest.name),
      -300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();
    expect(tester.getSize(find.text(longest.name)).height, lessThan(18));
    expect(tester.getSize(find.text(longest.name)).width, lessThan(109));
    await _settleImages(tester);
    await _shot(tester, 'collection_longest');
    await _leave(tester);
  });

  testWidgets('regional legends show only when met or in their zone', (
    tester,
  ) async {
    Future<void> showWith(List<Sighting> seen, String? zone) => _show(
      tester,
      CollectionPage(
        sightings: seen,
        opened: const {},
        timeZone: zone,
        onSettings: () {},
        onClose: () {},
        onOpen: (_) {},
      ),
    );
    final regional = animalEntries.where((e) => e.legend?.isRegional ?? false);
    final base = animalEntries.length - 5;
    expect(regional, hasLength(5));

    Future<int> count(List<Sighting> seen, String? zone) async {
      await showWith(seen, zone);
      final grid = tester.widget<GridView>(find.byType(GridView));
      return (grid.childrenDelegate as SliverChildListDelegate).children.length;
    }

    expect(await count(const [], null), base);
    expect(await count(const [], 'Europe/Berlin'), base);
    expect(await count(const [], 'Asia/Singapore'), base + 1);
    expect(await count(const [], 'Europe/London'), base + 1);
    final merlion = Sighting(
      _outing('m', 'Swim', DateTime(2025, 10, 22, 6, 55), 1, 30),
      'merlion',
    );
    expect(await count([merlion], 'Europe/Berlin'), base + 1);
    expect(await count([merlion], 'Asia/Singapore'), base + 1);
    await _leave(tester);
  });

  testWidgets('collection hides the dot once opened and unmet shows ???', (
    tester,
  ) async {
    await _show(
      tester,
      CollectionPage(
        sightings: _meetings,
        opened: const {'red-fox'},
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
    expect(find.text('Red fox'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('???'), findsWidgets);
    await _leave(tester);
  });

  testWidgets('animal page lists meetings newest first, oldest is first met', (
    tester,
  ) async {
    await _show(
      tester,
      AnimalPage(
        entry: entryOrDefault('red-fox'),
        meetings: _meetings,
        miles: false,
        onClose: () {},
      ),
    );
    expect(find.text('Red fox'), findsOneWidget);
    expect(find.text('Met 3 times'), findsOneWidget);
    expect(find.text('first met', findRichText: true), findsOneWidget);
    expect(find.text('Run · 3.6 km · 22 min'), findsOneWidget);
    await _shot(tester, 'animal');
    await _leave(tester);
  });

  testWidgets(
    'a meeting with a hat names it, and tapping it dresses the sprite',
    (tester) async {
      final hatted = [
        Sighting(_meetings[0].outing, 'red-fox'),
        Sighting(_meetings[1].outing, 'red-fox', hat: 'beanie'),
        Sighting(_meetings[2].outing, 'red-fox', hat: 'party-hat'),
      ];
      await _show(
        tester,
        AnimalPage(
          entry: entryOrDefault('red-fox'),
          meetings: hatted,
          miles: false,
          onClose: () {},
        ),
      );
      String? worn() =>
          tester.widget<AnimalSprite>(find.byType(AnimalSprite)).hatId;

      expect(find.text('party hat', findRichText: true), findsOneWidget);
      expect(find.text('beanie', findRichText: true), findsOneWidget);
      expect(find.byKey(const ValueKey('meeting-a')), findsNothing);
      expect(find.byType(AnimalSprite), findsOneWidget);
      expect(worn(), isNull);

      await tester.tap(find.byKey(const ValueKey('meeting-c')));
      await tester.pump();
      expect(worn(), 'party-hat');
      expect(find.byType(AnimalSprite), findsOneWidget);
      await _settleImages(tester);
      await _shot(tester, 'animal_hat');

      await tester.tap(find.byKey(const ValueKey('meeting-b')));
      await tester.pump();
      expect(worn(), 'beanie');

      await tester.tap(find.byKey(const ValueKey('meeting-b')));
      await tester.pump();
      expect(worn(), isNull);

      await tester.tap(find.textContaining('22 Oct', findRichText: true));
      await tester.pump();
      expect(worn(), isNull);
      await _leave(tester);
    },
  );

  testWidgets('the recent page draws a hat on the animal that wore it', (
    tester,
  ) async {
    await _show(
      tester,
      RecentPage(
        waiting: const [],
        sightings: [
          Sighting(
            _outing('h', 'Run', DateTime(2025, 10, 29, 8), 5, 30),
            'red-fox',
            hat: 'beanie',
          ),
          Sighting(
            _outing('p', 'Walk', DateTime(2025, 10, 28, 8), 2, 30),
            'tabby',
          ),
        ],
        miles: false,
        onClose: () {},
        onSettings: () {},
        now: DateTime(2025, 10, 30, 9),
      ),
    );
    final sprites = tester
        .widgetList<AnimalSprite>(find.byType(AnimalSprite))
        .toList();
    expect(sprites.map((s) => s.entry.id), ['red-fox', 'tabby']);
    expect(sprites.map((s) => s.hatId), ['beanie', null]);
    await _settleImages(tester);
    await _shot(tester, 'recent_hat');
    await _leave(tester);
  });

  testWidgets('animal page shows a colour species with its base frames', (
    tester,
  ) async {
    final entry = findEntry('golden-cat')!;
    expect(entry.isColour, isTrue);
    final cat = Sighting(
      _outing('f', 'Run', DateTime(2025, 10, 29, 7), 4, 25),
      entry.id,
    );
    await _show(
      tester,
      AnimalPage(entry: entry, meetings: [cat], miles: false, onClose: () {}),
    );
    expect(find.text(entry.name), findsOneWidget);
    expect(find.text(entryNote(entry)), findsOneWidget);
    expect(find.text('Met once'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/sprites/${entry.frames[0]}.png',
    );
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

    expect(prefs.checkUpdates, isTrue);
    await tester.tap(find.byKey(const ValueKey('toggle-Check for updates')));
    await tester.pump();
    expect(prefs.checkUpdates, isFalse);
    await tester.tap(find.byKey(const ValueKey('toggle-Check for updates')));
    await tester.pump();
    expect(prefs.checkUpdates, isTrue);

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

  testWidgets('sync details say what was read and what counted', (
    tester,
  ) async {
    final since = DateTime(2026, 10, 29, 21, 4);
    final report = SyncReport(
      since: since,
      at: DateTime(2026, 10, 31, 9, 30),
      found: [
        Outing(
          id: 'a',
          kind: 'Run',
          start: DateTime(2026, 10, 30, 7),
          distanceKm: 5,
          minutes: 31,
        ),
        Outing(
          id: 'b',
          kind: 'Walk',
          start: DateTime(2026, 10, 28, 18),
          distanceKm: null,
          minutes: 20,
        ),
      ],
    );
    Widget page(SyncReport? r) => SettingsPage(
      prefs: _allPrefs,
      onPrefs: (_) {},
      onBack: () {},
      onManage: () {},
      onStartOver: () {},
      report: r,
    );
    await _show(tester, page(report));
    expect(find.byKey(const ValueKey('sync-details')), findsNothing);
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.text('Counting activities from Oct 29, 21:04'), findsOneWidget);
    expect(find.text('Last checked Oct 31, 09:30'), findsOneWidget);
    expect(
      find.text('Run · 5.0 km · 31 min · Oct 30, 07:00 · counted'),
      findsOneWidget,
    );
    expect(
      find.text('Walk · 20 min · Oct 28, 18:00 · before the start'),
      findsOneWidget,
    );
    await tester.tap(find.text('Hide'));
    await tester.pump();
    expect(find.byKey(const ValueKey('sync-details')), findsNothing);
    await _leave(tester);

    await _show(tester, page(null));
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.textContaining('Not checked yet'), findsOneWidget);
    await _leave(tester);

    await _show(
      tester,
      page(SyncReport(since: since, at: since, found: const [])),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(
      find.textContaining('no exercise or sleep sessions'),
      findsOneWidget,
    );
    await _leave(tester);
  });

  testWidgets('settings footer shows the installed version', (tester) async {
    Widget page(String? version) => SettingsPage(
      prefs: _allPrefs,
      onPrefs: (_) {},
      onBack: () {},
      onManage: () {},
      onStartOver: () {},
      version: version,
    );
    await _show(tester, page('1.2.3'));
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.text('WildKaki 1.2.3 · Tiny5, OFL'), findsOneWidget);
    await _leave(tester);
    await _show(tester, page(null));
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.text('WildKaki · Tiny5, OFL'), findsOneWidget);
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
        sightings: _recentSightings,
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
