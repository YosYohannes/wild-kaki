import 'dart:math';

import '../animals/catalog.dart';
import '../animals/lookup.dart';
import '../animals/rolls.dart';
import '../world/pixel_buffer.dart';
import '../world/world_painter.dart';

const int maxFoxes = 6;

const int meadowFeetRef = 214;
const int meadowFeetSpan = 22;
const int riverFeetRef = 148;
const int riverFeetSpan = 33;
const int skyTopRef = -4;
const int skyTopSpan = 56;

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
    this.climbFrom,
  }) : top = (layout ?? Layout.reference).y(refTop),
       _random = random ?? Random() {
    t = _random.nextDouble() * 3;
    _phase = _random.nextDouble() * 2 * pi;
    _speed = 12 + _random.nextDouble() * 6;
  }

  static const double lo = -2;
  static const double hi = worldW - 30.0;
  static const double riseSeconds = 1.2;

  final Random _random;
  final String entryId;
  final String? hatId;
  double x;
  final int refTop;
  int top;
  int? climbFrom;
  double _rise = 0;
  int dir;
  late double t;
  late final double _phase;
  late final double _speed;
  double alarm = 0;
  double bubble = 0;

  void fit(Layout layout) => top = layout.y(refTop);

  int get bob => (3 * sin(t * 2.2 + _phase)).round();

  bool get rising => climbFrom != null;

  int get y {
    final from = climbFrom;
    if (from == null) return top + bob;
    return (from + (top + bob - from) * _rise).round();
  }

  int get frame => (t / 0.14).toInt() % 2;

  bool hit(double px, double py) =>
      px >= x + 1 && px < x + 31 && py >= y + 8 && py < y + 32;

  void startle() {
    alarm = 1.5;
    bubble = 1.5;
  }

  void step(double dt) {
    if (alarm > 0) alarm -= dt;
    if (climbFrom != null) {
      _rise += dt / riseSeconds;
      if (_rise >= 1) climbFrom = null;
    }
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
  }

  final Random _random;
  Layout _layout;
  double clock = 0;
  final List<Fox> foxes = [];
  final List<Swimmer> swimmers = [];
  final List<Flyer> flyers = [];

  int get animalCount => foxes.length + swimmers.length + flyers.length;

  void step(double dt, bool motion) {
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
  }

  void takeOff(Fox fox) {
    if (!foxes.remove(fox)) return;
    final flyer = Flyer(
      fox.x.clamp(Flyer.lo, Flyer.hi),
      skyTopRef + _random.nextInt(skyTopSpan),
      fox.dir,
      entryId: fox.entryId,
      hatId: fox.hatId,
      random: _random,
      layout: _layout,
      climbFrom: fox.feet - 32,
    );
    flyer.startle();
    flyers.add(flyer);
  }

  void addAnimal(double x, MeadowAnimal animal) {
    if (animalCount >= maxFoxes) return;
    _add(animal, x: x);
  }

  void _add(MeadowAnimal animal, {double? x}) {
    final lane = laneOf(entryOrDefault(animal.entryId).base, animal.outingId);
    final startX = x ?? _random.nextDouble() * (worldW - 30.0);
    final ref = switch (lane) {
      Lane.meadow => meadowFeetRef + _random.nextInt(meadowFeetSpan),
      Lane.river => riverFeetRef + _random.nextInt(riverFeetSpan),
      Lane.sky => skyTopRef + _random.nextInt(skyTopSpan),
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
