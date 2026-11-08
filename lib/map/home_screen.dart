import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../activities/activity_providers.dart';
import '../app/app_theme.dart';
import '../app/startup_providers.dart';
import '../app/step_routes.dart';
import '../app/widgets/loading_view.dart';
import '../core/audio/audio_providers.dart';
import '../core/audio/utterance.dart';
import '../core/content/models/content_bundle.dart';
import '../core/content/models/path_stage.dart';
import '../core/content/models/path_step.dart';
import '../core/profiles/profile_providers.dart';
import '../core/progress/progress_providers.dart';
import '../profiles/avatar_button.dart';
import '../profiles/profile_picker.dart';
import 'greeting.dart';
import 'leo_position.dart';
import 'place_view.dart';
import 'step_status.dart';
import 'write_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const switchProfileKey = ValueKey('switch-profile');
  static const albumKey = ValueKey('album');
  static const buttonsWidth = 148.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: ref
            .watch(startupProvider)
            .when(
              data: (bundle) => _home(ref, bundle),
              loading: () => const LoadingView(),
              error: (error, _) => Center(child: Text('$error')),
            ),
      ),
    );
  }
}

Widget _home(WidgetRef ref, ContentBundle bundle) {
  final playing = ref.watch(activeProfileProvider);
  if (playing == null) return ProfilePicker(bundle: bundle);
  return Stack(
    children: [
      PathMap(key: ValueKey('map-${playing.profile.id}'), bundle: bundle),
      Positioned(
        top: 8,
        right: 8,
        child: AvatarButton(
          key: HomeScreen.switchProfileKey,
          avatar: playing.profile.avatar,
          size: 64,
          onPressed: () {
            ref.read(promptPlayerProvider).stop();
            ref.read(activeProfileProvider.notifier).leave();
          },
        ),
      ),
      Positioned(
        top: 8,
        right: 84,
        child: Builder(
          builder: (context) => IconButton.filledTonal(
            key: HomeScreen.albumKey,
            iconSize: 48,
            onPressed: () {
              ref.read(promptPlayerProvider).stop();
              context.go('/stickers');
            },
            icon: const Icon(Icons.auto_stories_rounded),
          ),
        ),
      ),
      Positioned(right: 16, bottom: 16, child: WriteButton(bundle: bundle)),
    ],
  );
}

class PathMap extends ConsumerStatefulWidget {
  const PathMap({super.key, required this.bundle});

  static const introPrompt = 'home.intro';
  static const lockedPrompt = 'home.locked';
  static const finishedPrompt = 'home.finished';
  static const zigzag = [0.5, 0.74, 0.5, 0.26];

  final ContentBundle bundle;

  @override
  ConsumerState<PathMap> createState() => _PathMapState();
}

class _PathMapState extends ConsumerState<PathMap> {
  final _random = Random();
  late final Map<String, int> _placeOfStep = {
    for (final (index, place) in widget.bundle.stages.indexed)
      for (final step in place.steps) step.id: index,
  };
  late final Map<String, double> _columnOfStep = {
    for (final (index, step) in widget.bundle.steps.indexed)
      step.id: PathMap.zigzag[index % PathMap.zigzag.length],
  };
  late final PageController _pages = PageController(
    initialPage:
        _placeOfStep[_leoTarget(
          _statuses(ref.read(completedStepsProvider), ref.read(masteredStepsProvider)),
        )] ??
        0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _arrive());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _arrive() {
    if (!mounted) return;
    final greets = ref.read(greetingProvider.notifier).takeTurn();
    if (WriteButton.isPathFinished(widget.bundle, ref.read(completedStepsProvider)) &&
        ref.read(finishCheerProvider.notifier).takeTurn()) {
      _say(PathMap.finishedPrompt);
    } else if (greets) {
      _say(PathMap.introPrompt);
    }
    final target = _leoTarget(
      _statuses(ref.read(completedStepsProvider), ref.read(masteredStepsProvider)),
    );
    if (target != null && ref.read(leoPositionProvider) != target) {
      ref.read(leoPositionProvider.notifier).moveTo(target);
    }
  }

  void _say(String promptId) => ref
      .read(promptPlayerProvider)
      .say(Utterance([widget.bundle.prompts.line(promptId, _random)]));

  Map<String, StepStatus> _statuses(Set<String> completed, Set<String> mastered) {
    final registry = ref.read(activityRegistryProvider);
    return stepStatuses(
      widget.bundle.steps,
      completed: completed,
      mastered: mastered,
      isPlayable: (step) => registry.firstAvailable(step.activities) != null,
    );
  }

  String? _leoTarget(Map<String, StepStatus> statuses) {
    for (final MapEntry(key: id, value: status) in statuses.entries) {
      if (status == StepStatus.next) return id;
    }
    final done = [
      for (final MapEntry(key: id, value: status) in statuses.entries)
        if (status.isFinished) id,
    ];
    return done.isEmpty ? null : done.last;
  }

  void _open(PathStep step, StepStatus status) {
    final activityId = ref.read(activityRegistryProvider).firstAvailable(step.activities);
    if (status == StepStatus.locked || activityId == null) {
      _say(PathMap.lockedPrompt);
      return;
    }
    context.go(StepRoutes.entry(ref.read(activityRegistryProvider), step));
  }

  double _crossing(PathStage below, PathStage above) =>
      (_columnOfStep[below.steps.last.id]! + _columnOfStep[above.steps.first.id]!) / 2;

  LeoHere _leoHere(int place, String? leoAt) {
    if (leoAt == null) return LeoHere.none;
    final leoPlace = _placeOfStep[leoAt];
    if (leoPlace == place) return LeoHere.standing;
    final previous = place > 0 ? widget.bundle.stages[place - 1].steps : const <PathStep>[];
    return previous.isNotEmpty && previous.last.id == leoAt ? LeoHere.entering : LeoHere.none;
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _statuses(ref.watch(completedStepsProvider), ref.watch(masteredStepsProvider));
    final leoAt = ref.watch(leoPositionProvider) ?? _leoTarget(statuses);
    final places = widget.bundle.stages;
    return PageView.builder(
      controller: _pages,
      scrollDirection: Axis.vertical,
      reverse: true,
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return PlaceView(
          key: ValueKey('place-$index'),
          place: place,
          columns: [for (final step in place.steps) _columnOfStep[step.id]!],
          enteringColumn: index > 0 ? _crossing(places[index - 1], place) : null,
          leavingColumn: index < places.length - 1 ? _crossing(place, places[index + 1]) : null,
          statuses: statuses,
          onOpen: _open,
          leoStep: leoAt,
          leoHere: _leoHere(index, leoAt),
          rightReserved: HomeScreen.buttonsWidth,
        );
      },
    );
  }
}
