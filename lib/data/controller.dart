import 'package:flutter/foundation.dart';

import '../animals/rules.dart';
import 'health_sync.dart';
import 'model.dart';
import 'store.dart';

class WildController extends ChangeNotifier {
  WildController(this._store, this._source) {
    _home = _store.home();
    _prefs = _store.prefsState();
  }

  static Future<WildController> create({
    required bool systemAnimate,
    OutingSource? source,
    WildStore? store,
  }) async {
    final controller = WildController(
      store ?? await WildStore.open(systemAnimate: systemAnimate),
      source ?? HealthConnectSource(),
    );
    await controller._checkStatus();
    return controller;
  }

  final WildStore _store;
  final OutingSource _source;
  late HomeState _home;
  late Prefs _prefs;
  SourceStatus _status = SourceStatus.missing;
  bool _refreshing = false;
  String? _notice;

  HomeState get home => _home;
  Prefs get prefs => _prefs;
  bool get refreshing => _refreshing;
  String? get notice => _notice;
  bool get connected => _status == SourceStatus.available;

  Future<void> _checkStatus() async {
    try {
      _status = await _source.status();
    } catch (_) {
      _status = SourceStatus.missing;
    }
  }

  Future<void> syncQuietly() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _checkStatus();
      if (connected && await _source.hasAccess()) await _sync();
    } catch (_) {
      _notice = _couldntReach;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _notice = null;
    notifyListeners();
    try {
      await _checkStatus();
      if (!connected) {
        _notice = _status == SourceStatus.updateRequired
            ? 'update Health Connect to sync'
            : "Health Connect isn't on this phone";
      } else if (await _source.hasAccess() || await _source.requestAccess()) {
        await _sync();
      } else {
        _notice = 'allow Health Connect to find your activities';
      }
    } catch (_) {
      _notice = _couldntReach;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  static const _couldntReach = "couldn't reach Health Connect";

  Future<void> _sync() async {
    _notice = null;
    final baseline = _store.baseline;
    final found = await _source.outingsSince(baseline);
    final counted = found
        .where(
          // sleep starts the evening before, so it counts by when it ended
          (o) => !(o.kind == sleepKind ? o.end : o.start).isBefore(baseline),
        )
        .toList();
    _home = await _store.addWaiting(counted);
  }

  Future<void> reveal(Outing o) async {
    _home = await _store.reveal(o, animalIdFor(o));
    notifyListeners();
  }

  Future<void> markOpened(String animal) async {
    _home = await _store.markOpened(animal);
    notifyListeners();
  }

  Future<void> updatePrefs(Prefs p) async {
    _prefs = p;
    notifyListeners();
    await _store.savePrefs(p);
  }

  Future<void> startOver() async {
    _home = await _store.startOver();
    _notice = null;
    notifyListeners();
  }

  Future<void> openHealthSettings() => _source.openSettings();

  Future<String> writeFakeRun() async {
    try {
      final start = await _source.writeFakeRun();
      await _store.lowerBaseline(start);
      return 'wrote a fake run, pull down to find it';
    } catch (e) {
      return "couldn't write a fake run: $e";
    }
  }

  Future<String> writeFakeSleep() async {
    try {
      final start = await _source.writeFakeSleep();
      await _store.lowerBaseline(start);
      return 'wrote a fake sleep, pull down to find it';
    } catch (e) {
      return "couldn't write a fake sleep: $e";
    }
  }
}
