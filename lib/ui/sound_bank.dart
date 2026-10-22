import 'package:audioplayers/audioplayers.dart';

/// Preloaded sound effects. Pools let rapid taps overlap instead of cutting each other off.
class SoundBank {
  SoundBank._();
  static final instance = SoundBank._();

  final _pools = <String, AudioPool>{};

  Future<void> load() async {
    const sounds = {'tap_red': 6, 'tap_blue': 6, 'minus': 3, 'milestone': 2, 'win': 1};
    for (final MapEntry(key: name, value: players) in sounds.entries) {
      try {
        _pools[name] = await AudioPool.createFromAsset(path: 'sounds/$name.wav', maxPlayers: players);
      } catch (_) {
        // A missing or unsupported sound should never break the game.
      }
    }
  }

  void play(String name, {double volume = 1}) => _start(name, volume);

  Future<void> _start(String name, double volume) async {
    try {
      await _pools[name]?.start(volume: volume);
    } catch (_) {}
  }
}
