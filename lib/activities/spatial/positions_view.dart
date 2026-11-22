import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import '../../app/widgets/leo_avatar.dart';
import '../common/activity_item.dart';
import '../common/item_controller.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import 'positions_scene.dart';

class PositionsView extends StatefulWidget {
  const PositionsView({super.key, required this.item, required this.controller});

  static const tableAsset = 'assets/images/words/mesa.svg';
  static const ballAsset = 'assets/images/words/pelota.svg';
  static const ball = 'ball';
  static const placedBall = 'ball-placed';

  final ActivityItem item;
  final ItemController controller;

  @override
  State<PositionsView> createState() => _PositionsViewState();
}

class _PositionsViewState extends State<PositionsView> {
  SceneZone? _dropped;

  @override
  void didUpdateWidget(PositionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _dropped = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scene = PositionsScene.fit(constraints.biggest);
        final placed = widget.controller.isSolved ? _dropped : null;
        return DemoOverlay(
          key: ValueKey('demo-${widget.item.id}'),
          show: widget.controller.showsDemo,
          path: [scene.ballStart, _targetZone(scene).restingPlace],
          carrying: _ball(),
          carryingSize: scene.trayBallSize,
          child: Stack(
            children: [
              Positioned.fromRect(rect: scene.floor, child: const _Floor()),
              for (final table in scene.tables)
                Positioned.fromRect(rect: table, child: SvgPicture.asset(PositionsView.tableAsset)),
              for (final zone in scene.zones)
                Positioned.fromRect(rect: zone.area, child: _dropZone(zone)),
              Positioned.fromRect(
                rect: scene.leoArea,
                child: LeoAvatar(size: scene.leoArea.height, pose: leoPoseFor(widget.controller)),
              ),
              if (placed != null)
                Positioned.fromRect(
                  key: const ValueKey(PositionsView.placedBall),
                  rect: scene.ballAt(placed.restingPlace),
                  child: _ball(),
                )
              else
                Positioned.fromRect(rect: scene.grabArea, child: _draggableBall(scene)),
            ],
          ),
        );
      },
    );
  }

  SceneZone _targetZone(PositionsScene scene) =>
      scene.zones.firstWhere((zone) => zone.position == widget.item.target);

  Widget _dropZone(SceneZone zone) {
    final isHinted = widget.controller.isHintActive && zone.position == widget.item.target;
    return DragTarget<String>(
      key: ValueKey('zone-${zone.id}'),
      onAcceptWithDetails: (_) => _drop(zone),
      builder: (context, candidates, rejected) =>
          _ZoneGlow(isHinted: isHinted, isHovered: candidates.isNotEmpty),
    );
  }

  void _drop(SceneZone zone) {
    setState(() => _dropped = zone);
    widget.controller.answer(zone.position);
  }

  Widget _draggableBall(PositionsScene scene) {
    final ball = SizedBox.square(dimension: scene.trayBallSize, child: _ball());
    return Draggable<String>(
      key: const ValueKey(PositionsView.ball),
      data: PositionsView.ball,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: ball),
      childWhenDragging: const SizedBox.shrink(),
      child: ColoredBox(
        color: Colors.transparent,
        child: Center(child: ball),
      ),
    );
  }

  Widget _ball() => SvgPicture.asset(PositionsView.ballAsset);
}

class _Floor extends StatelessWidget {
  const _Floor();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.road,
        border: Border(top: BorderSide(color: AppTheme.outline, width: 6)),
      ),
    );
  }
}

class _ZoneGlow extends StatelessWidget {
  const _ZoneGlow({required this.isHinted, required this.isHovered});

  final bool isHinted;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isHovered ? color.withValues(alpha: 0.15) : Colors.transparent,
        border: Border.all(color: isHinted ? color : Colors.transparent, width: 6),
      ),
    );
  }
}
