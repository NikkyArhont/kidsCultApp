part of 'bonus_cubit.dart';

enum BonusStateStatus {
  initial,
  loading,
  success,
  error,
  canceling,
  cancelError,
  cancelSuccess,

  requestingReceive,
  requestReceiveError,
  requestReceiveSuccess,

  rejecting,
  rejectError,
  rejectSuccess,

  approving,
  approveError,
  approveSuccess,

  requestApproving,
  requestApproveError,
  requestApproveSuccess,
}

class BonusState extends Equatable {
  final String? errorMessage;
  final BonusStateStatus status;
  final List<BonusModel> bonuses;
  final BonusChip selectedChip;

  final UserModel? selectedKid;
  final UserModel? selectedMentor;

  const BonusState({
    this.errorMessage,
    this.status = BonusStateStatus.initial,
    this.bonuses = const [],
    this.selectedChip = BonusChip.request,
    this.selectedKid,
    this.selectedMentor,
  });

  BonusState copyWith({
    String? errorMessage,
    BonusStateStatus? status,
    List<BonusModel>? bonuses,
    BonusChip? selectedChip,
    UserModel? selectedKid,
    UserModel? selectedMentor,
  }) {
    return BonusState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      bonuses: bonuses ?? this.bonuses,
      selectedChip: selectedChip ?? this.selectedChip,
      selectedKid: selectedKid ?? this.selectedKid,
      selectedMentor: selectedMentor ?? this.selectedMentor,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        bonuses,
        selectedChip,
        selectedKid,
        selectedMentor,
      ];

  BonusState reset() => const BonusState();

  BonusState resetSelectedKid() {
    return BonusState(
      errorMessage: errorMessage,
      status: status,
      bonuses: bonuses,
      selectedChip: selectedChip,
      selectedKid: null,
      selectedMentor: selectedMentor,
    );
  }

  BonusState resetSelectedMentor() {
    return BonusState(
      errorMessage: errorMessage,
      status: status,
      bonuses: bonuses,
      selectedChip: selectedChip,
      selectedKid: selectedKid,
      selectedMentor: null,
    );
  }
}
