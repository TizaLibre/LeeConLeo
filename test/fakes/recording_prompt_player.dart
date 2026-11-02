import 'package:lee_con_leo/core/audio/prompt_player.dart';
import 'package:lee_con_leo/core/audio/utterance.dart';

class RecordingPromptPlayer implements PromptPlayer {
  static const stopCall = '<stop>';

  final List<String> spoken = [];
  final List<Utterance> utterances = [];
  final List<String> calls = [];

  @override
  Future<void> say(Utterance utterance, {bool queued = false}) async {
    spoken.add(utterance.text);
    utterances.add(utterance);
    calls.add(utterance.text);
  }

  @override
  Future<void> stop() async => calls.add(stopCall);

  @override
  void resumeAfterUserGesture() {}
}
