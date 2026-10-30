import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../animals/lookup.dart';
import 'model.dart';

class WildStore {
  WildStore(
    this._prefs, {
    required this.systemAnimate,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    if (!_prefs.containsKey(_baselineKey)) {
      _prefs.setInt(_baselineKey, _clock().millisecondsSinceEpoch);
    }
  }

  static Future<WildStore> open({
    required bool systemAnimate,
    DateTime Function()? clock,
  }) async => WildStore(
    await SharedPreferences.getInstance(),
    systemAnimate: systemAnimate,
    clock: clock,
  );

  final SharedPreferences _prefs;
  final bool systemAnimate;
  final DateTime Function() _clock;

  static const _baselineKey = 'baseline';
  static const _waitingKey = 'waiting';
  static const _sightingsKey = 'sightings';
  static const _openedKey = 'opened';
  static const _syncedKey = 'synced';
  static const _milesKey = 'miles';
  static const _animateKey = 'animate';
  static const _soundKey = 'sound';
  static const _legacyKinds = {'run': 'Run', 'walk': 'Walk', 'climb': 'Climb'};

  DateTime get baseline =>
      DateTime.fromMillisecondsSinceEpoch(_prefs.getInt(_baselineKey)!);

  HomeState home() => HomeState(
    waiting: _readOutings(_waitingKey),
    sightings: _readSightings(),
    opened: (_prefs.getStringList(_openedKey) ?? const <String>[])
        .map(legacyEntryId)
        .toSet(),
    lastSynced: _prefs
        .getInt(_syncedKey)
        .let(DateTime.fromMillisecondsSinceEpoch),
  );

  Future<HomeState> addWaiting(List<Outing> found) async {
    final waiting = _readOutings(_waitingKey);
    final known = {
      ...waiting.map((o) => o.id),
      ..._readSightings().map((s) => s.outing.id),
    };
    for (final outing in found) {
      if (known.add(outing.id)) waiting.add(outing);
    }
    waiting.sort((a, b) => a.start.compareTo(b.start));
    await _prefs.setString(_waitingKey, _write(waiting));
    await _prefs.setInt(_syncedKey, _clock().millisecondsSinceEpoch);
    return home();
  }

  Future<HomeState> reveal(Outing outing, String animal, {String? hat}) async {
    final waiting = _readOutings(_waitingKey)
        .where((o) => o.id != outing.id)
        .toList();
    final sightings = _readSightings()
      ..removeWhere((s) => s.outing.id == outing.id);
    final next = sightings.fold(0, (m, s) => max(m, s.order ?? 0)) + 1;
    sightings
      ..add(Sighting(outing, animal, hat: hat, order: next))
      ..sort((a, b) => b.outing.start.compareTo(a.outing.start));
    await _prefs.setString(_waitingKey, _write(waiting));
    await _prefs.setString(_sightingsKey, _writeSightings(sightings));
    return home();
  }

  Future<HomeState> markOpened(String entryId) async {
    final opened = {
      ..._prefs.getStringList(_openedKey) ?? const <String>[],
      entryId,
    };
    await _prefs.setStringList(_openedKey, opened.toList());
    return home();
  }

  Future<HomeState> startOver() async {
    await _prefs.remove(_waitingKey);
    await _prefs.remove(_sightingsKey);
    await _prefs.remove(_openedKey);
    await _prefs.remove(_syncedKey);
    await _prefs.setInt(_baselineKey, _clock().millisecondsSinceEpoch);
    return home();
  }

  Future<void> lowerBaseline(DateTime to) async {
    if (!to.isBefore(baseline)) return;
    await _prefs.setInt(_baselineKey, to.millisecondsSinceEpoch);
  }

  Prefs prefsState() {
    return Prefs(
      miles: _prefs.getBool(_milesKey) ?? false,
      animate: _prefs.getBool(_animateKey) ?? systemAnimate,
      sound: _prefs.getBool(_soundKey) ?? true,
    );
  }

  Future<void> savePrefs(Prefs value) async {
    await _prefs.setBool(_milesKey, value.miles);
    await _prefs.setBool(_animateKey, value.animate);
    await _prefs.setBool(_soundKey, value.sound);
  }

  List<Outing> _readOutings(String key) =>
      _readMaps(key).map(_outingFrom).toList();

  List<Sighting> _readSightings() => [
    for (final o in _readMaps(_sightingsKey))
      Sighting(
        _outingFrom(o),
        legacyEntryId((o['animal'] as String?) ?? ''),
        hat: o['hat'] as String?,
        order: o['order'] as int?,
      ),
  ];

  List<Map<String, dynamic>> _readMaps(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Outing _outingFrom(Map<String, dynamic> o) => Outing(
    id: o['id'] as String,
    kind: (o['kind'] as String?) ?? _legacyKinds[o['type']] ?? 'Workout',
    start: DateTime.fromMillisecondsSinceEpoch(o['start'] as int),
    distanceKm: (o['km'] as num?)?.toDouble(),
    minutes: o['minutes'] as int,
  );

  Map<String, dynamic> _outingJson(Outing o) => {
    'id': o.id,
    'kind': o.kind,
    'start': o.start.millisecondsSinceEpoch,
    'minutes': o.minutes,
    if (o.distanceKm != null) 'km': o.distanceKm,
  };

  String _write(List<Outing> outings) =>
      jsonEncode([for (final o in outings) _outingJson(o)]);

  String _writeSightings(List<Sighting> sightings) => jsonEncode([
    for (final s in sightings)
      {
        ..._outingJson(s.outing),
        'animal': s.animal,
        if (s.hat != null) 'hat': s.hat,
        if (s.order != null) 'order': s.order,
      },
  ]);
}

extension _Let<T extends Object> on T? {
  R? let<R>(R Function(T) f) {
    final self = this;
    return self == null ? null : f(self);
  }
}
