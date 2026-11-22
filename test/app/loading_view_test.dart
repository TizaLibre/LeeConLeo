import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/widgets/letter_bubble.dart';
import 'package:lee_con_leo/app/startup_providers.dart';
import 'package:lee_con_leo/app/widgets/loading_view.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/map/home_screen.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  testWidgets('while the content loads, Leo waits among floating letters', (tester) async {
    final content = Completer<ContentBundle>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          singleProfile(),
          contentProvider.overrideWith((ref) => content.future),
          minimumSplashProvider.overrideWithValue(Duration.zero),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.byKey(const ValueKey('leo-happy')), findsOneWidget);
    expect(find.byType(LetterBubble), findsNWidgets(LoadingView.letters.length));
  });

  testWidgets('the floating letters stay a moment even when the content is ready', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          singleProfile(),
          contentProvider.overrideWith((ref) async => testContent),
          minimumSplashProvider.overrideWithValue(const Duration(seconds: 1)),
          promptPlayerProvider.overrideWithValue(RecordingPromptPlayer()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LoadingView), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(PathMap), findsOneWidget);
  });
}
