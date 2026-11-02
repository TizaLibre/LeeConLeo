import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/widgets/leo_avatar.dart';
import '../app/widgets/pulse.dart';
import '../app/widgets/scene_band.dart';
import '../core/content/models/path_stage.dart';
import '../core/content/models/path_step.dart';
import 'label_slot.dart';
import 'place_layout.dart';
import 'route_painter.dart';
import 'step_button.dart';
import 'step_status.dart';

enum LeoHere { none, entering, standing }

class PlaceView extends StatelessWidget {
  const PlaceView({
    super.key,
    required this.place,
    required this.columns,
    required this.statuses,
    required this.onOpen,
    this.enteringColumn,
    this.leavingColumn,
    this.leoStep,
    this.leoHere = LeoHere.none,
    this.rightReserved = 0,
  });

  static const walkDuration = Duration(milliseconds: 900);
  static const maxRouteWidth = 560.0;
  static const labelMargin = 16.0;
  static const labelHeight = 44.0;

  final PathStage place;
  final List<double> columns;
  final Map<String, StepStatus> statuses;
  final void Function(PathStep step, StepStatus status) onOpen;
  final double? enteringColumn;
  final double? leavingColumn;
  final String? leoStep;
  final LeoHere leoHere;
  final double rightReserved;

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: _buildPlace());
  }

  Widget _buildPlace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final layout = PlaceLayout.fit(
          size: size,
          columns: columns,
          enteringColumn: enteringColumn,
          leavingColumn: leavingColumn,
          maxRouteWidth: maxRouteWidth,
        );
        final road = RoutePainter.through(layout.road);
        final steps = place.steps;
        return Stack(
          children: [
            Positioned.fill(child: _scene(context)),
            Positioned.fill(
              child: CustomPaint(
                painter: RoutePainter(
                  points: layout.road,
                  edge: AppTheme.outline,
                  road: AppTheme.road,
                ),
              ),
            ),
            for (final (index, step) in steps.indexed)
              Positioned.fromRect(
                rect: layout.stoneAt(index),
                child: FittedBox(child: _stone(step)),
              ),
            if (leoHere != LeoHere.none) _leo(layout),
            _label(context, road, size.width),
          ],
        );
      },
    );
  }

  Widget _stone(PathStep step) {
    final status = statuses[step.id]!;
    final stone = StepButton(
      key: ValueKey('step-${step.id}'),
      step: step,
      status: status,
      onPressed: () => onOpen(step, status),
    );
    return status == StepStatus.next ? Pulse(child: stone) : stone;
  }

  Widget _leo(PlaceLayout layout) {
    final index = place.steps.indexWhere((step) => step.id == leoStep);
    final rect = leoHere == LeoHere.standing && index >= 0
        ? layout.leoBeside(index)
        : layout.leoEntering;
    return AnimatedPositioned.fromRect(
      rect: rect,
      duration: walkDuration,
      curve: Curves.easeInOut,
      child: IgnorePointer(child: LeoAvatar(size: layout.leoHeight)),
    );
  }

  Widget _label(BuildContext context, Path road, double width) {
    final style = Theme.of(context).textTheme.titleMedium;
    final name = TextPainter(
      text: TextSpan(text: place.name, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final needed = name.width + 2 * _PlaceLabel.padding;
    name.dispose();
    final beside = labelSlot(
      road: road,
      roadHalfWidth: RoutePainter.halfWidth,
      top: labelMargin,
      bottom: labelMargin + labelHeight,
      width: width,
      margin: labelMargin,
      rightReserved: rightReserved,
    );
    final slot = needed <= beside.maxWidth
        ? beside
        : LabelSlot(isLeft: true, maxWidth: width - 2 * labelMargin - rightReserved);
    return Positioned(
      left: slot.isLeft ? labelMargin : null,
      right: slot.isLeft ? null : labelMargin + rightReserved,
      top: labelMargin,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: slot.maxWidth),
        child: _PlaceLabel(key: ValueKey('place-label-${place.name}'), name: place.name),
      ),
    );
  }

  Widget _scene(BuildContext context) {
    final scene = place.scene;
    return scene == null
        ? ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerLow)
        : SceneBand(asset: 'assets/images/$scene');
  }
}

class _PlaceLabel extends StatelessWidget {
  const _PlaceLabel({super.key, required this.name});

  static const padding = 12.0;

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name, maxLines: 1, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}
