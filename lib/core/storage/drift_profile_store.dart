import 'package:drift/drift.dart';

import '../profiles/profile.dart';
import '../profiles/profile_store.dart';
import 'app_database.dart';
import 'drift_event_log.dart';
import 'drift_progress_store.dart';

class DriftProfileStore implements ProfileStore {
  const DriftProfileStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<Profile>> all() async {
    final rows = await (_database.select(
      _database.profiles,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<Profile> create({required String nickname, required String avatar}) async {
    final row = await _database
        .into(_database.profiles)
        .insertReturning(
          ProfilesCompanion.insert(nickname: nickname, avatar: avatar, createdAt: DateTime.now()),
        );
    return _fromRow(row);
  }

  @override
  Future<void> update(Profile profile) =>
      (_database.update(_database.profiles)..where((row) => row.id.equals(profile.id))).write(
        ProfilesCompanion(nickname: Value(profile.nickname), avatar: Value(profile.avatar)),
      );

  @override
  Future<void> delete(Profile profile) => _database.transaction(() async {
    await (_database.delete(
      _database.itemEvents,
    )..where((row) => row.profileId.equals(profile.id))).go();
    await (_database.delete(
      _database.completedSteps,
    )..where((row) => row.profileId.equals(profile.id))).go();
    await (_database.delete(
      _database.playedGames,
    )..where((row) => row.profileId.equals(profile.id))).go();
    await (_database.delete(_database.profiles)..where((row) => row.id.equals(profile.id))).go();
  });

  @override
  Future<ProfileData> open(Profile profile) async => ProfileData(
    events: await DriftEventLog.open(_database, profile.id),
    progress: await DriftProgressStore.open(_database, profile.id),
  );

  static Profile _fromRow(ProfileRow row) =>
      Profile(id: row.id, nickname: row.nickname, avatar: row.avatar);
}
