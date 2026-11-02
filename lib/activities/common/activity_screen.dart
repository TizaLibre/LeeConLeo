import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/content/content_providers.dart';
import '../../core/content/models/content_bundle.dart';
import '../../core/content/activity_ids.dart';
import '../../core/content/models/path_stage.dart';
import '../../core/content/models/path_step.dart';
import '../../core/logging/logging_providers.dart';
import '../../core/audio/utterance.dart';
import '../../core/progress/progress_providers.dart';
import '../../core/progress/stickers.dart';
import '../../app/step_routes.dart';
import '../../app/widgets/loading_view.dart';
import '../../app/widgets/scene_band.dart';
import '../../utils/hex_color.dart';
import '../activity_providers.dart';
import 'activity_context.dart';
import 'activity_session.dart';
import 'activity_spec.dart';
import 'widgets/activity_top_bar.dart';
import 'widgets/intro_view.dart';
import 'widgets/reward_view.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({
    super.key,
    required this.stepId,
    required this.activityId,
    this.celebrationDuration = const Duration(milliseconds: 1500),
    this.random,
  });

  final String stepId;
  final String activityId;
  final Duration celebrationDuration;
  final Random? random;

  static const newStickerPrompt = 'stickers.new';

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivitySpec? _spec;
  ActivitySession? _session;
  Timer? _celebrationTimer;
  bool _isUnavailable = false;
  PathStage? _stage;
  PathStep? _step;
  String? _newSticker;

  @override
  void initState() {
    super.initState();
    final content = ref.read(contentProvider).value;
    if (content != null) {
      _startSession(content);
      return;
    }
    ref.read(contentProvider.future).then((content) {
      if (mounted) setState(() => _startSession(content));
    });
  }

  void _startSession(ContentBundle content) {
    final registry = ref.read(activityRegistryProvider);
    final spec = registry.find(widget.activityId);
    final step = content.stepById(widget.stepId);
    if (spec == null || step == null) {
      _isUnavailable = true;
      return;
    }

    final random = widget.random ?? Random();
    final events = ref.read(eventLogProvider).events;
    final items = spec.buildItems(
      ActivityContext(content: content, step: step, random: random, events: events),
    );
    _step = step;
    if (items.isEmpty) {
      _isUnavailable = true;
      _markPlayed();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _continue();
      });
      return;
    }
    final session = ActivitySession(
      sessionId: ref.read(sessionIdProvider),
      stepId: step.id,
      activityId: spec.id,
      items: items,
      prompts: content.prompts,
      player: ref.read(promptPlayerProvider),
      log: ref.read(eventLogProvider),
      random: random,
    )..addListener(_onSessionChanged);

    _spec = spec;
    _session = session;
    _stage = content.stageOf(step.id);
    session.start();
  }

  void _onSessionChanged() {
    final session = _session!;
    if (session.phase == SessionPhase.celebrating) {
      _celebrationTimer?.cancel();
      final feedback = session.feedbackDone;
      _celebrationTimer = Timer(
        widget.celebrationDuration,
        () => feedback.then((_) {
          if (mounted) session.next();
        }),
      );
    }
    if (session.phase == SessionPhase.finished) {
      _checkSticker(session.stepId);
      _markPlayed();
    }
    setState(() {});
  }

  bool get _isReview => widget.activityId == ActivityIds.review;

  bool get _isPractice => widget.activityId == ActivityIds.writeWord;

  void _markPlayed() {
    final step = _step;
    if (step == null || _isReview || _isPractice) return;
    final played = ref.read(playedGamesProvider.notifier);
    played.markPlayed((stepId: step.id, activityId: widget.activityId));
    final games = ref.read(activityRegistryProvider).available(step.activities);
    final playedHere = {
      for (final game in ref.read(playedGamesProvider))
        if (game.stepId == step.id) game.activityId,
    };
    if (games.every(playedHere.contains)) {
      ref.read(completedStepsProvider.notifier).markCompleted(step.id);
    }
  }

  void _checkSticker(String stepId) {
    final before = ref.read(masteredStepsProvider);
    ref.invalidate(masteredStepsProvider);
    if (before.contains(stepId) || !ref.read(masteredStepsProvider).contains(stepId)) return;
    final content = ref.read(contentProvider).value;
    final step = content?.stepById(stepId);
    if (content == null || step == null) return;
    _newSticker = Stickers.of(content, step);
    if (_newSticker == null) return;
    ref
        .read(promptPlayerProvider)
        .say(
          Utterance([content.prompts.line(ActivityScreen.newStickerPrompt, Random())]),
          queued: true,
        );
  }

  void _goHome() {
    ref.read(promptPlayerProvider).stop();
    context.go('/');
  }

  void _continue() {
    final step = _step;
    if (step == null || _isPractice) return _goHome();
    final registry = ref.read(activityRegistryProvider);
    ref.read(promptPlayerProvider).stop();
    context.go(_isReview ? StepRoutes.entry(registry, step) : StepRoutes.afterGame(registry, step));
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _stage?.scene;
    final showScene = scene != null && _showsScene;
    return Scaffold(
      backgroundColor: _tint,
      body: Stack(
        children: [
          if (showScene) Positioned.fill(child: SceneBand(asset: 'assets/images/$scene')),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }

  bool get _showsScene {
    final phase = _session?.phase;
    return _isUnavailable || phase == SessionPhase.intro || phase == SessionPhase.finished;
  }

  Color? get _tint {
    final tint = _stage?.tint;
    final argb = tint == null ? null : parseHexColor(tint);
    return argb == null ? null : Color(argb);
  }

  Widget _buildBody() {
    if (_isUnavailable) return RewardView(onDone: _goHome);
    final session = _session;
    if (session == null) return const LoadingView();

    return Column(
      children: [
        ActivityTopBar(
          onHome: _goHome,
          onRepeat: session.repeatPrompt,
          completed: _completedItems(session),
          total: session.itemCount,
          showsProgress: !_showsScene,
        ),
        Expanded(child: _buildPhase(session)),
      ],
    );
  }

  Widget _buildPhase(ActivitySession session) => switch (session.phase) {
    SessionPhase.intro => IntroView(onStart: session.begin),
    SessionPhase.playing ||
    SessionPhase.celebrating => _spec!.buildItemView(session.currentItem, session),
    SessionPhase.finished => RewardView(onDone: _continue, sticker: _newSticker),
  };

  int _completedItems(ActivitySession session) => switch (session.phase) {
    SessionPhase.intro => 0,
    SessionPhase.playing => session.itemNumber - 1,
    SessionPhase.celebrating => session.itemNumber,
    SessionPhase.finished => session.itemCount,
  };
}
