import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class EditBonusCubit extends Cubit<EditBonusState> {
  final UserCubit _userCubit;

  final BonusModel _bonus;

  EditBonusCubit({
    required UserCubit userCubit,
    required BonusModel bonus,
  })  : _userCubit = userCubit,
        _bonus = bonus,
        super(const EditBonusState());

  void init() async {
    bool isEmoji = _bonus.photo?.startsWith('emoji:') ?? false;
    String? photoUrl = _bonus.photo == null
        ? null
        : isEmoji
            ? null
            : _bonus.photo;
    emit(state.copyWith(
      photoUrl: photoUrl,
      emoji: isEmoji ? _bonus.photo?.replaceAll('emoji:', '') : null,
      name: _bonus.name,
      link: _bonus.link,
      point: _bonus.point,
    ));

    UserModel? mentor;
    UserModel? kid;

    final List<DocumentSnapshot> snapshots = await Future.wait([
      _bonus.mentor!.get(),
      _bonus.kid!.get(),
    ]);

    final mentorSnapshot = snapshots[0];
    final kidSnapshot = snapshots[1];

    if (mentorSnapshot.exists) {
      mentor = UserModel.fromFirestore(mentorSnapshot);
    }
    if (kidSnapshot.exists) {
      kid = UserModel.fromFirestore(kidSnapshot);
    }

    emit(state.copyWith(mentor: mentor, kid: kid));
  }

  void onChangeName(String name) {
    emit(state.copyWith(name: name));
  }

  void onChangeLink(String link) {
    emit(state.copyWith(link: link));
  }

  void onChangePhoto(XFile photo) {
    emit(state.copyWith(photo: photo, emoji: 'delete'));
  }

  void onChangeEmoji(String emoji) {
    emit(state.copyWith(emoji: emoji, photo: XFile('delete')));
  }

  void onChangePoint(int point) {
    emit(state.copyWith(point: point));
  }

  void onChangeKid(UserModel kid) {
    emit(state.copyWith(kid: kid));
  }

  void onChangeMentor(UserModel mentor) {
    emit(state.copyWith(kid: mentor));
  }

  void editBonus() async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: EditBonusStatus.error));
      return;
    }

    if (state.name == null || (state.point == null && !user.isKid) || (state.kid == null && state.mentor == null)) {
      emit(state.copyWith(errorMessage: 'fillAllFields'.tr(), status: EditBonusStatus.error));
      return;
    }

    try {
      emit(state.copyWith(status: EditBonusStatus.loading));

      final data = {
        'kid': (user.isKid) ? user.ref : state.kid!.ref,
        'mentor': (user.isKid) ? state.mentor!.ref : user.ref,
        'name': state.name,
        'link': (state.link ?? '').trim().isEmpty ? null : state.link?.trim(),
        'point': state.point,
      };

      if (state.photo != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(file: state.photo!, type: UploadType.user, uid: user.id);
        if (photoUrl == null) {
          emit(state.copyWith(status: EditBonusStatus.error, errorMessage: 'photoUploadError'.tr()));
          return;
        } else {
          data['photo'] = photoUrl;
        }
      } else if (state.emoji != null) {
        data['photo'] = 'emoji:${state.emoji}';
      }

      await _bonus.ref.update(data);

      emit(state.copyWith(status: EditBonusStatus.success));
    } catch (e) {
      print('error {editBonus}: $e');
      emit(state.copyWith(errorMessage: e.toString(), status: EditBonusStatus.error));
    }
  }

  void reset() => emit(state.reset());
}
