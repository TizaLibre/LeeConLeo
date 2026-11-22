import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_context.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/common/widgets/letter_glyph.dart';
import 'package:lee_con_leo/activities/syllables/blend_activity.dart';
import 'package:lee_con_leo/activities/syllables/blend_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/models/word.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';

import '../../fakes/recording_prompt_player.dart';
import '../../fakes/test_content.dart';

Word _word(String text, List<String> syllables) => Word(
  text: text,
  syllables: syllables,
  sounds: syllables,
  image: 'words/mapa.svg',
  audio: 'words/$text.m4a',
);

final _words = [
  _word('mapa', ['ma', 'pa']),
  _word('puma', ['pu', 'ma']),
  _word('oso', ['o', 'so']),
  _word('uva', ['u', 'ba']),
];

final _content = ContentBundle(
  words: _words,
  stages: const [
    PathStage(
      stage: 4,
      name: 'bosque',
      steps: [
        PathStep(id: 'ma', sounds: ['ma', 'me', 'mi', 'mo', 'mu'], activities: []),
        PathStep(id: 'pa', sounds: ['pa', 'pe', 'pi', 'po', 'pu'], activities: [ActivityIds.blend]),
      ],
    ),
  ],
  prompts: PromptLibrary({
    ...testPrompts.phrases,
    'syllables.blend.intro': ['intro'],
    'syllables.blend.ask': ['blend'],
    for (final word in _words) 'listening.clap.${word.text}': [word.syllables.join('-')],
  }),
);

void main() {
  test('each round says a known word in pieces among three pictures', () {
    final items = const BlendActivity()
        .buildItems(
          ActivityContext(content: _content, step: _content.stepById('pa')!, random: Random(2)),
        )
        .cast<BlendItem>();

    expect(items, hasLength(3));
    for (final item in items) {
      expect(['mapa', 'puma'], contains(item.target));
      expect(item.options, hasLength(3));
      expect(item.options.toSet(), hasLength(3));
      expect(item.options, contains(item.target));
      expect(item.images.keys, unorderedEquals(item.options));
      final word = _words.firstWhere((word) => word.text == item.target);
      expect(item.syllables, word.syllables);
      expect(item.promptTail!.text, word.syllables.join('-'));
      expect(item.optionNames[item.target]!.clip, word.audio);
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
              activityId: ActivityIds.blend,
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

    String asked() =>
        _words.firstWhere((word) => player.spoken.last.endsWith(word.syllables.join('-'))).text;

    testWidgets('picking the picture of the joined pieces names it and moves on', (tester) async {
      await play(tester);

      for (var round = 0; round < 3; round++) {
        final word = asked();
        expect(player.spoken.last, startsWith('blend'));
        for (final syllable in _words.firstWhere((other) => other.text == word).syllables) {
          expect(
            find.descendant(
              of: find.byKey(BlendView.syllablesKey),
              matching: find.widgetWithText(LetterGlyph, syllable),
            ),
            findsOneWidget,
          );
        }
        await tester.tap(find.byKey(ValueKey('choice-$word')));
        await tester.pump();
        expect(player.utterances.last.lines.first.clip, 'words/$word.m4a');
        await tester.pumpAndSettle(const Duration(milliseconds: 20));
      }

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.every((event) => event.isCorrect), isTrue);
    });

    testWidgets('a wrong picture is named before the pieces are said again', (tester) async {
      await play(tester);
      final word = asked();
      final wrong = _words.firstWhere(
        (other) => other.text != word && tester.any(find.byKey(ValueKey('choice-${other.text}'))),
      );

      await tester.tap(find.byKey(ValueKey('choice-${wrong.text}')));
      await tester.pump();

      final lines = player.utterances.last.lines;
      expect(lines.first.clip, wrong.audio);
      expect(lines.last.text, _words.firstWhere((other) => other.text == word).syllables.join('-'));
    });
  });
}
