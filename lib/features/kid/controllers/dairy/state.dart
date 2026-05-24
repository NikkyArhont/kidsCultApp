part of 'dairy_cubit.dart';

enum DairyStateStatus {
  initial,
  loading,
  success,
  error,
  creating,
  createError,
  createSuccess,

  editing,
  editError,
  editSuccess,
}

class DairyState extends Equatable {
  final String? errorMessage;
  final DairyStateStatus status;

  const DairyState({
    this.errorMessage,
    this.status = DairyStateStatus.initial,
  });

  DairyState copyWith({
    String? errorMessage,
    DairyStateStatus? status,
  }) {
    return DairyState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
      ];

  DairyState reset() => const DairyState();
}
