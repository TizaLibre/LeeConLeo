import 'package:material_ui/material_ui.dart';

import '../../../app/app_theme.dart';

class LetterGlyph extends StatelessWidget {
  const LetterGlyph(this.text, {super.key, this.size = 160, this.color});

  static const fontAscent = 1.591;
  static const inkTop = 1.16;
  static const inkBottom = 0.66;
  static const capitalTilde = 0.26;

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      inherit: false,
      fontFamily: AppTheme.letterFont,
      fontSize: size,
      color: color ?? DefaultTextStyle.of(context).style.color,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final width = painter.width;
    painter.dispose();
    final top = inkTop + (text.contains('Ñ') ? capitalTilde : 0);
    return SizedBox(
      width: width,
      height: (top + inkBottom) * size,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: Transform.translate(
          offset: Offset(0, -(fontAscent - top) * size),
          child: Text(text, textScaler: TextScaler.noScaling, style: style),
        ),
      ),
    );
  }
}
