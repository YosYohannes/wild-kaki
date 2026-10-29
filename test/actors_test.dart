import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/scene/actors.dart';
import 'package:wildkaki/world/pixel_buffer.dart';
import 'package:wildkaki/world/world_painter.dart';

List<MeadowAnimal> _meadow(int n, {String? hat}) => [
  for (var i = 0; i < n; i++) (entryId: 'red-fox', hatId: hat),
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
    scene.addFox(40, _meadow(1).first);
    expect(scene.foxes, hasLength(maxFoxes));

    final small = SceneState(_meadow(2), random: Random(2));
    expect(small.foxes, hasLength(2));
    small.addFox(100, _meadow(1).first);
    expect(small.foxes, hasLength(3));
    expect(small.foxes.last.dir, -1);
    for (var i = 0; i < 10; i++) {
      small.addFox(10, _meadow(1).first);
    }
    expect(small.foxes, hasLength(maxFoxes));
    for (final f in small.foxes) {
      expect(f.feet, inInclusiveRange(214, 235));
    }
  });

  test('meadow animals keep their entry and hat', () {
    final scene = SceneState([
      (entryId: 'duck', hatId: 'beanie'),
      (entryId: 'red-fox', hatId: null),
    ], random: Random(2));
    expect(scene.foxes.map((f) => f.entryId), ['duck', 'red-fox']);
    expect(scene.foxes.map((f) => f.hatId), ['beanie', null]);
    scene.addFox(40, (entryId: 'sparrow', hatId: 'top-hat'));
    expect(scene.foxes.last.entryId, 'sparrow');
    expect(scene.foxes.last.hatId, 'top-hat');
  });

  test('foxes and ducks follow the layout when the scene resizes', () {
    final scene = SceneState(_meadow(4), random: Random(2));
    final lanes = [for (final f in scene.foxes) f.refFeet];
    final short = Layout.forRows(213);
    scene.fit(short);
    scene.addFox(40, _meadow(1).first);
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
}
