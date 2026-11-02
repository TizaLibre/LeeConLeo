import 'letter_shape.dart';
import 'path_stage.dart';
import 'path_step.dart';
import 'prompt_library.dart';
import 'word.dart';

class ContentBundle {
  const ContentBundle({
    required this.words,
    required this.stages,
    required this.prompts,
    this.letters = const {},
    this.syllables = const {},
  });

  factory ContentBundle.fromJson(Map<String, dynamic> json) => ContentBundle(
    words: [for (final word in json['words'] as List) Word.fromJson(word as Map<String, dynamic>)],
    stages: [
      for (final stage in json['stages'] as List) PathStage.fromJson(stage as Map<String, dynamic>),
    ],
    prompts: PromptLibrary.fromJson(
      json['prompts'] as Map<String, dynamic>,
      clips: (json['promptClips'] as Map<String, dynamic>? ?? const {}).cast<String, String>(),
      beats: PromptLibrary.beatsFromJson(json['promptBeats'] as Map<String, dynamic>?),
    ),
    letters: {
      for (final MapEntry(key: grapheme, value: shape)
          in (json['letters'] as Map<String, dynamic>? ?? const {}).entries)
        grapheme: LetterShape.fromJson(shape as Map<String, dynamic>),
    },
    syllables: {
      for (final MapEntry(key: syllable, value: strokes)
          in (json['syllables'] as Map<String, dynamic>? ?? const {}).entries)
        syllable: LetterShape.parseStrokes(strokes),
    },
  );

  final List<Word> words;
  final List<PathStage> stages;
  final PromptLibrary prompts;
  final Map<String, LetterShape> letters;
  final Map<String, List<Stroke>> syllables;

  Iterable<PathStep> get steps => stages.expand((stage) => stage.steps);

  Word? wordByText(String text) {
    for (final word in words) {
      if (word.text == text) return word;
    }
    return null;
  }

  PathStep? stepById(String id) {
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  PathStage? stageOf(String stepId) {
    for (final stage in stages) {
      if (stage.steps.any((step) => step.id == stepId)) return stage;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'words': [for (final word in words) word.toJson()],
    'stages': [for (final stage in stages) stage.toJson()],
    'prompts': prompts.toJson(),
    if (prompts.clips.isNotEmpty) 'promptClips': prompts.clips,
    if (prompts.beats.isNotEmpty) 'promptBeats': prompts.beats,
    if (letters.isNotEmpty)
      'letters': {
        for (final MapEntry(key: grapheme, value: shape) in letters.entries)
          grapheme: shape.toJson(),
      },
    if (syllables.isNotEmpty)
      'syllables': {
        for (final MapEntry(key: syllable, value: strokes) in syllables.entries)
          syllable: LetterShape.encodeStrokes(strokes),
      },
  };
}
