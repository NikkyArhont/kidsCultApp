import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'state.dart';

class DairyCubit extends Cubit<DairyState> {
  final UserCubit _userCubit;

  DairyCubit({
    required UserCubit userCubit,
  })  : _userCubit = userCubit,
        super(const DairyState());

  void createDairy(String text, DairyEmotion em, DateTime time) async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: DairyStateStatus.createError));
      return;
    }

    try {
      emit(state.copyWith(status: DairyStateStatus.creating));

      final dairyData = {
        'kid': user.ref,
        'created_at': FieldValue.serverTimestamp(),
        'time': time,
        'text': text,
        'emotion': em.name,
      };

      await DairyModel.collection.add(dairyData);

      emit(state.copyWith(status: DairyStateStatus.createSuccess));
    } catch (e) {
      print('error: {createDairy}: ${e.toString()}');
      emit(state.copyWith(errorMessage: e.toString(), status: DairyStateStatus.createError));
    }
  }

  void editDairy(DairyModel dairy, String text, DairyEmotion em, DateTime time) async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: DairyStateStatus.editError));
      return;
    }

    try {
      emit(state.copyWith(status: DairyStateStatus.editing));

      final dairyData = {
        'time': time,
        'text': text,
        'emotion': em.name,
      };

      await dairy.ref.update(dairyData);

      emit(state.copyWith(status: DairyStateStatus.editSuccess));
    } catch (e) {
      print('error: {editDairy}: ${e.toString()}');
      emit(state.copyWith(errorMessage: e.toString(), status: DairyStateStatus.editError));
    }
  }

  Future<void> deleteDairy(DairyModel dairy) async {
    await dairy.ref.delete();
  }
}
