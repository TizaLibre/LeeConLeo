import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activities/activity_providers.dart';
import '../app/app_theme.dart';
import '../core/content/content_providers.dart';
import '../core/content/models/content_bundle.dart';
import '../core/profiles/profile.dart';
import '../core/profiles/profile_providers.dart';
import '../core/progress/mastery.dart';
import '../map/step_button.dart';
import '../map/step_status.dart';

final _statusesProvider = FutureProvider.autoDispose.family<Map<String, StepStatus>, Profile>((
  ref,
  profile,
) async {
  final content = await ref.watch(contentProvider.future);
  final data = await ref.watch(profileStoreProvider).open(profile);
  final registry = ref.watch(activityRegistryProvider);
  return stepStatuses(
    content.steps,
    completed: data.progress.completedSteps,
    mastered: Mastery.masteredSteps(data.events.events),
    isPlayable: (step) => registry.firstAvailable(step.activities) != null,
  );
});

class ProfileProgress extends ConsumerWidget {
  const ProfileProgress({super.key, required this.profile});

  static const stoneSize = 64.0;

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider).value;
    final statuses = ref.watch(_statusesProvider(profile)).value;
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(backgroundColor: AppTheme.cream, title: Text(profile.nickname)),
      body: SafeArea(
        child: content == null || statuses == null
            ? const Center(child: CircularProgressIndicator())
            : _progress(context, content, statuses),
      ),
    );
  }

  Widget _progress(BuildContext context, ContentBundle content, Map<String, StepStatus> statuses) {
    final finished = statuses.values.where((status) => status.isFinished).length;
    final mastered = statuses.values.where((status) => status == StepStatus.mastered).length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '$finished de ${statuses.length} pasos terminados, $mastered dominados.',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const _Legend(icon: Icons.star_rounded, text: 'Terminado: jugó todos los juegos del paso.'),
        const _Legend(
          icon: Icons.workspace_premium_rounded,
          text:
              'Dominado: acertó al primer intento 8 de sus últimas 10 respuestas, en dos sesiones o más.',
        ),
        for (final place in content.stages) ...[
          const SizedBox(height: 24),
          Text(place.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final step in place.steps)
                SizedBox.square(
                  dimension: stoneSize,
                  child: FittedBox(
                    child: StepButton(
                      key: ValueKey('progress-${step.id}'),
                      step: step,
                      status: statuses[step.id]!,
                      onPressed: null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.starGold),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
