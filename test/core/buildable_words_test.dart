import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_context.dart';
import 'package:lee_con_leo/activities/syllables/build_word_activity.dart';
import 'package:lee_con_leo/core/content/buildable_words.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/word.dart';

import '../fakes/test_content.dart';

final _telefono = Word(
  text: 'teléfono',
  syllables: const ['te', 'lé', 'fo', 'no'],
  sounds: const ['te', 'le', 'fo', 'no'],
  image: 'words/telefono.svg',
  audio: 'words/telefono.m4a',
);

final _content = ContentBundle(
  words: [_telefono],
  stages: const [
    PathStage(
      stage: 4,
      name: 'lago',
      steps: [
        PathStep(id: 'ta', sounds: ['ta', 'te', 'ti', 'to', 'tu'], activities: []),
        PathStep(id: 'la', sounds: ['la', 'le', 'li', 'lo', 'lu'], activities: []),
        PathStep(id: 'na', sounds: ['na', 'ne', 'ni', 'no', 'nu'], activities: []),
        PathStep(id: 'fa', sounds: ['fa', 'fe', 'fi', 'fo', 'fu'], activities: []),
      ],
    ),
  ],
  prompts: testPrompts,
);

void main() {
  test('a word with a written accent is built once its syllables are known', () {
    expect(BuildableWords.of(_content, _content.stepById('fa')!), [_telefono]);
    expect(BuildableWords.of(_content, _content.stepById('na')!), isEmpty);
    expect(BuildableWords.of(_content, _content.stepById('la')!), isEmpty);
  });

  test('tiles keep the accent as written and never repeat one of the word syllables', () {
    final items = const BuildWordActivity()
        .buildItems(
          ActivityContext(content: _content, step: _content.stepById('fa')!, random: Random(1)),
        )
        .cast<BuildWordItem>();

    for (final item in items) {
      expect(item.syllables, ['te', 'lé', 'fo', 'no']);
      expect(item.options, containsAll(['te', 'lé', 'fo', 'no']));
      expect(item.options.where((tile) => tile == 'fo'), hasLength(1));
      expect(item.optionNames['lé']!.clip, 'sounds/syllable.le.m4a');
    }
  });
}
