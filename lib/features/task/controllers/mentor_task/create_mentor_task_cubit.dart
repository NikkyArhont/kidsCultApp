import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class MentorTaskCreateCubit extends Cubit<MentorTaskCreateState> {
  final UserCubit _userCubit;
  final FirebaseFirestore _fs;
  final FirebaseMessaginService _fcm;
  final PageController pageController;

  MentorTaskCreateCubit({
    required UserCubit userCubit,
    required FirebaseMessaginService fcm,
  })  : _userCubit = userCubit,
        _fs = FirebaseFirestore.instance,
        _fcm = fcm,
        pageController = PageController(initialPage: 0),
        super(const MentorTaskCreateState());

  void initPopularTasks() async {
    final result = await _fs.collection('tasks').orderBy('used_counter', descending: true).limit(500).get();
    final tasks = result.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    emit(state.copyWith(usedTasks: tasks));
  }

  void onChangeKid(UserModel kid) {
    emit(state.copyWith(selectedKid: kid));
  }

  void onChangeNameAndDescription(String name, String? description) {
    emit(state.copyWith(name: name, description: description));
  }

  void onSelectSuggestTask(TaskModel task) {
    emit(state.copyWith(suggestTask: task, point: task.coin));
  }

  void onDeleteSuggestTask() {
    if (state.suggestTask == null) return;
    emit(state.copyWith(suggestTask: TaskModel(id: 'delete', name: '')));
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

  void onChangeStartDate(DateTime startData) {
    emit(state.copyWith(startData: startData));
  }

  void onChangeStartTime(TimeOfDay startTime) {
    final oldStartDay = state.startData;
    if (oldStartDay == null) return;
    final newStartDate = DateTime(
      oldStartDay.year,
      oldStartDay.month,
      oldStartDay.day,
      startTime.hour,
      startTime.minute,
    );
    emit(state.copyWith(startData: newStartDate));
  }

  void onChangeEndDate(DateTime? endData) {
    emit(state.copyWith(endData: endData ?? DateTime(0)));
  }

  void onChangeEndTime(TimeOfDay endTime) {
    final oldEndDay = state.endData;
    if (oldEndDay == null) return;
    final newEndDate = DateTime(
      oldEndDay.year,
      oldEndDay.month,
      oldEndDay.day,
      endTime.hour,
      endTime.minute,
    );
    emit(state.copyWith(endData: newEndDate));
  }

  void onChangeReminderType(ReminderType type) {
    emit(state.copyWith(reminderType: type));
  }

  void onChangeReminderDate(DateTime? reminder) {
    emit(state.copyWith(reminderDate: reminder ?? DateTime(0)));
  }

  void onChangeReminderTime(TimeOfDay? time) {
    if (state.reminderType == ReminderType.single && time != null) {
      final oldReminderDay = state.reminderDate;
      if (oldReminderDay == null) return;
      final newReminderDate = DateTime(
        oldReminderDay.year,
        oldReminderDay.month,
        oldReminderDay.day,
        time.hour,
        time.minute,
      );
      emit(state.copyWith(reminderDate: newReminderDate));
    } else {
      emit(state.copyWith(reminderTime: time ?? const TimeOfDay(hour: 0, minute: 0)));
    }
  }

  void onChangeReminderDayTap(int? day) {
    if (day == null) {
      emit(state.copyWith(reminderDays: []));
    } else {
      final oldDays = List.of(state.reminderDays);
      if (oldDays.contains(day)) {
        oldDays.remove(day);
      } else {
        oldDays.add(day);
      }
      emit(state.copyWith(reminderDays: oldDays));
    }
  }

  void onChangeTaskOfDay(bool val) {
    emit(state.copyWith(isTaskOfDay: val));
  }

  void onChangeMode(bool editMode) {
    emit(state.copyWith(isEditMode: editMode));
  }

  void onJumpToPage(int page) {
    pageController.jumpToPage(page);
  }

  void nextPage() {
    if (state.step == 4) {
      // create
    }
    pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    emit(state.copyWith(step: state.step + 1));
  }

  void prevPage() {
    if (state.step == 0) return;
    pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    emit(state.copyWith(step: state.step - 1));
  }

  void createTask() async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: MentorTaskCreateStatus.error));
      return;
    }

    if (state.selectedKid == null ||
        state.name == null ||
        state.startData == null ||
        (state.photo == null && state.emoji == null)) {
      emit(state.copyWith(errorMessage: 'fillAllFields'.tr(), status: MentorTaskCreateStatus.error));
      return;
    }

    try {
      emit(state.copyWith(status: MentorTaskCreateStatus.loading));

      final newTaskRef = _fs.collection('tasks').doc();

      DateTime now = DateTime.now();
      final DateTime? reminderTime = state.reminderTime != null
          ? DateTime(
              now.year,
              now.month,
              now.day,
              state.reminderTime!.hour,
              state.reminderTime!.minute,
            )
          : null;

      final data = {
        'owner': user.ref,
        'kid': state.selectedKid!.ref,
        'name': state.name,
        'description': state.description,
        'start_date': state.startData,
        'end_date': state.endData,
        'reminder_type': state.reminderType.name,
        'reminder_date': state.reminderDate,
        'reminder_time': reminderTime,
        'reminder_days': state.reminderDays,
        'created_at': DateTime.now(),
        'type': state.isTaskOfDay ? TaskType.priority.name : TaskType.mentor.name,
        'status': TaskStatus.inProgress.name,
        'coin': state.point ?? 0,
        'used_counter': 1,
      };

      if (state.photo != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(file: state.photo!, type: UploadType.user, uid: user.id);
        if (photoUrl == null) {
          emit(state.copyWith(status: MentorTaskCreateStatus.error, errorMessage: 'photoUploadError'.tr()));
          return;
        } else {
          data['photo'] = photoUrl;
        }
      } else if (state.emoji != null) {
        data['photo'] = 'emoji:${state.emoji}';
      } else {
        emit(state.copyWith(status: MentorTaskCreateStatus.error, errorMessage: 'photoUploadError'.tr()));
      }

      await newTaskRef.set(data);

      await _markSuggestTask();

      _fcm.sendPushToKidOnTaskCreated(state.selectedKid!.ref, state.name ?? '', newTaskRef.id);

      emit(state.copyWith(status: MentorTaskCreateStatus.success));
    } catch (e) {
      print('error {createTask}: $e');
      emit(state.copyWith(errorMessage: e.toString(), status: MentorTaskCreateStatus.error));
    }
  }

  Future<void> _markSuggestTask() async {
    final suggestTask = state.suggestTask;

    if (suggestTask != null) {
      await suggestTask.ref.update({'used_counter': FieldValue.increment(1)});
    }
  }

  void reset() => emit(state.reset());

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
