import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this.profileDao) : super(ProfileInitial());
  final ProfileDao profileDao;

  /// Mirrors the Profiles table constraint
  /// (name: text().withLength(min: 3, max: 16)).
  static const int minNameLength = 3;
  static const int maxNameLength = 16;

  /// Trims and clamps [name] to what the table accepts, or returns null when
  /// it is too short to be stored.
  static String? _sanitizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < minNameLength) return null;
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength)
        : trimmed;
  }

  Future<void> checkProfile() async {
    emit(ProfileLoading());
    try {
      final profiles = await profileDao.getAllProfiles();
      if (profiles.isNotEmpty) {
        emit(ProfileLoaded(profiles.first));
      } else {
        emit(const ProfileLoaded(null));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> createProfile(String name, int avatarIndex) async {
    final safeName = _sanitizeName(name);
    if (safeName == null) {
      emit(const ProfileError(
          'Name must be at least $minNameLength characters'));
      return;
    }
    emit(ProfileLoading());
    try {
      await profileDao.insertProfile(
        ProfilesCompanion.insert(
          name: safeName,
          avatarIndex: Value(avatarIndex),
        ),
      );
      final profiles = await profileDao.getAllProfiles();
      emit(ProfileLoaded(profiles.first));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    required int id,
    required String name,
    required int age,
    required int avatarIndex,
  }) async {
    final previous = state;
    final safeName = _sanitizeName(name);
    if (safeName == null) {
      emit(const ProfileError(
          'Name must be at least $minNameLength characters'));
      emit(previous);
      return;
    }
    emit(ProfileLoading());
    try {
      final existing = await profileDao.getProfileById(id);
      if (existing == null) {
        emit(const ProfileError('Profile not found'));
        return;
      }
      final updated = existing.copyWith(
        name: safeName,
        age: age,
        avatarIndex: avatarIndex,
      );
      await profileDao.updateProfile(updated);
      emit(ProfileLoaded(updated));
    } catch (e) {
      emit(ProfileError(e.toString()));
      emit(previous);
    }
  }
}
