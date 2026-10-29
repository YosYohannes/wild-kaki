enum Habitat { meadow, river, sky }

class Reaction {
  const Reaction({required this.sound, required this.bubble});

  final String sound;
  final String bubble;
}

class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.note,
    required this.arrival,
    required this.frames,
    required this.habitat,
    required this.reaction,
  });

  final String id;
  final String name;
  final String note;
  final String arrival;
  final List<String> frames;
  final Habitat habitat;
  final Reaction reaction;

  String arrivalFor(String activityWord) =>
      arrival.replaceAll('{activity}', activityWord);
}
