import 'dart:async';

import 'package:child_tracker/index.dart';
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

  void init() {
    final me = _userCubit.state;
    if (me == null) return;
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

    _taskStreamSubscription = query.snapshots().listen((event) {
      final tasks = event.docs.map((e) => TaskModel.fromFirestore(e)).toList();
      emit(state.copyWith(tasks: tasks, status: TaskStateStatus.success));
    })
      ..onError(
        (_, e) {
          emit(state.copyWith(errorMessage: e.toString(), status: TaskStateStatus.error));
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

  void onKidTaskChipSelected(KidTaskChip chip) {
    emit(state.copyWith(selectedKidChip: chip));
  }

  void onChangeDate(DateTime date) {
    emit(state.copyWith(currentDay: date));
  }

  void cancelTask(TaskModel task, String? reason) async {
    emit(state.copyWith(status: TaskStateStatus.canceling));
    try {
      await task.ref.update({
        'status': TaskStatus.canceled.name,
        'cancel_reason': reason,
        'action_date': FieldValue.serverTimestamp(),
      });

      if (_userCubit.state?.isKid == false) {
        //mentor owner cancel task
        _fcm.sendPushToKidOnTaskCanceled(task);
      }

      emit(state.copyWith(status: TaskStateStatus.cancelSuccess));
    } catch (e) {
      print('error: {cancelTask}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.cancelError, errorMessage: e.toString()));
    }
  }

  Future<bool> deleteTask(TaskModel task) async {
    try {
      await task.ref.update({'status': TaskStatus.deleted.name});

      if (_userCubit.state?.isKid == false) {
        //mentor owner cancel task
        _fcm.sendPushToKidOnTaskDeleted(task);
      }

      return true;
    } catch (e) {
      print('error: {deleteTask}: ${e.toString()}');
      return false;
    }
  }

  //Когда ребенок завершает собственную задачу
  Future<bool> completeTask(TaskModel task) async {
    try {
      await task.ref.update({
        'status': TaskStatus.completed.name,
        'action_date': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('error: {completeTask}: ${e.toString()}');
      return false;
    }
  }

  Future<void> completeByKid(TaskModel task, String? comment, List<XFile> files) async {
    emit(state.copyWith(status: TaskStateStatus.kidCompleting));

    if (comment != null || files.isNotEmpty) {
      final Map<String, dynamic> dialogDoc = {
        "comment": comment,
        "user": _userCubit.state?.ref,
        "time": FieldValue.serverTimestamp(),
      };

      if (files.isNotEmpty) {
        final uploadService = FirebaseStorageService();
        final List<String> urls = [];

        for (final file in files) {
          final photoUrl = await uploadService.uploadFile(file: file, type: UploadType.task, uid: task.id);
          if (photoUrl == null) {
            emit(state.copyWith(status: TaskStateStatus.kidCompletingError));
            return;
          } else {
            urls.add(photoUrl);
          }
        }

        dialogDoc['files'] = urls;
      }

      final dialogRef = task.ref.collection('dialogs').doc();
      await dialogRef.set(dialogDoc);
    }

    try {
      await task.ref.update({
        'status': TaskStatus.onReview.name,
      });

      _fcm.sendPushToMentorOnTaskSentToReview(task);

      emit(state.copyWith(status: TaskStateStatus.kidCompletingSuccess));
    } catch (e) {
      print('error: {completeByKid}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.kidCompletingError));
    }
  }

  Future<void> completeByKidSkip(TaskModel task) async {
    emit(state.copyWith(status: TaskStateStatus.kidCompletingSkip));

    try {
      await task.ref.update({
        'status': TaskStatus.onReview.name,
      });

      _fcm.sendPushToMentorOnTaskSentToReview(task);

      emit(state.copyWith(status: TaskStateStatus.kidCompletingSuccess));
    } catch (e) {
      print('error: {completeByKid}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.kidCompletingError));
    }
  }

  Future<void> reworkByMentor(TaskModel task, String? comment, List<XFile> files) async {
    emit(state.copyWith(status: TaskStateStatus.mentorSendRework));

    if (comment != null || files.isNotEmpty) {
      final Map<String, dynamic> dialogDoc = {
        "comment": comment,
        "user": _userCubit.state?.ref,
        "time": FieldValue.serverTimestamp(),
      };

      if (files.isNotEmpty) {
        final uploadService = FirebaseStorageService();
        final List<String> urls = [];

        for (final file in files) {
          final photoUrl = await uploadService.uploadFile(file: file, type: UploadType.task, uid: task.id);
          if (photoUrl == null) {
            emit(state.copyWith(status: TaskStateStatus.mentorSendReworkError));
            return;
          } else {
            urls.add(photoUrl);
          }
        }

        dialogDoc['files'] = urls;
      }

      final dialogRef = task.ref.collection('dialogs').doc();
      await dialogRef.set(dialogDoc);
    }

    try {
      await task.ref.update({
        'status': TaskStatus.needsRework.name,
      });

      _fcm.sendPushToKidOnTaskRework(task);

      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkSuccess));
    } catch (e) {
      print('error: {reworkByMentor}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkError));
    }
  }

  Future<void> reworkByMentorSkip(TaskModel task) async {
    emit(state.copyWith(status: TaskStateStatus.mentorSendReworkSkip));

    try {
      await task.ref.update({
        'status': TaskStatus.needsRework.name,
      });

      _fcm.sendPushToKidOnTaskRework(task);

      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkSuccess));
    } catch (e) {
      print('error: {reworkByMentorSkip}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.mentorSendReworkError));
    }
  }

  Future<void> completeByMentor(TaskModel task) async {
    emit(state.copyWith(status: TaskStateStatus.mentorCompleting));

    try {
      if (task.kid != null) {
        final taskKid = await _userCubit.getUserByRef(task.kid!);
        emit(state.copyWith(currentTaskKid: taskKid));
      }

      await task.ref.update({
        'status': TaskStatus.completed.name,
        'action_date': FieldValue.serverTimestamp(),
      });

      await _onAddPointToKid(task);

      _fcm.sendPushToKidOnTaskComplete(task);

      emit(state.copyWith(status: TaskStateStatus.mentorCompletingSuccess));
    } catch (e) {
      print('error: {completeByMentor}: ${e.toString()}');
      emit(state.copyWith(status: TaskStateStatus.mentorCompletingError));
    }
  }

  Future<void> _onAddPointToKid(TaskModel task) async {
    final point = task.coin ?? 0;
    try {
      await task.kid?.update({
        'points': FieldValue.increment(point),
      });

      final doc = {
        'kid': task.kid,
        'mentor': task.owner,
        'created_at': FieldValue.serverTimestamp(),
        'coin': point,
        'name': 'Выполнение задания: ${task.name}',
      };

      final ref = CoinChangeModel.collection.doc();
      await ref.set(doc);
    } catch (e) {
      print('error: {_onAddPointToKid}: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _taskStreamSubscription?.cancel();
    return super.close();
  }
}
