import 'package:flutter/widgets.dart';

import '../../core/content/activity_ids.dart';
import '../../core/content/letter_prompt_ids.dart';
import '../../core/content/models/letter_shape.dart';
import '../../core/content/models/spoken_line.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import 'meet_view.dart';

class MeetItem extends ActivityItem {
  const MeetItem({
    required super.id,
    required super.target,
    required super.promptId,
    required super.options,
    required this.grapheme,
    super.extraLines,
    this.image,
    this.caseLines = const {},
  });

  final String grapheme;
  final String? image;
  final Map<LetterCase, SpokenLine> caseLines;

  bool get isIntroduction => target == MeetActivity.bothCases;
}

class MeetActivity implements ActivitySpec {
  const MeetActivity();

  static const bothCases = 'letter';

  @override
  String get id => ActivityIds.meet;

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final grapheme = context.step.grapheme!;
    final word = context.step.word;
    final caseLines = {
      for (final letterCase in LetterCase.values)
        letterCase: context.content.prompts.line(
          LetterPromptIds.meetShow(grapheme, letterCase),
          context.random,
        ),
    };
    final cases = [...LetterCase.values]..shuffle(context.random);
    return [
      MeetItem(
        id: '0-$bothCases',
        target: bothCases,
        promptId: LetterPromptIds.meet(grapheme),
        options: [for (final letterCase in LetterCase.values.reversed) letterCase.name],
        extraLines: [caseLines[LetterCase.upper]!, caseLines[LetterCase.lower]!],
        caseLines: caseLines,
        grapheme: grapheme,
        image: word == null ? null : context.content.wordByText(word)?.image,
      ),
      for (final (index, letterCase) in cases.indexed)
        MeetItem(
          id: '${index + 1}-${letterCase.name}',
          target: letterCase.name,
          promptId: LetterPromptIds.meetCase(grapheme, letterCase),
          options: [
            for (final option in [...LetterCase.values]..shuffle(context.random)) option.name,
          ],
          grapheme: grapheme,
        ),
    ];
  }

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      MeetView(item: item as MeetItem, controller: controller);
}
