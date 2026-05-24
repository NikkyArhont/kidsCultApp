import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'edit_state.dart';

class KidTaskEditCubit extends Cubit<KidTaskEditState> {
  final UserCubit _userCubit;
  final TaskModel _task;

  KidTaskEditCubit({
    required UserCubit userCubit,
    required TaskModel task,
  })  : _userCubit = userCubit,
        _task = task,
        super(const KidTaskEditState());

  void init() {
    bool isEmoji = _task.photo?.startsWith('emoji:') ?? false;
    String? photoUrl = _task.photo == null
        ? null
        : isEmoji
            ? null
            : _task.photo;
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

  void editTask() async {
    final user = _userCubit.state;
    if (user == null) {
      emit(state.copyWith(errorMessage: 'userNotFound'.tr(), status: KidTaskEditStatus.error));
      return;
    }

    if (state.name == null || state.startData == null ) {
      emit(state.copyWith(errorMessage: 'fillAllFields'.tr(), status: KidTaskEditStatus.error));
      return;
    }

    try {
      emit(state.copyWith(status: KidTaskEditStatus.loading));

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
        'name': state.name,
        'description': state.description,
        'start_date': state.startData,
        'end_date': state.endData,
        'reminder_type': state.reminderType.name,
        'reminder_date': state.reminderDate,
        'reminder_time': reminderTime,
        'reminder_days': state.reminderDays,
      };

      if (state.photo != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(file: state.photo!, type: UploadType.user, uid: user.id);
        if (photoUrl == null) {
          emit(state.copyWith(status: KidTaskEditStatus.error, errorMessage: 'photoUploadError'.tr()));
          return;
        } else {
          data['photo'] = photoUrl;
        }
      } else if (state.emoji != null) {
        data['photo'] = 'emoji:${state.emoji}';
      }

      await taskRef.update(data);

      emit(state.copyWith(status: KidTaskEditStatus.success));
    } catch (e) {
      print('error {editTask}: $e');
      emit(state.copyWith(errorMessage: e.toString(), status: KidTaskEditStatus.error));
    }
  }

  void reset() => emit(state.reset());
}
