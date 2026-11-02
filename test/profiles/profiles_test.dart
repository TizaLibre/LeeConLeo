import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/app/app_router.dart';
import 'package:lee_con_leo/app/startup_providers.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/profiles/default_profile.dart';
import 'package:lee_con_leo/core/profiles/in_memory_profile_store.dart';
import 'package:lee_con_leo/core/profiles/profile.dart';
import 'package:lee_con_leo/core/profiles/profile_providers.dart';
import 'package:lee_con_leo/map/home_screen.dart';
import 'package:lee_con_leo/profiles/about_view.dart';
import 'package:lee_con_leo/profiles/adults_guide.dart';
import 'package:lee_con_leo/profiles/adults_screen.dart';
import 'package:lee_con_leo/profiles/parental_gate.dart';
import 'package:lee_con_leo/profiles/profile_edit_dialog.dart';
import 'package:lee_con_leo/profiles/profile_manager.dart';
import 'package:lee_con_leo/profiles/profile_picker.dart';
import 'package:lee_con_leo/profiles/profile_progress.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

const _beto = Profile(id: 2, nickname: 'Beto', avatar: 'words/pato.svg');

void main() {
  late RecordingPromptPlayer player;
  late InMemoryProfileStore store;

  Future<void> pumpApp(WidgetTester tester, List<Profile> profiles) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    player = RecordingPromptPlayer();
    store = InMemoryProfileStore(profiles);
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

  bool hasStar(WidgetTester tester, String stepId) => tester.any(
    find.descendant(
      of: find.byKey(ValueKey('step-$stepId')),
      matching: find.byIcon(Icons.star_rounded),
    ),
  );

  testWidgets('with no profile yet, a default one opens the map without an adult', (tester) async {
    await pumpApp(tester, const []);

    expect(find.byType(PathMap), findsOneWidget);
    expect((await store.all()).single.nickname, DefaultProfile.nickname);
  });

  testWidgets('a child picks their picture, plays as themselves, and can hand over', (
    tester,
  ) async {
    await pumpApp(tester, const [testProfile, _beto]);
    expect(player.spoken, ['profiles intro']);
    await (await store.open(testProfile)).progress.markCompleted('up-down');

    await tester.tap(find.byKey(const ValueKey('profile-1')));
    await tester.pumpAndSettle();
    expect(find.byType(PathMap), findsOneWidget);
    expect(hasStar(tester, 'up-down'), isTrue);

    await tester.tap(find.byKey(HomeScreen.switchProfileKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-2')));
    await tester.pumpAndSettle();
    expect(hasStar(tester, 'up-down'), isFalse);
  });

  testWidgets('a single profile goes straight to the map', (tester) async {
    await pumpApp(tester, const [testProfile]);

    expect(find.byType(PathMap), findsOneWidget);
    expect(find.byKey(HomeScreen.switchProfileKey), findsOneWidget);
  });

  group('adults', () {
    Future<void> openAdults(WidgetTester tester) async {
      await pumpApp(tester, const [testProfile, _beto]);
      await tester.tap(find.byKey(ProfilePicker.adultsKey));
      await tester.pumpAndSettle();
    }

    int gateAnswer(WidgetTester tester) {
      final question = tester.widget<Text>(find.byKey(ParentalGate.questionKey)).data!;
      final words = RegExp(r'es (\w+) más (\w+)').firstMatch(question)!;
      int value(String word) =>
          ParentalGate.numberWords.entries.firstWhere((entry) => entry.value == word).key;
      return value(words[1]!) + value(words[2]!);
    }

    Future<void> type(WidgetTester tester, int number) async {
      for (final digit in '$number'.split('')) {
        await tester.tap(find.byKey(ValueKey('digit-$digit')));
        await tester.pump();
      }
    }

    testWidgets('a wrong sum keeps the adult area closed', (tester) async {
      await openAdults(tester);
      await type(tester, gateAnswer(tester) == 10 ? 11 : 10);

      expect(find.byType(ProfileManager), findsNothing);
      expect(find.byType(ParentalGate), findsOneWidget);
    });

    Future<void> delete(WidgetTester tester, int id) async {
      await tester.tap(find.byKey(ValueKey('delete-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-delete')));
      await tester.pumpAndSettle();
    }

    testWidgets('an adult adds a profile, and removes it with its progress', (tester) async {
      await openAdults(tester);
      await type(tester, gateAnswer(tester));
      expect(find.byType(ProfileManager), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(ProfileManager.addKey),
        200,
        scrollable: find
            .descendant(of: find.byType(ProfileManager), matching: find.byType(Scrollable))
            .first,
      );
      await tester.enterText(find.byKey(ProfileManager.nicknameKey), 'Cami');
      await tester.tap(find.byKey(const ValueKey('avatar-words/pato.svg')));
      await tester.tap(find.byKey(ProfileManager.addKey));
      await tester.pumpAndSettle();
      final cami = (await store.all()).last;
      expect(cami.nickname, 'Cami');
      expect(cami.avatar, 'words/pato.svg');
      expect(find.text('Cami'), findsOneWidget);

      await delete(tester, cami.id);
      expect((await store.all()).map((profile) => profile.nickname), ['Ana', 'Beto']);

      await tester.tap(find.byKey(AdultsScreen.backKey));
      await tester.pumpAndSettle();
      expect(find.byType(ProfilePicker), findsOneWidget);
    });

    testWidgets('removing the last profile leaves a fresh default one', (tester) async {
      await openAdults(tester);
      await type(tester, gateAnswer(tester));

      await delete(tester, testProfile.id);
      await delete(tester, _beto.id);

      expect((await store.all()).single.nickname, DefaultProfile.nickname);
      expect(find.text(DefaultProfile.nickname), findsOneWidget);
    });

    testWidgets('an adult renames a profile and changes its picture', (tester) async {
      await openAdults(tester);
      await type(tester, gateAnswer(tester));

      await tester.tap(find.byKey(ValueKey('edit-${_beto.id}')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(ProfileEditDialog.nicknameKey), 'Sofi');
      await tester.tap(find.byKey(const ValueKey('edit-avatar-words/loro.svg')));
      await tester.tap(find.byKey(ProfileEditDialog.saveKey));
      await tester.pumpAndSettle();

      final sofi = (await store.all()).last;
      expect(sofi.id, _beto.id);
      expect(sofi.nickname, 'Sofi');
      expect(sofi.avatar, 'words/loro.svg');
      expect(find.text('Sofi'), findsOneWidget);
    });

    testWidgets('an adult sees a child\'s progress, the guide and the licenses', (tester) async {
      await pumpApp(tester, const [testProfile, _beto]);
      await (await store.open(testProfile)).progress.markCompleted('up-down');
      await tester.tap(find.byKey(ProfilePicker.adultsKey));
      await tester.pumpAndSettle();
      await type(tester, gateAnswer(tester));

      await tester.tap(find.byKey(const ValueKey('profile-progress-1')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileProgress), findsOneWidget);
      expect(find.textContaining('1 de '), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('progress-up-down')),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab-Guía')));
      await tester.pumpAndSettle();
      expect(find.byType(AdultsGuide), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tab-Acerca de')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(AboutView.licensesKey),
        200,
        scrollable: find
            .descendant(of: find.byType(AboutView), matching: find.byType(Scrollable))
            .first,
      );
      await tester.tap(find.byKey(AboutView.licensesKey));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
