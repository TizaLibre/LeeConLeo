import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/app_theme.dart';

class AvatarButton extends StatelessWidget {
  const AvatarButton({
    super.key,
    required this.avatar,
    required this.onPressed,
    this.size = 140,
    this.isSelected = false,
  });

  final String avatar;
  final VoidCallback? onPressed;
  final double size;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: isSelected ? colors.tertiary : AppTheme.outline,
            width: isSelected ? size * 0.06 : size * 0.03,
          ),
        ),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: SvgPicture.asset('assets/images/$avatar'),
          ),
        ),
      ),
    );
  }
}
