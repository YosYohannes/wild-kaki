import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../animals/lookup.dart';
import '../data/controller.dart';
import '../data/model.dart';
import '../ui/animal_page.dart';
import '../ui/collection_page.dart';
import '../ui/recent_page.dart';
import '../ui/dev_tools.dart';
import '../ui/reveal.dart';
import '../ui/settings_page.dart';
import '../ui/theme.dart';
import '../ui/update_banner.dart';
import '../update/update_service.dart';
import '../wallpaper/wallpaper_sync.dart';
import '../weather/weather_state.dart';
import '../world/pixel_buffer.dart';
import '../world/sky.dart';
import '../world/world_painter.dart';
import 'actors.dart';
import 'sounds.dart';
import 'sprites.dart';
import 'weather_layer.dart';

enum _Page { scene, collection, animal, settings, devTools, recent }

class _Revealing {
  const _Revealing(
    this.outing,
    this.entry,
    this.hatId,
    this.spot,
    this.first,
    this.timesMet,
    this.hint,
  );

  final Outing outing;
  final AnimalEntry entry;
  final String? hatId;
  final BushSpot? spot;
  final bool first;
  final int timesMet;
  final String? hint;
}

String syncedAgo(DateTime then, DateTime now) {
  final d = now.difference(then);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) {
    return '${d.inMinutes} ${d.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (d.inHours < 24) {
    return '${d.inHours} ${d.inHours == 1 ? 'hour' : 'hours'} ago';
  }
  return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
}

class SceneScreen extends StatefulWidget {
  const SceneScreen({
    super.key,
    required this.controller,
    required this.sprites,
    this.hourOverride,
    this.random,
    this.sounds,
    this.weather,
    this.updates,
    this.wallpaper,
  });

  final WildController controller;
  final SceneSprites sprites;
  final double? hourOverride;
  final math.Random? random;
  final SceneSounds? sounds;
  final WeatherState? weather;
  final UpdateService? updates;
  final WallpaperSync? wallpaper;

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late SceneState _world;
  String? _version;
  late final SceneSounds _sounds = widget.sounds ?? SceneSounds();
  late final Ticker _ticker;
  final _repaint = _Repaint();
  late WeatherState _weather;
  late final WeatherView _weatherView;
  late final WeatherLayer _weatherLayer;
  bool _ownsWeather = false;
  Timer? _clockTimer;
  Duration _last = Duration.zero;

  late double _hour;
  ui.Image? _worldImage;
  (int, int)? _worldKey;

  _Page _page = _Page.scene;
  _Page _animalFrom = _Page.collection;
  String _animalId = defaultEntryId;
  _Page _settingsFrom = _Page.collection;
  _Revealing? _revealing;
  Map<String, int> _slots = {};
  List<String> _bushIds = const [];
  List<BushSpot> _bushes = const [];
  int _bushRows = 0;

  WildController get _c => widget.controller;

  int _met(String entryId) =>
      _c.home.sightings.where((s) => s.animal == entryId).length;

  List<MeadowAnimal> get _meadow => [
    for (final s in _c.home.sightings.take(maxFoxes))
      (
        outingId: s.outing.id,
        entryId: entryOrDefault(s.animal).id,
        hatId: s.hat,
      ),
  ];

