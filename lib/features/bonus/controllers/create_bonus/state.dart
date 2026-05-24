part of 'create_bonus_cubit.dart';

enum CreateBonusStatus { initial, loading, success, error }

class CreateBonusState extends Equatable {
  final String? errorMessage;
  final CreateBonusStatus status;
  final bool isEditMode;
  final String? name;
  final String? link;
  final String? emoji;
  final XFile? photo;
  final UserModel? kid;
  final UserModel? mentor;
  final int? point;
  final int step;

  const CreateBonusState({
    this.errorMessage,
    this.status = CreateBonusStatus.initial,
    this.isEditMode = false,
    this.name,
    this.link,
    this.emoji,
    this.photo,
    this.kid,
    this.mentor,
    this.point,
    this.step = 0,
  });

  CreateBonusState copyWith({
    String? errorMessage,
    CreateBonusStatus? status,
    bool? isEditMode,
    String? name,
    String? link,
    String? emoji,
    XFile? photo,
    UserModel? kid,
    UserModel? mentor,
    int? point,
    int? step,
  }) {
    return CreateBonusState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      name: name ?? this.name,
      link: link ?? this.link,
      photo: photo == null
          ? this.photo
          : photo.path == 'delete'
              ? null
              : photo,
      emoji: emoji == null
          ? this.emoji
          : emoji == 'delete'
              ? null
              : emoji,
      kid: kid ?? this.kid,
      mentor: mentor ?? this.mentor,
      point: point ?? this.point,
      step: step ?? this.step,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        isEditMode,
        name,
        link,
        emoji,
        photo,
        kid,
        mentor,
        point,
        step,
      ];

  CreateBonusState reset() => const CreateBonusState();
}
