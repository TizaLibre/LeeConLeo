import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'asset_clip_speaker.dart';
import 'sound_effects.dart';

class AssetSoundEffects implements SoundEffects {
  AssetSoundEffects({this.voices = 3});

  final int voices;
  final List<AudioPlayer> _players = [];
  int _next = 0;

  @override
  void play(String effect) {
    if (_players.length < voices) _players.add(AudioPlayer());
    final player = _players[_next % _players.length];
    _next = (_next + 1) % voices;
    player
        .play(AssetSource('${AssetClipSpeaker.assetFolder}/$effect'))
        .catchError((Object error) => debugPrint('Sound effect failed: $effect ($error)'));
  }
}
