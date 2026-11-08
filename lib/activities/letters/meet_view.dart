import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/content/models/letter_shape.dart';
import '../../core/content/models/spoken_line.dart';
import '../common/item_controller.dart';
import '../common/widgets/choice_button.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import '../common/widgets/letter_glyph.dart';
import 'meet_activity.dart';

class MeetView extends StatefulWidget {
  const MeetView({super.key, required this.item, required this.controller});

  static const letterMargin = 40.0;

  final MeetItem item;
  final ItemController controller;

  @override
  State<MeetView> createState() => _MeetViewState();
}

class _MeetViewState extends State<MeetView> {
  StreamSubscription<SpokenLine>? _lines;
  LetterCase? _named;

  MeetItem get item => widget.item;

  ItemController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _lines = controller.linesSpoken.listen(_follow);
  }

  @override
  void didUpdateWidget(MeetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      _lines?.cancel();
      _lines = controller.linesSpoken.listen(_follow);
    }
    if (oldWidget.item.id != item.id) _named = null;
  }

  @override
  void dispose() {
    _lines?.cancel();
    super.dispose();
  }

  void _follow(SpokenLine line) {
    LetterCase? named;
    for (final MapEntry(key: letterCase, value: caseLine) in item.caseLines.entries) {
      if (identical(caseLine, line)) named = letterCase;
    }
    if (mounted && named != _named) setState(() => _named = named);
  }

  @override
  Widget build(BuildContext context) {
    final image = item.image;
    return LeoBeside(
      controller: controller,
      child: LayoutBuilder(
        builder: (context, constraints) => DemoOverlay(
          key: ValueKey('demo-${item.id}'),
          show: controller.showsDemo,
          path: [_targetCenter(constraints.biggest)],
          child: Flex(
            direction: _isWide(constraints.biggest) ? Axis.horizontal : Axis.vertical,
            children: [
              for (final option in item.options) Expanded(child: _card(option)),
              if (image != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SvgPicture.asset('assets/images/$image'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isWide(Size size) => size.width > size.height;

  Offset _targetCenter(Size size) {
    final slots = item.options.length + (item.image == null ? 0 : 1);
    final along = (max(0, item.options.indexOf(item.target)) + 0.5) / slots;
    return _isWide(size)
        ? Offset(size.width * along, size.height / 2)
        : Offset(size.width / 2, size.height * along);
  }

  Widget _card(String option) => ChoiceButton(
    key: ValueKey('choice-$option'),
    isHighlighted: (controller.isHintActive && option == item.target) || option == _named?.name,
    onPressed: () => controller.answer(item.isIntroduction ? item.target : option),
    child: Padding(
      padding: const EdgeInsets.all(MeetView.letterMargin),
      child: LetterGlyph(_glyphs(option)),
    ),
  );

  String _glyphs(String option) => LetterCase.values.byName(option).apply(item.grapheme);
}
