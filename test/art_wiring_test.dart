import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/art_data.dart';
import 'package:wildkaki/animals/lookup.dart';

EntryArt _art(String tag) => EntryArt(
  frames: ['${tag}_1', '${tag}_2'],
  headPoints: const [(x: 1, y: 2), (x: 3, y: 4)],
);

void main() {
  final red = animalEntries.firstWhere((e) => e.isColour);
  final fox = entryOrDefault(red.shape.id);

  test('colour entries are built on a shape species', () {
    expect(red.isColour, isTrue);
    expect(fox.isColour, isFalse);
    expect(red.shape.id, fox.id);
  });

  test('an entry without art falls back to the base stub', () {
    final art = red.artFrom(const {});
    expect(art.frames, red.base.frames);
    expect(art.headPoints, red.base.headPoints);
  });

  test('an entry with its own art uses it', () {
    final map = {red.id: _art('own'), fox.id: _art('shape')};
    expect(red.artFrom(map).frames, ['own_1', 'own_2']);
    expect(fox.artFrom(map).frames, ['shape_1', 'shape_2']);
  });

  test('a colour entry without art uses its shape species art', () {
    final map = {fox.id: _art('shape')};
    final art = red.artFrom(map);
    expect(art.frames, ['shape_1', 'shape_2']);
    expect(art.headPoints, _art('shape').headPoints);
  });

  test('a shape entry never borrows from its colours', () {
    final map = {red.id: _art('own')};
    expect(fox.artFrom(map).frames, fox.base.frames);
  });

  test('every entry resolves to frames and matching head points', () {
    for (final e in animalEntries) {
      expect(e.frames, isNotEmpty, reason: e.id);
      expect(e.headPoints, isNotEmpty, reason: e.id);
    }
  });

  test('sprite names used are the union of all entry frames', () {
    final map = {'a': _art('x'), 'b': _art('y')};
    expect(spriteNamesUsed(map), {'x_1', 'x_2', 'y_1', 'y_2'});
    expect(spriteNamesUsed(const {}), isEmpty);
  });

  test('entryNote falls back to the placeholder', () {
    expect(entryNote(red, notes: const {}), contains(red.name.toLowerCase()));
  });

  test('entryNote prefers the real note', () {
    expect(entryNote(red, notes: {red.id: 'Real note.'}), 'Real note.');
    expect(entryNote(fox, notes: {red.id: 'Real note.'}), isNot('Real note.'));
  });
}
