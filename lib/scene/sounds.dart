import 'package:audioplayers/audioplayers.dart';

class SceneSounds {
  final Map<String, AudioPlayer> _players = {};

  Future<void> play(String name) async {
    try {
      final player = _players.putIfAbsent(name, () {
        final p = AudioPlayer();
        p.setReleaseMode(ReleaseMode.stop);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'));
    } catch (_) {}
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
  }
}
