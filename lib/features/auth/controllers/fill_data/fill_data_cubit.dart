import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class FillDataCubit extends Cubit<FillDataState> {
  final UserCubit _userCubit;
  final FirebaseAuth _auth;
  final FirebaseFirestore _fs;
  final PageController pageController;

  FillDataCubit({
    required UserCubit userCubit,
    required FirebaseAuth auth,
    required FirebaseFirestore fs,
  })  : _userCubit = userCubit,
        _auth = auth,
        _fs = fs,
        pageController = PageController(initialPage: 0),
        super(const FillDataState());

  void onChangeType(UserType type) {
    emit(state.copyWith(userType: type));
  }

  void onChangeName(String name) {
    emit(state.copyWith(name: name));
  }

  void onChangeBirthDate(DateTime birthDate) {
    emit(state.copyWith(birthDate: birthDate));
  }

  void onChangeCity(String city) {
    emit(state.copyWith(city: city));
  }

  void onChangePhoto(XFile photo) {
    emit(state.copyWith(photo: photo));
  }

  void nextPage() {
    if (state.step == 4 && state.userType == UserType.kid) {
      print('createUser kid');
      createUser();
    } else if (state.step == 1 && state.userType == UserType.mentor) {
      print('createUser mentor');
      createUser();
    } else {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      emit(state.copyWith(step: state.step + 1));
    }
  }

  void prevPage() {
    if (state.step == 0) return;
    pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    emit(state.copyWith(step: state.step - 1));
  }

  Future<void> createUser() async {
    if (_auth.currentUser == null) {
      emit(state.copyWith(status: FillDataStatus.error, errorMessage: 'userNotFound'.tr()));
      return;
    }

    if (state.userType == null || state.name == null || state.photo == null) {
      emit(state.copyWith(status: FillDataStatus.error, errorMessage: 'fillAllFields'.tr()));
      return;
    }

    emit(state.copyWith(status: FillDataStatus.loading));

    try {
      Map<String, dynamic> data = state.userType == UserType.kid ? _getKidData() : _getMentorData();

      final uploadService = FirebaseStorageService();
      final photoUrl = await uploadService.uploadFile(
        file: state.photo!,
        type: UploadType.user,
        uid: _auth.currentUser!.uid,
      );
      if (photoUrl == null) {
        emit(state.copyWith(status: FillDataStatus.error, errorMessage: 'photoUploadError'.tr()));
        return;
      } else {
        data['photo'] = photoUrl;
      }

      final userRef = _fs.collection('users').doc(_auth.currentUser!.uid);
      await userRef.update(data);
      await _userCubit.getAndSet(_auth.currentUser!);
      await _createSupportChat(userRef);
      emit(state.copyWith(status: FillDataStatus.success));
    } catch (e) {
      print('Error {createUser}: $e');
      emit(state.copyWith(status: FillDataStatus.error, errorMessage: '$e'));
    }
  }

  Map<String, dynamic> _getMentorData() {
    Map<String, dynamic> userData = {
      'type': state.userType!.name,
      'name': state.name!,
      'profile_filled': true,
      'trial_subscription': DateTime.now().add(const Duration(days: 30)),
      'deleted': false,
      'banned': false,
    };
    return userData;
  }

  Map<String, dynamic> _getKidData() {
    Map<String, dynamic> userData = {
      'type': state.userType!.name,
      'name': state.name!,
      'profile_filled': true,
      'birth_date': state.birthDate,
      'city': state.city,
      'deleted': false,
      'banned': false,
    };
    return userData;
  }

  Future<void> _createSupportChat(DocumentReference userRef) async {
    try {
      final newChatRef = _fs.collection('chats').doc();

      final members = [userRef];
      final unreads = {userRef.id: 0, 'support': 0};
      final notification = {userRef.id: true};

      final Map<String, dynamic> newChatData = {
        'members': members,
        'unmodified_members': members,
        'type': ChatType.support.name,
        'last_edit_time': FieldValue.serverTimestamp(),
        'unreads': unreads,
        'notification': notification,
      };

      await newChatRef.set(newChatData);
    } catch (e) {
      rethrow;
    }
  }

  void reset() => emit(state.reset());

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
