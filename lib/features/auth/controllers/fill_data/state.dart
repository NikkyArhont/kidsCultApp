part of 'fill_data_cubit.dart';

enum FillDataStatus { initial, loading, success, error }

class FillDataState extends Equatable {
  final String? errorMessage;
  final FillDataStatus status;
  final UserType? userType;
  final String? name;
  final XFile? photo;
  final DateTime? birthDate;
  final String? city;
  final int step;

  const FillDataState({
    this.errorMessage,
    this.status = FillDataStatus.initial,
    this.userType,
    this.name,
    this.photo,
    this.birthDate,
    this.city,
    this.step = 0,
  });

  FillDataState copyWith({
    String? errorMessage,
    FillDataStatus? status,
    UserType? userType,
    String? name,
    XFile? photo,
    DateTime? birthDate,
    String? city,
    int? step,
  }) {
    return FillDataState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      step: step ?? this.step,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        userType,
        name,
        photo,
        birthDate,
        city,
        step,
      ];

    FillDataState reset() => const FillDataState();
}
