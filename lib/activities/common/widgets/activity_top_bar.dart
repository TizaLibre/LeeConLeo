import 'package:material_ui/material_ui.dart';

import 'progress_star.dart';

class ActivityTopBar extends StatelessWidget {
  const ActivityTopBar({
    super.key,
    required this.onHome,
    required this.onRepeat,
    required this.completed,
    required this.total,
    this.showsProgress = true,
  });

  final VoidCallback onHome;
  final VoidCallback onRepeat;
  final int completed;
  final int total;
  final bool showsProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            key: const ValueKey('home'),
            iconSize: 48,
            onPressed: onHome,
            icon: const Icon(Icons.home_rounded),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  if (showsProgress)
                    for (var i = 0; i < total; i++)
                      ProgressStar(key: ValueKey('star-$i'), isEarned: i < completed),
                ],
              ),
            ),
          ),
          IconButton.filled(
            key: const ValueKey('repeat'),
            iconSize: 48,
            onPressed: onRepeat,
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
    );
  }
}
