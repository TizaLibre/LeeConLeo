import 'prompt_player.dart';
import 'utterance.dart';

class PausablePromptPlayer implements PromptPlayer {
  PausablePromptPlayer(this._player);

  final PromptPlayer _player;
  bool _isPaused = false;

  bool get isPaused => _isPaused;

  Future<void> pause() {
    _isPaused = true;
    return _player.stop();
  }

  void resume() => _isPaused = false;

  @override
  Future<void> say(Utterance utterance, {bool queued = false}) async {
    if (!_isPaused) await _player.say(utterance, queued: queued);
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  void resumeAfterUserGesture() {
    if (!_isPaused) _player.resumeAfterUserGesture();
  }
}
