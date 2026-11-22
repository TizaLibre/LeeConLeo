import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/common/widgets/letter_glyph.dart';
import 'package:lee_con_leo/activities/letters/find_activity.dart';
import 'package:lee_con_leo/activities/letters/trace_path.dart';
import 'package:lee_con_leo/activities/letters/trace_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';

import '../../fakes/recording_prompt_player.dart';
import '../../fakes/test_content.dart';

const _sounds = ['ma', 'me', 'mi'];

const _stroke = [
  [Point(0.0, 0.0), Point(50.0, 0.0), Point(100.0, 30.0)],
];

final _content = ContentBundle(
  words: testContent.words,
  stages: const [
    PathStage(
      stage: 4,
      name: 'bosque',
      steps: [
        PathStep(
          id: 'ma',
          sounds: _sounds,
          activities: [
            ActivityIds.syllableMeet,
            ActivityIds.syllableTrace,
            ActivityIds.syllableFind,
          ],
        ),
      ],
    ),
  ],
  prompts: PromptLibrary({
    ...testPrompts.phrases,
    'syllables.meet.intro': ['intro'],
    'syllables.trace.intro': ['intro'],
    'syllables.find.intro': ['intro'],
    for (final sound in _sounds) ...{
      'syllables.meet.$sound': ['meet $sound'],
      'syllables.meet.$sound.choose': ['choose $sound'],
      'syllables.trace.$sound': ['trace $sound'],
      'syllables.find.$sound': ['find $sound'],
    },
  }),
  syllables: {for (final sound in _sounds) sound: _stroke},
);

void main() {
  late RecordingPromptPlayer player;
  late InMemoryEventLog log;

  Future<void> play(WidgetTester tester, String activityId) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    player = RecordingPromptPlayer();
    log = InMemoryEventLog();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => _content),
          promptPlayerProvider.overrideWithValue(player),
          eventLogProvider.overrideWithValue(log),
        ],
        child: MaterialApp(
          home: ActivityScreen(
            stepId: 'ma',
            activityId: activityId,
            celebrationDuration: const Duration(milliseconds: 10),
            random: Random(5),
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

  String asked() => player.spoken.last.split(' ').last;

  group(ActivityIds.syllableMeet, () {
    testWidgets('Leo joins each letter with a vowel in order, then asks for them mixed', (
      tester,
    ) async {
      await play(tester, ActivityIds.syllableMeet);

      for (final sound in _sounds) {
        expect(player.spoken.last, 'meet $sound');
        final parts = find.byKey(const ValueKey('syllable-parts'));
        expect(
          find.descendant(of: parts, matching: find.widgetWithText(LetterGlyph, 'm')),
          findsOne,
        );
        expect(
          find.descendant(of: parts, matching: find.widgetWithText(LetterGlyph, sound[1])),
          findsOne,
        );
        await tester.tap(find.byKey(ValueKey('choice-$sound')));
        await celebrate(tester);
      }

      for (var round = 0; round < 3; round++) {
        expect(player.spoken.last, startsWith('choose'));
        expect(find.byKey(const ValueKey('syllable-parts')), findsNothing);
        await tester.tap(find.byKey(ValueKey('choice-${asked()}')));
        await celebrate(tester);
      }

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.every((event) => event.isCorrect), isTrue);
    });

    testWidgets('Leo says a wrong syllable before asking again', (tester) async {
      await play(tester, ActivityIds.syllableMeet);
      for (final sound in _sounds) {
        await tester.tap(find.byKey(ValueKey('choice-$sound')));
        await celebrate(tester);
      }
      final target = asked();
      final wrong = _sounds.firstWhere(
        (sound) => sound != target && tester.any(find.byKey(ValueKey('choice-$sound'))),
      );

      await tester.tap(find.byKey(ValueKey('choice-$wrong')));
      await tester.pump();

      expect(player.utterances.last.lines.first.clip, 'sounds/syllable.$wrong.m4a');
      expect(player.spoken.last, endsWith('choose $target'));
    });
  });

  testWidgets('tracing three joined syllables earns the reward', (tester) async {
    await play(tester, ActivityIds.syllableTrace);

    for (var round = 0; round < 3; round++) {
      expect(player.spoken.last, startsWith('trace'));
      final canvas = tester.getRect(find.byKey(TraceView.canvasKey));
      final path = TracePath.fit(_stroke, width: canvas.width, height: canvas.height);
      final stroke = path.strokes.single;
      final gesture = await tester.startGesture(
        canvas.topLeft + Offset(stroke.first.x, stroke.first.y),
      );
      for (final point in stroke.skip(1)) {
        await gesture.moveTo(canvas.topLeft + Offset(point.x, point.y));
      }
      await gesture.up();
      await celebrate(tester);
    }

    expect(find.byKey(const ValueKey('reward')), findsOneWidget);
    expect(log.events.map((event) => event.target).toSet(), hasLength(3));
  });

  testWidgets('popping every bubble with the syllable, in either case, clears the board', (
    tester,
  ) async {
    await play(tester, ActivityIds.syllableFind);

    for (var round = 0; round < 3; round++) {
      final target = asked();
      final bubbles = [
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
      expect(bubbles.where((bubble) => FindActivity.isTarget(bubble, target)), hasLength(2));
      expect(bubbles.where((bubble) => !FindActivity.isTarget(bubble, target)), hasLength(4));
      for (final (index, bubble) in bubbles.indexed) {
        if (FindActivity.isTarget(bubble, target)) {
          await tester.tap(find.byKey(ValueKey('bubble-$index')));
          await tester.pump();
        }
      }
      await celebrate(tester);
    }

    expect(find.byKey(const ValueKey('reward')), findsOneWidget);
    expect(log.events.every((event) => event.isCorrect), isTrue);
  });
}
