import 'dart:math';

import '../animals/catalog.dart';
import '../animals/lookup.dart';
import '../animals/rolls.dart';
import '../world/pixel_buffer.dart';
import '../world/world_painter.dart';

const int maxFoxes = 6;

typedef MeadowAnimal = ({String outingId, String entryId, String? hatId});

enum Lane { meadow, river, sky }

Lane laneOf(Base base, String outingId) => switch (base.habitat) {
  Habitat.river => Lane.river,
  Habitat.sky when base.id == 'songbird' && roll('lane', outingId) < 0.5 =>
    Lane.meadow,
  Habitat.sky => Lane.sky,
  Habitat.meadow => Lane.meadow,
};

class Fox {
  Fox(
    this.x,
    this.refFeet,
    this.dir, {
    this.entryId = defaultEntryId,
    this.hatId,
    Random? random,
    Layout? layout,
  }) : feet = (layout ?? Layout.reference).y(refFeet),
       _random = random ?? Random() {
    t = _random.nextDouble() * 3;
    _left = 1 + _random.nextDouble() * 3;
    _speed = 9 + _random.nextDouble() * 4;
  }

  final Random _random;
  final String entryId;
  final String? hatId;
  double x;
  final int refFeet;
  int feet;
  int dir;
  bool walking = true;
  late double t;
  late double _left;
  late final double _speed;

  void step(double dt) {
    _left -= dt;
    if (alarm > 0) alarm -= dt;
    if (walking) {
      x += dir * _speed * (alarm > 0 ? 3.2 : 1) * dt;
      t += dt * (alarm > 0 ? 2 : 1);
      if (x <= -2) {
        x = -2;
        dir = 1;
      }
      if (x >= worldW - 30.0) {
        x = worldW - 30.0;
        dir = -1;
      }
    }
    if (_left <= 0) {
      walking = !walking;
      _left = walking
          ? 1.5 + _random.nextDouble() * 3.5
          : 1 + _random.nextDouble() * 2.5;
      if (walking && _random.nextDouble() < 0.35) dir = -dir;
    }
  }

  double alarm = 0;
  double bubble = 0;

  void startle() {
    alarm = 1.4;
    bubble = 1.4;
    walking = true;
    _left = 1.4;
  }

  void fit(Layout layout) => feet = layout.y(refFeet);

  int get frame => walking ? (t / 0.2).toInt() % 2 : 0;

  bool hit(double px, double py) =>
      px >= x + 1 && px < x + 31 && py >= feet - 17 && py < feet;
}

class Duck {
  Duck(this.refFeet, this._lo, this._hi, this.dir, {Random? random})
    : feet = refFeet,
      _random = random ?? Random() {
    x = _lo + _random.nextDouble() * (_hi - _lo);
    _left = 2 + _random.nextDouble() * 4;
    _speed = 3 + _random.nextDouble() * 2;
  }

  final Random _random;
  final int refFeet;
  int feet;
  final double _lo;
  final double _hi;
  int dir;
  late double x;
  bool moving = true;
  late double _left;
  late final double _speed;
  double alarm = 0;
  double bubble = 0;

  void fit(Layout layout) => feet = layout.y(refFeet);

  bool hit(double px, double py) =>
      px >= x - 2 && px < x + 18 && py >= feet - 14 && py < feet + 2;

  void startle() {
    alarm = 1.4;
    bubble = 1.4;
    moving = true;
  }

  void step(double dt) {
    _left -= dt;
    if (alarm > 0) alarm -= dt;
    if (moving) {
      x += dir * _speed * (alarm > 0 ? 3 : 1) * dt;
      if (x <= _lo) {
        x = _lo;
        dir = 1;
      }
      if (x >= _hi) {
        x = _hi;
        dir = -1;
      }
    }
    if (_left <= 0) {
      moving = !moving;
      _left = 2 + _random.nextDouble() * 4;
      if (moving && _random.nextDouble() < 0.4) dir = -dir;
    }
  }
}

class Bird {
  Bird(this._wait, {Random? random}) : _random = random ?? Random();

  final Random _random;
  double _wait;
  bool active = false;
  double x = 0;
  double y = 0;
  int dir = 1;
  double t = 0;
  double _speed = 18;
  double alarm = 0;
  double bubble = 0;

  bool hit(double px, double py, Layout layout) {
    final top = layout.y(y);
    return active &&
        px >= x + 5 &&
        px < x + 27 &&
        py >= top + 17 &&
        py < top + 34;
  }

