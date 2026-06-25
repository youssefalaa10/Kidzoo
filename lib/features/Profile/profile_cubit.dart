import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {

  ProfileCubit(this.profileDao) : super(ProfileInitial());
  final ProfileDao profileDao;

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
    emit(ProfileLoading());
    try {
      await profileDao.insertProfile(
        ProfilesCompanion.insert(
          name: name,
          avatarIndex: Value(avatarIndex),
        ),
      );
      final profiles = await profileDao.getAllProfiles();
      emit(ProfileLoaded(profiles.first));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
