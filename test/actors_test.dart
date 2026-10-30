import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/lookup.dart';
import 'package:wildkaki/scene/actors.dart';
import 'package:wildkaki/world/pixel_buffer.dart';
import 'package:wildkaki/world/world_painter.dart';

const _groundOuting = 'o0';
const _airOuting = 'o1';

List<MeadowAnimal> _meadow(int n, {String? hat}) => [
  for (var i = 0; i < n; i++) (outingId: 'o0', entryId: 'red-fox', hatId: hat),
];

void main() {
  test('bush slots are fixed, evenly spaced and inside the far bank', () {
    final spots = [for (var i = 0; i < maxBushes; i++) bushAtSlot('b$i', i)];
    expect(spots.map((s) => s.x), [52, 73, 94]);
    for (final s in spots) {
      expect(s.x, inInclusiveRange(Layout.bushFrom, Layout.bushTo));
      expect(s.base, inInclusiveRange(129, 131));
    }
    expect(spots[1].x - spots[0].x, greaterThanOrEqualTo(21));
    expect(spots[2].x - spots[1].x, greaterThanOrEqualTo(21));
  });

  test('a waiting activity keeps its slot and a freed slot is reused', () {
    var slots = assignBushSlots(['a', 'b', 'c'], {});
    expect(slots, {'a': 0, 'b': 1, 'c': 2});
    slots = assignBushSlots(['b', 'c', 'd'], slots);
    expect(slots, {'b': 1, 'c': 2, 'd': 0});
    expect(assignBushSlots(['a', 'b', 'c', 'd'], {}).containsKey('d'), isFalse);
  });

  test('fox is clamped to the world and turns around', () {
    final right = Fox(worldW - 31.0, 220, 1, random: Random(3));
    for (var i = 0; i < 200; i++) {
      right.step(0.1);
      expect(right.x, lessThanOrEqualTo(worldW - 30.0));
      expect(right.x, greaterThanOrEqualTo(-2));
    }
    final left = Fox(-1, 220, -1, random: Random(4));
    left.walking = true;
    left.step(1);
    expect(left.x, -2);
    expect(left.dir, 1);
  });

  test('fox hit box', () {
    final fox = Fox(10, 220, 1, random: Random(5));
    expect(fox.hit(11, 203), isTrue);
    expect(fox.hit(10.5, 210), isFalse);
    expect(fox.hit(20, 220), isFalse);
    expect(fox.hit(20, 202.9), isFalse);
    expect(fox.hit(41, 210), isFalse);
  });

  test('duck turns around at both ends', () {
    final duck = Duck(150, 4, 98, 1, random: Random(7));
    duck.x = 97.9;
    duck.dir = 1;
    duck.moving = true;
    duck.step(1);
    expect(duck.x, 98);
    expect(duck.dir, -1);

    duck.x = 4.1;
    duck.dir = -1;
    duck.moving = true;
    duck.step(1);
    expect(duck.x, 4);
    expect(duck.dir, 1);
  });

  test('birds only take off by day', () {
    final birds = [Bird(1, random: Random(1)), Bird(2, random: Random(2))];
    for (var i = 0; i < 100; i++) {
      for (final b in birds) {
        b.step(0.5, false);
      }
    }
    expect(birds.any((b) => b.active), isFalse);
    for (final b in birds) {
      b.step(0.5, true);
    }
    expect(birds.every((b) => b.active), isTrue);
    for (final b in birds) {
      expect(b.dir == 1 ? b.x : b.x - worldW, anyOf(-32, 0));
    }
  });

  test('scene caps foxes at six', () {
    final scene = SceneState(_meadow(10), random: Random(2));
    expect(scene.foxes, hasLength(maxFoxes));
    scene.addAnimal(40, _meadow(1).first);
    expect(scene.foxes, hasLength(maxFoxes));

    final small = SceneState(_meadow(2), random: Random(2));
    expect(small.foxes, hasLength(2));
    small.addAnimal(100, _meadow(1).first);
    expect(small.foxes, hasLength(3));
    expect(small.foxes.last.dir, -1);
    for (var i = 0; i < 10; i++) {
      small.addAnimal(10, _meadow(1).first);
    }
    expect(small.foxes, hasLength(maxFoxes));
    for (final f in small.foxes) {
      expect(f.feet, inInclusiveRange(214, 235));
    }
  });

  test('meadow animals keep their entry and hat', () {
    final scene = SceneState([
      (outingId: 'o0', entryId: 'barn-owl', hatId: 'beanie'),
      (outingId: 'o0', entryId: 'red-fox', hatId: null),
    ], random: Random(2));
    expect(scene.foxes.map((f) => f.entryId), ['barn-owl', 'red-fox']);
    expect(scene.foxes.map((f) => f.hatId), ['beanie', null]);
    scene.addAnimal(40, (
      outingId: _groundOuting,
      entryId: 'sparrow',
      hatId: 'top-hat',
    ));
    expect(scene.foxes.last.entryId, 'sparrow');
    expect(scene.foxes.last.hatId, 'top-hat');
  });

  test('foxes and ducks follow the layout when the scene resizes', () {
    final scene = SceneState(_meadow(4), random: Random(2));
    final lanes = [for (final f in scene.foxes) f.refFeet];
    final short = Layout.forRows(213);
    scene.fit(short);
    scene.addAnimal(40, _meadow(1).first);
    for (final f in scene.foxes) {
      expect(f.feet, short.y(f.refFeet));
      expect(f.feet, lessThan(213));
    }
    expect(scene.ducks.map((d) => d.feet), short.duckFeet);
    scene.fit(Layout.reference);
    expect([for (final f in scene.foxes.take(4)) f.feet], lanes);
  });

  test('bush spots follow the layout', () {
    final short = Layout.forRows(213);
    final spots = [
      bushAtSlot('a', 0, layout: short),
      bushAtSlot('b', 1, layout: short),
    ];
    for (final s in spots) {
      expect(s.base, short.y(s.refBase));
      expect(s.refBase, inInclusiveRange(129, 131));
      expect(s.fit(Layout.reference).base, s.refBase);
    }
  });

  test('scene step advances the clock and only moves actors with motion', () {
    final scene = SceneState(_meadow(1), random: Random(9));
    final x = scene.foxes.first.x;
    scene.step(0.5, false, 0);
    expect(scene.clock, 0.5);
    expect(scene.foxes.first.x, x);
    scene.step(0.5, true, 0);
    expect(scene.clock, 1.0);
    expect(scene.foxes.first.x, isNot(x));
  });

  test('a duck hit box covers its body and startling speeds it up', () {
    final d = Duck(150, 20, 80, 1, random: Random(1))..x = 40;
    expect(d.hit(46, 145), isTrue);
    expect(d.hit(46, 120), isFalse);
    final before = d.x;
    d.step(0.1);
    final calm = d.x - before;
    d
      ..startle()
      ..x = before
      ..moving = true;
    d.step(0.1);
    expect(d.x - before, greaterThan(calm * 2));
    expect(d.bubble, greaterThan(0));
  });

  test('a bird is only hit while flying and startling speeds it up', () {
    final layout = Layout.reference;
    final b = Bird(0, random: Random(2));
    expect(b.hit(50, 40, layout), isFalse);
    b.step(0.1, true);
    expect(b.active, isTrue);
    b
      ..x = 40
      ..y = 30;
    expect(b.hit(50, layout.y(30) + 24, layout), isTrue);
    expect(b.hit(50, layout.y(30) - 5, layout), isFalse);
    final x = b.x;
    b.startle();
    b.step(0.1, true);
    expect((b.x - x).abs(), greaterThan(18 * 0.1 * 2));
  });

  test('bubbles fade even when motion is off', () {
    final scene = SceneState(_meadow(0), random: Random(1));
    scene.ducks.first.startle();
    scene.step(2, false, 0);
    expect(scene.ducks.first.bubble, lessThanOrEqualTo(0));
  });

  test('startling a fox makes it run off faster and show a bubble', () {
    final calm = Fox(40, 220, 1, random: Random(3))..walking = true;
    final scared = Fox(40, 220, 1, random: Random(3))..startle();
    calm.step(0.1);
    scared.step(0.1);
    expect(scared.x - 40, greaterThan((calm.x - 40) * 2));
    expect(scared.bubble, greaterThan(0));
    expect(scared.walking, isTrue);
  });

  test('only river bases swim, bats fly and songbirds do either', () {
    Lane lane(String id, [String outing = _groundOuting]) =>
        laneOf(entryOrDefault(id).base, outing);
    for (final id in ['duck', 'goose', 'otter', 'hamsa', 'kappa', 'nessie']) {
      expect(lane(id), Lane.river, reason: id);
      expect(lane(id, _airOuting), Lane.river, reason: id);
    }
    expect(lane('merlion'), Lane.river);
    for (final id in ['fruit-bat', 'pipistrelle', 'vampire']) {
      expect(lane(id), Lane.sky, reason: id);
      expect(lane(id, _airOuting), Lane.sky, reason: id);
    }
    for (final id in ['barn-owl', 'owl-of-athena', 'red-fox']) {
      expect(lane(id), Lane.meadow, reason: id);
      expect(lane(id, _airOuting), Lane.meadow, reason: id);
    }
    for (final id in ['sparrow', 'garuda']) {
      expect(lane(id, _groundOuting), Lane.meadow, reason: id);
      expect(lane(id, _airOuting), Lane.sky, reason: id);
    }
  });

  test('a songbird keeps its lane for the same outing', () {
    final base = entryOrDefault('sparrow').base;
    for (var i = 0; i < 40; i++) {
      expect(laneOf(base, 'x$i'), laneOf(base, 'x$i'));
    }
    final lanes = {for (var i = 0; i < 40; i++) laneOf(base, 'x$i')};
    expect(lanes, {Lane.meadow, Lane.sky});
  });

  test('sightings are split into lanes and share the cap of six', () {
    final scene = SceneState([
      (outingId: 'o0', entryId: 'duck', hatId: 'beanie'),
      (outingId: 'o0', entryId: 'fruit-bat', hatId: null),
      (outingId: _airOuting, entryId: 'sparrow', hatId: null),
      (outingId: _groundOuting, entryId: 'sparrow', hatId: null),
      (outingId: 'o0', entryId: 'barn-owl', hatId: null),
      (outingId: 'o0', entryId: 'merlion', hatId: null),
      (outingId: 'o0', entryId: 'red-fox', hatId: null),
    ], random: Random(4));
    expect(scene.swimmers.map((s) => s.entryId), ['duck', 'merlion']);
    expect(scene.swimmers.first.hatId, 'beanie');
    expect(scene.flyers.map((f) => f.entryId), ['fruit-bat', 'sparrow']);
    expect(scene.foxes.map((f) => f.entryId), ['sparrow', 'barn-owl']);
    expect(scene.animalCount, maxFoxes);
    scene.addAnimal(40, (outingId: 'o0', entryId: 'otter', hatId: null));
    scene.addAnimal(40, (outingId: 'o0', entryId: 'vampire', hatId: null));
    expect(scene.animalCount, maxFoxes);
    expect(scene.ducks, hasLength(3));
    expect(scene.birds, hasLength(2));
  });

  test('new arrivals go to their lane', () {
    final scene = SceneState(const [], random: Random(6));
    scene.addAnimal(100, (outingId: 'o0', entryId: 'otter', hatId: 'top-hat'));
    scene.addAnimal(40, (outingId: 'o0', entryId: 'pipistrelle', hatId: null));
    scene.addAnimal(40, (
      outingId: _airOuting,
      entryId: 'sparrow',
      hatId: null,
    ));
    scene.addAnimal(40, (
      outingId: _groundOuting,
      entryId: 'sparrow',
      hatId: null,
    ));
    scene.addAnimal(40, (outingId: 'o0', entryId: 'barn-owl', hatId: null));
    expect(scene.swimmers.single.dir, -1);
    expect(scene.swimmers.single.hatId, 'top-hat');
    expect(scene.flyers.map((f) => f.entryId), ['pipistrelle', 'sparrow']);
    expect(scene.flyers.first.dir, 1);
    expect(scene.foxes.map((f) => f.entryId), ['sparrow', 'barn-owl']);
  });

  test('swimmers keep to the river lane and turn at its ends', () {
    final layout = Layout.reference;
    final scene = SceneState([
      for (var i = 0; i < 6; i++)
        (outingId: 'o0', entryId: 'duck', hatId: null),
    ], random: Random(8));
    for (final s in scene.swimmers) {
      expect(s.feet, inInclusiveRange(layout.riverTopY + 12, layout.riverBotY));
      expect(s.feet - Swimmer.waterline, greaterThan(layout.riverTopY + 4));
    }
    final right = Swimmer(worldW - 31.0, 160, 1, random: Random(3));
    for (var i = 0; i < 300; i++) {
      right.step(0.1);
      expect(right.x, lessThanOrEqualTo(worldW - 30.0));
      expect(right.x, greaterThanOrEqualTo(-2));
    }
    final left = Swimmer(-1, 160, -1, random: Random(4))..moving = true;
    left.step(1);
    expect(left.x, -2);
    expect(left.dir, 1);
  });

  test('swimmer frames alternate while moving and its hit box skips water', () {
    final s = Swimmer(40, 160, 1, random: Random(2))
      ..t = 0
      ..moving = true;
    final frames = <int>{};
    for (var i = 0; i < 20; i++) {
      s.step(0.1);
      frames.add(s.frame);
    }
    expect(frames, {0, 1});
    expect(s.hit(s.x + 10, 150), isTrue);
    expect(s.hit(s.x + 10, 160.0 - Swimmer.waterline), isFalse);
    expect(s.hit(s.x + 10, 140), isFalse);
    final before = s.x;
    s.startle();
    s.step(0.1);
    expect(s.x - before, greaterThan(4 * 0.1 * 2));
    expect(s.bubble, greaterThan(0));
  });

  test('flyers bob, turn at the edges and fly off when startled', () {
    final f = Flyer(worldW - 31.0, 20, 1, random: Random(5));
    final tops = <int>{};
    for (var i = 0; i < 300; i++) {
      f.step(0.1);
      tops.add(f.y);
      expect(f.x, inInclusiveRange(-2, worldW - 30.0));
      expect((f.y - f.top).abs(), lessThanOrEqualTo(3));
    }
    expect(tops.length, greaterThan(3));
    expect(f.frame, anyOf(0, 1));
    f
      ..x = 60
      ..dir = 1;
    f.step(0.1);
    final calm = f.x - 60;
    f
      ..x = 60
      ..dir = 1
      ..startle();
    f.step(0.1);
    expect(f.x - 60, greaterThan(calm * 2));
    expect(f.bubble, greaterThan(0));
    expect(f.hit(f.x + 10, f.y + 20), isTrue);
    expect(f.hit(f.x + 10, f.y + 9), isTrue);
    expect(f.hit(f.x + 10, f.y + 5), isFalse);
  });

  test('swimmers and flyers stand still without motion and follow layout', () {
    final scene = SceneState([
      (outingId: 'o0', entryId: 'otter', hatId: null),
      (outingId: 'o0', entryId: 'vampire', hatId: null),
    ], random: Random(9));
    final s = scene.swimmers.single;
    final f = scene.flyers.single;
    final x = [s.x, f.x];
    scene.step(0.5, false, 0);
    expect([s.x, f.x], x);
    scene.step(0.5, true, 0);
    expect(s.x, isNot(x[0]));
    expect(f.x, isNot(x[1]));
    final short = Layout.forRows(213);
    scene.fit(short);
    expect(s.feet, short.y(s.refFeet));
    expect(f.top, short.y(f.refTop));
  });
}
