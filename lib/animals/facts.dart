import '../data/model.dart';
import 'bands.dart';
import 'holidays.dart';

class ActivityFacts {
  const ActivityFacts({
    required this.kind,
    required this.partOfDay,
    required this.lengthBand,
    this.distanceBand,
    this.speedBand,
    required this.dayOff,
  });

  factory ActivityFacts.from(Outing activity, HolidayProvider holidays) {
    final start = activity.start.toLocal();
    final minutes = activity.minutes < 1 ? 1 : activity.minutes;
    final km = activity.distanceKm;
    final hasDistance = km != null && km > 0;
    return ActivityFacts(
      kind: activity.kind,
      partOfDay: partOfDayFor(start.hour),
      lengthBand: lengthBandFor(activity.kind, minutes),
      distanceBand: hasDistance ? distanceBandFor(activity.kind, km) : null,
      speedBand: hasDistance ? speedBandFor(activity.kind, km, minutes) : null,
      dayOff:
          start.weekday == DateTime.saturday ||
          start.weekday == DateTime.sunday ||
          holidays.isPublicHoliday(start),
    );
  }

  final String kind;
  final PartOfDay partOfDay;
  final LengthBand lengthBand;
  final DistanceBand? distanceBand;
  final SpeedBand? speedBand;
  final bool dayOff;

  Iterable<Band> get bands => [
    partOfDay,
    lengthBand,
    ?distanceBand,
    ?speedBand,
  ];
}

PartOfDay partOfDayFor(int hour) {
  if (hour >= 7 && hour < 17) return PartOfDay.day;
  if (hour >= 17 && hour < 21 || hour >= 5 && hour < 7) {
    return PartOfDay.twilight;
  }
  return PartOfDay.night;
}

const _lengthCuts = <String, List<int>>{
  'Run': [15, 30, 60],
  'Walk': [15, 40, 90],
  'Hike': [30, 90, 180],
  'Ride': [20, 45, 120],
  'Swim': [15, 30, 60],
  'Climb': [20, 45, 90],
  'Sleep': [240, 360, 540],
};

const _defaultLengthCuts = [15, 30, 60];

const _distanceCuts = <String, List<double>>{
  'Run': [3, 8, 21],
  'Walk': [2, 5, 12],
  'Hike': [4, 10, 20],
  'Ride': [8, 25, 60],
  'Swim': [0.5, 1.5, 4],
};

const _speedCuts = <String, List<double>>{
  'Run': [8, 12],
  'Walk': [3.5, 5.5],
  'Hike': [2.5, 4.5],
  'Ride': [14, 22],
  'Swim': [1.5, 2.5],
};

LengthBand lengthBandFor(String kind, int minutes) {
  final cuts = _lengthCuts[kind] ?? _defaultLengthCuts;
  if (minutes < cuts[0]) return LengthBand.brief;
  if (minutes < cuts[1]) return LengthBand.short;
  if (minutes < cuts[2]) return LengthBand.medium;
  return LengthBand.long;
}

DistanceBand? distanceBandFor(String kind, double km) {
  final cuts = _distanceCuts[kind];
  if (cuts == null) return null;
  if (km < cuts[0]) return DistanceBand.near;
  if (km < cuts[1]) return DistanceBand.medium;
  if (km < cuts[2]) return DistanceBand.far;
  return DistanceBand.epic;
}

SpeedBand? speedBandFor(String kind, double km, int minutes) {
  final cuts = _speedCuts[kind];
  if (cuts == null || minutes < 5) return null;
  final kmh = km * 60 / minutes;
  if (kmh < cuts[0]) return SpeedBand.slow;
  if (kmh < cuts[1]) return SpeedBand.steady;
  return SpeedBand.fast;
}
