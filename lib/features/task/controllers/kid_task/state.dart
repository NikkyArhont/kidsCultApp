part of 'create_kid_task_cubit.dart';

enum KidTaskCreateStatus { initial, loading, success, error }



class KidTaskCreateState extends Equatable {
  final String? errorMessage;
  final KidTaskCreateStatus status;
  final bool isEditMode;
  final String? name;
  final String? description;
  final String? emoji;
  final XFile? photo;
  final DateTime? startData;
  final DateTime? endData;
  final ReminderType reminderType;
  final DateTime? reminderDate;
  final TimeOfDay? reminderTime;
  final List<int> reminderDays;

  final int step;

  const KidTaskCreateState({
    this.errorMessage,
    this.status = KidTaskCreateStatus.initial,
    this.isEditMode = false,
    this.name,
    this.description,
    this.emoji,
    this.photo,
    this.startData,
    this.endData,
    this.reminderType = ReminderType.single,
    this.reminderDate,
    this.reminderTime,
    this.reminderDays = const [],
    this.step = 0,
  });

  KidTaskCreateState copyWith({
    String? errorMessage,
    KidTaskCreateStatus? status,
    bool? isEditMode,
    String? name,
    String? description,
    String? emoji,
    XFile? photo,
    DateTime? startData,
    DateTime? endData,
    ReminderType? reminderType,
    DateTime? reminderDate,
    TimeOfDay? reminderTime, 
    List<int>? reminderDays,
    int? step,
  }) {
    return KidTaskCreateState(
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
      endData: endData == null ? this.endData : endData.year == 0 ? null : endData,
      reminderType: reminderType ?? this.reminderType,
      reminderDate: reminderDate == null ? this.reminderDate : reminderDate.year == 0 ? null : reminderDate,
      reminderTime: reminderTime == null ? this.reminderTime : (reminderTime.hour == 0 && reminderTime.minute == 0) ? null : reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      step: step ?? this.step,
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
      ];

  KidTaskCreateState reset() => const KidTaskCreateState();
}
