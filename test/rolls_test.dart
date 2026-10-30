import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/animals/rolls.dart';

void main() {
  test('rolls are pinned to stable values', () {
    expect(roll('visitor', 'a0'), 2395063716 / 4294967296);
    expect(roll('base', 'a0'), 3749317657 / 4294967296);
    expect(roll('species', 'a0'), 3408029188 / 4294967296);
    expect(roll('colour', 'a0'), 4150832439 / 4294967296);
    expect(roll('hat', 'a0'), 4102195185 / 4294967296);
    final r = Rolls.of('health-connect-id-123');
    expect(r.visitor, 2660710787 / 4294967296);
    expect(r.base, 874088618 / 4294967296);
    expect(r.species, 2702671337 / 4294967296);
    expect(r.colour, 2397816682 / 4294967296);
    expect(r.hat, 3632085317 / 4294967296);
  });

  test('the regional and legend rolls have their own salts', () {
    final r = Rolls.of('a0');
    expect(r.regional, roll('regional', 'a0'));
    expect(r.legend, roll('legend', 'a0'));
    expect({
      r.visitor,
      r.base,
      r.species,
      r.colour,
      r.hat,
      r.regional,
      r.legend,
    }, hasLength(7));
  });

  test('the same id gives the same rolls', () {
    final a = Rolls.of('x');
    final b = Rolls.of('x');
    expect(
      [a.visitor, a.base, a.species, a.colour, a.hat],
      [b.visitor, b.base, b.species, b.colour, b.hat],
    );
  });

  test('every roll is in [0, 1)', () {
    for (var i = 0; i < 5000; i++) {
      final r = Rolls.of('id-$i');
      for (final v in [r.visitor, r.base, r.species, r.colour, r.hat]) {
        expect(v, inInclusiveRange(0, 1));
        expect(v, lessThan(1));
      }
    }
  });

  test('the five rolls of one id are different numbers', () {
    final r = Rolls.of('some-id');
    expect({r.visitor, r.base, r.species, r.colour, r.hat}, hasLength(5));
  });

  test('each roll is uniform and independent of the others', () {
    const n = 20000;
    final buckets = List.filled(10, 0);
    var sameTenth = 0;
    for (var i = 0; i < n; i++) {
      final r = Rolls.of('a$i');
      buckets[(r.base * 10).floor()]++;
      if ((r.visitor * 10).floor() == (r.base * 10).floor()) sameTenth++;
    }
    for (final b in buckets) {
      expect(b / n, closeTo(0.1, 0.012));
    }
    expect(sameTenth / n, closeTo(0.1, 0.012));
  });
}
