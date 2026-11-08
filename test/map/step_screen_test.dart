import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/app/app_router.dart';
import 'package:lee_con_leo/app/startup_providers.dart';
import 'package:lee_con_leo/app/widgets/pulse.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/profiles/in_memory_profile_store.dart';
import 'package:lee_con_leo/core/profiles/profile_providers.dart';
import 'package:lee_con_leo/core/profiles/profile_store.dart';
import 'package:lee_con_leo/map/home_screen.dart';
import 'package:lee_con_leo/map/step_screen.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  late RecordingPromptPlayer player;
  late ProfileData data;

  Future<void> pumpApp(
    WidgetTester tester, [
    void Function(ProfileData data)? seed,
    ContentBundle content = testContent,
  ]) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    player = RecordingPromptPlayer();
    final store = InMemoryProfileStore(const [testProfile]);
    await tester.runAsync(() async => data = await store.open(testProfile));
    seed?.call(data);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => content),
          minimumSplashProvider.overrideWithValue(Duration.zero),
          promptPlayerProvider.overrideWithValue(player),
          profileStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp.router(routerConfig: createAppRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  void finishSpatialSteps(ProfileData data) {
    for (final step in ['up-down', 'left-right', 'positions']) {
      data.progress.markCompleted(step);
    }
  }

  Finder card(String activityId) => find.byKey(ValueKey('game-$activityId'));

  bool pulses(WidgetTester tester, String activityId) =>
      tester.any(find.descendant(of: card(activityId), matching: find.byType(Pulse)));

  testWidgets('a step with several games opens on one card per game, the next one pulsing', (
    tester,
  ) async {
    await pumpApp(tester, (data) {
      finishSpatialSteps(data);
      data.progress.markPlayed((stepId: 'a', activityId: ActivityIds.meet));
    });

    await tester.tap(find.byKey(const ValueKey('step-a')));
    await tester.pumpAndSettle();

    expect(find.byType(StepScreen), findsOneWidget);
    expect(player.spoken.last, 'step intro');
    for (final game in [
      ActivityIds.meet,
      ActivityIds.trace,
      ActivityIds.find,
      ActivityIds.startsWith,
    ]) {
      expect(card(game), findsOneWidget);
    }
    expect(pulses(tester, ActivityIds.meet), isFalse);
    expect(pulses(tester, ActivityIds.trace), isTrue);

    await tester.tap(card(ActivityIds.find));
    await tester.pumpAndSettle();
    expect(tester.widget<ActivityScreen>(find.byType(ActivityScreen)).activityId, ActivityIds.find);

    await tester.tap(find.byKey(const ValueKey('home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('step-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(StepScreen.mapKey));
    await tester.pumpAndSettle();
    expect(find.byType(PathMap), findsOneWidget);
  });

  testWidgets('a step with a single game opens it directly and returns to the map', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const ValueKey('step-up-down')));
    await tester.pumpAndSettle();
    expect(find.byType(StepScreen), findsNothing);
    expect(find.byType(ActivityScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();
    while (!tester.any(find.byKey(const ValueKey('reward')))) {
      await tester.tap(find.byKey(ValueKey('choice-${player.spoken.last.split(' ').last}')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    await tester.tap(find.byKey(const ValueKey('done')));
    await tester.pumpAndSettle();

    expect(find.byType(PathMap), findsOneWidget);
    expect(data.progress.completedSteps, {'up-down'});
  });

  testWidgets('playing the last game of a step finishes it', (tester) async {
    await pumpApp(tester, (data) {
      finishSpatialSteps(data);
      for (final game in [ActivityIds.meet, ActivityIds.trace, ActivityIds.find]) {
        data.progress.markPlayed((stepId: 'a', activityId: game));
      }
    });

    await tester.tap(find.byKey(const ValueKey('step-a')));
    await tester.pumpAndSettle();
    expect(pulses(tester, ActivityIds.startsWith), isTrue);
    await tester.tap(card(ActivityIds.startsWith));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();
    while (!tester.any(find.byKey(const ValueKey('reward')))) {
      await tester.tap(find.byKey(const ValueKey('choice-abeja')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    await tester.tap(find.byKey(const ValueKey('done')));
    await tester.pumpAndSettle();

    expect(find.byType(StepScreen), findsOneWidget);
    expect(data.progress.completedSteps, contains('a'));
    expect(player.spoken.last, 'step done');

    await tester.tap(find.byKey(StepScreen.nextKey));
    await tester.pumpAndSettle();
    expect(find.byType(PathMap), findsOneWidget);
  });

  testWidgets('until the first game is played, the others are locked and Leo explains', (
    tester,
  ) async {
    await pumpApp(tester, finishSpatialSteps);

    await tester.tap(find.byKey(const ValueKey('step-a')));
    await tester.pumpAndSettle();
    expect(pulses(tester, ActivityIds.meet), isTrue);
    expect(
      find.descendant(of: card(ActivityIds.trace), matching: find.byIcon(Icons.lock_rounded)),
      findsOne,
    );

    await tester.tap(card(ActivityIds.trace));
    await tester.pumpAndSettle();
    expect(find.byType(StepScreen), findsOneWidget);
    expect(player.spoken.last, 'step locked');

    await tester.tap(card(ActivityIds.meet));
    await tester.pumpAndSettle();
    expect(tester.widget<ActivityScreen>(find.byType(ActivityScreen)).activityId, ActivityIds.meet);
  });

  testWidgets('the arrow only shows once every game of the step was played', (tester) async {
    await pumpApp(tester, (data) {
      finishSpatialSteps(data);
      data.progress.markPlayed((stepId: 'a', activityId: ActivityIds.meet));
    });

    await tester.tap(find.byKey(const ValueKey('step-a')));
    await tester.pumpAndSettle();

    expect(find.byKey(StepScreen.nextKey), findsNothing);
  });
}
