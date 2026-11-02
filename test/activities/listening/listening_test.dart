import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_context.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/listening/clap_activity.dart';
import 'package:lee_con_leo/activities/listening/clap_view.dart';
import 'package:lee_con_leo/activities/sounds/picture_sound_activity.dart';
import 'package:lee_con_leo/activities/sounds/picture_sound_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/audio/sound_effects.dart';
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
import '../../fakes/recording_sound_effects.dart';
import '../../fakes/test_content.dart';

Word _word(String text, List<String> syllables) => Word(
  text: text,
  syllables: syllables,
  sounds: syllables,
  image: 'words/oso.svg',
  audio: 'words/$text.m4a',
);

final _words = [
  _word('oso', ['o', 'so']),
  _word('ola', ['o', 'la']),
  _word('ojota', ['o', 'jo', 'ta']),
  _word('oveja', ['o', 've', 'ja']),
  _word('sol', ['sol']),
  _word('mariposa', ['ma', 'ri', 'po', 'sa']),
  _word('abeja', ['a', 'be', 'ja']),
  _word('uva', ['u', 'ba']),
];

final _content = ContentBundle(
  words: _words,
  stages: const [
    PathStage(
      stage: 2,
      name: 'vocales',
      steps: [
        PathStep(
          id: 'o',
          grapheme: 'o',
          sounds: ['o'],
          activities: [ActivityIds.clap, ActivityIds.sameSound],
        ),
      ],
    ),
  ],
  prompts: PromptLibrary(
    {
      ...testPrompts.phrases,
      'listening.clap.intro': ['intro'],
      'listening.clap.ask': ['clap'],
      'listening.clap.show': ['look'],
      'listening.clap.your_turn': ['your turn'],
      'listening.same_sound.intro': ['intro'],
      'syllables.starts_with.o': ['starts o'],
      for (final word in _words) 'listening.clap.${word.text}': [word.syllables.join('-')],
    },
    beats: {
      for (final word in _words)
        'listening.clap.${word.text}.0': [for (var i = 0; i < word.syllables.length; i++) i * 0.5],
    },
  ),
);

String _split(String text) => _words.firstWhere((word) => word.text == text).syllables.join('-');

void main() {
  final step = _content.stepById('o')!;

  test('clap rounds use the step words first and vary the number of syllables', () {
    final items = const ClapActivity()
        .buildItems(ActivityContext(content: _content, step: step, random: Random(3)))
        .cast<ClapItem>();

    expect(items, hasLength(4));
    final words = [for (final item in items) item.promptTail!.text];
    expect(words.every((word) => word.startsWith('o')), isTrue);
    expect(items.map((item) => item.claps).toSet(), {2, 3});
    for (final item in items) {
      final word = _words.firstWhere((word) => word.text == item.promptTail!.text);
      expect(item.claps, word.syllables.length);
      expect(item.promptTail!.clip, word.audio);
      expect(item.optionNames[item.target]!.text, word.syllables.join('-'));
    }
  });

  group('game', () {
    late RecordingPromptPlayer player;
    late InMemoryEventLog log;
    late RecordingSoundEffects effects;

    Future<void> play(WidgetTester tester, String activityId) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      player = RecordingPromptPlayer();
      log = InMemoryEventLog();
      effects = RecordingSoundEffects();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentProvider.overrideWith((ref) async => _content),
            promptPlayerProvider.overrideWithValue(player),
            eventLogProvider.overrideWithValue(log),
            soundEffectsProvider.overrideWithValue(effects),
          ],
          child: MaterialApp(
            home: ActivityScreen(
              stepId: 'o',
              activityId: activityId,
              celebrationDuration: const Duration(milliseconds: 10),
              random: Random(4),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start')));
      await tester.pumpAndSettle();
    }

    String askedWord() => player.utterances.last.lines[1].text;

    Future<void> clap(WidgetTester tester, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(find.byKey(ClapView.clapKey));
        await tester.pump();
      }
      await tester.tap(find.byKey(ClapView.doneKey));
      await tester.pump();
    }

    int syllablesOf(String text) => _words.firstWhere((word) => word.text == text).syllables.length;

    testWidgets('clapping once per syllable says the word split up and moves on', (tester) async {
      await play(tester, ActivityIds.clap);

      for (var round = 0; round < 4; round++) {
        final word = askedWord();
        expect(player.spoken.last, startsWith('clap $word'));
        await clap(tester, syllablesOf(word));
        expect(
          player.utterances.last.lines.first.text,
          _words.firstWhere((other) => other.text == word).syllables.join('-'),
        );
        expect(player.spoken.last, endsWith('correct'));
        await tester.pumpAndSettle(const Duration(milliseconds: 20));
      }

      expect(find.byKey(const ValueKey('reward')), findsOneWidget);
      expect(log.events.every((event) => event.isCorrect), isTrue);
    });

    testWidgets('a wrong count clears the claps, asks again, and later hints the dots', (
      tester,
    ) async {
      await play(tester, ActivityIds.clap);
      final word = askedWord();
      final claps = syllablesOf(word);

      await clap(tester, claps + 1);
      expect(find.byKey(const ValueKey('clap-dot-0')), findsNothing);
      expect(player.spoken.last, 'retry clap $word');
      await tester.pump(const Duration(seconds: 3));

      await clap(tester, claps + 1);
      expect(find.byKey(ValueKey('clap-dot-${claps - 1}')), findsOneWidget);
      expect(find.byKey(ValueKey('clap-dot-$claps')), findsNothing);
    });

    testWidgets('on the first word Leo shows how, clapping silently on each syllable', (
      tester,
    ) async {
      await play(tester, ActivityIds.clap);
      final word = askedWord();
      final claps = syllablesOf(word);

      expect(player.spoken.last, 'clap $word look ${_split(word)} your turn');
      expect(effects.played, isEmpty);
      final example = player.utterances.last;
      example.onLine!(example.lines[3]);
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byKey(const ValueKey('leo-clapping')), findsOneWidget);
      await tester.pump(Duration(milliseconds: 500 * (claps - 1) + 10));
      expect(find.byKey(ValueKey('clap-dot-${claps - 1}')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(effects.played, isEmpty);
      expect(find.byKey(const ValueKey('leo-clapping')), findsNothing);
    });

    testWidgets('each tap on the hands sounds a clap', (tester) async {
      await play(tester, ActivityIds.clap);
      await tester.pump(const Duration(seconds: 3));
      effects.played.clear();

      await tester.tap(find.byKey(ClapView.clapKey));
      await tester.tap(find.byKey(ClapView.clapKey));

      expect(effects.played, [SoundEffects.clap, SoundEffects.clap]);
    });

    testWidgets('same sound asks like starts with but shows no letters', (tester) async {
      await play(tester, ActivityIds.sameSound);

      expect(player.spoken.last, 'starts o');
      expect(find.byKey(PictureSoundView.soundKey), findsNothing);
      final item = PictureSoundActivity.sameSound
          .buildItems(ActivityContext(content: _content, step: step, random: Random(1)))
          .first;
      expect(item.options, hasLength(PictureSoundActivity.choices));
    });
  });
}
