import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/app/lee_con_leo_app.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/audio/pausable_prompt_player.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/test_content.dart';

void main() {
  testWidgets('Leo goes quiet while the app is in the background', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final recording = RecordingPromptPlayer();
    final player = PausablePromptPlayer(recording);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => testContent),
          pausablePlayerProvider.overrideWithValue(player),
        ],
        child: const LeeConLeoApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    void moveTo(List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    moveTo([AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    expect(player.isPaused, isTrue);
    expect(recording.calls.last, RecordingPromptPlayer.stopCall);

    moveTo([AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(player.isPaused, isFalse);
  });
}
