import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_theme.dart';
import '../core/content/models/path_step.dart';
import 'step_status.dart';

class StepButton extends StatelessWidget {
  const StepButton({super.key, required this.step, required this.status, required this.onPressed});

  final PathStep step;
  final StepStatus status;
  final VoidCallback? onPressed;

  static const size = 96.0;
  static const lockedOpacity = 0.45;
  static const badgeSize = 36.0;
  static const masteredKey = ValueKey('mastered-badge');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLocked = status == StepStatus.locked;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              shape: CircleBorder(side: BorderSide(color: AppTheme.outline, width: 4)),
              color: isLocked ? colors.surfaceContainerHighest : colors.primaryContainer,
              elevation: isLocked ? 0 : 4,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: Opacity(
                  opacity: isLocked ? lockedOpacity : 1,
                  child: Center(child: _face(colors.onPrimaryContainer)),
                ),
              ),
            ),
          ),
          if (status == StepStatus.done)
            const Positioned(
              right: -4,
              bottom: -4,
              child: Icon(Icons.star_rounded, size: badgeSize, color: AppTheme.starGold),
            ),
          if (status == StepStatus.mastered)
            const Positioned(
              key: masteredKey,
              right: -6,
              bottom: -6,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: badgeSize * 1.2,
                color: AppTheme.starGold,
              ),
            ),
          if (isLocked)
            Positioned(
              right: -2,
              bottom: -2,
              child: Icon(Icons.lock_rounded, size: badgeSize * 0.8, color: colors.outline),
            ),
        ],
      ),
    );
  }

  Widget _face(Color textColor) {
    final icon = step.icon;
    if (icon != null) {
      return Padding(
        padding: const EdgeInsets.all(size * 0.14),
        child: SvgPicture.asset('assets/images/$icon'),
      );
    }
    final grapheme = step.grapheme ?? (step.sounds.length > 1 ? step.sounds.first : null);
    if (grapheme != null) {
      return Text(
        grapheme,
        style: TextStyle(fontFamily: AppTheme.letterFont, fontSize: 44, color: textColor),
      );
    }
    return Icon(Icons.explore_rounded, size: 48, color: textColor);
  }
}
