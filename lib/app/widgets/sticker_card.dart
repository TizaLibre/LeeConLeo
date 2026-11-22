import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_theme.dart';

class StickerCard extends StatelessWidget {
  const StickerCard({super.key, required this.image, this.size = 120, this.isEarned = true});

  static const _grayscale = ColorFilter.matrix([
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0, //
    0.33, 0.33, 0.33, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  final String image;
  final double size;
  final bool isEarned;

  @override
  Widget build(BuildContext context) {
    final picture = SvgPicture.asset('assets/images/$image');
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEarned ? Colors.white : AppTheme.outline.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(size * 0.2),
          border: Border.all(
            color: isEarned ? AppTheme.starGold : AppTheme.outline.withValues(alpha: 0.25),
            width: size * (isEarned ? 0.05 : 0.02),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: isEarned
              ? picture
              : Opacity(
                  opacity: 0.25,
                  child: ColorFiltered(colorFilter: _grayscale, child: picture),
                ),
        ),
      ),
    );
  }
}
