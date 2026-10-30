import 'dart:convert';

class Rolls {
  const Rolls({
    required this.visitor,
    required this.base,
    required this.species,
    required this.colour,
    required this.hat,
    this.regional = 1,
    this.legend = 1,
  });

  factory Rolls.of(String activityId) => Rolls(
    visitor: roll('visitor', activityId),
    base: roll('base', activityId),
    species: roll('species', activityId),
    colour: roll('colour', activityId),
    hat: roll('hat', activityId),
    regional: roll('regional', activityId),
    legend: roll('legend', activityId),
  );

  final double visitor;
  final double base;
  final double species;
  final double colour;
  final double hat;
  final double regional;
  final double legend;
}

double roll(String salt, String activityId) =>
    _hash(utf8.encode('$salt:$activityId')) / 4294967296;

int _hash(List<int> bytes) {
  var h = 0x811C9DC5;
  for (final byte in bytes) {
    h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  h ^= h >> 16;
  h = (h * 0x85EBCA6B) & 0xFFFFFFFF;
  h ^= h >> 13;
  h = (h * 0xC2B2AE35) & 0xFFFFFFFF;
  return h ^ (h >> 16);
}
