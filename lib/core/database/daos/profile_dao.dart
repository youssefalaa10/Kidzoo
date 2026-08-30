import 'package:drift/drift.dart';
import 'package:kidzo/core/database/tables/profile_table.dart';
import '../config.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Stream<List<Profile>> watchProfiles() => select(profiles).watch();
  Future<List<Profile>> getAllProfiles() => select(profiles).get();
  Future<Profile?> getProfileById(int id) =>
      (select(profiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertProfile(ProfilesCompanion companion) =>
      into(profiles).insert(companion);

  Future<bool> updateProfile(Profile profile) =>
      update(profiles).replace(profile);

  Future<int> deleteProfile(int id) =>
      (delete(profiles)..where((t) => t.id.equals(id))).go();
}
