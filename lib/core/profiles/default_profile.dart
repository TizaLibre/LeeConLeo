import 'avatars.dart';
import 'profile.dart';
import 'profile_store.dart';

abstract final class DefaultProfile {
  static const nickname = 'Mi perfil';

  static Future<List<Profile>> ensure(ProfileStore store) async {
    final profiles = await store.all();
    if (profiles.isNotEmpty) return profiles;
    return [await store.create(nickname: nickname, avatar: Avatars.all.first)];
  }
}
