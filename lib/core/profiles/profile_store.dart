import '../logging/event_log.dart';
import '../progress/progress_store.dart';
import 'profile.dart';

class ProfileData {
  const ProfileData({required this.events, required this.progress});

  final EventLog events;
  final ProgressStore progress;
}

abstract interface class ProfileStore {
  Future<List<Profile>> all();

  Future<Profile> create({required String nickname, required String avatar});

  Future<void> update(Profile profile);

  Future<void> delete(Profile profile);

  Future<ProfileData> open(Profile profile);
}
