import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../app/widgets/leo_avatar.dart';
import '../core/audio/audio_providers.dart';
import '../core/audio/utterance.dart';
import '../core/content/models/content_bundle.dart';
import '../core/profiles/profile.dart';
import '../core/profiles/profile_providers.dart';
import 'avatar_button.dart';

class ProfilePicker extends ConsumerStatefulWidget {
  const ProfilePicker({super.key, required this.bundle});

  static const introPrompt = 'profiles.intro';
  static const adultsKey = ValueKey('adults');

  final ContentBundle bundle;

  @override
  ConsumerState<ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends ConsumerState<ProfilePicker> {
  final _random = Random();

  @override
  void initState() {
    super.initState();
    ref
        .read(promptPlayerProvider)
        .say(Utterance([widget.bundle.prompts.line(ProfilePicker.introPrompt, _random)]));
  }

  void _choose(Profile profile) {
    ref.read(promptPlayerProvider).stop();
    ref.read(activeProfileProvider.notifier).choose(profile);
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider).value ?? const [];
    return Stack(
      children: [
        Positioned(left: 16, bottom: 16, child: const LeoAvatar(size: 180, pose: LeoPose.happy)),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            key: ProfilePicker.adultsKey,
            iconSize: 32,
            color: AppTheme.outline.withValues(alpha: 0.6),
            icon: const Icon(Icons.lock_rounded),
            onPressed: () {
              ref.read(promptPlayerProvider).stop();
              context.go('/adults');
            },
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 200),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 24,
              children: [for (final profile in profiles) _profile(profile)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profile(Profile profile) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AvatarButton(
        key: ValueKey('profile-${profile.id}'),
        avatar: profile.avatar,
        onPressed: () => _choose(profile),
      ),
      const SizedBox(height: 8),
      Text(
        profile.nickname,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.outline),
      ),
    ],
  );
}
