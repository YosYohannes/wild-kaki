import 'habitat.dart';
import 'bands.dart';

export 'habitat.dart';

enum Affinity {
  avoids(0.25),
  neutral(1),
  likes(2),
  loves(4);

  const Affinity(this.weight);

  final double weight;
}

typedef HeadPoint = ({int x, int y});

class Base {
  const Base({
    required this.id,
    required this.name,
    required this.homeKinds,
    required this.habitat,
    required this.sound,
    required this.bubble,
    required this.arrival,
    required this.frames,
    required this.headPoints,
  });

  final String id;
  final String name;
  final Set<String> homeKinds;
  final Habitat habitat;
  final String sound;
  final String bubble;
  final String arrival;
  final List<String> frames;
  final List<HeadPoint> headPoints;

  String arrivalFor(String activityWord) =>
      arrival.replaceAll('{activity}', activityWord);
}

class Species {
  const Species({
    required this.id,
    required this.name,
    required this.baseId,
    this.affinities = const {},
    this.alsoHomeKinds = const {},
    this.colours = const [],
  });

  final String id;
  final String name;
  final String baseId;
  final Map<Band, Affinity> affinities;
  final Set<String> alsoHomeKinds;
  final List<ColourSpecies> colours;

  Affinity affinityFor(Band band) => affinities[band] ?? Affinity.neutral;
}

class ColourSpecies {
  const ColourSpecies({
    required this.id,
    required this.name,
    required this.shapeSpeciesId,
    required this.chance,
  });

  final String id;
  final String name;
  final String shapeSpeciesId;
  final double chance;
}

class Hat {
  const Hat({required this.id, required this.name, required this.sprite});

  final String id;
  final String name;
  final String sprite;
}

class Catalog {
  Catalog({required this.bases, required this.species, required this.hats})
    : _speciesById = {for (final s in species) s.id: s},
      _baseById = {for (final b in bases) b.id: b};

  final List<Base> bases;
  final List<Species> species;
  final List<Hat> hats;
  final Map<String, Species> _speciesById;
  final Map<String, Base> _baseById;

  List<ColourSpecies> get colourSpecies => [
    for (final s in species) ...s.colours,
  ];

  Base? baseById(String id) => _baseById[id];

  Species? speciesById(String id) => _speciesById[id];

  List<Species> speciesOf(String baseId) => [
    for (final s in species)
      if (s.baseId == baseId) s,
  ];
}
