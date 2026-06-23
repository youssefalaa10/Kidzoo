import 'package:equatable/equatable.dart';
import 'package:kidzo/core/database/config.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Profile? currentProfile;
  const ProfileLoaded(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
