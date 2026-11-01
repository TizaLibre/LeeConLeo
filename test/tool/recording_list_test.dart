import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/models/word.dart';

import '../../tool/src/voice/recording_list.dart';

void main() {
  const bundle = ContentBundle(
    words: [
      Word(
        text: 'abeja',
        syllables: ['a', 'be', 'ja'],
        sounds: ['a', 'be', 'ja'],
        audio: 'words/abeja.m4a',
      ),
      Word(text: 'ojo', syllables: ['o', 'jo'], sounds: ['o', 'jo'], audio: 'words/ojo.m4a'),
      Word(text: 'mano', syllables: ['ma', 'no'], sounds: ['ma', 'no']),
    ],
    stages: [],
    prompts: PromptLibrary(
      {
        'feedback.correct': ['¡Muy bien!', '¡Súper!'],
        'reward': ['¡Terminaste!'],
      },
      clips: {
        'feedback.correct.0': 'prompts/feedback.correct.0.m4a',
        'reward.0': 'prompts/reward.0.m4a',
      },
    ),
  );

  bool recorded(String path) => path == 'words/ojo.m4a';

  test('lists only the phrases and words that have no recording yet', () {
    final list = RecordingList.missing(bundle, hasAudio: recorded);

    expect(list.phrases, [
      {'promptId': 'feedback.correct', 'index': 1, 'text': '¡Súper!'},
    ]);
    expect(list.words, [
      {'name': 'abeja', 'text': 'abeja'},
    ]);
    expect(list.sounds, isEmpty);
  });

  test('redo adds recorded phrases, words and sounds back to the list', () {
    final list = RecordingList.missing(
      bundle,
      hasAudio: recorded,
      redo: {'reward', 'word.ojo', 'syllable.pa', 'vowel.i'},
    );

    expect(list.phrases.map((phrase) => phrase['promptId']), ['feedback.correct', 'reward']);
    expect(list.words.map((word) => word['name']), ['abeja', 'ojo']);
    expect(list.sounds, unorderedEquals(['pa', 'i']));
  });

  test('a step sound with no clip yet is listed to record', () {
    final withSteps = ContentBundle(
      words: const [],
      stages: const [
        PathStage(
          stage: 4,
          name: 'montaña',
          steps: [
            PathStep(id: 'da', sounds: ['da', 'de'], activities: []),
          ],
        ),
      ],
      prompts: const PromptLibrary({}),
    );

    final list = RecordingList.missing(
      withSteps,
      hasAudio: (path) => path == 'sounds/syllable.de.m4a',
    );

    expect(list.sounds, ['da']);
  });

  test('a phrase whose text changed since it was recorded is listed again', () {
    final list = RecordingList.missing(
      bundle,
      hasAudio: recorded,
      recordedTexts: {'feedback.correct.0': '¡Muy bien!', 'reward.0': '¡Lo terminaste!'},
    );

    expect(list.phrases.map((phrase) => phrase['promptId']), ['feedback.correct', 'reward']);
  });

  test('nothing to record gives an empty list', () {
    final complete = RecordingList.missing(
      const ContentBundle(words: [], stages: [], prompts: PromptLibrary({})),
      hasAudio: recorded,
    );
    expect(complete.isEmpty, isTrue);
  });
}
