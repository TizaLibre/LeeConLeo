import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/common/widgets/reward_view.dart';
import 'package:lee_con_leo/app/app_router.dart';
import 'package:lee_con_leo/app/startup_providers.dart';
import 'package:lee_con_leo/app/widgets/sticker_card.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/word.dart';
import 'package:lee_con_leo/core/profiles/in_memory_profile_store.dart';
import 'package:lee_con_leo/core/profiles/profile_providers.dart';
import 'package:lee_con_leo/core/profiles/profile_store.dart';
import 'package:lee_con_leo/core/progress/review.dart';
import 'package:lee_con_leo/core/progress/stickers.dart';
import 'package:lee_con_leo/map/home_screen.dart';
import 'package:lee_con_leo/map/review_button.dart';
import 'package:lee_con_leo/map/sticker_album.dart';

import '../fakes/item_events.dart';
import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  group('review', () {
    test('picks only mastered steps other than the one about to be played', () {
      final events = [
        ...firstTries('a', correct: 10),
        ...firstTries('e', correct: 10),
        ...firstTries('i', correct: 3),
      ];
      final steps = Review.pickSteps(events, Random(1), except: 'e');
      expect(steps, hasLength(Review.rounds));
      expect(steps, everyElement('a'));
      expect(Review.pickSteps(firstTries('i', correct: 3), Random(1)), isEmpty);
    });

    test('steps with recent mistakes come back more often', () {
      final events = [...firstTries('a', correct: 10), ...firstTries('e', correct: 8, wrong: 2)];
      final random = Random(7);
      final picks = [for (var i = 0; i < 200; i++) ...Review.pickSteps(events, random)];
      expect(picks.where((step) => step == 'e').length, greaterThan(picks.length * 0.65));
    });
  });

  test('a sticker is the step icon, its key word, or a picture starting with its syllable', () {
    Word pictured(String text, String first) =>
        Word(text: text, syllables: [first], sounds: [first], image: 'words/$text.svg');
    final content = ContentBundle(
      words: [pictured('mesa', 'me'), pictured('mano', 'ma'), pictured('mapa', 'ma')],
      stages: const [
        PathStage(
          stage: 4,
          name: 'bosque',
          steps: [
            PathStep(id: 'up-down', icon: 'steps/up_down.svg', activities: []),
            PathStep(id: 'm', grapheme: 'm', word: 'mesa', activities: []),
            PathStep(id: 'ma', sounds: ['ma', 'me'], activities: []),
            PathStep(id: 'empty', activities: []),
          ],
        ),
      ],
      prompts: testPrompts,
    );
    String? sticker(String step) => Stickers.of(content, content.stepById(step)!);

    expect(sticker('up-down'), 'steps/up_down.svg');
    expect(sticker('m'), 'words/mesa.svg');
    expect(sticker('ma'), 'words/mano.svg');
    expect(sticker('empty'), isNull);
  });

  group('app', () {
    late RecordingPromptPlayer player;
    late ProfileData data;

    Future<void> pumpApp(WidgetTester tester, void Function(ProfileData data) seed) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      player = RecordingPromptPlayer();
      final store = InMemoryProfileStore(const [testProfile]);
      await tester.runAsync(() async => data = await store.open(testProfile));
      seed(data);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentProvider.overrideWith((ref) async => testContent),
            minimumSplashProvider.overrideWithValue(Duration.zero),
            promptPlayerProvider.overrideWithValue(player),
            profileStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp.router(routerConfig: createAppRouter()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> answerAll(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('start')));
      await tester.pumpAndSettle();
      while (!tester.any(find.byKey(const ValueKey('reward')))) {
        final target = player.spoken.last.replaceFirst('say ', '');
        await tester.tap(find.byKey(ValueKey('choice-$target')));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    }

    ActivityScreen screen(WidgetTester tester) =>
        tester.widget<ActivityScreen>(find.byType(ActivityScreen));

    testWidgets('a review is only played when the child taps its button in the album', (
      tester,
    ) async {
      await pumpApp(tester, (data) {
        data.progress.markCompleted('up-down');
        firstTries('up-down', correct: 10).forEach(data.events.record);
      });

      await tester.tap(find.byKey(const ValueKey('step-left-right')));
      await tester.pumpAndSettle();
      expect(screen(tester).activityId, 'spatial.left_right');
      await tester.tap(find.byKey(const ValueKey('home')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeScreen.albumKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ReviewButton.buttonKey));
      await tester.pumpAndSettle();
      expect(player.spoken.last, 'review intro');
      final before = data.events.events.length;
      await answerAll(tester);
      final reviewed = data.events.events.skip(before);
      expect(reviewed, hasLength(Review.rounds));
      expect(reviewed.map((event) => (event.stepId, event.activityId)).toSet(), {
        ('up-down', 'spatial.up_down'),
      });

      await tester.tap(find.byKey(RewardView.againKey));
      await tester.pumpAndSettle();
      expect(screen(tester).activityId, 'review');
      expect(find.byKey(const ValueKey('reward')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('home')));
      await tester.pumpAndSettle();
      expect(find.byType(PathMap), findsOneWidget);
    });

    testWidgets('without a mastered step there is nothing to review', (tester) async {
      await pumpApp(tester, (data) => data.progress.markCompleted('up-down'));
      await tester.tap(find.byKey(HomeScreen.albumKey));
      await tester.pumpAndSettle();

      expect(find.byType(StickerAlbum), findsOneWidget);
      expect(find.byKey(ReviewButton.buttonKey), findsNothing);
    });

    testWidgets('mastering a step earns its sticker, which shows in the album', (tester) async {
      await pumpApp(tester, (data) {
        firstTries('up-down', correct: 9, sessions: ['earlier']).forEach(data.events.record);
      });

      await tester.tap(find.byKey(const ValueKey('step-up-down')));
      await tester.pumpAndSettle();
      await answerAll(tester);

      expect(find.byKey(RewardView.newStickerKey), findsOneWidget);
      expect(player.spoken.last, 'new sticker');

      await tester.tap(find.byKey(const ValueKey('done')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(HomeScreen.albumKey));
      await tester.pumpAndSettle();
      expect(find.byType(StickerAlbum), findsOneWidget);
      expect(player.spoken.last, 'stickers intro');
      bool earned(String step) =>
          tester.widget<StickerCard>(find.byKey(ValueKey('sticker-$step'))).isEarned;
      expect(earned('up-down'), isTrue);
      expect(earned('a'), isFalse);
    });
  });
}
