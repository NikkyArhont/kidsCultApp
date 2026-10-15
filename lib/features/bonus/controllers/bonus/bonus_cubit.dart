import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:child_tracker/shared/services/balance_service.dart';
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
  int _subscriptionGeneration = 0;
  int _sessionGeneration = 0;

  bool Function() _operationGuard() {
    final generation = _sessionGeneration;
    final userId = _userCubit.state?.id;
    return () => !isClosed && generation == _sessionGeneration && userId != null && _userCubit.state?.id == userId;
  }

  Future<void> init() async {
    final generation = ++_subscriptionGeneration;
    final previous = _bonusStreamSubscription;
    _bonusStreamSubscription = null;
    await previous?.cancel();
    if (isClosed || generation != _subscriptionGeneration) return;
    final me = _userCubit.state;
    if (me == null) {
      emit(state.reset());
      return;
    }
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

    _bonusStreamSubscription = query.snapshots().listen(
      (event) {
        if (isClosed || generation != _subscriptionGeneration) return;
        final bonuses = event.docs.map((e) => BonusModel.fromFirestore(e)).toList();
        emit(state.copyWith(bonuses: bonuses, status: BonusStateStatus.success));
      },
      onError: (Object error) {
        if (isClosed || generation != _subscriptionGeneration) return;
        emit(state.copyWith(errorMessage: error.toString(), status: BonusStateStatus.error));
      },
    );
  }

  Future<void> reset() async {
    ++_sessionGeneration;
    ++_subscriptionGeneration;
    final previous = _bonusStreamSubscription;
    _bonusStreamSubscription = null;
    if (!isClosed) emit(state.reset());
    await previous?.cancel();
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

  Future<void> cancelBonus(BonusModel bonus, String? reason) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: BonusStateStatus.canceling));
    try {
      await _updateStatus(
          bonus,
          {
            'status': BonusStatus.canceled.name,
            'cancel_reason': reason,
          },
          allowed: {BonusStatus.active, BonusStatus.needApprove},
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      if (_userCubit.state?.isKid == false) {
        //mentor owner cancel bonus
        _fcm.sendPushToKidOnBonusCanceled(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.cancelSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {cancelBonus}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.cancelError, errorMessage: e.toString()));
    }
  }

  Future<bool> deleteBonus(BonusModel bonus) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return false;
    try {
      await _updateStatus(bonus, {'status': BonusStatus.deleted.name},
          allowed: {
            BonusStatus.active,
            BonusStatus.needApprove,
            BonusStatus.canceled,
            BonusStatus.rejected,
            BonusStatus.received,
          },
          isCurrent: isCurrent);
      if (!isCurrent()) return false;

      return true;
    } catch (e) {
      if (!isCurrent()) return false;
      print('error: {deleteBonus}: ${e.toString()}');
      return false;
    }
  }

  Future<void> requestBonusByKid(BonusModel bonus) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: BonusStateStatus.requestingReceive));
    try {
      final user = _userCubit.state;
      if (user == null || !user.isKid) throw StateError('Ребенок не найден.');
      final result = await BalanceService(_fs).purchaseBonus(bonus.id, user.id);
      if (!isCurrent()) return;
      if (_userCubit.state?.id == result.kidId) {
        _userCubit.setUser(_userCubit.state!.copyWith(points: result.points));
      }

      emit(state.copyWith(status: BonusStateStatus.requestReceiveSuccess));

      if (result.changed && bonus.mentor != null) {
        //kid request bonus
        _fcm.sendPushToMentorOnBonusRequested(bonus.mentor!, user.name, bonus.name, bonus.id);
      }
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {requestBonusByKid}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.requestReceiveError, errorMessage: e.toString()));
    }
  }

  Future<void> rejectBonus(BonusModel bonus, String? reason) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: BonusStateStatus.rejecting));
    try {
      await _updateStatus(
          bonus,
          {
            'status': BonusStatus.rejected.name,
            'cancel_reason': reason,
          },
          allowed: {BonusStatus.needApprove},
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      if (_userCubit.state?.isKid == false) {
        //mentor owner reject bonus
        _fcm.sendPushToKidOnBonusRejected(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.rejectSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {rejectBonus}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.rejectError, errorMessage: e.toString()));
    }
  }

  Future<void> rejectRequest(BonusModel bonus, String? reason) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: BonusStateStatus.rejecting));
    try {
      final user = _userCubit.state;
      if (user == null || user.isKid) throw StateError('Наставник не найден.');
      await BalanceService(_fs).refundBonus(bonus.id, user.id, reason);
      if (!isCurrent()) return;

      emit(state.copyWith(status: BonusStateStatus.rejectSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {rejectRequest}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.rejectError, errorMessage: e.toString()));
    }
  }

  Future<void> approveBonus(BonusModel bonus, int point) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: BonusStateStatus.approving));
    try {
      if (point < 0) throw StateError('Некорректное количество баллов.');
      await _updateStatus(
          bonus,
          {
            'status': BonusStatus.active.name,
            'point': point,
          },
          allowed: {BonusStatus.needApprove},
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      if (_userCubit.state?.isKid == false) {
        //mentor owner approve bonus
        _fcm.sendPushToKidOnBonusApproved(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.approveSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {approveBonus}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.approveError, errorMessage: e.toString()));
    }
  }

  Future<void> approveRequest(BonusModel bonus) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: BonusStateStatus.requestApproving));
    try {
      await _updateStatus(
          bonus,
          {
            'status': BonusStatus.received.name,
          },
          allowed: {BonusStatus.readyToReceive},
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      if (_userCubit.state?.isKid == false) {
        //mentor owner approve bonus request
        _fcm.sendPushToKidOnBonusRequestApproved(bonus.kid!, bonus.name, bonus.id);
      }

      emit(state.copyWith(status: BonusStateStatus.requestApproveSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {approveRequest}: ${e.toString()}');
      emit(state.copyWith(status: BonusStateStatus.requestApproveError, errorMessage: e.toString()));
    }
  }

  Future<void> _updateStatus(
    BonusModel bonus,
    Map<String, dynamic> update, {
    required bool Function() isCurrent,
    required Set<BonusStatus> allowed,
  }) async {
    if (!isCurrent()) throw StateError('Сессия пользователя изменилась.');
    final ref = _fs.collection('bonuses').doc(bonus.id);
    await _fs.runTransaction((transaction) async {
      if (!isCurrent()) throw StateError('Сессия пользователя изменилась.');
      final snapshot = await transaction.get(ref);
      if (!isCurrent()) throw StateError('Сессия пользователя изменилась.');
      final data = snapshot.data();
      if (data == null) throw StateError('Бонус не найден.');
      final current = data['status'];
      if (current == update['status']) return;
      if (!allowed.any((status) => status.name == current) || current != bonus.status?.name) {
        throw StateError('Бонус уже изменен. Обновите страницу.');
      }
      transaction.update(ref, update);
    });
  }

  @override
  Future<void> close() async {
    await reset();
    await super.close();
  }
}
