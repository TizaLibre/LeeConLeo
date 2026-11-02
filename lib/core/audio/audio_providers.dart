import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'asset_clip_speaker.dart';
import 'asset_sound_effects.dart';
import 'clip_prompt_player.dart';
import 'pausable_prompt_player.dart';
import 'prompt_player.dart';
import 'sound_effects.dart';

final pausablePlayerProvider = Provider<PausablePromptPlayer>(
  (ref) => PausablePromptPlayer(ClipPromptPlayer(speaker: AssetClipSpeaker())),
);

final promptPlayerProvider = Provider<PromptPlayer>((ref) => ref.watch(pausablePlayerProvider));

final soundEffectsProvider = Provider<SoundEffects>((ref) => AssetSoundEffects());
