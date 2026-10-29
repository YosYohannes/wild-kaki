import 'dart:math';

import 'package:flutter/services.dart';
import 'package:health/health.dart';

import 'model.dart';

enum SourceStatus { available, updateRequired, missing }

abstract class OutingSource {
  Future<SourceStatus> status();
  Future<bool> hasAccess();
  Future<bool> requestAccess();
  Future<List<Outing>> outingsSince(DateTime since);
  Future<void> openSettings();
  Future<DateTime> writeFakeRun();
  Future<DateTime> writeFakeSleep();
}

Outing outingFromSession(Map<Object?, Object?> session) {
  final start = DateTime.fromMillisecondsSinceEpoch(
    (session['startMillis'] as num).toInt(),
  );
  final end = DateTime.fromMillisecondsSinceEpoch(
    (session['endMillis'] as num).toInt(),
  );
  final meters = session['distanceMeters'] as num?;
  final sleep = session['kind'] == 'sleep';
  return Outing(
    id: session['id'] as String,
    kind: sleep ? sleepKind : kindForExercise(session['exerciseType'] as int),
    start: start,
    distanceKm: meters != null && meters > 0 ? meters / 1000 : null,
    minutes: end.difference(start).inMinutes,
  );
}

class HealthConnectSource implements OutingSource {
  HealthConnectSource({Health? health, Random? random})
    : _health = health ?? Health(),
      _random = random ?? Random();

  static const _types = [
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.SLEEP_SESSION,
  ];
  static const _runTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.DISTANCE_DELTA,
  ];
  static const _sleepTypes = [HealthDataType.SLEEP_SESSION];
  static const _channel = MethodChannel('app.wildkaki/health');

  final Health _health;
  final Random _random;
  bool _configured = false;

  Future<void> _ready() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<SourceStatus> status() async {
    final status = await _health.getHealthConnectSdkStatus();
    return switch (status) {
      HealthConnectSdkStatus.sdkAvailable => SourceStatus.available,
      HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
        SourceStatus.updateRequired,
      _ => SourceStatus.missing,
    };
  }

  @override
  Future<bool> hasAccess() async {
    await _ready();
    return await _health.hasPermissions(_types) ?? false;
  }

  @override
  Future<bool> requestAccess() async {
    await _ready();
    return _health.requestAuthorization(_types);
  }

  @override
  Future<List<Outing>> outingsSince(DateTime since) async {
    final now = DateTime.now();
    if (!since.isBefore(now)) return [];
    final sessions = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'readOutings',
      {'sinceMillis': since.millisecondsSinceEpoch},
    );
    final outings = [
      for (final session in sessions ?? const <Map<Object?, Object?>>[])
        outingFromSession(session),
    ];
    outings.sort((a, b) => b.start.compareTo(a.start));
    return outings;
  }

  @override
  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on MissingPluginException {
      await requestAccess();
    }
  }

  @override
  Future<DateTime> writeFakeRun() async {
    await _ready();
    await _requireWrite(_runTypes);
    final minutes = 25 + _random.nextInt(45);
    final now = DateTime.now();
    final lead = minutes + 5 + _random.nextInt(115);
    final raw = now.subtract(Duration(minutes: lead));
    final start = DateTime(raw.year, raw.month, raw.day, raw.hour, raw.minute);
    final meters = (minutes * 60 * (2.6 + _random.nextDouble() * 0.8)).round();
    final ok = await _health.writeWorkoutData(
      activityType: HealthWorkoutActivityType.RUNNING,
      start: start,
      end: start.add(Duration(minutes: minutes)),
      totalDistance: meters,
      title: 'Fake run',
      recordingMethod: RecordingMethod.manual,
    );
    if (!ok) throw StateError('write failed');
    return start;
  }

  @override
  Future<DateTime> writeFakeSleep() async {
    await _ready();
    await _requireWrite(_sleepTypes);
    final minutes = 400 + _random.nextInt(60);
    final raw = DateTime.now().subtract(const Duration(minutes: 30));
    final end = DateTime(raw.year, raw.month, raw.day, raw.hour, raw.minute);
    final start = end.subtract(Duration(minutes: minutes));
    final ok = await _health.writeHealthData(
      value: 0,
      type: HealthDataType.SLEEP_SESSION,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );
    if (!ok) throw StateError('write failed');
    return start;
  }

  Future<void> _requireWrite(List<HealthDataType> types) async {
    final access = [for (final _ in types) HealthDataAccess.READ_WRITE];
    final granted =
        await _health.hasPermissions(types, permissions: access) ?? false;
    if (!granted &&
        !await _health.requestAuthorization(types, permissions: access)) {
      throw StateError('write permission denied');
    }
  }
}
