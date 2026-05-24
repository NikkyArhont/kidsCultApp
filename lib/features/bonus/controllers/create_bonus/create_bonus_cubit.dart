import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class CreateBonusCubit extends Cubit<CreateBonusState> {
  final UserCubit _userCubit;
  final FirebaseFirestore _fs;
  final FirebaseMessaginService _fcm;
  final PageController pageController;

  CreateBonusCubit({
    required UserCubit userCubit,
    required FirebaseMessaginService fcm,
  })  : _userCubit = userCubit,
        _fs = FirebaseFirestore.instance,
        _fcm = fcm,
        pageController = PageController(initialPage: 0),
        super(const CreateBonusState());

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
    emit(state.copyWith(mentor: mentor));
  }

  void onChangeMode(bool editMode) {
    emit(state.copyWith(isEditMode: editMode));
  }

  void onJumpToPage(int page) {
    pageController.jumpToPage(page);
  }

  void nextPage() {
    pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    emit(state.copyWith(step: state.step + 1));
  }

  void prevPage() {
    if (state.step == 0) return;
    pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    emit(state.copyWith(step: state.step - 1));
  }

  void createBonus() async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: CreateBonusStatus.error));
      return;
    }

    if (state.name == null ||
        (state.point == null && !user.isKid) ||
        (state.photo == null && state.emoji == null) ||
        (state.kid == null && state.mentor == null)) {
      emit(state.copyWith(errorMessage: 'fillAllFields'.tr(), status: CreateBonusStatus.error));
      return;
    }

    try {
      emit(state.copyWith(status: CreateBonusStatus.loading));

      final newBonusRef = _fs.collection('bonuses').doc();

      final data = {
        'owner': user.ref,
        'kid': (user.isKid) ? user.ref : state.kid!.ref,
        'mentor': (user.isKid) ? state.mentor!.ref : user.ref,
        'name': state.name,
        'link': (state.link ?? '').trim().isEmpty ? null : state.link?.trim(),
        'point': state.point,
        'created_at': DateTime.now(),
        'status': (user.isKid) ? BonusStatus.needApprove.name : BonusStatus.active.name,
      };

      if (state.photo != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(file: state.photo!, type: UploadType.user, uid: user.id);
        if (photoUrl == null) {
          emit(state.copyWith(status: CreateBonusStatus.error, errorMessage: 'photoUploadError'.tr()));
          return;
        } else {
          data['photo'] = photoUrl;
        }
      } else if (state.emoji != null) {
        data['photo'] = 'emoji:${state.emoji}';
      } else {
        emit(state.copyWith(status: CreateBonusStatus.error, errorMessage: 'photoUploadError'.tr()));
      }

      await newBonusRef.set(data);

      if (user.isKid) {
        _fcm.sendPushToMentorOnBonusNeedApprove(
          state.mentor!.ref,
          user.name,
          state.name ?? '',
          newBonusRef.id,
        );
      } else {
        _fcm.sendPushToKidOnBonusCreated(
          state.kid!.ref,
          state.name ?? '',
          newBonusRef.id,
        );
      }

      emit(state.copyWith(status: CreateBonusStatus.success));
    } catch (e) {
      print('error {createBonus}: $e');
      emit(state.copyWith(errorMessage: e.toString(), status: CreateBonusStatus.error));
    }
  }

  void reset() => emit(state.reset());

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
