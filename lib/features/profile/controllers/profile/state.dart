part of 'profile_cubit.dart';

enum ProfileStateStatus { initial, saving, success, error }

class ProfileState extends Equatable {
  final String? errorMessage;
  final ProfileStateStatus status;

  const ProfileState({
    this.errorMessage,
    this.status = ProfileStateStatus.initial,
  });

  ProfileState copyWith({
    String? errorMessage,
    ProfileStateStatus? status,
  }) {
    return ProfileState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [errorMessage, status];
}
