import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import '../common/item_controller.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import '../common/widgets/letter_glyph.dart';
import 'build_word_activity.dart';

class BuildWordView extends StatefulWidget {
  const BuildWordView({super.key, required this.item, required this.controller});

  static const slotsKey = ValueKey('word-slots');
  static const pictureShare = 0.4;
  static const slotsShare = 0.27;
  static const gap = 12.0;
  static const cellPadding = 6.0;

  final BuildWordItem item;
  final ItemController controller;

  @override
  State<BuildWordView> createState() => _BuildWordViewState();
}

class _BuildWordViewState extends State<BuildWordView> {
  final _placed = <int>[];

  BuildWordItem get _item => widget.item;

  @override
  void didUpdateWidget(BuildWordView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _placed.clear();
  }

  bool _fitsNext(int tile) =>
      _placed.length < _item.syllables.length &&
      _item.options[tile] == _item.syllables[_placed.length];

  int get _nextTile => [
    for (var i = 0; i < _item.options.length; i++) i,
  ].firstWhere((i) => !_placed.contains(i) && _fitsNext(i), orElse: () => -1);

  void _place(int tile) {
    if (widget.controller.isSolved || _placed.contains(tile)) return;
    if (!_fitsNext(tile)) {
      widget.controller.answer(_item.options[tile]);
      return;
    }
    setState(() => _placed.add(tile));
    if (_placed.length == _item.syllables.length) widget.controller.answer(_item.target);
  }

  bool _isWide(Size size) => size.width > size.height * 1.2;

  ({Rect picture, Rect slots, Rect tiles}) _layout(Size size) {
    const gap = BuildWordView.gap;
    if (_isWide(size)) {
      final left = size.width * BuildWordView.pictureShare;
      final middle = size.height / 2;
      return (
        picture: Rect.fromLTWH(0, 0, left, size.height),
        slots: Rect.fromLTRB(left + gap, 0, size.width, middle),
        tiles: Rect.fromLTRB(left + gap, middle + gap, size.width, size.height),
      );
    }
    final pictureBottom = size.height * BuildWordView.pictureShare;
    final slotsBottom = pictureBottom + size.height * BuildWordView.slotsShare;
    return (
      picture: Rect.fromLTWH(0, 0, size.width, pictureBottom),
      slots: Rect.fromLTRB(0, pictureBottom + gap, size.width, slotsBottom),
      tiles: Rect.fromLTRB(0, slotsBottom + gap, size.width, size.height),
    );
  }

  static List<Rect> _cells(Rect area, int count) {
    var best = (rows: 1, side: 0.0);
    for (var rows = 1; rows <= 2; rows++) {
      final columns = (count / rows).ceil();
      final side = min(area.width / columns, area.height / rows);
      if (side > best.side) best = (rows: rows, side: side);
    }
    final columns = (count / best.rows).ceil();
    final side = best.side;
    return [
      for (var i = 0; i < count; i++)
        Rect.fromLTWH(
          area.center.dx - side * _rowLength(i, count, columns) / 2 + side * (i % columns),
          area.center.dy - side * best.rows / 2 + side * (i ~/ columns),
          side,
          side,
        ),
    ];
  }

  static int _rowLength(int index, int count, int columns) =>
      min(columns, count - index ~/ columns * columns);

  @override
  Widget build(BuildContext context) {
    return LeoBeside(
      controller: widget.controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _layout(constraints.biggest);
          final slots = _cells(layout.slots, _item.syllables.length);
          final tiles = _cells(layout.tiles, _item.options.length);
          final next = _nextTile;
          return DemoOverlay(
            key: ValueKey('demo-${_item.id}'),
            show: widget.controller.showsDemo,
            path: [
              if (next >= 0) ...[tiles[next].center, slots[_placed.length].center],
            ],
            carrying: next >= 0 ? _card(_item.options[next]) : null,
            carryingSize: tiles.first.width - BuildWordView.cellPadding * 2,
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: layout.picture,
                  child: SvgPicture.asset('assets/images/${_item.image}'),
                ),
                Positioned.fromRect(
                  rect: layout.slots,
                  child: DragTarget<int>(
                    key: BuildWordView.slotsKey,
                    onAcceptWithDetails: (details) => _place(details.data),
                    builder: (context, candidates, rejected) => const SizedBox.expand(),
                  ),
                ),
                for (final (index, rect) in slots.indexed)
                  Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(child: _slot(index)),
                  ),
                for (final (index, rect) in tiles.indexed)
                  if (!_placed.contains(index))
                    Positioned.fromRect(rect: rect, child: _tile(index, rect.width)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _slot(int index) {
    final filled = index < _placed.length;
    final isNext = index == _placed.length;
    final hint = Theme.of(context).colorScheme.tertiary;
    return Padding(
      key: ValueKey('slot-$index'),
      padding: const EdgeInsets.all(BuildWordView.cellPadding),
      child: filled
          ? _card(_item.options[_placed[index]])
          : DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.outline.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNext && widget.controller.isHintActive ? hint : AppTheme.outline,
                  width: isNext ? 4 : 2,
                ),
              ),
            ),
    );
  }

  Widget _tile(int index, double side) {
    final isHinted = widget.controller.isHintActive && index == _nextTile;
    final card = _card(_item.options[index], isHinted: isHinted);
    final size = side - BuildWordView.cellPadding * 2;
    return Padding(
      padding: const EdgeInsets.all(BuildWordView.cellPadding),
      child: Draggable<int>(
        key: ValueKey('tile-$index'),
        data: index,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: SizedBox.square(dimension: size, child: card),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: GestureDetector(onTap: () => _place(index), child: card),
      ),
    );
  }

  Widget _card(String syllable, {bool isHinted = false}) {
    final hint = Theme.of(context).colorScheme.tertiary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHinted ? hint : AppTheme.outline, width: isHinted ? 8 : 3),
      ),
      padding: const EdgeInsets.all(10),
      child: FittedBox(child: LetterGlyph(syllable, color: AppTheme.outline)),
    );
  }
}
