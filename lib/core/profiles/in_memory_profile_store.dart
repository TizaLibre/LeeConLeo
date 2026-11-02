import '../logging/in_memory_event_log.dart';
import '../progress/in_memory_progress_store.dart';
import 'profile.dart';
import 'profile_store.dart';

class InMemoryProfileStore implements ProfileStore {
  InMemoryProfileStore([List<Profile> profiles = const []]) : _profiles = [...profiles];

  final List<Profile> _profiles;
  final Map<int, ProfileData> _data = {};

  @override
  Future<List<Profile>> all() async => List.unmodifiable(_profiles);

  @override
  Future<Profile> create({required String nickname, required String avatar}) async {
    final id = _profiles.fold(0, (highest, profile) => profile.id > highest ? profile.id : highest);
    final profile = Profile(id: id + 1, nickname: nickname, avatar: avatar);
    _profiles.add(profile);
    return profile;
  }

  @override
  Future<void> update(Profile profile) async {
    final index = _profiles.indexWhere((other) => other.id == profile.id);
    if (index >= 0) _profiles[index] = profile;
  }

  @override
  Future<void> delete(Profile profile) async {
    _profiles.removeWhere((other) => other.id == profile.id);
    _data.remove(profile.id);
  }

  @override
  Future<ProfileData> open(Profile profile) async => _data[profile.id] ??= ProfileData(
    events: InMemoryEventLog(),
    progress: InMemoryProgressStore(),
  );
}
