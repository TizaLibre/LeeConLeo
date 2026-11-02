import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/core/audio/audio_providers.dart';
import 'package:lee_con_leo/core/content/asset_content_repository.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/progress/in_memory_progress_store.dart';
import 'package:lee_con_leo/core/progress/progress_providers.dart';
import 'package:lee_con_leo/map/home_screen.dart';
import 'package:lee_con_leo/map/leo_position.dart';
import 'package:lee_con_leo/map/label_slot.dart';
import 'package:lee_con_leo/map/place_layout.dart';
import 'package:lee_con_leo/map/place_view.dart';
import 'package:lee_con_leo/map/route_painter.dart';

import '../fakes/recording_prompt_player.dart';

void main() {
  final bundle = ContentBundle.fromJson(
    jsonDecode(File(AssetContentRepository.bundlePath).readAsStringSync()) as Map<String, dynamic>,
  );
  final places = bundle.stages;

  Future<void> pumpMap(WidgetTester tester, Size size, {Set<String> completed = const {}}) async {
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
          promptPlayerProvider.overrideWithValue(RecordingPromptPlayer()),
          progressStoreProvider.overrideWithValue(InMemoryProgressStore(completed)),
        ],
        child: MaterialApp(
          home: Scaffold(body: PathMap(bundle: bundle)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToNextPlace(WidgetTester tester, Size size) async {
    await tester.drag(find.byType(PageView), Offset(0, size.height * 0.8));
    await tester.pumpAndSettle();
  }

  Finder placeOnScreen(int index) => find.byKey(ValueKey('place-$index'));

  for (final (name, size) in [('small phone', Size(360, 640)), ('tablet', Size(800, 1100))]) {
    testWidgets('every place fits one screen of a $name, its name on one line', (tester) async {
      await pumpMap(tester, size);
      final screen = Offset.zero & size;

      for (final (index, place) in places.indexed) {
        if (index > 0) await goToNextPlace(tester, size);
        expect(placeOnScreen(index), findsOneWidget);

        final stones = [
          for (final step in place.steps) tester.getRect(find.byKey(ValueKey('step-${step.id}'))),
        ];
        for (final (i, stone) in stones.indexed) {
          expect(screen.expandToInclude(stone), screen, reason: '${place.name} step $i');
          expect(stone.width, greaterThanOrEqualTo(PlaceLayout.minStone - 0.01));
          for (final other in stones.skip(i + 1)) {
            expect(stone.overlaps(other), isFalse, reason: '${place.name} stones overlap');
          }
        }

        final painter = tester
            .widgetList<CustomPaint>(
              find.descendant(of: placeOnScreen(index), matching: find.byType(CustomPaint)),
            )
            .map((paint) => paint.painter)
            .whereType<RoutePainter>()
            .single;
        final road = RoutePainter.through(painter.points);
        final labelRect = tester.getRect(find.byKey(ValueKey('place-label-${place.name}')));
        expect(labelRect.height, lessThanOrEqualTo(PlaceView.labelHeight), reason: place.name);
        final beside = labelSlot(
          road: road,
          roadHalfWidth: RoutePainter.halfWidth,
          top: PlaceView.labelMargin,
          bottom: PlaceView.labelMargin + PlaceView.labelHeight,
          width: size.width,
          margin: PlaceView.labelMargin,
        );
        if (labelRect.width > beside.maxWidth) continue;
        final label = labelRect.inflate(RoutePainter.halfWidth);
        for (final metric in road.computeMetrics()) {
          for (var distance = 0.0; distance <= metric.length; distance += 2) {
            final point = metric.getTangentForOffset(distance)!.position;
            expect(label.contains(point), isFalse, reason: '${place.name} label covers $point');
          }
        }
      }
    });
  }

  testWidgets('the road leaves one place where it enters the next', (tester) async {
    const size = Size(390, 800);
    await pumpMap(tester, size);
    List<Offset> roadOf(int index) => tester
        .widgetList<CustomPaint>(
          find.descendant(of: placeOnScreen(index), matching: find.byType(CustomPaint)),
        )
        .map((paint) => paint.painter)
        .whereType<RoutePainter>()
        .single
        .points;

    var leaving = roadOf(0).last;
    for (var index = 1; index < places.length; index++) {
      await goToNextPlace(tester, size);
      final entering = roadOf(index).first;
      expect(leaving.dy, 0);
      expect(entering.dy, size.height);
      expect(entering.dx, leaving.dx);
      leaving = roadOf(index).last;
    }
  });

  testWidgets('a place clips its road to its own page', (tester) async {
    await pumpMap(tester, const Size(390, 800));
    final road = find.descendant(
      of: placeOnScreen(0),
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is RoutePainter,
      ),
    );

    expect(
      find.ancestor(
        of: road,
        matching: find.descendant(of: placeOnScreen(0), matching: find.byType(ClipRect)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the map opens on the place where Leo plays next', (tester) async {
    final spatial = {for (final step in places.first.steps) step.id};
    await pumpMap(tester, const Size(390, 800), completed: spatial);

    expect(placeOnScreen(1), findsOneWidget);
    expect(find.byKey(ValueKey('place-label-${places[1].name}')), findsOneWidget);
    expect(find.byKey(const ValueKey('leo-front')), findsOneWidget);
  });

  testWidgets('Leo walks into a new place from its bottom edge', (tester) async {
    final spatial = {for (final step in places.first.steps) step.id};
    const size = Size(390, 800);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = ProviderContainer(
      overrides: [
        promptPlayerProvider.overrideWithValue(RecordingPromptPlayer()),
        progressStoreProvider.overrideWithValue(InMemoryProgressStore(spatial)),
      ],
    );
    addTearDown(container.dispose);
    container.read(leoPositionProvider.notifier).moveTo(places.first.steps.last.id);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: PathMap(bundle: bundle)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('leo-front'))).dy, greaterThan(size.height));

    await tester.pump();
    await tester.pump(PlaceView.walkDuration);
    final leo = tester.getRect(find.byKey(const ValueKey('leo-front')));
    final stone = tester.getRect(find.byKey(ValueKey('step-${places[1].steps.first.id}')));
    expect(leo.bottom, closeTo(stone.bottom, 1));
  });
}
