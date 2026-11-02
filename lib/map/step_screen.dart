import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../activities/activity_providers.dart';
import '../activities/common/widgets/letter_glyph.dart';
import '../app/app_theme.dart';
import '../app/startup_providers.dart';
import '../app/step_routes.dart';
import '../app/widgets/leo_avatar.dart';
import '../app/widgets/loading_view.dart';
import '../app/widgets/pulse.dart';
import '../core/audio/audio_providers.dart';
import '../core/audio/utterance.dart';
import '../core/content/models/content_bundle.dart';
import '../core/content/models/path_step.dart';
import '../core/progress/progress_providers.dart';
import '../utils/hex_color.dart';
import 'game_icons.dart';

class StepScreen extends ConsumerStatefulWidget {
  const StepScreen({super.key, required this.stepId});

  static const introPrompt = 'step.intro';
  static const donePrompt = 'step.done';
  static const nextKey = ValueKey('step-next');
  static const mapKey = ValueKey('step-map');
  static const maxCard = 132.0;
  static const minCard = 72.0;
  static const spacing = 20.0;
  static const headerHeight = 96.0;

  final String stepId;

  @override
  ConsumerState<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends ConsumerState<StepScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(startupProvider.future).then((content) {
      final step = content.stepById(widget.stepId);
      if (!mounted || step == null) return;
      final prompt = _unplayed(step).isEmpty ? StepScreen.donePrompt : StepScreen.introPrompt;
      ref.read(promptPlayerProvider).say(Utterance([content.prompts.line(prompt, Random())]));
    });
  }

  List<String> _unplayed(PathStep step) {
    final played = {
      for (final game in ref.read(playedGamesProvider))
        if (game.stepId == step.id) game.activityId,
    };
    return [
      for (final game in ref.read(activityRegistryProvider).available(step.activities))
        if (!played.contains(game)) game,
    ];
  }

  String _nextRoute(ContentBundle content, PathStep step) {
    final steps = content.steps.toList();
    final index = steps.indexWhere((other) => other.id == step.id);
    if (index < 0 || index == steps.length - 1) return '/';
    return StepRoutes.entry(ref.read(activityRegistryProvider), steps[index + 1]);
  }

  void _go(String route) {
    ref.read(promptPlayerProvider).stop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(startupProvider).value;
    final step = content?.stepById(widget.stepId);
    final tint = content?.stageOf(widget.stepId)?.tint;
    final argb = tint == null ? null : parseHexColor(tint);
    return Scaffold(
      backgroundColor: argb == null ? AppTheme.cream : Color(argb),
      body: SafeArea(
        child: content == null || step == null ? const LoadingView() : _body(content, step),
      ),
    );
  }

  Widget _body(ContentBundle content, PathStep step) {
    final games = ref.watch(activityRegistryProvider).available(step.activities);
    final played = {
      for (final game in ref.watch(playedGamesProvider))
        if (game.stepId == step.id) game.activityId,
    };
    final suggested = games.where((game) => !played.contains(game)).firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight;
        final cards = LayoutBuilder(
          builder: (context, area) {
            final side = _cardSide(area.biggest, games.length);
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(StepScreen.spacing / 2),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: StepScreen.spacing,
                  runSpacing: StepScreen.spacing,
                  children: [
                    for (final game in games)
                      _card(
                        game,
                        side: side,
                        isPlayed: played.contains(game),
                        isSuggested: game == suggested,
                      ),
                  ],
                ),
              ),
            );
          },
        );
        const leo = Padding(
          padding: EdgeInsets.all(16),
          child: LeoAvatar(size: 140, pose: LeoPose.happy),
        );
        final board = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(80, 16, 80, 8),
              child: SizedBox(height: StepScreen.headerHeight, child: _face(step)),
            ),
            Expanded(child: cards),
          ],
        );
        return Stack(
          children: [
            Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: isWide ? [leo, Expanded(child: board)] : [Expanded(child: board), leo],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filledTonal(
                key: StepScreen.mapKey,
                iconSize: 48,
                onPressed: () => _go('/'),
                icon: const Icon(Icons.map_rounded),
              ),
            ),
            if (suggested == null)
              Positioned(
                right: 16,
                bottom: 16,
                child: Pulse(
                  child: IconButton.filled(
                    key: StepScreen.nextKey,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                    iconSize: 64,
                    onPressed: () => _go(_nextRoute(content, step)),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _face(PathStep step) {
    if (step.icon case final icon?) return SvgPicture.asset('assets/images/$icon');
    final text = step.grapheme ?? step.sounds.join(' ');
    return FittedBox(child: LetterGlyph(text, color: AppTheme.outline));
  }

  Widget _icon(String game, double side, Color color) {
    final icon = GameIcons.of(game);
    if (icon == null) return Icon(Icons.videogame_asset_rounded, size: side * 0.55, color: color);
    return Padding(
      padding: EdgeInsets.all(side * 0.16),
      child: SvgPicture.asset('assets/images/$icon'),
    );
  }

  static double _cardSide(Size area, int count) {
    var best = 0.0;
    for (var columns = 1; columns <= count; columns++) {
      final rows = (count / columns).ceil();
      final side = min(
        (area.width - StepScreen.spacing * columns) / columns,
        (area.height - StepScreen.spacing * rows) / rows,
      );
      best = max(best, side);
    }
    return best.clamp(StepScreen.minCard, StepScreen.maxCard);
  }

  Widget _card(
    String game, {
    required double side,
    required bool isPlayed,
    required bool isSuggested,
  }) {
    final colors = Theme.of(context).colorScheme;
    final card = SizedBox.square(
      dimension: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: colors.primaryContainer,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: AppTheme.outline, width: 4),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => _go('/play/${widget.stepId}/$game'),
                child: _icon(game, side, colors.onPrimaryContainer),
              ),
            ),
          ),
          if (isPlayed)
            Positioned(
              right: -6,
              bottom: -6,
              child: Icon(Icons.star_rounded, size: side / 3, color: AppTheme.starGold),
            ),
        ],
      ),
    );
    return KeyedSubtree(
      key: ValueKey('game-$game'),
      child: isSuggested ? Pulse(child: card) : card,
    );
  }
}