  bool get _motion =>
      _c.prefs.animate &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    (widget.updates?.platform ?? PlatformApp()).installedVersion().then((v) {
      if (mounted) setState(() => _version = v);
    });
    _hour = widget.hourOverride ?? currentHour();
    _bindWeather();
    _weatherView = WeatherView(_weather.value);
    _weatherLayer = WeatherLayer(_weatherView);
    _world = SceneState(_meadow, random: widget.random);
    _ticker = createTicker(_onTick)..start();
    if (widget.hourOverride == null) {
      _clockTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => _tickClock(),
      );
    }
  }

  void _bindWeather() {
    final given = widget.weather;
    _ownsWeather = given == null;
    _weather = given ?? WeatherState();
    _weather.addListener(_onWeather);
  }

  void _unbindWeather() {
    _weather.removeListener(_onWeather);
    if (_ownsWeather) _weather.dispose();
  }

  void _onWeather() {
    _weatherView.change(_weather.value, animate: _motion);
    _repaint.poke();
  }

  @override
  void didUpdateWidget(SceneScreen old) {
    super.didUpdateWidget(old);
    if (old.weather != widget.weather) {
      _unbindWeather();
      _bindWeather();
      _weatherView.change(_weather.value, animate: false);
      _repaint.poke();
    }
  }

  @override
  void dispose() {
    _unbindWeather();
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _ticker.dispose();
    _repaint.dispose();
    _worldImage?.dispose();
    _sounds.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tickClock();
  }

  void _tickClock() {
    if (widget.hourOverride != null || !mounted) return;
    setState(() => _hour = currentHour());
  }

  void _onTick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 0.05);
    _last = elapsed;
    _world.step(dt, _motion);
    _weatherView.step(dt);
    _repaint.poke();
  }

  void _syncTicker() {
    final run = _page == _Page.scene && _motion;
    if (_ticker.muted == run) _ticker.muted = !run;
  }

  void _ensureWorld(int rows) {
    final key = ((_hour * 12).toInt(), rows);
    if (key == _worldKey) return;
    _worldKey = key;
    paintWorld(_hour, rows).then((image) {
      if (!mounted || _worldKey != key) {
        image.dispose();
        return;
      }
      final old = _worldImage;
      setState(() => _worldImage = image);
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    });
  }

  List<BushSpot> _placeBushes(List<String> ids, Layout layout) {
    if (!listEquals(ids, _bushIds)) {
      _slots = assignBushSlots(ids, _slots);
      _bushIds = List.of(ids);
      _bushRows = 0;
    }
    if (_bushRows != layout.rows) {
      _bushRows = layout.rows;
      _bushes = [
        for (final id in ids)
          if (_slots.containsKey(id))
            bushAtSlot(id, _slots[id]!, layout: layout),
      ];
    }
    return _bushes;
  }

  void _go(_Page page) => setState(() => _page = page);

  void _back() {
    switch (_page) {
      case _Page.scene:
        break;
      case _Page.collection:
        _go(_Page.scene);
      case _Page.animal:
        _go(_animalFrom);
      case _Page.settings:
        _go(_settingsFrom);
      case _Page.devTools:
        _go(_Page.settings);
      case _Page.recent:
        _go(_Page.scene);
    }
  }

  void _tap(Offset local, double scale, Layout layout, List<BushSpot> bushes) {
    if (_page != _Page.scene || _revealing != null) return;
    final px = local.dx / scale;
    final py = local.dy / scale;
    void react(String sound) {
      if (_c.prefs.sound) _sounds.play(sound);
    }

    final fox = _world.foxes.where((f) => f.hit(px, py)).firstOrNull;
    if (fox != null) {
      fox.startle();
      react(entryOrDefault(fox.entryId).base.sound);
      return;
    }
    final swimmer = _world.swimmers.where((s) => s.hit(px, py)).firstOrNull;
    if (swimmer != null) {
      swimmer.startle();
      react(entryOrDefault(swimmer.entryId).base.sound);
      return;
    }
    final flyer = _world.flyers.where((f) => f.hit(px, py)).firstOrNull;
    if (flyer != null) {
      flyer.startle();
      react(entryOrDefault(flyer.entryId).base.sound);
      return;
    }
    for (final b in bushes) {
      if (px >= b.x - 1 &&
          px < b.x + 25 &&
          py >= b.base - 21 &&
          py < b.base + 1) {
        final outing = _c.home.waiting.where((o) => o.id == b.id).firstOrNull;
        if (outing == null) return;
        final pick = _c.previewPick(outing);
        final entry = entryOrDefault(pick.entryId);
        final met = _met(entry.id);
        setState(
          () => _revealing = _Revealing(
            outing,
            entry,
            pick.hatId,
            b,
            met == 0,
            met + 1,
            _c.previewHint(outing, pick),
          ),
        );
        return;
      }
    }
    if (px >= 12 &&
        px < 48 &&
        py >= layout.benchY - 3 &&
        py < layout.benchY + 20) {
      _go(_Page.collection);
      return;
    }
    if (px < 12 && py >= layout.lampY && py < layout.lampY + 41) {
      _go(_Page.recent);
    }
  }

  void _close(_Revealing r) {
    _world.addAnimal(r.spot?.x.toDouble() ?? 40, (
      outingId: r.outing.id,
      entryId: r.entry.id,
      hatId: r.hatId,
    ));
    _c.reveal(r.outing);
    if (_c.prefs.sound) _sounds.play(r.entry.base.sound);
  }

  Widget _pageFor(_Page page) {
    switch (page) {
      case _Page.scene:
        return const SizedBox.shrink();
      case _Page.collection:
        return CollectionPage(
          sightings: _c.home.sightings,
          opened: _c.home.opened,
          timeZone: _c.timeZone,
          onSettings: () {
            _settingsFrom = _Page.collection;
            _go(_Page.settings);
          },
          onClose: () => _go(_Page.scene),
          onOpen: (animal) {
            _c.markOpened(animal);
            _animalId = animal;
            _animalFrom = _Page.collection;
            _go(_Page.animal);
          },
        );
      case _Page.animal:
        return AnimalPage(
          entry: entryOrDefault(_animalId),
          meetings: _c.home.sightings
              .where((s) => s.animal == _animalId)
              .toList(),
          miles: _c.prefs.miles,
          onClose: _back,
        );
      case _Page.settings:
        return SettingsPage(
          prefs: _c.prefs,
          onPrefs: _c.updatePrefs,
          onBack: _back,
          onManage: _c.openHealthSettings,
          onStartOver: () async {
            await _c.startOver();
            if (mounted) {
              setState(
                () => _world = SceneState(const [], random: widget.random),
              );
            }
          },
          onDevTools: kDebugMode ? () => _go(_Page.devTools) : null,
          version: _version,
          report: _c.report,
          onWallpaper: widget.wallpaper == null
              ? null
              : () => widget.wallpaper!.choose(),
        );
      case _Page.devTools:
        return DevToolsPage(
          weather: _weather,
          onBack: _back,
          onFakeRun: _c.writeFakeRun,
          onFakeSleep: _c.writeFakeSleep,
        );
      case _Page.recent:
        return RecentPage(
          waiting: _c.home.waiting,
          sightings: _c.home.sightings,
          miles: _c.prefs.miles,
          onClose: _back,
          onSettings: () {
            _settingsFrom = _Page.recent;
            _go(_Page.settings);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return PopScope(
      canPop: _page == _Page.scene && _revealing == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _revealing == null) _back();
      },
      child: LayoutBuilder(
        builder: (context, box) => ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncTicker();
            });
            final width = box.maxWidth;
            final scale = width / worldW;
            final rows = (box.maxHeight / scale).ceil();
            _ensureWorld(rows);
            final layout = Layout.forRows(rows);
            _world.fit(layout);
            final bushes = _placeBushes([
              for (final o in _c.home.waiting.take(maxBushes)) o.id,
            ], layout);
            final night = skyAt(_hour).stars;
            final reveal = _revealing;
            final synced = _c.home.lastSynced;
            final status =
                _c.notice ??
                (synced != null
                    ? 'synced ${syncedAgo(synced, DateTime.now())}'
                    : 'pull down to sync');
            return Stack(
              children: [
                Positioned.fill(
                  child: RefreshIndicator(
                    onRefresh: _c.refresh,
                    color: Wild.ember,
                    backgroundColor: Wild.parchment,
                    edgeOffset: top,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) =>
                            _tap(d.localPosition, scale, layout, bushes),
                        child: SizedBox(
                          width: width,
                          height: box.maxHeight,
                          child: CustomPaint(
                            painter: _ScenePainter(
                              repaint: _repaint,
                              world: _worldImage,
                              sprites: widget.sprites,
                              state: _world,
                              layout: layout,
                              bushes: bushes,
                              hiddenBush: reveal?.outing.id,
                              night: night,
                              motion: _motion,
                              weather: _weatherLayer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  right: 20,
                  child: IgnorePointer(
                    child: Text(
                      status,
                      style: numberText(11, color: Wild.fern),
                    ),
                  ),
                ),
                if (_page == _Page.scene &&
                    reveal == null &&
                    widget.updates != null)
                  Positioned(
                    top: top + 32,
                    left: 16,
                    right: 16,
                    child: ValueListenableBuilder<UpdateInfo?>(
                      valueListenable: widget.updates!.available,
                      builder: (context, info, _) =>
                          info == null || !_c.prefs.checkUpdates
                          ? const SizedBox.shrink()
                          : UpdateBanner(
                              info: info,
                              onLater: widget.updates!.dismiss,
                              onUpdate: widget.updates!.openUpdate,
                            ),
                    ),
                  ),
                if (_page != _Page.scene)
                  Positioned.fill(child: _pageFor(_page)),
                if (reveal != null)
                  Positioned.fill(
                    child: RevealOverlay(
                      key: ValueKey(reveal.outing.id),
                      outing: reveal.outing,
                      entry: reveal.entry,
                      hatId: reveal.hatId,
                      first: reveal.first,
                      timesMet: reveal.timesMet,
                      hint: reveal.hint,
                      miles: _c.prefs.miles,
                      bushTopLeft: Offset(
                        ((reveal.spot?.x ?? 40) - 5) * scale,
                        ((reveal.spot?.base ?? layout.y(130)) - 32) * scale,
                      ),
                      scale: scale,
                      layout: layout,
                      animate: _motion,
                      onClose: () => _close(reveal),
                      onFinished: () => setState(() => _revealing = null),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Repaint extends ChangeNotifier {
  void poke() => notifyListeners();
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required Listenable repaint,
    required this.world,
    required this.sprites,
    required this.state,
    required this.layout,
    required this.bushes,
    required this.hiddenBush,
    required this.night,
    required this.motion,
    required this.weather,
  }) : super(repaint: repaint);

  final ui.Image? world;
  final SceneSprites sprites;
  final SceneState state;
  final Layout layout;
  final List<BushSpot> bushes;
  final String? hiddenBush;
  final double night;
  final bool motion;
  final WeatherLayer weather;

  static final _plain = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  void _sprite(
    Canvas canvas,
    ui.Image img,
    int x,
    int y,
    double s, [
    Paint? paint,
  ]) {
    final x0 = (x * s).round();
    final y0 = (y * s).round();
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTRB(
        x0.toDouble(),
        y0.toDouble(),
        ((x + img.width) * s).roundToDouble(),
        ((y + img.height) * s).roundToDouble(),
      ),
      paint ?? _plain,
    );
  }

  void _animal(
    Canvas canvas,
    String entryId,
    String? hatId,
    int frame,
    bool left,
    int x,
    int y,
    double s, {
    bool flying = false,
  }) {
    final entry = entryOrDefault(entryId);
    final frames = flying ? entry.flyFrames : entry.frames;
    final headPoints = flying ? entry.flyHeadPoints : entry.headPoints;
    final i = frame % frames.length;
    _sprite(canvas, sprites.named(frames[i], mirrored: left), x, y, s);
    final hat = hatById(hatId);
    if (hat == null) return;
    final img = sprites.named(hat.sprite, mirrored: left);
    final head = headPoints[i % headPoints.length];
    final hx = left ? 31 - head.x : head.x;
    _sprite(
      canvas,
      img,
      x + hx - img.width ~/ 2,
      y + head.y - img.height + 1,
      s,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / worldW;
    final image = world;
    if (image == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Wild.night);
      return;
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        0,
        0,
        size.width.roundToDouble(),
        (image.height * s).roundToDouble(),
      ),
      _plain,
    );

    final wet = weather.active;
    if (wet) {
      weather.paintTint(canvas, size, layout, night);
      weather.paintParticles(
        canvas,
        size,
        layout,
        night,
        motion ? state.clock : 0,
      );
    }

    Color? dimColor;
    if (night > 0.01) {
      dimColor = const Color(0xFF0B1510).withValues(alpha: night * 0.55);
    }
    final wetDim = wet ? weather.dim(night) : null;
    if (wetDim != null) {
      dimColor = dimColor == null ? wetDim : combineDim(dimColor, wetDim);
    }
    Paint? dim;
    if (dimColor != null) {
      dim = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..colorFilter = ColorFilter.mode(dimColor, BlendMode.srcATop);
    }
    _sprite(canvas, sprites.bench, Layout.benchX, layout.benchY, s, dim);
    _sprite(canvas, sprites.lamppost, Layout.lampX, layout.lampY, s, dim);
    if (night > 0.05) {
      canvas.drawRect(
        Rect.fromLTWH(4 * s, layout.lanternY * s, 6 * s, 6 * s),
        Paint()
          ..color = const Color(0xFFFFE9A0)
              .withValues(alpha: night.clamp(0.0, 1.0)),
      );
    }
    for (final f in state.flyers) {
      _animal(
        canvas,
        f.entryId,
        f.hatId,
        f.frame,
        f.dir < 0,
        f.x.round(),
        f.y,
        s,
        flying: true,
      );
    }

    final clock = state.clock;
    final blink = motion && (clock % 3.2) > 3.0;
    final items = <(int, int, void Function())>[];
    for (final b in bushes) {
      if (b.id == hiddenBush) continue;
      items.add((
        b.base,
        items.length,
        () {
          final rustle = motion && ((clock + b.x * 0.03) % 5) < 0.45
              ? ((clock * 24).toInt() % 2 == 1 ? 1 : -1)
              : 0;
          _sprite(
            canvas,
            blink ? sprites.bushBlink : sprites.bush,
            b.x - 5 + rustle,
            b.base - 32,
            s,
          );
        },
      ));
    }
    for (final f in state.foxes) {
      items.add((
        f.feet,
        items.length,
        () => _animal(
          canvas,
          f.entryId,
          f.hatId,
          f.frame,
          f.dir < 0,
          f.x.round(),
          f.feet - 32,
          s,
        ),
      ));
    }
    for (final w in state.swimmers) {
      items.add((
        w.feet,
        items.length,
        () {
          canvas.save();
          canvas.clipRect(
            Rect.fromLTRB(
              0,
              0,
              size.width,
              ((w.feet - Swimmer.waterline) * s).roundToDouble(),
            ),
            doAntiAlias: false,
          );
          _animal(
            canvas,
            w.entryId,
            w.hatId,
            w.frame,
            w.dir < 0,
            w.x.round(),
            w.feet - 32,
            s,
          );
          canvas.restore();
        },
      ));
    }
    items.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    for (final item in items) {
      item.$3();
    }
    for (final f in state.foxes.where((f) => f.bubble > 0)) {
      _bubble(
        canvas,
        entryOrDefault(f.entryId).base.bubble,
        (f.x + 16) * s,
        (f.feet - 20) * s,
        s,
      );
    }
    for (final w in state.swimmers.where((w) => w.bubble > 0)) {
      _bubble(
        canvas,
        entryOrDefault(w.entryId).base.bubble,
        (w.x + 16) * s,
        (w.feet - 20) * s,
        s,
      );
    }
    for (final f in state.flyers.where((f) => f.bubble > 0)) {
      _bubble(
        canvas,
        entryOrDefault(f.entryId).base.bubble,
        (f.x + 16) * s,
        (f.y + 12) * s,
        s,
      );
    }
  }

  void _bubble(Canvas canvas, String text, double cx, double bottom, double s) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: pixelText(s * 4.2, color: Wild.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pad = s * 1.5;
    final rect = Rect.fromLTWH(
      cx - tp.width / 2 - pad,
      bottom - tp.height - pad * 2,
      tp.width + pad * 2,
      tp.height + pad * 2,
    );
    canvas.drawRect(rect, Paint()..color = Wild.parchment);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.8
        ..color = Wild.outline,
    );
    tp.paint(canvas, rect.topLeft + Offset(pad, pad));
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.world != world ||
      old.state != state ||
      old.layout != layout ||
      old.bushes != bushes ||
      old.hiddenBush != hiddenBush ||
      old.night != night ||
      old.motion != motion ||
      old.weather != weather;
}
