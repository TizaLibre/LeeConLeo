import 'package:material_ui/material_ui.dart';

import '../../app/widgets/leo_avatar.dart';
import '../common/activity_item.dart';
import '../common/item_controller.dart';
import '../common/widgets/choice_button.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import 'direction_activity.dart';

class DirectionView extends StatelessWidget {
  const DirectionView({
    super.key,
    required this.activity,
    required this.item,
    required this.controller,
  });

  static const leoHeight = 140.0;
  static const leoMargin = 16.0;
  static const moveDuration = Duration(milliseconds: 600);
  static const leoBox = Size(
    leoHeight * LeoAvatar.aspectRatio + 2 * leoMargin,
    leoHeight + 2 * leoMargin,
  );

  final DirectionActivity activity;
  final ActivityItem item;
  final ItemController controller;

  bool get _isVertical => activity.axis == Axis.vertical;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            DemoOverlay(
              key: ValueKey('demo-${item.id}'),
              show: controller.showsDemo,
              path: [_targetCenter(size)],
              child: _isVertical ? _stackedArrows() : _sideBySideArrows(),
            ),
            IgnorePointer(
              child: AnimatedAlign(
                alignment: controller.isSolved
                    ? _alignmentAt(_targetCenter(size), size)
                    : _restingAlignment,
                duration: moveDuration,
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(leoMargin),
                  child: LeoAvatar(size: leoHeight, pose: leoPoseFor(controller)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stackedArrows() => Column(
    children: [
      Expanded(child: _arrow(activity.first)),
      SizedBox(height: leoBox.height),
      Expanded(child: _arrow(activity.second)),
    ],
  );

  Widget _sideBySideArrows() => Column(
    children: [
      SizedBox(height: leoBox.height),
      Expanded(
        child: Row(
          children: [
            Expanded(child: _arrow(activity.first)),
            Expanded(child: _arrow(activity.second)),
          ],
        ),
      ),
    ],
  );

  Alignment get _restingAlignment => _isVertical ? Alignment.center : Alignment.topCenter;

  Offset _targetCenter(Size size) {
    final isFirst = item.target == activity.first.value;
    if (_isVertical) {
      final arrowHeight = (size.height - leoBox.height) / 2;
      final y = isFirst ? arrowHeight / 2 : size.height - arrowHeight / 2;
      return Offset(size.width / 2, y);
    }
    final y = leoBox.height + (size.height - leoBox.height) / 2;
    return Offset(size.width * (isFirst ? 0.25 : 0.75), y);
  }

  Alignment _alignmentAt(Offset center, Size size) => Alignment(
    (center.dx - leoBox.width / 2) / (size.width - leoBox.width) * 2 - 1,
    (center.dy - leoBox.height / 2) / (size.height - leoBox.height) * 2 - 1,
  );

  Widget _arrow(Direction direction) => ChoiceButton(
    key: ValueKey('choice-${direction.value}'),
    isHighlighted: controller.isHintActive && item.target == direction.value,
    onPressed: () => controller.answer(direction.value),
    child: Icon(direction.icon),
  );
}
