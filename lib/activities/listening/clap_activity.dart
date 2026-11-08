import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/content/activity_ids.dart';
import '../../core/content/clap_words.dart';
import '../../core/content/listening_prompt_ids.dart';
import '../../core/content/models/prompt_library.dart';
import '../../core/content/models/spoken_line.dart';
import '../../core/content/models/word.dart';
import '../../core/content/sound_position.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import 'clap_view.dart';

class ClapItem extends ActivityItem {
  const ClapItem({
    required super.id,
    required super.target,
    required super.promptId,
    required super.optionNames,
    required super.promptTail,
    required super.demoLines,
    required this.image,
  }) : super(options: const []);

  final String image;

  int get claps => int.parse(target);
}

class ClapActivity implements ActivitySpec {
  const ClapActivity({this.rounds = 4});

  final int rounds;

  @override
  String get id => ActivityIds.clap;

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final random = context.random;
    final words = ClapWords.all(context.content.words);
    List<Word> having(SoundPosition position) => [
      for (final word in words)
        if (context.step.sounds.any(
          (sound) => position.matches(word, sound) && position.isSpelled(word, sound),
        ))
          word,
    ];
    final starting = having(SoundPosition.start);
    final containing = {...starting, ...having(SoundPosition.inside)}.toList();
    final pool = starting.length >= rounds
        ? starting
        : (containing.isNotEmpty ? containing : words);
    if (pool.isEmpty) return const [];
    final byLength = <int, List<Word>>{};
    for (final word in [...pool]..shuffle(random)) {
      (byLength[word.syllables.length] ??= []).add(word);
    }
    final lengths = byLength.keys.toList()..shuffle(random);
    final asked = [
      for (var round = 0; round < rounds; round++)
        _take(byLength[lengths[round % lengths.length]]!, round ~/ lengths.length),
    ];
    return [
      for (final (round, word) in asked.indexed)
        _item(context.content.prompts, round, word, random),
    ];
  }

  static ClapItem _item(PromptLibrary prompts, int round, Word word, Random random) {
    final split = prompts.line(ListeningPromptIds.clapSplit(word.text), random);
    return ClapItem(
      id: '$round-${word.text}',
      target: '${word.syllables.length}',
      promptId: ListeningPromptIds.clapAsk,
      promptTail: SpokenLine(word.text, clip: word.audio),
      optionNames: {'${word.syllables.length}': split},
      demoLines: [
        prompts.line(ListeningPromptIds.clapShow, random),
        split,
        prompts.line(ListeningPromptIds.clapYourTurn, random),
      ],
      image: word.image!,
    );
  }

  static Word _take(List<Word> words, int turn) => words[turn % words.length];

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      ClapView(item: item as ClapItem, controller: controller);
}
