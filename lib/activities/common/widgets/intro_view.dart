import 'package:material_ui/material_ui.dart';

import '../../../app/widgets/leo_avatar.dart';

class IntroView extends StatelessWidget {
  const IntroView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LeoAvatar(size: 260, pose: LeoPose.happy),
            const SizedBox(height: 32),
            IconButton.filled(
              key: const ValueKey('start'),
              iconSize: 96,
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