  void startle() {
    alarm = 1.5;
    bubble = 1.5;
  }

  void step(double dt, bool day) {
    if (alarm > 0) alarm -= dt;
    if (active) {
      x += dir * _speed * (alarm > 0 ? 2.5 : 1) * dt;
      t += dt;
      if (x < -34 || x > worldW + 2) {
        active = false;
        _wait = 10 + _random.nextDouble() * 14;
      }
    } else {
      _wait -= dt;
      if (_wait <= 0 && day) {
        active = true;
        dir = _random.nextBool() ? 1 : -1;
        x = dir > 0 ? -32 : worldW.toDouble();
        y = -12 + _random.nextDouble() * 80;
        _speed = 16 + _random.nextDouble() * 8;
        t = 0;
      }
    }
  }

  int get frame => (t / 0.14).toInt() % 2;
}

class Swimmer {
  Swimmer(
    this.x,
    this.refFeet,
    this.dir, {
    this.entryId = defaultEntryId,
    this.hatId,
    Random? random,
    Layout? layout,
  }) : feet = (layout ?? Layout.reference).y(refFeet),
       _random = random ?? Random() {
    t = _random.nextDouble() * 3;
    _left = 2 + _random.nextDouble() * 4;
    _speed = 4 + _random.nextDouble() * 3;
  }

  static const int waterline = 7;
  static const double lo = -2;
  static const double hi = worldW - 30.0;

  final Random _random;
  final String entryId;
  final String? hatId;
  double x;
  final int refFeet;
  int feet;
  int dir;
  bool moving = true;
  late double t;
  late double _left;
  late final double _speed;
  double alarm = 0;
  double bubble = 0;

  void fit(Layout layout) => feet = layout.y(refFeet);

  int get frame => moving ? (t / 0.3).toInt() % 2 : 0;

  bool hit(double px, double py) =>
      px >= x + 1 && px < x + 31 && py >= feet - 17 && py < feet - waterline;

  void startle() {
    alarm = 1.4;
    bubble = 1.4;
    moving = true;
    _left = 1.4;
  }

  void step(double dt) {
    _left -= dt;
    if (alarm > 0) alarm -= dt;
    if (moving) {
      x += dir * _speed * (alarm > 0 ? 3 : 1) * dt;
      t += dt * (alarm > 0 ? 2 : 1);
      if (x <= lo) {
        x = lo;
        dir = 1;
      }
      if (x >= hi) {
        x = hi;
        dir = -1;
      }
    }
    if (_left <= 0) {
      moving = !moving;
      _left = 2 + _random.nextDouble() * 4;
      if (moving && _random.nextDouble() < 0.4) dir = -dir;
    }
  }
}

class Flyer {
  Flyer(
    this.x,
    this.refTop,
    this.dir, {
    this.entryId = defaultEntryId,
    this.hatId,
    Random? random,
    Layout? layout,
  }) : top = (layout ?? Layout.reference).y(refTop),
       _random = random ?? Random() {
    t = _random.nextDouble() * 3;
    _phase = _random.nextDouble() * 2 * pi;
    _speed = 12 + _random.nextDouble() * 6;
  }

  static const double lo = -2;
  static const double hi = worldW - 30.0;

  final Random _random;
  final String entryId;
  final String? hatId;
  double x;
  final int refTop;
  int top;
  int dir;
  late double t;
  late final double _phase;
  late final double _speed;
  double alarm = 0;
  double bubble = 0;

  void fit(Layout layout) => top = layout.y(refTop);

  int get bob => (3 * sin(t * 2.2 + _phase)).round();

  int get y => top + bob;

  int get frame => (t / 0.14).toInt() % 2;

  bool hit(double px, double py) =>
      px >= x + 1 && px < x + 31 && py >= y + 14 && py < y + 32;

  void startle() {
    alarm = 1.5;
    bubble = 1.5;
  }

  void step(double dt) {
    if (alarm > 0) alarm -= dt;
    x += dir * _speed * (alarm > 0 ? 3 : 1) * dt;
    t += dt * (alarm > 0 ? 2 : 1);
    if (x <= lo) {
      x = lo;
      dir = 1;
    }
    if (x >= hi) {
      x = hi;
      dir = -1;
    }
  }
}

class BushSpot {
  final String id;
  final int x;
  final int base;
  final int refBase;

  BushSpot.at(this.id, this.x, this.refBase, Layout layout)
    : base = layout.y(refBase);

  BushSpot fit(Layout layout) => BushSpot.at(id, x, refBase, layout);
}

