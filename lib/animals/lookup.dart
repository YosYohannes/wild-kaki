import 'art_data.dart';
import 'catalog.dart';
import 'catalog_data.dart';
import 'notes_data.dart';

class AnimalEntry {
  const AnimalEntry({
    required this.id,
    required this.name,
    required this.base,
    this.shape,
    this.colour,
    this.legend,
  });

  final String id;
  final String name;
  final Base base;
  final Species? shape;
  final ColourSpecies? colour;
  final Legend? legend;

  bool get isColour => colour != null;

  bool get isLegend => legend != null;

  List<String> get frames => artFrom(entryArt).frames;

  List<HeadPoint> get headPoints => artFrom(entryArt).headPoints;

  List<String> get flyFrames {
    final art = artFrom(entryArt);
    return art.flyFrames.isEmpty ? art.frames : art.flyFrames;
  }

  List<HeadPoint> get flyHeadPoints {
    final art = artFrom(entryArt);
    return art.flyHeadPoints.isEmpty ? art.headPoints : art.flyHeadPoints;
  }

  EntryArt artFrom(Map<String, EntryArt> art) {
    final own = art[id] ?? (isColour ? art[shape!.id] : null);
    return own ?? EntryArt(frames: base.frames, headPoints: base.headPoints);
  }
}

Set<String> spriteNamesUsed(Map<String, EntryArt> art) => {
  for (final a in art.values) ...[...a.frames, ...a.flyFrames],
};

final List<AnimalEntry> animalEntries = [
  for (final base in defaultCatalog.bases) ...[
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
    for (final regional in [false, true])
      for (final legend in defaultCatalog.legends)
        if (legend.baseId == base.id && legend.isRegional == regional)
          AnimalEntry(
            id: legend.id,
            name: legend.name,
            base: base,
            legend: legend,
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

String entryNote(AnimalEntry entry, {Map<String, String> notes = entryNotes}) =>
    notes[entry.id] ??
    'A ${entry.name.toLowerCase()} keeps you company for a while.';
