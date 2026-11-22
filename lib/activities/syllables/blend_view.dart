import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import '../common/item_controller.dart';
import '../common/widgets/choice_button.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import '../common/widgets/letter_glyph.dart';
import 'blend_activity.dart';

class BlendView extends StatefulWidget {
  const BlendView({super.key, required this.item, required this.controller});

  static const syllablesKey = ValueKey('blend-syllables');
  static const syllablesShare = 0.28;
  static const revealDelay = Duration(milliseconds: 1600);
  static const revealStep = Duration(milliseconds: 750);

  final BlendItem item;
  final ItemController controller;

  @override
  State<BlendView> createState() => _BlendViewState();
}

class _BlendViewState extends State<BlendView> {
  Timer? _timer;
  int _shown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && _shown == 0) _reveal();
  }

  @override
  void didUpdateWidget(BlendView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _reveal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reveal() {
    _timer?.cancel();
    final count = widget.item.syllables.length;
    if (MediaQuery.disableAnimationsOf(context)) {
      _shown = count;
      return;
    }
    _shown = 0;
    _timer = Timer(BlendView.revealDelay, () {
      if (!mounted) return;
      setState(() => _shown = 1);
      _timer = Timer.periodic(BlendView.revealStep, (timer) {
        if (!mounted || _shown >= count) return timer.cancel();
        setState(() => _shown++);
      });
    });
  }

  bool _isWide(Size size) => size.width > size.height * 1.5;

  Rect _syllablesRect(Size size) => _isWide(size)
      ? Rect.fromLTWH(0, 0, size.width * BlendView.syllablesShare, size.height)
      : Rect.fromLTWH(0, 0, size.width, size.height * BlendView.syllablesShare);

  Rect _choicesRect(Size size) {
    final top = _syllablesRect(size);
    return _isWide(size)
        ? Rect.fromLTRB(top.right + 12, 0, size.width, size.height)
        : Rect.fromLTRB(0, top.bottom + 12, size.width, size.height);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return LeoBeside(
      controller: widget.controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final choices = _choicesRect(size);
          final columns = choices.width > choices.height * 1.5 ? item.options.length : 2;
          final rows = (item.options.length / columns).ceil();
          final index = item.options.indexOf(item.target);
          final inRow = min(columns, item.options.length - index ~/ columns * columns);
          final cell = Size(choices.width / columns, choices.height / rows);
          final target = Offset(
            choices.center.dx + (index % columns - (inRow - 1) / 2) * cell.width,
            choices.top + (index ~/ columns + 0.5) * cell.height,
          );
          return DemoOverlay(
            key: ValueKey('demo-${item.id}'),
            show: widget.controller.showsDemo,
            path: [target],
            child: Stack(
              children: [
                Positioned.fromRect(rect: _syllablesRect(size), child: _syllables()),
                Positioned.fromRect(
                  rect: choices,
                  child: Column(
                    children: [
                      for (var row = 0; row < rows; row++)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final word in item.options.skip(row * columns).take(columns))
                                SizedBox(width: cell.width, child: _choice(word)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _syllables() => Center(
    child: FittedBox(
      key: BlendView.syllablesKey,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, syllable) in widget.item.syllables.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedOpacity(
                key: ValueKey('blend-syllable-$index'),
                duration: const Duration(milliseconds: 250),
                opacity: index < _shown ? 1 : 0,
                child: LetterGlyph(syllable, color: AppTheme.outline),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _choice(String word) => ChoiceButton(
    key: ValueKey('choice-$word'),
    isHighlighted: widget.controller.isHintActive && word == widget.item.target,
    onPressed: () => widget.controller.answer(word),
    child: SvgPicture.asset('assets/images/${widget.item.images[word]}'),
  );
}
