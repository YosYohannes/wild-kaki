import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildkaki/animals/animals.dart';
import 'package:wildkaki/animals/rules.dart';
import 'package:wildkaki/data/controller.dart';
import 'package:wildkaki/data/health_sync.dart';
import 'package:wildkaki/data/model.dart';
import 'package:wildkaki/data/store.dart';

final t0 = DateTime(2026, 10, 1, 12);

Outing outing(
  String id,
  int hoursAfter, {
  String kind = 'Run',
  double? km = 5,
}) => Outing(
  id: id,
  kind: kind,
  start: t0.add(Duration(hours: hoursAfter)),
  distanceKm: km,
  minutes: 30,
);

class FakeSource implements OutingSource {
  SourceStatus sourceStatus = SourceStatus.available;
  bool access = true;
  bool grantOnRequest = true;
  bool fail = false;
  List<Outing> outings = [];
  int requests = 0;
  int settingsOpened = 0;
  DateTime? lastSince;
  DateTime? fakeRunStart;

  @override
  Future<SourceStatus> status() async => sourceStatus;

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<bool> requestAccess() async {
    requests++;
    access = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<List<Outing>> outingsSince(DateTime since) async {
    lastSince = since;
    if (fail) throw StateError('boom');
    return outings;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<DateTime> writeFakeRun() async {
    final start = fakeRunStart;
    if (start == null) throw StateError('denied');
    return start;
  }

  @override
  Future<DateTime> writeFakeSleep() async {
    final start = fakeRunStart;
    if (start == null) throw StateError('denied');
    return start;
  }
}

Future<WildStore> newStore({
  bool systemAnimate = true,
  DateTime? now,
  DateTime Function()? clock,
  Map<String, Object> initial = const {},
}) async {
  SharedPreferences.setMockInitialValues(initial);
  return WildStore.open(
    systemAnimate: systemAnimate,
    clock: clock ?? () => now ?? t0,
  );
}

const runType = 56;
const walkType = 79;
const hikeType = 37;
const bikeType = 8;

Map<Object?, Object?> session(
  int exerciseType, {
  double? meters,
  String id = 'w1',
}) => {
  'id': id,
  'exerciseType': exerciseType,
  'startMillis': t0.millisecondsSinceEpoch,
  'endMillis': t0.add(const Duration(minutes: 40)).millisecondsSinceEpoch,
  'distanceMeters': meters,
};

void main() {
  group('WildStore', () {
    test('first launch writes a baseline and keeps it', () async {
      final store = await newStore();
      expect(store.baseline, t0);
      final again = WildStore(
        await SharedPreferences.getInstance(),
        systemAnimate: true,
        clock: () => t0.add(const Duration(days: 3)),
      );
      expect(again.baseline, t0);
    });

    test('empty home and default prefs', () async {
      final store = await newStore(systemAnimate: false);
      final home = store.home();
      expect(home.waiting, isEmpty);
      expect(home.sightings, isEmpty);
      expect(home.opened, isEmpty);
      expect(home.lastSynced, isNull);
      final prefs = store.prefsState();
      expect(prefs.miles, isFalse);
      expect(prefs.animate, isFalse);
    });

    test('prefs round trip and override the system animate default', () async {
      final store = await newStore(systemAnimate: false);
      await store.savePrefs(const Prefs(miles: true, animate: true));
      final reread = WildStore(
        await SharedPreferences.getInstance(),
        systemAnimate: false,
      );
      final prefs = reread.prefsState();
      expect(prefs.miles, isTrue);
      expect(prefs.animate, isTrue);
    });

    test(
      'outings survive a round trip, including a missing distance',
      () async {
        final store = await newStore();
        final a = outing('a', 1, km: 4.25);
        final b = outing('b', 2, kind: 'Climb', km: null);
        await store.addWaiting([a, b]);
        final reread = WildStore(
          await SharedPreferences.getInstance(),
          systemAnimate: true,
        );
        final waiting = reread.home().waiting;
        expect(waiting.map((o) => o.id), ['a', 'b']);
        expect(waiting[0].distanceKm, 4.25);
        expect(waiting[0].kind, 'Run');
        expect(waiting[0].start, a.start);
        expect(waiting[0].minutes, 30);
        expect(waiting[1].distanceKm, isNull);
        expect(waiting[1].kind, 'Climb');
      },
    );

    test('older stored outings with a type field keep their kind', () async {
      final store = await newStore(
        initial: {
          'waiting':
              '[{"id":"r","type":"run","start":1,"minutes":30,"km":5.0},'
              '{"id":"w","type":"walk","start":2,"minutes":30},'
              '{"id":"c","type":"climb","start":3,"minutes":30}]',
          'sightings': '[{"id":"n","kind":"Swim","start":4,"minutes":30}]',
          'counted': ['run'],
        },
      );
      final home = store.home();
      expect(home.waiting.map((o) => o.kind), ['Run', 'Walk', 'Climb']);
      expect(home.sightings.single.outing.kind, 'Swim');
      expect(store.prefsState().miles, isFalse);
    });

    test('legacy sightings become foxes and legacy opened is migrated', () async {
      final store = await newStore(
        initial: {
          'sightings':
              '[{"id":"n","kind":"Swim","start":4,"minutes":30},'
              '{"id":"m","kind":"Run","start":5,"minutes":30,"animal":"duck"}]',
          'opened': ['Fox'],
        },
      );
      final home = store.home();
      expect(home.sightings.map((s) => s.animal), ['fox', 'duck']);
      expect(home.opened, {'fox'});
    });

    test('the animal id of a sighting survives a round trip', () async {
      final store = await newStore();
      await store.addWaiting([outing('a', 1), outing('b', 2)]);
      await store.reveal(outing('a', 1), 'duck');
      await store.reveal(outing('b', 2), 'fox');
      final reread = WildStore(
        await SharedPreferences.getInstance(),
        systemAnimate: true,
      );
      expect(reread.home().sightings.map((s) => s.animal), ['fox', 'duck']);
    });

    test('kind survives a round trip', () async {
      final store = await newStore();
      await store.addWaiting([
        outing('s', 1, kind: sleepKind, km: null),
        outing('y', 2, kind: 'Yoga', km: null),
      ]);
      final reread = WildStore(
        await SharedPreferences.getInstance(),
        systemAnimate: true,
      );
      expect(reread.home().waiting.map((o) => o.kind), ['Sleep', 'Yoga']);
    });

    test('addWaiting dedupes by id and sorts oldest first', () async {
      final store = await newStore(now: t0.add(const Duration(days: 1)));
      await store.addWaiting([outing('c', 3), outing('a', 1)]);
      final home = await store.addWaiting([
        outing('b', 2),
        outing('a', 1),
        outing('b', 2),
      ]);
      expect(home.waiting.map((o) => o.id), ['a', 'b', 'c']);
      expect(home.lastSynced, t0.add(const Duration(days: 1)));
    });

    test('reveal moves waiting to sightings, newest first, and is not re-added by a later sync', () async {
      final store = await newStore();
      await store.addWaiting([outing('a', 1), outing('b', 2), outing('c', 3)]);
      await store.reveal(outing('a', 1), 'fox');
      final home = await store.reveal(outing('c', 3), 'duck');
      expect(home.waiting.map((o) => o.id), ['b']);
      expect(home.sightings.map((s) => s.outing.id), ['c', 'a']);
      expect(home.sightings.map((s) => s.animal), ['duck', 'fox']);
      final after = await store.addWaiting([
        outing('a', 1),
        outing('c', 3),
        outing('d', 4),
      ]);
      expect(after.waiting.map((o) => o.id), ['b', 'd']);
      expect(after.sightings.length, 2);
    });

    test('markOpened is remembered once per animal', () async {
      final store = await newStore();
      await store.markOpened('fox');
      final home = await store.markOpened('fox');
      expect(home.opened, {'fox'});
    });

    test(
      'startOver clears the collection and moves the baseline to now',
      () async {
        final later = t0.add(const Duration(days: 2));
        final store = await newStore();
        await store.addWaiting([outing('a', 1), outing('b', 2)]);
        await store.reveal(outing('a', 1), 'fox');
        await store.markOpened('fox');
        await store.savePrefs(
          const Prefs(miles: true, animate: false, sound: false),
        );
        final restarted = WildStore(
          await SharedPreferences.getInstance(),
          systemAnimate: true,
          clock: () => later,
        );
        final home = await restarted.startOver();
        expect(home.waiting, isEmpty);
        expect(home.sightings, isEmpty);
        expect(home.opened, isEmpty);
        expect(home.lastSynced, isNull);
        expect(restarted.baseline, later);
        expect(restarted.prefsState().miles, isTrue);
        expect(restarted.prefsState().sound, isFalse);
      },
    );

    test('lowerBaseline only moves the baseline earlier', () async {
      final store = await newStore();
      await store.lowerBaseline(t0.add(const Duration(hours: 1)));
      expect(store.baseline, t0);
      await store.lowerBaseline(t0.subtract(const Duration(hours: 1)));
      expect(store.baseline, t0.subtract(const Duration(hours: 1)));
    });
  });

  group('health mapping', () {
    test('kindForExercise follows the Health Connect table', () {
      const expected = {
        56: 'Run',
        57: 'Run',
        79: 'Walk',
        37: 'Hike',
        8: 'Ride',
        9: 'Ride',
        73: 'Swim',
        74: 'Swim',
        51: 'Climb',
        68: 'Climb',
        69: 'Climb',
        83: 'Yoga',
        48: 'Yoga',
        71: 'Yoga',
        0: 'Workout',
        70: 'Workout',
        64: 'Workout',
        999: 'Workout',
        -1: 'Workout',
      };
      expected.forEach((type, kind) => expect(kindForExercise(type), kind));
    });

    test('arrivalPhrase reads naturally for every kind', () {
      final fox = animalById('fox');
      expect(arrivalPhrase(fox, 'Run'), 'joined your run');
      expect(arrivalPhrase(fox, 'Walk'), 'joined your walk');
      expect(arrivalPhrase(fox, 'Hike'), 'joined your hike');
      expect(arrivalPhrase(fox, 'Ride'), 'joined your ride');
      expect(arrivalPhrase(fox, 'Swim'), 'joined your swim');
      expect(arrivalPhrase(fox, 'Climb'), 'joined your climb');
      expect(arrivalPhrase(fox, 'Workout'), 'joined your workout');
      expect(arrivalPhrase(fox, 'Yoga'), 'joined your yoga session');
      expect(arrivalPhrase(fox, 'Sleep'), 'watched over your sleep');
      expect(
        arrivalPhrase(animalById('duck'), 'Run'),
        'paddled along on your run',
      );
      expect(
        arrivalPhrase(animalById('duck'), 'Sleep'),
        'watched over your sleep',
      );
    });

    test('builds an outing from a native session', () {
      final o = outingFromSession(session(runType, meters: 5000));
      expect(o.id, 'w1');
      expect(o.kind, 'Run');
      expect(o.start, t0);
      expect(o.minutes, 40);
      expect(o.distanceKm, closeTo(5, 1e-9));
    });

    test('accepts integral distances', () {
      final o = outingFromSession({
        ...session(walkType),
        'distanceMeters': 1500,
      });
      expect(o.distanceKm, closeTo(1.5, 1e-9));
    });

    test('leaves the distance empty when none or zero was recorded', () {
      expect(outingFromSession(session(hikeType)).distanceKm, isNull);
      expect(
        outingFromSession(session(hikeType, meters: 0)).distanceKm,
        isNull,
      );
    });

    test('keeps every exercise type, labelled by its kind', () {
      expect(outingFromSession(session(bikeType, meters: 9000)).kind, 'Ride');
      expect(outingFromSession(session(70)).kind, 'Workout');
    });

    test('builds a sleep outing without distance', () {
      final o = outingFromSession({
        'id': 's1',
        'kind': 'sleep',
        'startMillis': t0.millisecondsSinceEpoch,
        'endMillis': t0
            .add(const Duration(hours: 7, minutes: 20))
            .millisecondsSinceEpoch,
      });
      expect(o.id, 's1');
      expect(o.kind, sleepKind);
      expect(o.distanceKm, isNull);
      expect(o.minutes, 440);
      expect(o.end, t0.add(const Duration(hours: 7, minutes: 20)));
      expect(outingMeta(o, miles: false), 'Sleep · 7 h 20 min');
    });

    test('meta shows hours only for sleep', () {
      Outing of(String kind, int minutes, [double? km]) => Outing(
        id: 'x',
        kind: kind,
        start: t0,
        distanceKm: km,
        minutes: minutes,
      );
      expect(outingMeta(of('Sleep', 420), miles: false), 'Sleep · 7 h');
      expect(outingMeta(of('Sleep', 45), miles: false), 'Sleep · 45 min');
      expect(
        outingMeta(of('Run', 90, 3.6), miles: false),
        'Run · 3.6 km · 90 min',
      );
      expect(outingMeta(of('Ride', 30), miles: false), 'Ride · 30 min');
    });
  });

  group('WildController', () {
    late FakeSource source;

    Future<WildController> make({
      Map<String, Object> initial = const {},
      DateTime? now,
      DateTime Function()? clock,
    }) async {
      final store = await newStore(initial: initial, now: now, clock: clock);
      return WildController.create(
        systemAnimate: true,
        source: source,
        store: store,
      );
    }

    setUp(() => source = FakeSource());

    test(
      'refresh adds every kind after the baseline and reports connected',
      () async {
        source.outings = [
          outing('new', 2),
          outing('old', -3),
          outing('walk', 4, kind: 'Walk'),
        ];
        final c = await make();
        expect(c.connected, isTrue);
        await c.refresh();
        expect(source.lastSince, t0);
        expect(c.home.waiting.map((o) => o.id), ['new', 'walk']);
        expect(c.notice, isNull);
        expect(c.refreshing, isFalse);
        expect(c.home.lastSynced, isNotNull);
      },
    );

    test(
      'refresh asks for access when missing and syncs once granted',
      () async {
        source
          ..access = false
          ..outings = [outing('a', 1)];
        final c = await make();
        await c.refresh();
        expect(source.requests, 1);
        expect(c.home.waiting.length, 1);
      },
    );

    test('refresh sets a notice when access is refused', () async {
      source
        ..access = false
        ..grantOnRequest = false
        ..outings = [outing('a', 1)];
      final c = await make();
      await c.refresh();
      expect(c.notice, 'allow Health Connect to find your activities');
      expect(c.home.waiting, isEmpty);
    });

    test('refresh sets a notice when Health Connect fails, and clears it next time', () async {
      source
        ..fail = true
        ..outings = [outing('a', 1)];
      final c = await make();
      await c.refresh();
      expect(c.notice, "couldn't reach Health Connect");
      expect(c.refreshing, isFalse);
      expect(c.home.lastSynced, isNull);
      expect(c.home.waiting, isEmpty);
      source.fail = false;
      await c.refresh();
      expect(c.notice, isNull);
      expect(c.home.waiting.length, 1);
    });

    test(
      'refresh explains an unavailable or outdated Health Connect',
      () async {
        source.sourceStatus = SourceStatus.missing;
        final c = await make();
        expect(c.connected, isFalse);
        await c.refresh();
        expect(c.notice, "Health Connect isn't on this phone");
        source.sourceStatus = SourceStatus.updateRequired;
        await c.refresh();
        expect(c.notice, 'update Health Connect to sync');
      },
    );

    test('syncQuietly syncs only when already permitted', () async {
      source
        ..access = false
        ..outings = [outing('a', 1)];
      final c = await make();
      await c.syncQuietly();
      expect(source.requests, 0);
      expect(c.home.waiting, isEmpty);
      expect(c.notice, isNull);
      source.access = true;
      await c.syncQuietly();
      expect(c.home.waiting.length, 1);
    });

    test('notifies listeners while refreshing', () async {
      final c = await make();
      final seen = <bool>[];
      c.addListener(() => seen.add(c.refreshing));
      await c.refresh();
      expect(seen, [true, false]);
    });

    test('reveal, markOpened and startOver flow through the store', () async {
      source.outings = [outing('a', 1), outing('b', 2)];
      var now = t0;
      final c = await make(clock: () => now);
      await c.refresh();
      await c.reveal(c.home.waiting.first);
      expect(c.home.sightings.single.animal, animalIdFor(outing('a', 1)));
      await c.markOpened('fox');
      expect(c.home.waiting.map((o) => o.id), ['b']);
      expect(c.home.sightings.map((s) => s.outing.id), ['a']);
      expect(c.home.opened, {'fox'});
      now = t0.add(const Duration(days: 1));
      await c.startOver();
      expect(c.home.waiting, isEmpty);
      expect(c.home.sightings, isEmpty);
      expect(c.home.opened, isEmpty);
      await c.refresh();
      expect(c.home.waiting, isEmpty);
    });

    test('updatePrefs persists', () async {
      final c = await make();
      await c.updatePrefs(const Prefs(miles: true, animate: false));
      expect(c.prefs.miles, isTrue);
      final reread = WildStore(
        await SharedPreferences.getInstance(),
        systemAnimate: true,
      );
      expect(reread.prefsState().miles, isTrue);
    });

    test(
      'sleep counts by when it ended, other kinds by when they started',
      () async {
        Outing sleep(String id, int startHours, int minutes) => Outing(
          id: id,
          kind: sleepKind,
          start: t0.add(Duration(hours: startHours)),
          distanceKm: null,
          minutes: minutes,
        );
        source.outings = [
          sleep('last-night', -4, 420),
          sleep('long-gone', -20, 420),
          outing('before', -1),
        ];
        final c = await make();
        await c.refresh();
        expect(c.home.waiting.map((o) => o.id), ['last-night']);
      },
    );

    test('openHealthSettings reaches the source', () async {
      final c = await make();
      await c.openHealthSettings();
      expect(source.settingsOpened, 1);
    });

    test('writeFakeRun lowers the baseline so the run is found', () async {
      final start = t0.subtract(const Duration(hours: 2));
      source.fakeRunStart = start;
      source.outings = [
        Outing(id: 'f', kind: 'Run', start: start, distanceKm: 6, minutes: 40),
      ];
      final c = await make();
      final message = await c.writeFakeRun();
      expect(message, 'wrote a fake run, pull down to find it');
      await c.refresh();
      expect(source.lastSince, start);
      expect(c.home.waiting.map((o) => o.id), ['f']);
    });

    test('writeFakeSleep lowers the baseline so the night is found', () async {
      final start = t0.subtract(const Duration(hours: 8));
      source.fakeRunStart = start;
      source.outings = [
        Outing(
          id: 'z',
          kind: sleepKind,
          start: start,
          distanceKm: null,
          minutes: 420,
        ),
      ];
      final c = await make();
      expect(
        await c.writeFakeSleep(),
        'wrote a fake sleep, pull down to find it',
      );
      await c.refresh();
      expect(c.home.waiting.map((o) => o.id), ['z']);
    });

    test('writeFakeSleep reports a failure as a message', () async {
      final c = await make();
      expect(
        await c.writeFakeSleep(),
        startsWith("couldn't write a fake sleep"),
      );
    });

    test('writeFakeRun reports a failure as a message', () async {
      final c = await make();
      expect(await c.writeFakeRun(), startsWith("couldn't write a fake run"));
    });
  });
}
