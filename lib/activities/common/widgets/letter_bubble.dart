import 'package:material_ui/material_ui.dart';

import '../../../app/app_theme.dart';
import 'letter_glyph.dart';

class LetterBubble extends StatelessWidget {
  const LetterBubble({
    super.key,
    required this.letter,
    this.isHinted = false,
    this.letterShare = 0.6,
  });

  static const fill = Color(0xFFBDE4F7);
  static const borderShare = 0.025;

  final String letter;
  final bool isHinted;
  final double letterShare;

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).colorScheme.tertiary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final border = constraints.biggest.shortestSide * borderShare;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.4, -0.5),
              colors: [Colors.white, fill],
            ),
            border: Border.all(
              color: isHinted ? hint : AppTheme.outline,
              width: isHinted ? border * 2 : border,
            ),
          ),
          child: Center(
            child: FractionallySizedBox(
              heightFactor: letterShare,
              child: FittedBox(child: LetterGlyph(letter, color: AppTheme.outline)),
            ),
          ),
        );
      },
    );
  }
}
