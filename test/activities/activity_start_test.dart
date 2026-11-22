import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/app/widgets/loading_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  testWidgets('a game opens straight on its intro when the content is already loaded', (
    tester,
  ) async {
    final player = RecordingPromptPlayer();
    final container = ProviderContainer(
      overrides: [
        contentProvider.overrideWith((ref) async => testContent),
        promptPlayerProvider.overrideWithValue(player),
        eventLogProvider.overrideWithValue(InMemoryEventLog()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(contentProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ActivityScreen(stepId: 'up-down', activityId: ActivityIds.upDown),
        ),
      ),
    );

    expect(find.byType(LoadingView), findsNothing);
    expect(find.byKey(const ValueKey('start')), findsOneWidget);
    expect(player.spoken, ['intro']);
  });
}
