import 'package:lee_con_leo/core/audio/sound_effects.dart';

class RecordingSoundEffects implements SoundEffects {
  final List<String> played = [];

  @override
  void play(String effect) => played.add(effect);
}
