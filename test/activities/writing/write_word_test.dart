import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_context.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/writing/word_model.dart';
import 'package:lee_con_leo/activities/writing/write_word_activity.dart';
import 'package:lee_con_leo/activities/writing/write_word_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/models/word.dart';
import 'package:lee_con_leo/core/content/writable_words.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';

import '../../fakes/recording_prompt_player.dart';
import '../../fakes/test_content.dart';

Word _word(String text, List<String> syllables, {List<String>? sounds, bool pictured = true}) =>
    Word(
      text: text,
      syllables: syllables,
      sounds: sounds ?? syllables,
      image: pictured ? 'words/$text.svg' : null,
      audio: pictured ? 'words/$text.m4a' : null,
    );

final _content = ContentBundle(
  words: [
    _word('mamá', ['ma', 'má'], sounds: ['ma', 'ma']),
    _word('mapa', ['ma', 'pa']),
    _word('humo', ['hu', 'mo'], sounds: ['u', 'mo']),
    _word('mimo', ['mi', 'mo'], pictured: false),
    _word('lupa', ['lu', 'pa']),
  ],
  stages: const [
    PathStage(
      stage: 4,
      name: 'bosque',
      steps: [
        PathStep(id: 'ma', sounds: ['ma', 'me', 'mi', 'mo', 'mu'], activities: []),
        PathStep(id: 'pa', sounds: ['pa', 'pe', 'pi', 'po', 'pu'], activities: []),
        PathStep(id: 'la', sounds: ['la', 'le', 'li', 'lo', 'lu'], activities: []),
      ],
    ),
  ],
  prompts: PromptLibrary({
    ...testPrompts.phrases,
    'writing.word.intro': ['intro'],
    'writing.word.ask': ['write'],
  }),
);

void main() {
  test('words to write use only syllables learned so far, as they are said', () {
    expect(WritableWords.upTo(_content, _content.stepById('ma')!).map((w) => w.text), ['mamá']);
    expect(WritableWords.upTo(_content, _content.stepById('pa')!).map((w) => w.text), [
      'mamá',
      'mapa',
    ]);
  });

  test('each round asks a word aloud and logs apart from the path steps', () {
    final items = const WriteWordActivity().buildItems(
      ActivityContext(content: _content, step: _content.stepById('la')!, random: Random(1)),
    );

    expect(items, hasLength(3));
    for (final item in items.cast<WriteWordItem>()) {
      expect(item.stepId, WriteWordActivity.stepId);
      expect(item.promptTail!.clip, 'words/${item.target}.m4a');
      expect(item.image, 'words/${item.target}.svg');
    }
  });

  group('game', () {
    late RecordingPromptPlayer player;
    late InMemoryEventLog log;

    Future<void> play(WidgetTester tester) async {
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
              stepId: 'pa',
              activityId: ActivityIds.writeWord,
              celebrationDuration: const Duration(milliseconds: 10),
              random: Random(2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start')));
      await tester.pumpAndSettle();
    }

    String asked() => player.spoken.last.split(' ').last;

    Future<void> done(WidgetTester tester) async {
      await tester.tap(find.byKey(WriteWordView.doneKey));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }

    Future<void> scribble(WidgetTester tester) async {
      final canvas = tester.getRect(find.byKey(WriteWordView.canvasKey));
      await tester.dragFrom(canvas.topLeft + const Offset(20, 20), const Offset(200, 0));
      await tester.pump();
    }

    Future<void> writeOver(WidgetTester tester, String word) async {
      final canvas = tester.getRect(find.byKey(WriteWordView.canvasKey));
      final model = (await tester.runAsync(() => WordModel(word, canvas.size).points()))!;
      for (var i = 0; i < model.length; i += 4) {
        final gesture = await tester.startGesture(canvas.topLeft + Offset(model[i].x, model[i].y));
        await gesture.up();
      }
      await tester.pump();
    }

    testWidgets('writing over the word earns stars and moves on', (tester) async {
      await play(tester);
      final word = asked();

      await writeOver(tester, word);
      await done(tester);

      expect(find.byKey(const ValueKey('write-stars-3')), findsOneWidget);
      expect(log.events.single.isCorrect, isTrue);
      expect(log.events.single.stepId, WriteWordActivity.stepId);
      expect(player.utterances.last.lines.first.clip, 'words/$word.m4a');
    });

    testWidgets('a scribble is wiped for another try, and after two Leo lets it pass', (
      tester,
    ) async {
      await play(tester);

      await scribble(tester);
      await done(tester);
      expect(player.spoken.last, contains('retry'));
      expect(log.events.last.isCorrect, isFalse);

      await scribble(tester);
      await done(tester);
      expect(player.spoken.last, contains('hint'));

      await scribble(tester);
      await done(tester);
      expect(find.byKey(const ValueKey('write-stars-1')), findsOneWidget);
      expect(log.events.last.isCorrect, isTrue);
    });

    testWidgets('the clear button wipes the ink', (tester) async {
      await play(tester);
      await scribble(tester);

      await tester.tap(find.byKey(WriteWordView.clearKey));
      await tester.pump();
      await done(tester);

      expect(log.events, isEmpty);
    });
  });
}
