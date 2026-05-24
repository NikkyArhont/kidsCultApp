import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'edit_state.dart';

class MentorTaskEditCubit extends Cubit<MentorTaskEditState> {
  final UserCubit _userCubit;
  final TaskModel _task;

  MentorTaskEditCubit({
    required UserCubit userCubit,
    required TaskModel task,
  })  : _userCubit = userCubit,
        _task = task,
        super(const MentorTaskEditState());

  void init() async {
    bool isEmoji = _task.photo?.startsWith('emoji:') ?? false;
    String? photoUrl = _task.photo == null
        ? null
        : isEmoji
            ? null
            : _task.photo;

    final UserModel? selectedKid = _task.kid != null ? await _userCubit.getUserByRef(_task.kid!) : null;
    emit(state.copyWith(
      photoUrl: photoUrl,
      emoji: isEmoji ? _task.photo?.replaceAll('emoji:', '') : null,
      name: _task.name,
      description: _task.description,
      startData: _task.startDate,
      endData: _task.endDate,
      reminderType: _task.reminderType,
      reminderDate: _task.reminderDate,
      reminderTime: _task.reminderTime,
      reminderDays: _task.reminderDays,
      selectedKid: selectedKid,
      isTaskOfDay: _task.type == TaskType.priority,
      point: _task.coin ?? 0,
    ));
  }

  void onChangeNameAndDescription(String name, String? description) {
    emit(state.copyWith(name: name, description: description));
  }

  void onChangePhoto(XFile photo) {
    emit(state.copyWith(photo: photo, emoji: 'delete'));
  }

  void onChangeEmoji(String emoji) {
    emit(state.copyWith(emoji: emoji, photo: XFile('delete')));
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

  void onChangeKid(UserModel kid) {
    emit(state.copyWith(selectedKid: kid));
  }

  void onChangePoint(int point) {
    emit(state.copyWith(point: point));
  }

  void editTask() async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: MentorTaskEditStatus.error));
      return;
    }

    if (state.name == null ||
        state.startData == null ||
        state.selectedKid == null ||
        (state.photo == null && state.emoji == null)) {
      emit(state.copyWith(errorMessage: 'fillAllFields'.tr(), status: MentorTaskEditStatus.error));
      return;
    }

    try {
      emit(state.copyWith(status: MentorTaskEditStatus.loading));

      final taskRef = _task.ref;

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
        'kid': state.selectedKid!.ref,
        'name': state.name,
        'description': state.description,
        'start_date': state.startData,
        'end_date': state.endData,
        'reminder_type': state.reminderType.name,
        'reminder_date': state.reminderDate,
        'reminder_time': reminderTime,
        'reminder_days': state.reminderDays,
        'type': state.isTaskOfDay ? TaskType.priority.name : TaskType.mentor.name,
        'coin': state.point ?? 0,
      };

      if (state.photo != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(file: state.photo!, type: UploadType.user, uid: user.id);
        if (photoUrl == null) {
          emit(state.copyWith(status: MentorTaskEditStatus.error, errorMessage: 'photoUploadError'.tr()));
          return;
        } else {
          data['photo'] = photoUrl;
        }
      } else if (state.emoji != null) {
        data['photo'] = 'emoji:${state.emoji}';
      }

      await taskRef.update(data);

      emit(state.copyWith(status: MentorTaskEditStatus.success));
    } catch (e) {
      print('error {editTask}: $e');
      emit(state.copyWith(errorMessage: e.toString(), status: MentorTaskEditStatus.error));
    }
  }

  void reset() => emit(state.reset());
}
