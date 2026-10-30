import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/lookup.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/ui/reveal.dart';
import 'package:wildkaki/world/world_painter.dart';

const _shots = 'build/test_shots';
const _sprites = [
  'bush',
  'bush_blink',
  'stub_fox_1',
  'stub_fox_2',
  'hat_party-hat',
];

final _outing = Outing(
  id: 'o1',
  kind: 'Run',
  start: DateTime(2026, 10, 29, 7, 30),
  distanceKm: 3.6,
  minutes: 22,
);

String _arrival(String entryId, String kind) =>
    arrivalLine(entryOrDefault(entryId).base, kind);

final _now = DateTime(2026, 10, 29, 10);
final _key = GlobalKey();

Widget _host({
  required Outing outing,
  String entryId = 'red-fox',
  String? hatId,
  bool first = true,
  bool animate = true,
  VoidCallback? onClose,
  VoidCallback? onFinished,
  int timesMet = 3,
  String? hint,
  bool miles = false,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
      key: _key,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF2B5E52))),
          Positioned.fill(
            child: RevealOverlay(
              outing: outing,
              entry: entryOrDefault(entryId),
              hatId: hatId,
              first: first,
              timesMet: timesMet,
              hint: hint,
              miles: miles,
              bushTopLeft: const Offset(171, 294),
              scale: 3,
              layout: Layout.reference,
              animate: animate,
              now: _now,
              onClose: onClose ?? () {},
              onFinished: onFinished ?? () {},
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _load(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(RevealOverlay));
    for (final n in _sprites) {
      await precacheImage(AssetImage('assets/sprites/$n.png'), context);
    }
  });
}

