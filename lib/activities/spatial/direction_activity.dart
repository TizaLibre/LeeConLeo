import 'package:material_ui/material_ui.dart';

import '../../core/content/activity_ids.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import 'direction_view.dart';

class Direction {
  const Direction(this.value, this.icon);

  final String value;
  final IconData icon;
}

class DirectionActivity implements ActivitySpec {
  const DirectionActivity({
    required this.id,
    required this.first,
    required this.second,
    required this.axis,
    this.itemCount = 6,
  });

  static const upDown = DirectionActivity(
    id: ActivityIds.upDown,
    first: Direction('up', Icons.arrow_upward_rounded),
    second: Direction('down', Icons.arrow_downward_rounded),
    axis: Axis.vertical,
  );

  static const leftRight = DirectionActivity(
    id: ActivityIds.leftRight,
    first: Direction('left', Icons.arrow_back_rounded),
    second: Direction('right', Icons.arrow_forward_rounded),
    axis: Axis.horizontal,
  );

  @override
  final String id;
  final Direction first;
  final Direction second;
  final Axis axis;
  final int itemCount;

  @override
  List<ActivityItem> buildItems(ActivityContext context) => [
    for (var i = 0; i < itemCount; i++) _item(i, context.random.nextBool() ? first : second),
  ];

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      DirectionView(activity: this, item: item, controller: controller);

  ActivityItem _item(int index, Direction target) => ActivityItem(
    id: '$index-${target.value}',
    target: target.value,
    promptId: '$id.${target.value}',
    options: [first.value, second.value],
  );
}
