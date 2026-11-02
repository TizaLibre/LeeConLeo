import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'in_memory_profile_store.dart';
import 'profile.dart';
import 'profile_store.dart';

final profileStoreProvider = Provider<ProfileStore>((ref) => InMemoryProfileStore());

final profilesProvider = FutureProvider<List<Profile>>(
  (ref) => ref.watch(profileStoreProvider).all(),
);

class PlayingProfile {
  const PlayingProfile({required this.profile, required this.data});

  final Profile profile;
  final ProfileData data;
}

final activeProfileProvider = NotifierProvider<ActiveProfile, PlayingProfile?>(ActiveProfile.new);

class ActiveProfile extends Notifier<PlayingProfile?> {
  @override
  PlayingProfile? build() => null;

  Future<void> choose(Profile profile) async {
    final data = await ref.read(profileStoreProvider).open(profile);
    state = PlayingProfile(profile: profile, data: data);
  }

  void rename(Profile profile) {
    final playing = state;
    if (playing == null || playing.profile.id != profile.id) return;
    state = PlayingProfile(profile: profile, data: playing.data);
  }

  void leave() => state = null;
}
