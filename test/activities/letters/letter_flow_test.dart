import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/common/widgets/demo_overlay.dart';
import 'package:lee_con_leo/activities/common/widgets/choice_button.dart';
import 'package:lee_con_leo/activities/common/widgets/letter_glyph.dart';
import 'package:lee_con_leo/activities/letters/find_activity.dart';
import 'package:lee_con_leo/activities/letters/trace_path.dart';
import 'package:lee_con_leo/activities/letters/trace_view.dart';
import 'package:lee_con_leo/app/app_router.dart';
import 'package:lee_con_leo/app/startup_providers.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/map/step_screen.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/letter_shape.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';
import 'package:lee_con_leo/core/progress/progress_providers.dart';

import '../../fakes/recording_prompt_player.dart';
import '../../fakes/test_content.dart';

void main() {
  late RecordingPromptPlayer player;
  late InMemoryEventLog log;

  List<Override> overrides() {
    player = RecordingPromptPlayer();
    log = InMemoryEventLog();
    return [
      singleProfile(),
      contentProvider.overrideWith((ref) async => testContent),
      minimumSplashProvider.overrideWithValue(Duration.zero),
      promptPlayerProvider.overrideWithValue(player),
      eventLogProvider.overrideWithValue(log),
    ];
  }

  void disableAnimations(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  Future<void> play(WidgetTester tester, String activityId) async {
    disableAnimations(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          home: ActivityScreen(
            stepId: 'a',
            activityId: activityId,
            celebrationDuration: const Duration(milliseconds: 10),
            random: Random(3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();
  }

  Future<void> celebrate(WidgetTester tester) =>
      tester.pumpAndSettle(const Duration(milliseconds: 20));

  Set<String> completedSteps(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ActivityScreen)),
  ).read(completedStepsProvider);

  group(ActivityIds.meet, () {
    const choices = {
      'meet a show upper show lower': 'upper',
      'say upper': 'upper',
      'say lower': 'lower',
    };

    testWidgets('Leo shows the letter with its word, then both cases', (tester) async {
      await play(tester, ActivityIds.meet);
      expect(player.spoken.last, 'meet a show upper show lower');
      expect(find.widgetWithText(LetterGlyph, 'A'), findsOneWidget);
      expect(find.widgetWithText(LetterGlyph, 'a'), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(ValueKey('choice-${choices[player.spoken.last]}')));
        await celebrate(tester);
      }

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.first.target, 'letter');
      expect(log.events.skip(1).map((event) => event.target).toSet(), {'upper', 'lower'});
    });

    testWidgets('each case lights up while Leo names it', (tester) async {
      await play(tester, ActivityIds.meet);
      bool lit(String option) =>
          tester.widget<ChoiceButton>(find.byKey(ValueKey('choice-$option'))).isHighlighted;
      final intro = player.utterances.last;

      intro.onLine?.call(intro.lines[1]);
      await tester.pump();
      expect(lit('upper'), isTrue);
      expect(lit('lower'), isFalse);

      intro.onLine?.call(intro.lines[2]);
      await tester.pump();
      expect(lit('upper'), isFalse);
      expect(lit('lower'), isTrue);
    });

    testWidgets('picking the wrong case asks to try again', (tester) async {
      await play(tester, ActivityIds.meet);
      await tester.tap(find.byKey(const ValueKey('choice-lower')));
      await celebrate(tester);

      final target = choices[player.spoken.last]!;
      await tester.tap(find.byKey(ValueKey('choice-${target == 'upper' ? 'lower' : 'upper'}')));
      await tester.pump();

      expect(player.spoken.last, startsWith('retry'));
      expect(find.byKey(const ValueKey('leo-thinking')), findsOneWidget);
    });
  });

  group(ActivityIds.trace, () {
    Future<void> trace(WidgetTester tester, List<Stroke> shape, {int? strokes}) async {
      final canvas = tester.getRect(find.byKey(TraceView.canvasKey));
      final path = TracePath.fit(shape, width: canvas.width, height: canvas.height);
      for (final stroke in path.strokes.take(strokes ?? path.strokes.length)) {
        final gesture = await tester.startGesture(canvas.topLeft + _offset(stroke.first));
        for (final point in stroke.skip(1)) {
          await gesture.moveTo(canvas.topLeft + _offset(point));
        }
        await gesture.up();
        await tester.pump();
      }
    }

    testWidgets('tracing the lowercase and then the uppercase letter earns the reward', (
      tester,
    ) async {
      await play(tester, ActivityIds.trace);
      expect(player.spoken.last, 'trace a');

      await trace(tester, testLetter.lower);
      expect(find.byKey(const ValueKey('leo-cheering')), findsOneWidget);
      await celebrate(tester);

      expect(player.spoken.last, 'trace A');
      await trace(tester, testLetter.upper);
      await celebrate(tester);

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.map((event) => event.target), ['a', 'A']);
      expect(completedSteps(tester), isNot(contains('a')));
    });

    testWidgets('a hand traces the first stroke until the child starts', (tester) async {
      await play(tester, ActivityIds.trace);
      expect(find.byKey(DemoOverlay.handKey), findsOneWidget);

      await trace(tester, testLetter.lower, strokes: 1);
      expect(find.byKey(DemoOverlay.handKey), findsNothing);
    });

    testWidgets('a letter is not done until every stroke is traced', (tester) async {
      await play(tester, ActivityIds.trace);

      await trace(tester, testLetter.lower, strokes: 1);

      expect(find.byKey(const ValueKey('leo-cheering')), findsNothing);
      expect(log.events, isEmpty);
    });

    testWidgets('dragging where the stroke does not start draws nothing', (tester) async {
      await play(tester, ActivityIds.trace);
      final reversed = [for (final stroke in testLetter.lower) stroke.reversed.toList()];

      await trace(tester, reversed, strokes: 1);

      expect(log.events, isEmpty);
    });
  });

  group(ActivityIds.find, () {
    List<String> bubbles(WidgetTester tester) => [
      for (var i = 0; tester.any(find.byKey(ValueKey('bubble-$i'))); i++)
        tester
            .widget<LetterGlyph>(
              find.descendant(
                of: find.byKey(ValueKey('bubble-$i')),
                matching: find.byType(LetterGlyph),
              ),
            )
            .text,
    ];

    testWidgets('popping every bubble with the letter clears the board', (tester) async {
      await play(tester, ActivityIds.find);
      expect(player.spoken.last, 'find a');

      for (var round = 0; round < 3; round++) {
        final letters = bubbles(tester);
        expect(letters.where((letter) => FindActivity.isTarget(letter, 'a')), hasLength(3));
        expect(letters, contains('a'));
        for (final (index, letter) in letters.indexed) {
          if (FindActivity.isTarget(letter, 'a')) {
            await tester.tap(find.byKey(ValueKey('bubble-$index')));
            await tester.pump();
          }
        }
        await celebrate(tester);
      }

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.every((event) => event.isCorrect), isTrue);
      expect(completedSteps(tester), isNot(contains('a')));
    });

    testWidgets('popping another letter asks to try again and then shows a hint', (tester) async {
      await play(tester, ActivityIds.find);
      final wrong = bubbles(tester).indexWhere((letter) => !FindActivity.isTarget(letter, 'a'));

      await tester.tap(find.byKey(ValueKey('bubble-$wrong')));
      await tester.pump();
      expect(player.spoken.last, 'retry find a');

      await tester.tap(find.byKey(ValueKey('bubble-$wrong')));
      await tester.pump();
      expect(player.spoken.last, 'hint find a');
      expect(log.events.map((event) => event.isCorrect), [false, false]);
    });
  });

  testWidgets('finishing one letter game goes back to the step with a star on it', (tester) async {
    disableAnimations(tester);
    final router = createAppRouter()..go('/step/a');
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('game-${ActivityIds.meet}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start')));
    await tester.pumpAndSettle();

    const choices = {
      'meet a show upper show lower': 'upper',
      'say upper': 'upper',
      'say lower': 'lower',
    };
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('choice-${choices[player.spoken.last]}')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.tap(find.byKey(const ValueKey('done')));
    await tester.pumpAndSettle();

    expect(find.byType(StepScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('game-${ActivityIds.meet}')),
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsOneWidget,
    );
    expect(
      ProviderScope.containerOf(
        tester.element(find.byType(StepScreen)),
      ).read(completedStepsProvider),
      isEmpty,
    );

    await tester.tap(find.byKey(const ValueKey('game-${ActivityIds.trace}')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ActivityScreen>(find.byType(ActivityScreen)).activityId,
      ActivityIds.trace,
    );
  });
}

Offset _offset(Point<double> point) => Offset(point.x, point.y);
