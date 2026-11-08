import 'package:flutter/widgets.dart';

import '../../core/content/activity_ids.dart';
import '../../core/content/models/spoken_line.dart';
import '../../core/content/models/word.dart';
import '../../core/content/writable_words.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import 'write_word_view.dart';

class WriteWordItem extends ActivityItem {
  const WriteWordItem({
    required super.id,
    required super.target,
    required super.promptId,
    required super.optionNames,
    required super.promptTail,
    required super.stepId,
    required this.image,
  }) : super(options: const []);

  final String image;
}

class WriteWordActivity implements ActivitySpec {
  const WriteWordActivity({this.rounds = 5});

  static const askPrompt = 'writing.word.ask';
  static const stepId = 'writing';

  final int rounds;

  @override
  String get id => ActivityIds.writeWord;

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final words = WritableWords.upTo(context.content, context.step);
    if (words.isEmpty) return const [];
    final asked = <Word>[];
    while (asked.length < rounds) {
      asked.addAll([...words]..shuffle(context.random));
    }
    return [
      for (final (round, word) in asked.take(rounds).indexed)
        WriteWordItem(
          id: '$round-${word.text}',
          target: word.text,
          promptId: askPrompt,
          promptTail: SpokenLine(word.text, clip: word.audio),
          optionNames: {word.text: SpokenLine(word.text, clip: word.audio)},
          stepId: stepId,
          image: word.image!,
        ),
    ];
  }

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      WriteWordView(item: item as WriteWordItem, controller: controller);
}
