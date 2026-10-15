import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:child_tracker/shared/services/balance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class TaskCubit extends Cubit<TaskState> {
  final UserCubit _userCubit;
  final FirebaseFirestore _fs;
  final FirebaseMessaginService _fcm;

  TaskCubit({
    required UserCubit userCubit,
    required FirebaseFirestore fs,
    required FirebaseMessaginService fcm,
  })  : _userCubit = userCubit,
        _fs = fs,
        _fcm = fcm,
        super(TaskState(currentDay: DateTime.now()));

  StreamSubscription? _taskStreamSubscription;
  int _subscriptionGeneration = 0;
  int _sessionGeneration = 0;

  bool Function() _operationGuard() {
    final generation = _sessionGeneration;
    final userId = _userCubit.state?.id;
    return () => !isClosed && generation == _sessionGeneration && userId != null && _userCubit.state?.id == userId;
  }

  Future<void> init() async {
    final generation = ++_subscriptionGeneration;
    final previous = _taskStreamSubscription;
    _taskStreamSubscription = null;
    await previous?.cancel();
    if (isClosed || generation != _subscriptionGeneration) return;
    final me = _userCubit.state;
    if (me == null) {
      emit(state.reset());
      return;
    }
    emit(state.copyWith(status: TaskStateStatus.loading));

    late Query query;

    if (me.isKid) {
      query = _fs
          .collection('tasks')
          .where('kid', isEqualTo: me.ref)
          .where('status', isNotEqualTo: TaskStatus.deleted.name)
          .orderBy('created_at', descending: true);

      final selectedMentor = state.selectedMentor;
      if (selectedMentor != null) {
        query = query.where('owner', isEqualTo: selectedMentor.ref);
      }
    } else {
      query = _fs
          .collection('tasks')
          .where('owner', isEqualTo: me.ref)
          .where('status', isNotEqualTo: TaskStatus.deleted.name)
          .orderBy('created_at', descending: true);

      final selectedKid = state.selectedKid;
      if (selectedKid != null) {
        query = query.where('kid', isEqualTo: selectedKid.ref);
      }
    }

    _taskStreamSubscription = query.snapshots().listen(
      (event) {
        if (isClosed || generation != _subscriptionGeneration) return;
        final tasks = event.docs.map((e) => TaskModel.fromFirestore(e)).toList();
        emit(state.copyWith(tasks: tasks, status: TaskStateStatus.success));
      },
      onError: (Object error) {
        if (isClosed || generation != _subscriptionGeneration) return;
        emit(state.copyWith(errorMessage: error.toString(), status: TaskStateStatus.error));
      },
    );
  }

  Future<void> reset() async {
    ++_sessionGeneration;
    ++_subscriptionGeneration;
    final previous = _taskStreamSubscription;
    _taskStreamSubscription = null;
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

  void onKidTaskChipSelected(KidTaskChip chip) {
    emit(state.copyWith(selectedKidChip: chip));
  }

  void onChangeDate(DateTime date) {
    emit(state.copyWith(currentDay: date));
  }

  Future<void> cancelTask(TaskModel task, String? reason) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: TaskStateStatus.canceling));
    try {
      await _updateStatus(
          task,
          {
            'status': TaskStatus.canceled.name,
            'cancel_reason': reason,
            'action_date': FieldValue.serverTimestamp(),
          },
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      if (_userCubit.state?.isKid == false) {
        //mentor owner cancel task
        _fcm.sendPushToKidOnTaskCanceled(task);
      }

      emit(state.copyWith(status: TaskStateStatus.cancelSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {cancelTask}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.cancelError, errorMessage: e.toString()));
    }
  }

  Future<bool> deleteTask(TaskModel task) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return false;
    try {
      await _updateStatus(task, {'status': TaskStatus.deleted.name}, isCurrent: isCurrent);
      if (!isCurrent()) return false;

      if (_userCubit.state?.isKid == false) {
        //mentor owner cancel task
        _fcm.sendPushToKidOnTaskDeleted(task);
      }

      return true;
    } catch (e) {
      if (!isCurrent()) return false;
      print('error: {deleteTask}: ${e.toString()}');
      return false;
    }
  }

  //Когда ребенок завершает собственную задачу
  Future<bool> completeTask(TaskModel task) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return false;
    try {
      await _updateStatus(
          task,
          {
            'status': TaskStatus.completed.name,
            'action_date': FieldValue.serverTimestamp(),
          },
          isCurrent: isCurrent);
      if (!isCurrent()) return false;
      return true;
    } catch (e) {
      if (!isCurrent()) return false;
      print('error: {completeTask}: ${e.toString()}');
      return false;
    }
  }

  Future<void> completeByKid(TaskModel task, String? comment, List<XFile> files) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: TaskStateStatus.kidCompleting));

    try {
      Map<String, dynamic>? dialogDoc;
      if (comment != null || files.isNotEmpty) {
        dialogDoc = {
          "comment": comment,
          "user": _userCubit.state?.ref,
          "time": FieldValue.serverTimestamp(),
        };

        if (files.isNotEmpty) {
          final uploadService = FirebaseStorageService();
          final List<String> urls = [];

          for (final file in files) {
            final photoUrl = await uploadService.uploadFile(file: file, type: UploadType.task, uid: task.id);
            if (!isCurrent()) return;
            if (photoUrl == null) {
              emit(state.copyWith(status: TaskStateStatus.kidCompletingError));
              return;
            } else {
              urls.add(photoUrl);
            }
          }

          dialogDoc['files'] = urls;
        }
      }

      await _updateStatus(
          task,
          {
            'status': TaskStatus.onReview.name,
          },
          dialogDoc: dialogDoc,
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      _fcm.sendPushToMentorOnTaskSentToReview(task);

      emit(state.copyWith(status: TaskStateStatus.kidCompletingSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {completeByKid}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.kidCompletingError));
    }
  }

  Future<void> completeByKidSkip(TaskModel task) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: TaskStateStatus.kidCompletingSkip));

    try {
      await _updateStatus(
          task,
          {
            'status': TaskStatus.onReview.name,
          },
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      _fcm.sendPushToMentorOnTaskSentToReview(task);

      emit(state.copyWith(status: TaskStateStatus.kidCompletingSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {completeByKid}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.kidCompletingError));
    }
  }

  Future<void> reworkByMentor(TaskModel task, String? comment, List<XFile> files) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: TaskStateStatus.mentorSendRework));

    try {
      Map<String, dynamic>? dialogDoc;
      if (comment != null || files.isNotEmpty) {
        dialogDoc = {
          "comment": comment,
          "user": _userCubit.state?.ref,
          "time": FieldValue.serverTimestamp(),
        };

        if (files.isNotEmpty) {
          final uploadService = FirebaseStorageService();
          final List<String> urls = [];

          for (final file in files) {
            final photoUrl = await uploadService.uploadFile(file: file, type: UploadType.task, uid: task.id);
            if (!isCurrent()) return;
            if (photoUrl == null) {
              emit(state.copyWith(status: TaskStateStatus.mentorSendReworkError));
              return;
            } else {
              urls.add(photoUrl);
            }
          }

          dialogDoc['files'] = urls;
        }
      }

      await _updateStatus(
          task,
          {
            'status': TaskStatus.needsRework.name,
          },
          dialogDoc: dialogDoc,
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      _fcm.sendPushToKidOnTaskRework(task);

      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {reworkByMentor}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkError));
    }
  }

  Future<void> reworkByMentorSkip(TaskModel task) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    emit(state.copyWith(status: TaskStateStatus.mentorSendReworkSkip));

    try {
      await _updateStatus(
          task,
          {
            'status': TaskStatus.needsRework.name,
          },
          isCurrent: isCurrent);
      if (!isCurrent()) return;

      _fcm.sendPushToKidOnTaskRework(task);

      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {reworkByMentorSkip}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkError));
    }
  }

  Future<void> completeByMentor(TaskModel task) async {
    final isCurrent = _operationGuard();
    if (!isCurrent()) return;
    final user = _userCubit.state;
    emit(state.copyWith(status: TaskStateStatus.mentorCompleting));

    try {
      if (user == null || user.isKid) throw StateError('Наставник не найден.');
      if (task.kid != null) {
        final taskKid = await _userCubit.getUserByRef(task.kid!);
        if (!isCurrent()) return;
        emit(state.copyWith(currentTaskKid: taskKid));
      }

      final result = await BalanceService(_fs).completeTask(task.id, user.id);
      if (!isCurrent()) return;
      if (result.changed) _fcm.sendPushToKidOnTaskComplete(task);

      if (!isCurrent()) return;
      emit(state.copyWith(status: TaskStateStatus.mentorCompletingSuccess));
    } catch (e) {
      if (!isCurrent()) return;
      print('error: {completeByMentor}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.mentorCompletingError));
    }
  }

  Future<void> _updateStatus(
    TaskModel task,
    Map<String, dynamic> update, {
    required bool Function() isCurrent,
    Map<String, dynamic>? dialogDoc,
  }) async {
    if (!isCurrent()) throw StateError('Сессия пользователя изменилась.');
    final ref = _fs.collection('tasks').doc(task.id);
    final dialogRef = dialogDoc == null ? null : ref.collection('dialogs').doc();
    await _fs.runTransaction((transaction) async {
      if (!isCurrent()) throw StateError('Сессия пользователя изменилась.');
      final snapshot = await transaction.get(ref);
      if (!isCurrent()) throw StateError('Сессия пользователя изменилась.');
      final data = snapshot.data();
      if (data == null) throw StateError('Задание не найдено.');
      final current = data['status'];
      if (current == update['status']) return;
      if (current == TaskStatus.completed.name || current == TaskStatus.deleted.name) {
        throw StateError('Задание уже завершено или удалено.');
      }
      // Stale screens must not overwrite a newer review/cancel decision.
      if (current != task.status?.name) throw StateError('Задание уже изменено. Обновите страницу.');
      transaction.update(ref, update);
      if (dialogRef != null && dialogDoc != null) transaction.set(dialogRef, dialogDoc);
    });
  }

  @override
  Future<void> close() async {
    await reset();
    await super.close();
  }
}
