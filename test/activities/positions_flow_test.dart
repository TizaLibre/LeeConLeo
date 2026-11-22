import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/spatial/positions_scene.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  late RecordingPromptPlayer player;
  late InMemoryEventLog log;

  Future<void> pumpActivity(
    WidgetTester tester, {
    Duration celebration = const Duration(milliseconds: 10),
  }) async {
    player = RecordingPromptPlayer();
    log = InMemoryEventLog();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => testContent),
          promptPlayerProvider.overrideWithValue(player),
          eventLogProvider.overrideWithValue(log),
        ],
        child: MaterialApp(
          home: ActivityScreen(
            stepId: 'positions',
            activityId: ActivityIds.positions,
            celebrationDuration: celebration,
            random: Random(1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();
  }

  String currentTarget() => player.spoken.last.split('say ').last;

  String zoneFor(String position) =>
      position == PositionsScene.between ? PositionsScene.between : '$position-0';

  Future<void> dropBallOn(WidgetTester tester, String zoneId) async {
    final ball = find.byKey(const ValueKey('ball'));
    final zone = find.byKey(ValueKey('zone-$zoneId'));
    await tester.drag(ball, tester.getCenter(zone) - tester.getCenter(ball));
    await tester.pump();
  }

  testWidgets('a child can drag the ball to every position and reach the reward', (tester) async {
    await pumpActivity(tester);

    for (var i = 0; i < 6; i++) {
      await dropBallOn(tester, zoneFor(currentTarget()));
      expect(find.byKey(const ValueKey('leo-cheering')), findsOneWidget);
      await tester.pumpAndSettle(const Duration(milliseconds: 20));
    }

    expect(find.byKey(const ValueKey('reward')), findsOneWidget);
    expect(log.events, hasLength(6));
    expect(log.events.every((event) => event.isCorrect), isTrue);
  });

  testWidgets('a wrong spot sends the ball back and Leo thinks', (tester) async {
    await pumpActivity(tester);
    final start = tester.getCenter(find.byKey(const ValueKey('ball')));
    final wrong = PositionsScene.between == currentTarget() ? 'under-1' : PositionsScene.between;

    await dropBallOn(tester, wrong);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('leo-thinking')), findsOneWidget);
    expect(tester.getCenter(find.byKey(const ValueKey('ball'))), start);
    expect(player.spoken.last, startsWith('retry say '));
  });

  testWidgets('the ball stays where the child dropped it on the right spot', (tester) async {
    await pumpActivity(tester, celebration: const Duration(seconds: 5));
    final target = currentTarget();
    final zone = find.byKey(ValueKey('zone-${zoneFor(target)}'));

    await dropBallOn(tester, zoneFor(target));

    expect(find.byKey(const ValueKey('ball')), findsNothing);
    final placed = tester.getCenter(find.byKey(const ValueKey('ball-placed')));
    final area = tester.getRect(zone);
    final isOver = target == PositionsScene.over;
    expect(placed.dx, closeTo(area.center.dx, 1));
    expect(isOver ? placed.dy < area.bottom : area.contains(placed), isTrue);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
