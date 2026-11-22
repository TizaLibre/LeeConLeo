import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../common/activity_item.dart';
import '../common/item_controller.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import '../common/widgets/letter_bubble.dart';
import 'find_activity.dart';

class FindView extends StatefulWidget {
  const FindView({super.key, required this.item, required this.controller});

  static const floatPeriod = Duration(seconds: 3);

  final ActivityItem item;
  final ItemController controller;

  @override
  State<FindView> createState() => _FindViewState();
}

class _FindViewState extends State<FindView> with SingleTickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: FindView.floatPeriod);
  final _popped = <int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void didUpdateWidget(FindView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _popped.clear();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  bool _isTarget(int index) =>
      FindActivity.isTarget(widget.item.options[index], widget.item.target);

  void _tap(int index) {
    if (widget.controller.isSolved || _popped.contains(index)) return;
    if (!_isTarget(index)) {
      widget.controller.answer(widget.item.options[index]);
      return;
    }
    setState(() => _popped.add(index));
    final options = widget.item.options;
    final isCleared = [
      for (var i = 0; i < options.length; i++) i,
    ].where(_isTarget).every(_popped.contains);
    if (isCleared) widget.controller.answer(widget.item.target);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.item.options;
    return LeoBeside(
      controller: widget.controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > constraints.maxHeight ? 3 : 2;
          final rows = (options.length / columns).ceil();
          final cell = Size(constraints.maxWidth / columns, constraints.maxHeight / rows);
          final diameter = min(cell.width, cell.height) * 0.8;
          Offset centerOf(int i) =>
              Offset((i % columns + 0.5) * cell.width, (i ~/ columns + 0.5) * cell.height);
          final firstTarget = [
            for (var i = 0; i < options.length; i++) i,
          ].firstWhere((i) => _isTarget(i) && !_popped.contains(i), orElse: () => -1);
          return DemoOverlay(
            key: ValueKey('demo-${widget.item.id}'),
            show: widget.controller.showsDemo,
            path: [if (firstTarget >= 0) centerOf(firstTarget)],
            child: Stack(
              children: [
                for (var i = 0; i < options.length; i++)
                  Positioned(
                    left: (i % columns) * cell.width + (cell.width - diameter) / 2,
                    top: (i ~/ columns) * cell.height + (cell.height - diameter) / 2,
                    width: diameter,
                    height: diameter,
                    child: _bubble(i, diameter),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bubble(int index, double diameter) {
    final phase = index / widget.item.options.length;
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin(2 * pi * (_float.value + phase)) * diameter * 0.05),
        child: child,
      ),
      child: AnimatedScale(
        scale: _popped.contains(index) ? 0 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInBack,
        child: GestureDetector(
          key: ValueKey('bubble-$index'),
          onTap: () => _tap(index),
          child: LetterBubble(
            letter: widget.item.options[index],
            isHinted: widget.controller.isHintActive && _isTarget(index),
          ),
        ),
      ),
    );
  }
}
