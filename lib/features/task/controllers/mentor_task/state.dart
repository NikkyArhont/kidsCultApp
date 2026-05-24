part of 'create_mentor_task_cubit.dart';

enum MentorTaskCreateStatus { initial, loading, success, error }

class MentorTaskCreateState extends Equatable {
  final String? errorMessage;
  final MentorTaskCreateStatus status;
  final bool isEditMode;
  final UserModel? selectedKid;
  final String? name;
  final String? description;
  final String? emoji;
  final XFile? photo;
  final int? point;
  final DateTime? startData;
  final DateTime? endData;
  final ReminderType reminderType;
  final DateTime? reminderDate;
  final TimeOfDay? reminderTime;
  final List<int> reminderDays;
  final List<TaskModel> usedTasks;
  final bool isTaskOfDay;
  final int step;
  final TaskModel? suggestTask;

  const MentorTaskCreateState({
    this.errorMessage,
    this.status = MentorTaskCreateStatus.initial,
    this.isEditMode = false,
    this.name,
    this.description,
    this.emoji,
    this.photo,
    this.point,
    this.startData,
    this.endData,
    this.reminderType = ReminderType.single,
    this.reminderDate,
    this.reminderTime,
    this.reminderDays = const [],
    this.step = 0,
    this.selectedKid,
    this.usedTasks = const [],
    this.isTaskOfDay = false,
    this.suggestTask,
  });

  MentorTaskCreateState copyWith({
    String? errorMessage,
    MentorTaskCreateStatus? status,
    bool? isEditMode,
    String? name,
    String? description,
    String? emoji,
    XFile? photo,
    int? point,
    DateTime? startData,
    DateTime? endData,
    ReminderType? reminderType,
    DateTime? reminderDate,
    TimeOfDay? reminderTime,
    List<int>? reminderDays,
    int? step,
    UserModel? selectedKid,
    List<TaskModel>? usedTasks,
    bool? isTaskOfDay,
    TaskModel? suggestTask,
  }) {
    return MentorTaskCreateState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      name: name ?? this.name,
      description: description ?? this.description,
      photo: photo == null
          ? this.photo
          : photo.path == 'delete'
              ? null
              : photo,
      emoji: emoji == null
          ? this.emoji
          : emoji == 'delete'
              ? null
              : emoji,
      startData: startData ?? this.startData,
      endData: endData == null
          ? this.endData
          : endData.year == 0
              ? null
              : endData,
      reminderType: reminderType ?? this.reminderType,
      reminderDate: reminderDate == null
          ? this.reminderDate
          : reminderDate.year == 0
              ? null
              : reminderDate,
      reminderTime: reminderTime == null
          ? this.reminderTime
          : (reminderTime.hour == 0 && reminderTime.minute == 0)
              ? null
              : reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      step: step ?? this.step,
      selectedKid: selectedKid ?? this.selectedKid,
      usedTasks: usedTasks ?? this.usedTasks,
      point: point ?? this.point,
      isTaskOfDay: isTaskOfDay ?? this.isTaskOfDay,
      suggestTask: suggestTask == null
          ? this.suggestTask
          : suggestTask.id == 'delete'
              ? null
              : suggestTask,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        isEditMode,
        name,
        description,
        emoji,
        photo,
        startData,
        endData,
        reminderType,
        reminderDate,
        reminderTime,
        reminderDays,
        step,
        selectedKid,
        usedTasks,
        point,
        isTaskOfDay,
        suggestTask,
      ];

  MentorTaskCreateState reset() => const MentorTaskCreateState();
}
