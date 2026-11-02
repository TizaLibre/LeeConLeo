import 'package:flutter/widgets.dart';

import '../../core/content/activity_ids.dart';
import '../../core/progress/review.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';

class ReviewItem extends ActivityItem {
  ReviewItem({
    required super.id,
    required this.inner,
    required this.spec,
    required String super.stepId,
  }) : super(
         target: inner.target,
         promptId: inner.promptId,
         options: inner.options,
         optionNames: inner.optionNames,
         activityId: spec.id,
       );

  final ActivityItem inner;
  final ActivitySpec spec;
}

class ReviewActivity implements ActivitySpec {
  const ReviewActivity(this.specs);

  static const slowActivities = {ActivityIds.trace, ActivityIds.syllableTrace};

  final List<ActivitySpec> specs;

  @override
  String get id => ActivityIds.review;

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final random = context.random;
    final items = <ActivityItem>[];
    final steps = Review.pickSteps(
      context.events.where((event) => context.content.stepById(event.stepId) != null).toList(),
      random,
      except: context.step.id,
    );
    for (final (round, stepId) in steps.indexed) {
      final step = context.content.stepById(stepId);
      if (step == null) continue;
      final games =
          specs
              .where(
                (spec) => step.activities.contains(spec.id) && !slowActivities.contains(spec.id),
              )
              .toList()
            ..shuffle(random);
      for (final spec in games) {
        final candidates = spec
            .buildItems(ActivityContext(content: context.content, step: step, random: random))
            .where((item) => item.options.length > 1)
            .toList();
        if (candidates.isEmpty) continue;
        final inner = candidates[random.nextInt(candidates.length)];
        items.add(
          ReviewItem(id: '$round-$stepId-${inner.id}', inner: inner, spec: spec, stepId: stepId),
        );
        break;
      }
    }
    return items;
  }

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) {
    final review = item as ReviewItem;
    return KeyedSubtree(
      key: ValueKey(review.id),
      child: review.spec.buildItemView(review.inner, controller),
    );
  }
}
