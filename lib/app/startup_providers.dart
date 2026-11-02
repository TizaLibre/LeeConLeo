import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/content/content_providers.dart';
import '../core/content/models/content_bundle.dart';
import '../core/profiles/default_profile.dart';
import '../core/profiles/profile_providers.dart';

final minimumSplashProvider = Provider<Duration>((ref) => const Duration(milliseconds: 1500));

final startupProvider = FutureProvider<ContentBundle>((ref) async {
  final minimum = Future<void>.delayed(ref.watch(minimumSplashProvider));
  final content = await ref.watch(contentProvider.future);
  final profiles = await DefaultProfile.ensure(ref.read(profileStoreProvider));
  if (profiles.length == 1) {
    await ref.read(activeProfileProvider.notifier).choose(profiles.single);
  }
  await minimum;
  return content;
});
