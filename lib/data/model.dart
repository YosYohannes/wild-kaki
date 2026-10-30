import '../animals/catalog.dart' show Base;

const sleepKind = 'Sleep';

String kindForExercise(int exerciseType) => switch (exerciseType) {
  56 || 57 => 'Run',
  79 => 'Walk',
  37 => 'Hike',
  8 || 9 => 'Ride',
  73 || 74 => 'Swim',
  51 || 68 || 69 => 'Climb',
  48 || 71 || 83 => 'Yoga',
  _ => 'Workout',
};

String activityWord(String kind) =>
    kind == 'Yoga' ? 'yoga session' : kind.toLowerCase();

String arrivalLine(Base base, String kind) => kind == sleepKind
    ? 'watched over your sleep'
    : base.arrivalFor(activityWord(kind));

class Outing {
  const Outing({
    required this.id,
    required this.kind,
    required this.start,
    required this.distanceKm,
    required this.minutes,
  });

  final String id;
  final String kind;
  final DateTime start;
  final double? distanceKm;
  final int minutes;

  DateTime get end => start.add(Duration(minutes: minutes));
}

class Sighting {
  const Sighting(this.outing, this.animal, {this.hat, this.order});

  final Outing outing;
  final String animal;
  final String? hat;
  final int? order;
}

class HomeState {
  const HomeState({
    required this.waiting,
    required this.sightings,
    required this.opened,
    required this.lastSynced,
  });

  final List<Outing> waiting;
  final List<Sighting> sightings;
  final Set<String> opened;
  final DateTime? lastSynced;
}

class Prefs {
  const Prefs({
    required this.miles,
    required this.animate,
    this.sound = true,
    this.checkUpdates = true,
  });

  final bool miles;
  final bool animate;
  final bool sound;
  final bool checkUpdates;

  Prefs copyWith({
    bool? miles,
    bool? animate,
    bool? sound,
    bool? checkUpdates,
  }) => Prefs(
    miles: miles ?? this.miles,
    animate: animate ?? this.animate,
    sound: sound ?? this.sound,
    checkUpdates: checkUpdates ?? this.checkUpdates,
  );
}

String _duration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final rest = minutes % 60;
  return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
}

String outingMeta(Outing outing, {required bool miles}) {
  final parts = <String>[outing.kind];
  final km = outing.distanceKm;
  if (km != null) {
    parts.add(
      miles
          ? '${(km * 0.621371).toStringAsFixed(1)} mi'
          : '${km.toStringAsFixed(1)} km',
    );
  }
  parts.add(
    outing.kind == sleepKind
        ? _duration(outing.minutes)
        : '${outing.minutes} min',
  );
  return parts.join(' · ');
}
