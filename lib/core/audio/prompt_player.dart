import 'utterance.dart';

abstract interface class PromptPlayer {
  Future<void> say(Utterance utterance, {bool queued = false});

  Future<void> stop();

  void resumeAfterUserGesture();
}
