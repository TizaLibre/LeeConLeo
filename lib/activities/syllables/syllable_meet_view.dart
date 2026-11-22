import 'package:material_ui/material_ui.dart';

import '../../app/app_theme.dart';
import '../common/item_controller.dart';
import '../common/widgets/choice_button.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import '../common/widgets/letter_glyph.dart';
import 'syllable_meet_activity.dart';

class SyllableMeetView extends StatelessWidget {
  const SyllableMeetView({super.key, required this.item, required this.controller});

  static const partsShare = 0.35;
  static const glyphMargin = 24.0;

  final SyllableItem item;
  final ItemController controller;

  bool get _showsParts => item.parts.isNotEmpty;

  bool _isWide(Size size) => size.width > size.height;

  Rect _cardsRect(Size size) => _showsParts
      ? Rect.fromLTRB(0, size.height * partsShare, size.width, size.height)
      : Offset.zero & size;

  Offset _targetCenter(Size size) {
    final cards = _cardsRect(size);
    final along = (item.options.indexOf(item.target) + 0.5) / item.options.length;
    final center = _isWide(cards.size)
        ? Offset(cards.width * along, cards.height / 2)
        : Offset(cards.width / 2, cards.height * along);
    return cards.topLeft + center;
  }

  @override
  Widget build(BuildContext context) {
    return LeoBeside(
      controller: controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final cards = _cardsRect(size);
          return DemoOverlay(
            key: ValueKey('demo-${item.id}'),
            show: controller.showsDemo,
            path: [_targetCenter(size)],
            child: Stack(
              children: [
                if (_showsParts)
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(0, 0, size.width, cards.top),
                    child: _parts(),
                  ),
                Positioned.fromRect(
                  rect: cards,
                  child: Flex(
                    direction: _isWide(cards.size) ? Axis.horizontal : Axis.vertical,
                    children: [for (final option in item.options) Expanded(child: _card(option))],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _parts() => FittedBox(
    key: const ValueKey('syllable-parts'),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LetterGlyph(item.parts.first, color: AppTheme.outline),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: glyphMargin),
          child: Icon(Icons.add_rounded, size: 96, color: AppTheme.outline),
        ),
        LetterGlyph(item.parts.last, color: AppTheme.outline),
      ],
    ),
  );

  Widget _card(String option) => ChoiceButton(
    key: ValueKey('choice-$option'),
    isHighlighted: controller.isHintActive && option == item.target,
    onPressed: () => controller.answer(option),
    child: Padding(padding: const EdgeInsets.all(glyphMargin), child: LetterGlyph(option)),
  );
}
