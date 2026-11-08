import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../app/startup_providers.dart';
import '../app/widgets/leo_avatar.dart';
import '../app/widgets/loading_view.dart';
import '../app/widgets/sticker_card.dart';
import '../core/audio/audio_providers.dart';
import '../core/audio/utterance.dart';
import '../core/content/models/content_bundle.dart';
import '../core/progress/progress_providers.dart';
import '../core/progress/stickers.dart';
import 'review_button.dart';

class StickerAlbum extends ConsumerStatefulWidget {
  const StickerAlbum({super.key});

  static const introPrompt = 'stickers.intro';
  static const backKey = ValueKey('album-back');

  @override
  ConsumerState<StickerAlbum> createState() => _StickerAlbumState();
}

class _StickerAlbumState extends ConsumerState<StickerAlbum> {
  @override
  void initState() {
    super.initState();
    ref.read(startupProvider.future).then((content) {
      if (!mounted) return;
      ref
          .read(promptPlayerProvider)
          .say(Utterance([content.prompts.line(StickerAlbum.introPrompt, Random())]));
    });
  }

  void _back() {
    ref.read(promptPlayerProvider).stop();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: ref
            .watch(startupProvider)
            .when(
              data: _album,
              loading: () => const LoadingView(),
              error: (error, _) => Center(child: Text('$error')),
            ),
      ),
    );
  }

  Widget _album(ContentBundle content) {
    final mastered = ref.watch(masteredStepsProvider);
    final stickers = [
      for (final step in content.steps)
        if (Stickers.of(content, step) case final image?) (step: step.id, image: image),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GridView.extent(
                      maxCrossAxisExtent: 140,
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        for (final sticker in stickers)
                          Center(
                            child: StickerCard(
                              key: ValueKey('sticker-${sticker.step}'),
                              image: sticker.image,
                              isEarned: mastered.contains(sticker.step),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton.filledTonal(
                      key: StickerAlbum.backKey,
                      iconSize: 48,
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Positioned(top: 8, right: 8, child: ReviewButton(bundle: content)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: LeoAvatar(size: 140, pose: LeoPose.happy),
            ),
          ],
        );
      },
    );
  }
}
