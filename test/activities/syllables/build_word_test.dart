import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_context.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/common/widgets/letter_glyph.dart';
import 'package:lee_con_leo/activities/syllables/build_word_activity.dart';
import 'package:lee_con_leo/activities/syllables/build_word_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/buildable_words.dart';
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
    _word('mapa', ['ma', 'pa']),
    _word('puma', ['pu', 'ma']),
    _word('mimo', ['mi', 'mo']),
    _word('humo', ['hu', 'mo'], sounds: ['u', 'mo']),
    _word('ola', ['o', 'la']),
    _word('pipa', ['pi', 'pa'], pictured: false),
  ],
  stages: const [
    PathStage(
      stage: 4,
      name: 'bosque',
      steps: [
        PathStep(id: 'o', sounds: ['o'], activities: []),
        PathStep(id: 'ma', sounds: ['ma', 'me', 'mi', 'mo', 'mu'], activities: []),
        PathStep(
          id: 'pa',
          sounds: ['pa', 'pe', 'pi', 'po', 'pu'],
          activities: [ActivityIds.buildWord],
        ),
      ],
    ),
  ],
  prompts: PromptLibrary({
    ...testPrompts.phrases,
    'syllables.build_word.intro': ['intro'],
    'syllables.build_word.mapa': ['build mapa'],
    'syllables.build_word.puma': ['build puma'],
  }),
);

void main() {
  final step = _content.stepById('pa')!;

  test('only pictured words spelled with known syllables, including the new ones, are built', () {
    expect(BuildableWords.of(_content, step).map((word) => word.text), ['mapa', 'puma']);
  });

  test('each round offers the word syllables and two more from the family', () {
    final items = const BuildWordActivity().buildItems(
      ActivityContext(content: _content, step: step, random: Random(3)),
    );

    expect(items, hasLength(3));
    for (final item in items.cast<BuildWordItem>()) {
      expect(item.options, hasLength(item.syllables.length + 2));
      expect(item.options, containsAll(item.syllables));
      final extra = item.options.where((tile) => !item.syllables.contains(tile));
      expect(extra.every(step.sounds.contains), isTrue);
      expect(item.optionNames[item.target]!.clip, 'words/${item.target}.m4a');
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
              activityId: ActivityIds.buildWord,
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

    Map<int, String> tiles(WidgetTester tester) => {
      for (var i = 0; i < 4; i++)
        if (tester.any(find.byKey(ValueKey('tile-$i'))))
          i: tester
              .widget<LetterGlyph>(
                find.descendant(
                  of: find.byKey(ValueKey('tile-$i')),
                  matching: find.byType(LetterGlyph),
                ),
              )
              .text,
    };

    int tileOf(WidgetTester tester, String syllable) =>
        tiles(tester).entries.firstWhere((tile) => tile.value == syllable).key;

    testWidgets('placing the syllables in order builds each word', (tester) async {
      await play(tester);

      for (var round = 0; round < 3; round++) {
        final word = _content.wordByText(asked())!;
        for (final syllable in word.syllables) {
          await tester.tap(find.byKey(ValueKey('tile-${tileOf(tester, syllable)}')));
          await tester.pump();
        }
        expect(player.utterances.last.lines.first.clip, 'words/${word.text}.m4a');
        await tester.pumpAndSettle(const Duration(milliseconds: 20));
      }

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.every((event) => event.isCorrect), isTrue);
    });

    testWidgets('a tile dragged onto the slots fills the next one', (tester) async {
      await play(tester);
      final first = _content.wordByText(asked())!.syllables.first;

      await tester.drag(
        find.byKey(ValueKey('tile-${tileOf(tester, first)}')),
        tester.getCenter(find.byKey(BuildWordView.slotsKey)) -
            tester.getCenter(find.byKey(ValueKey('tile-${tileOf(tester, first)}'))),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('slot-0')),
          matching: find.widgetWithText(LetterGlyph, first),
        ),
        findsOne,
      );
      expect(tiles(tester).values, isNot(contains(first)));
    });

    testWidgets('Leo says a wrong syllable before asking again', (tester) async {
      await play(tester);
      final word = _content.wordByText(asked())!;
      final wrong = tiles(tester).values.firstWhere((tile) => !word.syllables.contains(tile));

      await tester.tap(find.byKey(ValueKey('tile-${tileOf(tester, wrong)}')));
      await tester.pump();

      expect(player.utterances.last.lines.first.clip, 'sounds/syllable.$wrong.m4a');
      expect(player.spoken.last, endsWith('build ${word.text}'));
      expect(log.events.single.answer, wrong);
    });
  });
}
