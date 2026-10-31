import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildkaki/animals/lookup.dart';
import 'package:wildkaki/data/controller.dart';
import 'package:wildkaki/data/health_sync.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/data/store.dart';
import 'package:wildkaki/scene/actors.dart';
import 'package:wildkaki/scene/sprites.dart';
import 'package:wildkaki/wallpaper/wallpaper_export.dart';
import 'package:wildkaki/wallpaper/wallpaper_sync.dart';
import 'package:wildkaki/weather/weather_state.dart';

class _Source implements OutingSource {
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

class _Host implements WallpaperHost {
  _Host(this.dir);

  final String dir;
  bool active = false;
  bool background = false;
  int chooser = 0;

  @override
  Future<String?> directory() async => dir;

  @override
  Future<bool> isActive() async => active;

  @override
  Future<bool> openChooser() async {
    chooser++;
    return true;
  }

  @override
  Future<bool> backgroundAllowed() async => background;

  @override
  Future<bool> requestBackground() async => background = true;
}

Future<WildController> _controller(List<(String, String?)> animals) async {
  SharedPreferences.setMockInitialValues({});
  final store = await WildStore.open(systemAnimate: true);
  final seen = [
    for (var i = 0; i < animals.length; i++)
      Outing(
        id: 's$i',
        kind: 'Run',
        start: DateTime(2026, 10, 20 + i, 7),
        distanceKm: 5,
        minutes: 30,
      ),
  ];
  await store.addWaiting(seen);
  for (var i = 0; i < animals.length; i++) {
    await store.reveal(seen[i], animals[i].$1, hat: animals[i].$2);
  }
  return WildController(store, _Source());
}

const _screen = ui.Size(1080, 2520);

void main() {
  late SceneSprites sprites;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sprites = await SceneSprites.load();
  });

  test('rows follow the screen shape', () {
    expect(wallpaperRows(1080, 2520), 280);
    expect(wallpaperRows(1080, 2340), 260);
    expect(wallpaperRows(1080, 2400), 267);
  });

  group('manifest', () {
    Map<String, Object?> build({
      Weather weather = Weather.clear,
      bool animate = true,
      List<MeadowAnimal>? animals,
    }) => wallpaperManifest(
      rows: 315,
      animate: animate,
      weather: weather,
      animals:
          animals ??
          [
            (outingId: 'a', entryId: 'red-fox', hatId: 'beanie'),
            (outingId: 'b', entryId: 'mallard', hatId: null),
          ],
    );

    test('describes the world, its lanes and the 24 backdrops', () {
      final m = build();
      expect(m['worldW'], 120);
      expect(m['rows'], 315);
      expect(m['k'], 315 / 280);
      expect(m['waterline'], Swimmer.waterline);
      expect(m['lanes'], {
        'meadow': [meadowFeetRef, meadowFeetSpan],
        'river': [riverFeetRef, riverFeetSpan],
        'sky': [skyTopRef, skyTopSpan],
      });
      final backdrops = m['backdrops'] as List;
      expect(backdrops, hasLength(24));
      expect(backdrops.first, 'bg_00.png');
      expect(backdrops.last, 'bg_23.png');
      final night = m['night'] as List;
      expect(night, hasLength(24));
      expect(night[2], 1);
      expect(night[12], 0);
    });

    test('each animal carries its lane, frames, head points and hat', () {
      final animals = build()['animals'] as List;
      final fox = animals[0] as Map;
      expect(fox['lane'], 'meadow');
      expect(fox['frames'], entryOrDefault('red-fox').frames);
      expect(fox['hat'], 'hat_beanie');
      expect((fox['heads'] as List).first, [
        entryOrDefault('red-fox').headPoints.first.x,
        entryOrDefault('red-fox').headPoints.first.y,
      ]);
      expect((animals[1] as Map)['hat'], isNull);
    });

    test('swimmers and flyers get their own lanes and frames', () {
      final swimmer =
          (build(
                        animals: [
                          (outingId: 'x', entryId: 'mallard', hatId: null),
                        ],
                      )['animals']
                      as List)
                  .single
              as Map;
      expect(swimmer['lane'], 'river');
      final flyer = entryOrDefault('fruit-bat');
      final bat =
          (build(
                        animals: [
                          (outingId: 'x', entryId: flyer.id, hatId: null),
                        ],
                      )['animals']
                      as List)
                  .single
              as Map;
      expect(bat['lane'], 'sky');
      expect(bat['frames'], flyer.flyFrames);
    });

    test('it lists the three bush spots and how many activities wait', () {
      final m = wallpaperManifest(
        rows: 315,
        animate: true,
        weather: Weather.clear,
        animals: const [],
        waiting: 2,
      );
      expect(m['waiting'], 2);
      final bushes = m['bushes'] as List;
      expect(bushes, hasLength(maxBushes));
      for (var i = 0; i < maxBushes; i++) {
        final spot = bushAtSlot('', i);
        expect(bushes[i], [spot.x, spot.refBase]);
      }
      expect(build()['waiting'], 0);
    });

    test('only the newest six animals are listed', () {
      final animals =
          build(
                animals: [
                  for (var i = 0; i < 9; i++)
                    (outingId: 'o$i', entryId: 'red-fox', hatId: null),
                ],
              )['animals']
              as List;
      expect(animals, hasLength(maxFoxes));
    });

    test('rain is described only for wet weather', () {
      expect(build()['rain'], isNull);
      expect(build(weather: Weather.cloudy)['rain'], isNull);
      final rain = build(weather: Weather.rain)['rain'] as Map;
      expect(rain['drops'], hasLength(40));
      expect(
        (build(weather: Weather.storm)['rain'] as Map)['drops'],
        hasLength(80),
      );
    });

    test('it survives JSON', () {
      final m = build(weather: Weather.rain);
      expect(jsonDecode(jsonEncode(m)), isA<Map>());
    });
  });

  group('rendering', () {
    test('a backdrop is a PNG the size of the world', () async {
      final png = await renderBackdrop(
        hour: 12,
        rows: 315,
        weather: Weather.clear,
        sprites: sprites,
      );
      final codec = await ui.instantiateImageCodec(png);
      final image = (await codec.getNextFrame()).image;
      expect((image.width, image.height), (120, 315));
    });

    test('the hours differ and the weather changes the picture', () async {
      Future<List<int>> at(double hour, Weather w) =>
          renderBackdrop(hour: hour, rows: 315, weather: w, sprites: sprites);
      final noon = await at(12, Weather.clear);
      expect(await at(12, Weather.clear), noon);
      expect(await at(0, Weather.clear), isNot(noon));
      expect(await at(12, Weather.rain), isNot(noon));
    });

    test('an export writes 24 backdrops and then the manifest', () async {
      final dir = await Directory.systemTemp.createTemp('wallpaper');
      addTearDown(() => dir.delete(recursive: true));
      final manifest = wallpaperManifest(
        rows: 315,
        animate: true,
        weather: Weather.clear,
        animals: [(outingId: 'a', entryId: 'red-fox', hatId: null)],
      );
      await exportWallpaper(
        dir: dir,
        manifest: manifest,
        weather: Weather.clear,
        sprites: sprites,
      );
      for (var h = 0; h < 24; h++) {
        expect(File('${dir.path}/${backdropName(h)}').existsSync(), isTrue);
      }
      final written = jsonDecode(
        File('${dir.path}/manifest.json').readAsStringSync(),
      ) as Map;
      expect(written['rows'], 315);
      expect(written['writtenAt'], isA<int>());
      expect(File('${dir.path}/manifest.json.tmp').existsSync(), isFalse);
    });
  });

  group('sync', () {
    late Directory dir;
    late _Host host;
    late WeatherState weather;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('wallpaper');
      host = _Host(dir.path);
      weather = WeatherState();
    });

    tearDown(() => dir.delete(recursive: true));

    Future<WallpaperSync> sync(WildController c) async => WallpaperSync(
      controller: c,
      weather: weather,
      sprites: sprites,
      host: host,
      screen: () => _screen,
      debounce: const Duration(milliseconds: 10),
    );

    Future<List<String>> files() async => [
      for (final f in dir.listSync()) f.path.split('/').last,
    ];

    test('nothing is written while the wallpaper is not in use', () async {
      final c = await _controller([('red-fox', null)]);
      final s = await sync(c);
      await s.update();
      expect(await files(), isEmpty);
    });

    test(
      'it writes once the wallpaper is active, then only on change',
      () async {
        final c = await _controller([('red-fox', null)]);
        final s = await sync(c);
        host.active = true;
        await s.update();
        final manifest = File('${dir.path}/manifest.json');
        expect(manifest.existsSync(), isTrue);
        final first = manifest.lastModifiedSync();

        await Future<void>.delayed(const Duration(milliseconds: 20));
        await s.update();
        expect(manifest.lastModifiedSync(), first);

        weather.live = Weather.rain;
        await s.update();
        expect(manifest.lastModifiedSync().isAfter(first), isTrue);
        final written = jsonDecode(manifest.readAsStringSync()) as Map;
        expect(written['rain'], isNotNull);
        expect((written['animals'] as List), hasLength(1));
      },
    );

    test(
      'a change in waiting rewrites the manifest but not the backdrops',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = await WildStore.open(systemAnimate: true);
        final c = WildController(store, _Source());
        final s = await sync(c);
        host.active = true;
        await s.update();
        final bg = File('${dir.path}/bg_12.png');
        final manifest = File('${dir.path}/manifest.json');
        expect((jsonDecode(manifest.readAsStringSync()) as Map)['waiting'], 0);
        final bgTime = bg.lastModifiedSync();

        await store.addWaiting([
          Outing(
            id: 'w',
            kind: 'Run',
            start: DateTime.now().add(const Duration(hours: 1)),
            distanceKm: 3,
            minutes: 20,
          ),
        ]);
        await c.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await s.update();
        expect(
          (jsonDecode(manifest.readAsStringSync()) as Map)['waiting'],
          c.home.waiting.length,
        );
        expect(bg.lastModifiedSync(), bgTime);
      },
    );

    test('the background permission is asked through the host', () async {
      final c = await _controller([('red-fox', null)]);
      final s = await sync(c);
      expect(await s.backgroundAllowed(), isFalse);
      expect(await s.requestBackground(), isTrue);
      expect(await s.backgroundAllowed(), isTrue);
    });

    test('a new animal and the animate setting both reach the file', () async {
      final c = await _controller([('red-fox', null)]);
      final s = await sync(c);
      host.active = true;
      await s.update();
      await c.updatePrefs(c.prefs.copyWith(animate: false));
      await s.update();
      final written = jsonDecode(
        File('${dir.path}/manifest.json').readAsStringSync(),
      ) as Map;
      expect(written['animate'], isFalse);
    });

    test('choosing exports first and then opens the chooser', () async {
      final c = await _controller([('red-fox', 'beanie')]);
      final s = await sync(c);
      expect(await s.choose(), isTrue);
      expect(host.chooser, 1);
      expect(File('${dir.path}/manifest.json').existsSync(), isTrue);
      final animal =
          ((jsonDecode(File('${dir.path}/manifest.json').readAsStringSync())
                          as Map)['animals']
                      as List)
                  .single
              as Map;
      expect(animal['hat'], 'hat_beanie');
    });

    test('a failing host leaves the app alone', () async {
      final c = await _controller([('red-fox', null)]);
      final s = WallpaperSync(
        controller: c,
        weather: weather,
        sprites: sprites,
        host: _Host('/nonexistent/readonly/path')..active = true,
        screen: () => _screen,
      );
      await s.update();
    });

    test('changes schedule one debounced update', () async {
      final c = await _controller([('red-fox', null)]);
      host.active = true;
      final s = await sync(c);
      s.attach();
      weather.live = Weather.rain;
      weather.live = Weather.cloudy;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(File('${dir.path}/manifest.json').existsSync(), isTrue);
      s.detach();
    });
  });
}
