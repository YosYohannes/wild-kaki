import '../data/model.dart';

class Rule {
  const Rule({
    required this.id,
    required this.description,
    required this.matches,
    required this.animals,
  });

  final String id;
  final String description;
  final bool Function(Outing activity) matches;
  final List<String> animals;
}

final List<Rule> rules = [
  Rule(
    id: 'any-activity',
    description: 'Every activity brings a fox.',
    matches: (_) => true,
    animals: const ['fox'],
  ),
];

int _stableHash(String text) {
  var h = 0x811C9DC5;
  for (final unit in text.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

String animalIdFor(Outing activity, {List<Rule>? using}) {
  final rule = (using ?? rules).firstWhere((r) => r.matches(activity));
  return rule.animals[_stableHash(activity.id) % rule.animals.length];
}
