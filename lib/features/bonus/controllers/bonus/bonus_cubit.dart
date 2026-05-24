import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'state.dart';

class BonusCubit extends Cubit<BonusState> {
  final UserCubit _userCubit;
  final FirebaseFirestore _fs;
  final FirebaseMessaginService _fcm;

  BonusCubit({
    required UserCubit userCubit,
    required FirebaseFirestore fs,
    required FirebaseMessaginService fcm,
  })  : _userCubit = userCubit,
        _fs = fs,
        _fcm = fcm,
        super(const BonusState());

  StreamSubscription? _bonusStreamSubscription;

  void init() {
    final me = _userCubit.state;
    if (me == null) return;
    emit(state.copyWith(status: BonusStateStatus.loading));

    late Query query;

    if (me.isKid) {
      query = _fs
          .collection('bonuses')
          .where('kid', isEqualTo: me.ref)
          .where('status', isNotEqualTo: BonusStatus.deleted.name)
          .orderBy('created_at', descending: true);

      final selectedMentor = state.selectedMentor;
      if (selectedMentor != null) {
        query = query.where('mentor', isEqualTo: selectedMentor.ref);
      }
    } else {
      query = _fs
          .collection('bonuses')
          .where('mentor', isEqualTo: me.ref)
          .where('status', isNotEqualTo: BonusStatus.deleted.name)
          .orderBy('created_at', descending: true);

      final selectedKid = state.selectedKid;
      if (selectedKid != null) {
        query = query.where('kid', isEqualTo: selectedKid.ref);
      }
    }

    _bonusStreamSubscription = query.snapshots().listen((event) {
      final bonuses = event.docs.map((e) => BonusModel.fromFirestore(e)).toList();
      emit(state.copyWith(bonuses: bonuses, status: BonusStateStatus.success));
    })
      ..onError(
        (_, e) {
          print('error: {init}: ${e.toString()}');
          emit(state.copyWith(errorMessage: e.toString(), status: BonusStateStatus.error));
        },
      );
  }

  void onKidSelected(UserModel? kid) {
    if (kid == null) {
      emit(state.resetSelectedKid());
    } else {
      emit(state.copyWith(selectedKid: kid));
    }
    init();
  }

  void onMentorSelected(UserModel? mentor) {
    if (mentor == null) {
      emit(state.resetSelectedMentor());
    } else {
      emit(state.copyWith(selectedMentor: mentor));
    }
    init();
  }

  void onChipSelected(BonusChip chip) {
    emit(state.copyWith(selectedChip: chip));
  }

  void cancelBonus(BonusModel bonus, String? reason) async {
    emit(state.copyWith(status: BonusStateStatus.canceling));
    try {
      await bonus.ref.update({
        'status': BonusStatus.canceled.name,
        'cancel_reason': reason,
      });

      if (_userCubit.state?.isKid == false) {
        //mentor owner cancel bonus
        _fcm.sendPushToKidOnBonusCanceled(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.cancelSuccess));
    } catch (e) {
      print('error: {cancelBonus}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.cancelError, errorMessage: e.toString()));
    }
  }

  Future<bool> deleteBonus(BonusModel bonus) async {
    try {
      await bonus.ref.update({'status': BonusStatus.deleted.name});

      return true;
    } catch (e) {
      print('error: {deleteBonus}: ${e.toString()}');
      return false;
    }
  }

  void requestBonusByKid(BonusModel bonus) async {
    emit(state.copyWith(status: BonusStateStatus.requestingReceive));
    try {
      await bonus.ref.update({
        'status': BonusStatus.readyToReceive.name,
      });

      int bonusPoint = bonus.point ?? 0;
      await _userCubit.onChangePoint(-bonusPoint);

      final ref = CoinChangeModel.collection.doc();

      final doc = {
        'kid': bonus.kid,
        'mentor': bonus.mentor,
        'created_at': FieldValue.serverTimestamp(),
        'coin': -bonusPoint,
        'name': 'Покупка бонуса "${bonus.name}"',
      };

      await ref.set(doc);

      emit(state.copyWith(status: BonusStateStatus.requestReceiveSuccess));

      if (_userCubit.state?.isKid == true) {
        //kid request bonus
        _fcm.sendPushToMentorOnBonusRequested(bonus.mentor!, _userCubit.state?.name ?? '-', bonus.name, bonus.id);
      }
    } catch (e) {
      print('error: {requestBonusByKid}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.requestReceiveError, errorMessage: e.toString()));
    }
  }

  void rejectBonus(BonusModel bonus, String? reason) async {
    emit(state.copyWith(status: BonusStateStatus.rejecting));
    try {
      await bonus.ref.update({
        'status': BonusStatus.rejected.name,
        'cancel_reason': reason,
      });

      if (_userCubit.state?.isKid == false) {
        //mentor owner reject bonus
        _fcm.sendPushToKidOnBonusRejected(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.rejectSuccess));
    } catch (e) {
      print('error: {rejectBonus}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.rejectError, errorMessage: e.toString()));
    }
  }

  void rejectRequest(BonusModel bonus, String? reason) async {
    emit(state.copyWith(status: BonusStateStatus.rejecting));
    try {
      await bonus.ref.update({
        'status': BonusStatus.rejected.name,
        'cancel_reason': reason,
      });

      int bonusPoint = bonus.point ?? 0;
      await _userCubit.onChangePoint(bonusPoint);

      emit(state.copyWith(status: BonusStateStatus.rejectSuccess));
    } catch (e) {
      print('error: {rejectRequest}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.rejectError, errorMessage: e.toString()));
    }
  }

  void approveBonus(BonusModel bonus, int point) async {
    emit(state.copyWith(status: BonusStateStatus.approving));
    try {
      await bonus.ref.update({
        'status': BonusStatus.active.name,
        'point': point,
      });

      if (_userCubit.state?.isKid == false) {
        //mentor owner approve bonus
        _fcm.sendPushToKidOnBonusApproved(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.approveSuccess));
    } catch (e) {
      print('error: {approveBonus}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.approveError, errorMessage: e.toString()));
    }
  }

  void approveRequest(BonusModel bonus) async {
    emit(state.copyWith(status: BonusStateStatus.requestApproving));
    try {
      await bonus.ref.update({
        'status': BonusStatus.received.name,
      });

      if (_userCubit.state?.isKid == false) {
        //mentor owner approve bonus request
        _fcm.sendPushToKidOnBonusRequestApproved(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.requestApproveSuccess));
    } catch (e) {
      print('error: {approveRequest}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.requestApproveError, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _bonusStreamSubscription?.cancel();
    return super.close();
  }
}
