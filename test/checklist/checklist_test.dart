import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/activity_providers.dart';
import 'package:lee_con_leo/activities/common/activity_screen.dart';
import 'package:lee_con_leo/activities/listening/clap_view.dart';
import 'package:lee_con_leo/app/app_theme.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/content_providers.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';

import '../fakes/recording_prompt_player.dart';
import '../fakes/recording_sound_effects.dart';

const _minTarget = Size(64, 64);
const _maxFeedback = Duration(milliseconds: 300);
const _sizes = {'phone': Size(390, 800), 'tablet': Size(1180, 820)};
const _answeredByDragging = {ActivityIds.trace, ActivityIds.syllableTrace, ActivityIds.writeWord};

final _content = ContentBundle.fromJson(
  jsonDecode(File('assets/content/bundle.json').readAsStringSync()) as Map<String, dynamic>,
);

void main() {
  final games = ProviderContainer()
      .read(activityRegistryProvider)
      .ids
      .where((id) => id != ActivityIds.review);

  for (final game in games) {
    final step = game == ActivityIds.writeWord
        ? _content.steps.last
        : _content.steps.firstWhere((step) => step.activities.contains(game));
    for (final MapEntry(key: device, value: size) in _sizes.entries) {
      testWidgets('$game on a $device: big targets, spoken instructions, quick feedback', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final player = RecordingPromptPlayer();
        await _open(tester, size, player, step.id, game);

        await expectLater(tester, meetsGuideline(_tapTargets));
        expect(player.utterances, isNotEmpty, reason: 'the intro is spoken');
        expect(player.utterances.last.hasAllClips, isTrue, reason: 'the intro is recorded');

        await tester.tap(find.byKey(const ValueKey('start')));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(_tapTargets));
        final question = player.utterances.last;
        expect(question.isEmpty, isFalse, reason: 'the first item is spoken');
        expect(question.hasAllClips, isTrue, reason: 'the first item is recorded');

        if (!_answeredByDragging.contains(game)) {
          final spoken = player.utterances.length;
          final tapped = await _answer(tester);
          await tester.pump(_maxFeedback);
          final moved = !tester.any(find.byKey(tapped));
          expect(
            player.utterances.length > spoken || moved,
            isTrue,
            reason: 'Leo answers the tap, or the tapped piece moves',
          );
        }
        semantics.dispose();
      });
    }
  }
}

const _tapTargets = MinimumTapTargetGuideline(
  size: _minTarget,
  link: 'docs/06-roadmap.md (M3 checklist: touch targets of at least 64 dp)',
);

Future<void> _open(
  WidgetTester tester,
  Size size,
  RecordingPromptPlayer player,
  String stepId,
  String game,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
    disableAnimations: true,
  );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentProvider.overrideWith((ref) async => _content),
        promptPlayerProvider.overrideWithValue(player),
        eventLogProvider.overrideWithValue(InMemoryEventLog()),
        soundEffectsProvider.overrideWithValue(RecordingSoundEffects()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: ActivityScreen(stepId: stepId, activityId: game, random: Random(1)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Key> _answer(WidgetTester tester) async {
  if (tester.any(find.byKey(ClapView.clapKey))) {
    await tester.tap(find.byKey(ClapView.clapKey));
    await tester.pump();
    await tester.tap(find.byKey(ClapView.doneKey));
    return ClapView.doneKey;
  }
  final ball = find.byKey(const ValueKey('ball'));
  if (tester.any(ball)) {
    final zone = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          '${(widget.key! as ValueKey).value}'.startsWith('zone-'),
    );
    await tester.drag(ball, tester.getCenter(zone.first) - tester.getCenter(ball));
    return const ValueKey('ball');
  }
  for (final prefix in ['choice-', 'bubble-', 'tile-']) {
    final target = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> && '${(widget.key! as ValueKey).value}'.startsWith(prefix),
    );
    if (tester.any(target)) {
      final key = tester.widget(target.first).key!;
      await tester.tap(target.first, warnIfMissed: false);
      return key;
    }
  }
  fail('no answer to tap');
}