const int maxBushes = 3;
const List<int> _bushSlotX = [52, 73, 94];
const List<int> _bushSlotLane = [130, 129, 131];

BushSpot bushAtSlot(String id, int slot, {Layout? layout}) => BushSpot.at(
  id,
  _bushSlotX[slot],
  _bushSlotLane[slot],
  layout ?? Layout.reference,
);

Map<String, int> assignBushSlots(List<String> ids, Map<String, int> current) {
  final slots = {
    for (final id in ids)
      if (current.containsKey(id)) id: current[id]!,
  };
  for (final id in ids) {
    if (slots.containsKey(id)) continue;
    final free = List.generate(
      maxBushes,
      (i) => i,
    ).where((i) => !slots.containsValue(i));
    if (free.isEmpty) break;
    slots[id] = free.first;
  }
  return slots;
}

class SceneState {
  SceneState(List<MeadowAnimal> animals, {Random? random, Layout? layout})
    : _random = random ?? Random(),
      _layout = layout ?? Layout.reference {
    for (final a in animals.take(maxFoxes)) {
      _add(a);
    }
    ducks = [
      Duck(150, 4, 98, 1, random: _random),
      Duck(163, 6, 96, -1, random: _random),
      Duck(176, 20, 80, 1, random: _random),
    ];
    for (final d in ducks) {
      d.fit(_layout);
    }
    birds = [Bird(2, random: _random), Bird(9, random: _random)];
  }

  final Random _random;
  Layout _layout;
  double clock = 0;
  final List<Fox> foxes = [];
  final List<Swimmer> swimmers = [];
  final List<Flyer> flyers = [];
  late final List<Duck> ducks;
  late final List<Bird> birds;

  int get animalCount => foxes.length + swimmers.length + flyers.length;

  void step(double dt, bool motion, double night) {
    clock += dt;
    for (final f in foxes) {
      if (f.bubble > 0) f.bubble -= dt;
    }
    for (final s in swimmers) {
      if (s.bubble > 0) s.bubble -= dt;
    }
    for (final f in flyers) {
      if (f.bubble > 0) f.bubble -= dt;
    }
    for (final d in ducks) {
      if (d.bubble > 0) d.bubble -= dt;
    }
    for (final b in birds) {
      if (b.bubble > 0) b.bubble -= dt;
    }
    if (!motion) return;
    for (final f in foxes) {
      f.step(dt);
    }
    for (final s in swimmers) {
      s.step(dt);
    }
    for (final f in flyers) {
      f.step(dt);
    }
    for (final d in ducks) {
      d.step(dt);
    }
    for (final b in birds) {
      b.step(dt, night < 0.5);
    }
  }

  void fit(Layout layout) {
    if (layout == _layout) return;
    _layout = layout;
    for (final f in foxes) {
      f.fit(layout);
    }
    for (final s in swimmers) {
      s.fit(layout);
    }
    for (final f in flyers) {
      f.fit(layout);
    }
    for (final d in ducks) {
      d.fit(layout);
    }
  }

  void addAnimal(double x, MeadowAnimal animal) {
    if (animalCount >= maxFoxes) return;
    _add(animal, x: x);
  }

  void _add(MeadowAnimal animal, {double? x}) {
    final lane = laneOf(entryOrDefault(animal.entryId).base, animal.outingId);
    final startX = x ?? _random.nextDouble() * (worldW - 30.0);
    final ref = switch (lane) {
      Lane.meadow => 214 + _random.nextInt(22),
      Lane.river => 148 + _random.nextInt(33),
      Lane.sky => -4 + _random.nextInt(56),
    };
    final dir = x == null ? (_random.nextBool() ? 1 : -1) : (x > 60 ? -1 : 1);
    switch (lane) {
      case Lane.meadow:
        foxes.add(
          Fox(
            startX,
            ref,
            dir,
            entryId: animal.entryId,
            hatId: animal.hatId,
            random: _random,
            layout: _layout,
          ),
        );
      case Lane.river:
        swimmers.add(
          Swimmer(
            startX.clamp(Swimmer.lo, Swimmer.hi),
            ref,
            dir,
            entryId: animal.entryId,
            hatId: animal.hatId,
            random: _random,
            layout: _layout,
          ),
        );
      case Lane.sky:
        flyers.add(
          Flyer(
            startX.clamp(Flyer.lo, Flyer.hi),
            ref,
            dir,
            entryId: animal.entryId,
            hatId: animal.hatId,
            random: _random,
            layout: _layout,
          ),
        );
    }
  }
}
