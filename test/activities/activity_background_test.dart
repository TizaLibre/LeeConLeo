import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/app/widgets/scene_band.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';
import 'package:lee_con_leo/utils/hex_color.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  testWidgets('the scene frames the intro and reward, and the game gets a calm tint', (
    tester,
  ) async {
    final player = RecordingPromptPlayer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => testContent),
          promptPlayerProvider.overrideWithValue(player),
          eventLogProvider.overrideWithValue(InMemoryEventLog()),
        ],
        child: MaterialApp(
          home: ActivityScreen(
            stepId: 'up-down',
            activityId: ActivityIds.upDown,
            celebrationDuration: const Duration(milliseconds: 10),
            random: Random(1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Color? background() => tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;

    expect(find.byType(SceneBand), findsOneWidget);
    expect(find.byKey(const ValueKey('star-0')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();
    expect(find.byType(SceneBand), findsNothing);
    expect(find.byKey(const ValueKey('star-0')), findsOneWidget);
    expect(background(), Color(parseHexColor(testTint)!));

    for (var i = 0; i < 6; i++) {
      final target = player.spoken.last.replaceFirst('say ', '');
      await tester.tap(find.byKey(ValueKey('choice-$target')));
      await tester.pumpAndSettle(const Duration(milliseconds: 20));
    }
    expect(find.byKey(const ValueKey('reward')), findsOneWidget);
    expect(find.byType(SceneBand), findsOneWidget);
    expect(find.byKey(const ValueKey('star-0')), findsNothing);
    expect(find.byKey(const ValueKey('home')), findsOneWidget);
  });
}
