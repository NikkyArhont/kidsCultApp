import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserCubit _userCubit;
  ProfileCubit({required UserCubit userCubit})
      : _userCubit = userCubit,
        super(const ProfileState());

  void updateProfile(Map<String, dynamic> data, XFile? file) async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(status: ProfileStateStatus.error, errorMessage: "userNotFound".tr()));
      return;
    }
    emit(state.copyWith(status: ProfileStateStatus.saving));
    try {
      final Map<Object, Object?> newData = user.isKid
          ? {
              'name': data['name'],
              'city': data['city'],
              'birth_date': (data['birth_date'] as DateTime),
            }
          : {'name': data['name']};

      if (file != null) {
        final service = FirebaseStorageService();
        final String? url = await service.uploadFile(file: file, type: UploadType.user, uid: user.id);
        newData['photo'] = url;
      }

      await user.ref.update(newData);

      _userCubit.setUser(user.copyWith(
        name: data['name'],
        city: data['city'],
        birthDate: (data['birth_date'] as DateTime?),
        photo: newData['photo'] as String?,
      ));

      emit(state.copyWith(status: ProfileStateStatus.success));
    } catch (e) {
      print('Error {updateProfile}: $e');
      emit(state.copyWith(status: ProfileStateStatus.error, errorMessage: e.toString()));
    }
  }
}
