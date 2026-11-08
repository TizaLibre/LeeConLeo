import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/widgets/leo_avatar.dart';
import '../../../app/widgets/sticker_card.dart';

class RewardView extends StatelessWidget {
  const RewardView({super.key, required this.onDone, this.onAgain, this.sticker});

  static const newStickerKey = ValueKey('new-sticker');
  static const againKey = ValueKey('again');

  final VoidCallback onDone;
  final VoidCallback? onAgain;
  final String? sticker;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: const ValueKey('reward'),
              child: switch (sticker) {
                final sticker? => StickerCard(key: newStickerKey, image: sticker, size: 200),
                null => const Icon(Icons.star_rounded, size: 200, color: AppTheme.starGold),
              },
            ),
            const LeoAvatar(size: 200, pose: LeoPose.cheering),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onAgain case final onAgain?) ...[
                  IconButton.filledTonal(
                    key: againKey,
                    iconSize: 72,
                    onPressed: onAgain,
                    icon: const Icon(Icons.replay_rounded),
                  ),
                  const SizedBox(width: 48),
                ],
                IconButton.filled(
                  key: const ValueKey('done'),
                  iconSize: 72,
                  onPressed: onDone,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
