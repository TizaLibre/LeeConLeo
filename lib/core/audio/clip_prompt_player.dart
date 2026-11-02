import 'dart:async';

import 'package:flutter/foundation.dart';

import 'clip_speaker.dart';
import 'prompt_player.dart';
import 'utterance.dart';

class ClipPromptPlayer implements PromptPlayer {
  ClipPromptPlayer({required ClipSpeaker speaker}) : _speaker = speaker;

  final ClipSpeaker _speaker;
  _Request? _pending;
  Utterance? _blocked;
  bool _isPlaying = false;
  int _stops = 0;

  @override
  Future<void> say(Utterance utterance, {bool queued = false}) {
    if (utterance.isEmpty) return Future.value();
    _blocked = null;
    if (!utterance.hasAllClips) {
      debugPrint('No recorded clip for "${utterance.text}"');
      return Future.value();
    }
    final request = _Request(utterance);
    _pending?.done.complete();
    _pending = request;
    if (_isPlaying && !queued) _cut();
    _playPending();
    return request.done.future;
  }

  @override
  Future<void> stop() async {
    _blocked = null;
    await _cut();
  }

  @override
  void resumeAfterUserGesture() {
    final blocked = _blocked;
    if (blocked != null) say(blocked);
  }

  Future<void> _cut() {
    _stops++;
    return _speaker.stop();
  }

  Future<void> _playPending() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      for (var next = _pending; next != null; next = _pending) {
        _pending = null;
        await _play(next.utterance);
        next.done.complete();
      }
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> _play(Utterance utterance) async {
    final stops = _stops;
    for (final line in utterance.lines) {
      utterance.onLine?.call(line);
      final result = await _speaker.play(line.clip!);
      if (_stops != stops || result == ClipResult.failed) return;
      if (result == ClipResult.blocked) {
        _blocked = utterance;
        return;
      }
    }
  }
}

class _Request {
  _Request(this.utterance);

  final Utterance utterance;
  final done = Completer<void>();
}
