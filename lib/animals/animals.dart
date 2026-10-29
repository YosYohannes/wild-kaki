import 'animal.dart';

const List<Animal> animals = [
  Animal(
    id: 'fox',
    name: 'Fox',
    note: 'A fox keeps you company for a stretch, then wanders off.',
    arrival: 'joined your {activity}',
    frames: ['fox_walk_1', 'fox_walk_2'],
    habitat: Habitat.meadow,
    reaction: Reaction(sound: 'yip', bubble: 'yip!'),
  ),
  Animal(
    id: 'duck',
    name: 'Duck',
    note: 'A duck paddles along beside you, never in a hurry.',
    arrival: 'paddled along on your {activity}',
    frames: ['duck'],
    habitat: Habitat.river,
    reaction: Reaction(sound: 'quack', bubble: 'quack!'),
  ),
  Animal(
    id: 'bird',
    name: 'Bird',
    note: 'A bird crosses the sky above you and is gone.',
    arrival: 'flew over your {activity}',
    frames: ['bird_1', 'bird_2'],
    habitat: Habitat.sky,
    reaction: Reaction(sound: 'tweet', bubble: 'tweet!'),
  ),
];

Animal animalById(String id) =>
    animals.firstWhere((a) => a.id == id, orElse: () => animals.first);
