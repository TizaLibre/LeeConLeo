import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import 'leo_avatar.dart';
import 'letter_cloud.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.animate = true});

  static const letters = [
    FloatingLetter('a', Alignment(-0.72, -0.62), 0.24),
    FloatingLetter('E', Alignment(0.7, -0.72), 0.22),
    FloatingLetter('i', Alignment(-0.78, 0.3), 0.2),
    FloatingLetter('O', Alignment(0.76, 0.18), 0.24),
    FloatingLetter('u', Alignment(0.5, 0.82), 0.18),
  ];

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.cream,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.85,
          child: LetterCloud(
            letters: letters,
            animate: animate,
            childSize: 0.62,
            child: const LeoAvatar(pose: LeoPose.happy),
          ),
        ),
      ),
    );
  }
}
