import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_providers.dart';
import '../core/content/activity_ids.dart';
import '../core/content/models/content_bundle.dart';
import '../core/progress/progress_providers.dart';
import 'write_button.dart';

class ReviewButton extends ConsumerWidget {
  const ReviewButton({super.key, required this.bundle});

  static const buttonKey = ValueKey('review');

  final ContentBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(masteredStepsProvider).isEmpty) return const SizedBox.shrink();
    final completed = ref.watch(completedStepsProvider);
    final step = bundle.steps.firstWhere(
      (step) => !completed.contains(step.id),
      orElse: () => bundle.steps.last,
    );
    return SizedBox.square(
      dimension: WriteButton.size,
      child: IconButton.filledTonal(
        key: buttonKey,
        iconSize: 56,
        onPressed: () {
          ref.read(promptPlayerProvider).stop();
          context.go('/play/${step.id}/${ActivityIds.review}');
        },
        icon: const Icon(Icons.replay_rounded),
      ),
    );
  }
}