Future<void> _pumpHost(WidgetTester tester, Widget w) async {
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(w);
  await _load(tester);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_key),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_shots).createSync(recursive: true);
    await File('$_shots/flutter_reveal_$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _at(WidgetTester tester, int ms, {int from = 0}) async {
  await tester.pump(Duration(milliseconds: ms - from));
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Tiny5')
      ..addFont(rootBundle.load('assets/fonts/tiny5.ttf'));
    await loader.load();
  });

  testWidgets('stages progress with pumped time', (tester) async {
    await _pumpHost(tester, _host(outing: _outing));
    await tester.pump(Duration.zero);

    await _at(tester, 400);
    expect(find.bySemanticsLabel('Close'), findsNothing);
    await _shot(tester, '1_shake');

    await _at(tester, 1200, from: 400);
    await _shot(tester, '2_hop');

    await _at(tester, 2100, from: 1200);
    await _shot(tester, '3_colour');

    await _at(tester, 2600, from: 2100);
    expect(find.bySemanticsLabel('Close'), findsNothing);
    expect(find.text(_arrival('red-fox', 'Run')), findsNothing);

    await _at(tester, 2800, from: 2600);
    expect(find.text('R'), findsOneWidget);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);

    await _at(tester, 3700, from: 2800);
    expect(find.text('Red fox'), findsOneWidget);
    expect(find.text(_arrival('red-fox', 'Run')), findsOneWidget);
    expect(find.text('Run · 3.6 km · 22 min · this morning'), findsOneWidget);
    expect(find.text(entryNote(entryOrDefault('red-fox'))), findsOneWidget);
    await _shot(tester, '4_text');
  });

  testWidgets(
    'Close fires onClose, fox leaves, ember blinks, then onFinished',
    (tester) async {
      var nice = 0;
      var finished = 0;
      await _pumpHost(
        tester,
        _host(
          outing: _outing,
          onClose: () => nice++,
          onFinished: () => finished++,
        ),
      );
      await tester.pump(Duration.zero);
      await tester.pump(const Duration(milliseconds: 3200));

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pump();
      expect(nice, 1);
      expect(find.bySemanticsLabel('Close'), findsNothing);
      expect(finished, 0);

      await tester.pump(const Duration(milliseconds: 1000));
      await _shot(tester, '5_walk');
      expect(finished, 0);

      await tester.pump(const Duration(milliseconds: 1000));
      await _shot(tester, '6_ember');
      expect(finished, 0);

      await tester.pump(const Duration(milliseconds: 2500));
      expect(finished, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(finished, 1);
      expect(nice, 1);
    },
  );

  testWidgets('tag differs for first and met before', (tester) async {
    await _pumpHost(tester, _host(outing: _outing, animate: false));
    await tester.pump();
    expect(find.text('New in your collection'), findsOneWidget);
    expect(find.text('Met 3 times'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _pumpHost(
      tester,
      _host(outing: _outing, first: false, animate: false, timesMet: 4),
    );
    await tester.pump();
    expect(find.text('Met 4 times'), findsOneWidget);
    expect(find.text('New in your collection'), findsNothing);
  });

  testWidgets('a repeat meeting shows a hint about someone unmet', (
    tester,
  ) async {
    await _pumpHost(tester, _host(outing: _outing, animate: false));
    await tester.pump();
    expect(find.byKey(const ValueKey('reveal-hint')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await _pumpHost(
      tester,
      _host(
        outing: _outing,
        first: false,
        animate: false,
        timesMet: 2,
        hint: 'fennec',
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('reveal-hint-title')), findsOneWidget);
    expect(
      find.text('Turns up on runs. Loves speed, fond of daylight.'),
      findsOneWidget,
    );
    expect(find.text('Fennec'), findsNothing);
    await _shot(tester, 'hint');
  });

  testWidgets('animate false shows the text immediately', (tester) async {
    var nice = 0;
    var finished = 0;
    await _pumpHost(
      tester,
      _host(
        outing: _outing,
        animate: false,
        onClose: () => nice++,
        onFinished: () => finished++,
      ),
    );
    await tester.pump();
    expect(find.text('Red fox'), findsOneWidget);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    expect(find.text(entryNote(entryOrDefault('red-fox'))), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump();
    expect(nice, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(finished, 1);
  });

  testWidgets('sleep is greeted without joining and shows its duration', (
    tester,
  ) async {
    final sleep = Outing(
      id: 'o4',
      kind: sleepKind,
      start: DateTime(2026, 10, 28, 23, 10),
      distanceKm: null,
      minutes: 440,
    );
    await _pumpHost(tester, _host(outing: sleep, animate: false));
    await tester.pump();
    expect(find.text('watched over your sleep'), findsOneWidget);
    expect(find.textContaining('joined'), findsNothing);
    expect(find.text('Sleep · 7 h 20 min · yesterday'), findsOneWidget);
    await _shot(tester, 'sleep');
  });

  testWidgets('a duck arrives with its own name, heading and bubble', (
    tester,
  ) async {
    await _pumpHost(tester, _host(outing: _outing, entryId: 'duck'));
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 3600));
    expect(find.text('Duck'), findsOneWidget);
    expect(find.text('paddled along on your run'), findsOneWidget);
    expect(find.text(entryNote(entryOrDefault('duck'))), findsOneWidget);
    await _shot(tester, 'duck');

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('quack!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a hat sits on the animal in the hop, the card and the run-off', (
    tester,
  ) async {
    final hat = find.image(
      const AssetImage('assets/sprites/hat_party-hat.png'),
    );
    await _pumpHost(tester, _host(outing: _outing, hatId: 'party-hat'));
    await tester.pump(Duration.zero);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(hat, findsOneWidget);
    await _shot(tester, 'hat_hop');

    await tester.pump(const Duration(milliseconds: 2400));
    expect(hat, findsWidgets);
    await _shot(tester, 'hat_card');

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(hat, findsWidgets);
    await _shot(tester, 'hat_walk');
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('no hat is drawn when none was picked', (tester) async {
    await _pumpHost(tester, _host(outing: _outing, animate: false));
    await tester.pump();
    expect(
      find.image(const AssetImage('assets/sprites/hat_party-hat.png')),
      findsNothing,
    );
  });

  testWidgets('the run-off bubble is the base bubble', (tester) async {
    await _pumpHost(tester, _host(outing: _outing));
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(entryOrDefault('red-fox').base.bubble), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('meta follows units and day', (tester) async {
    final yesterday = Outing(
      id: 'o2',
      kind: 'Walk',
      start: DateTime(2026, 10, 28, 18),
      distanceKm: 2.0,
      minutes: 30,
    );
    await _pumpHost(
      tester,
      _host(outing: yesterday, animate: false, miles: true),
    );
    await tester.pump();
    expect(find.text('Walk · 1.2 mi · 30 min · yesterday'), findsOneWidget);
    expect(find.text(_arrival('red-fox', 'Walk')), findsOneWidget);

    final old = Outing(
      id: 'o3',
      kind: 'Hike',
      start: DateTime(2026, 10, 21, 9),
      distanceKm: null,
      minutes: 45,
    );
    await tester.pumpWidget(const SizedBox());
    await _pumpHost(tester, _host(outing: old, animate: false));
    await tester.pump();
    expect(find.text('Hike · 45 min · Wed 21 Oct'), findsOneWidget);
  });
}
