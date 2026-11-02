import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../app/widgets/pulse.dart';
import '../core/audio/audio_providers.dart';
import '../core/audio/utterance.dart';
import '../core/content/activity_ids.dart';
import '../core/content/models/content_bundle.dart';
import '../core/content/models/path_step.dart';
import '../core/content/writable_words.dart';
import '../core/progress/progress_providers.dart';

class WriteButton extends ConsumerWidget {
  const WriteButton({super.key, required this.bundle});

  static const lockedPrompt = 'writing.locked';
  static const size = 88.0;

  final ContentBundle bundle;

  static PathStep? practiceStep(ContentBundle bundle, Set<String> completed) {
    PathStep? found;
    for (final step in bundle.steps) {
      if (completed.contains(step.id) && WritableWords.upTo(bundle, step).isNotEmpty) {
        found = step;
      }
    }
    return found;
  }

  static bool isPathFinished(ContentBundle bundle, Set<String> completed) =>
      bundle.steps.every((step) => completed.contains(step.id));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completedStepsProvider);
    final step = practiceStep(bundle, completed);
    final button = SizedBox.square(
      dimension: size,
      child: Material(
        shape: const CircleBorder(side: BorderSide(color: AppTheme.outline, width: 4)),
        color: Colors.white,
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(context, ref, step),
          child: Opacity(
            opacity: step == null ? 0.45 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset('assets/images/games/write.svg'),
            ),
          ),
        ),
      ),
    );
    return isPathFinished(bundle, completed) ? Pulse(child: button) : button;
  }

  void _open(BuildContext context, WidgetRef ref, PathStep? step) {
    final player = ref.read(promptPlayerProvider);
    if (step == null) {
      player.say(Utterance([bundle.prompts.line(lockedPrompt, Random())]));
      return;
    }
    player.stop();
    context.go('/play/${step.id}/${ActivityIds.writeWord}');
  }
}
