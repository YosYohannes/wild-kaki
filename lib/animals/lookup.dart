import 'catalog.dart';
import 'catalog_data.dart';

class AnimalEntry {
  const AnimalEntry({
    required this.id,
    required this.name,
    required this.base,
    required this.shape,
    this.colour,
  });

  final String id;
  final String name;
  final Base base;
  final Species shape;
  final ColourSpecies? colour;

  bool get isColour => colour != null;
}

final List<AnimalEntry> animalEntries = [
  for (final base in defaultCatalog.bases)
    for (final shape in defaultCatalog.speciesOf(base.id)) ...[
      AnimalEntry(id: shape.id, name: shape.name, base: base, shape: shape),
      for (final colour in shape.colours)
        AnimalEntry(
          id: colour.id,
          name: colour.name,
          base: base,
          shape: shape,
          colour: colour,
        ),
    ],
];

final Map<String, AnimalEntry> _entriesById = {
  for (final e in animalEntries) e.id: e,
};

const String defaultEntryId = 'red-fox';

AnimalEntry? findEntry(String id) => _entriesById[id];

AnimalEntry entryOrDefault(String id) =>
    _entriesById[id] ?? _entriesById[defaultEntryId]!;

Hat? hatById(String? id) {
  if (id == null) return null;
  for (final hat in defaultCatalog.hats) {
    if (hat.id == id) return hat;
  }
  return null;
}

String legacyEntryId(String stored) => switch (stored) {
  'Fox' || 'fox' => 'red-fox',
  'duck' => 'duck',
  'bird' => 'sparrow',
  _ => _entriesById.containsKey(stored) ? stored : defaultEntryId,
};

String entryNote(AnimalEntry entry) =>
    'A ${entry.name.toLowerCase()} keeps you company for a while.';
