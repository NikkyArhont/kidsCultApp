part of 'edit_bonus_cubit.dart';

enum EditBonusStatus { initial, loading, success, error }

class EditBonusState extends Equatable {
  final String? errorMessage;
  final EditBonusStatus status;
  final String? name;
  final String? link;
  final String? emoji;
  final String? photoUrl;
  final XFile? photo;
  final UserModel? kid;
  final UserModel? mentor;
  final int? point;

  const EditBonusState({
    this.errorMessage,
    this.status = EditBonusStatus.initial,
    this.name,
    this.link,
    this.emoji,
    this.photoUrl,
    this.photo,
    this.kid,
    this.mentor,
    this.point,
  });

  EditBonusState copyWith({
    String? errorMessage,
    EditBonusStatus? status,
    String? name,
    String? link,
    String? emoji,
    String? photoUrl,
    XFile? photo,
    UserModel? kid,
    UserModel? mentor,
    int? point,
  }) {
    return EditBonusState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
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
      photoUrl: photoUrl ?? this.photoUrl,
      kid: kid ?? this.kid,
      mentor: mentor ?? this.mentor,
      point: point ?? this.point,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        name,
        link,
        emoji,
        photo,
        kid,
        mentor,
        point,
      ];

  EditBonusState reset() => const EditBonusState();
}
