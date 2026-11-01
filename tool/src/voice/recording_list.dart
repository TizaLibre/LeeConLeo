import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/sound_clips.dart';

class RecordingList {
  const RecordingList({required this.phrases, required this.words, required this.sounds});

  factory RecordingList.missing(
    ContentBundle bundle, {
    required bool Function(String audioPath) hasAudio,
    Map<String, String> recordedTexts = const {},
    Set<String> redo = const {},
  }) {
    final prompts = bundle.prompts;
    return RecordingList(
      phrases: [
        for (final MapEntry(key: id, value: variants) in prompts.phrases.entries)
          for (final (index, text) in variants.indexed)
            if (redo.contains(id) ||
                !prompts.clips.containsKey(PromptLibrary.clipKey(id, index)) ||
                _changed(recordedTexts[PromptLibrary.clipKey(id, index)], text))
              {'promptId': id, 'index': index, 'text': text},
      ],
      words: [
        for (final word in bundle.words)
          if (word.audio case final audio?)
            if (redo.contains('word.${_name(audio)}') || !hasAudio(audio))
              {'name': _name(audio), 'text': word.text},
      ],
      sounds: {
        for (final id in redo)
          if (id.startsWith(vowelPrefix) || id.startsWith(syllablePrefix)) id.split('.').last,
        for (final step in bundle.steps)
          for (final sound in step.sounds)
            if (!hasAudio(SoundClips.of(sound))) sound,
      }.toList(),
    );
  }

  static bool _changed(String? recorded, String text) => recorded != null && recorded != text;

  static const vowelPrefix = 'vowel.';
  static const syllablePrefix = 'syllable.';

  final List<Map<String, Object>> phrases;
  final List<Map<String, Object>> words;
  final List<String> sounds;

  bool get isEmpty => phrases.isEmpty && words.isEmpty && sounds.isEmpty;

  Map<String, dynamic> toJson() => {'phrases': phrases, 'words': words, 'sounds': sounds};

  static String _name(String audioPath) {
    final file = audioPath.split('/').last;
    return file.substring(0, file.lastIndexOf('.'));
  }
}
