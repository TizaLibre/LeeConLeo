import 'package:flutter/widgets.dart';

import '../../core/content/activity_ids.dart';
import '../../core/content/syllable_prompt_ids.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import '../letters/trace_activity.dart';
import '../letters/trace_view.dart';

class SyllableTraceActivity implements ActivitySpec {
  const SyllableTraceActivity();

  @override
  String get id => ActivityIds.syllableTrace;

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final sounds = [...context.step.sounds]..shuffle(context.random);
    return [
      for (final (index, sound) in sounds.indexed)
        TraceItem(
          id: '$index-$sound',
          target: sound,
          promptId: SyllablePromptIds.trace(sound),
          strokes: context.content.syllables[sound]!,
        ),
    ];
  }

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      TraceView(item: item as TraceItem, controller: controller);
}
