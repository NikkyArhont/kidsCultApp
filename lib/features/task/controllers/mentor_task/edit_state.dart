part of 'edit_mentor_task_cubit.dart';

enum MentorTaskEditStatus { initial, loading, success, error }

class MentorTaskEditState extends Equatable {
  final String? errorMessage;
  final MentorTaskEditStatus status;
  final String? name;
  final String? description;
  final String? emoji;
  final String? photoUrl;
  final XFile? photo;
  final DateTime? startData;
  final DateTime? endData;
  final ReminderType reminderType;
  final DateTime? reminderDate;
  final TimeOfDay? reminderTime;
  final List<int> reminderDays;
  final bool isTaskOfDay;
  final int? point;
  final UserModel? selectedKid;

  const MentorTaskEditState({
    this.errorMessage,
    this.status = MentorTaskEditStatus.initial,
    this.name,
    this.description,
    this.emoji,
    this.photo,
    this.photoUrl,
    this.startData,
    this.endData,
    this.reminderType = ReminderType.single,
    this.reminderDate,
    this.reminderTime,
    this.reminderDays = const [],
    this.isTaskOfDay = false,
    this.point,
    this.selectedKid,
  });

  MentorTaskEditState copyWith({
    String? errorMessage,
    MentorTaskEditStatus? status,
    String? name,
    String? description,
    String? emoji,
    XFile? photo,
    String? photoUrl,
    DateTime? startData,
    DateTime? endData,
    ReminderType? reminderType,
    DateTime? reminderDate,
    TimeOfDay? reminderTime,
    List<int>? reminderDays,
    bool? isTaskOfDay,
    UserModel? selectedKid,
    int? point,
  }) {
    return MentorTaskEditState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
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
      photoUrl: photoUrl ?? this.photoUrl,
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
      isTaskOfDay: isTaskOfDay ?? this.isTaskOfDay,
      selectedKid: selectedKid ?? this.selectedKid,
      point: point ?? this.point,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        name,
        description,
        emoji,
        photo,
        photoUrl,
        startData,
        endData,
        reminderType,
        reminderDate,
        reminderTime,
        reminderDays,
        isTaskOfDay,
        point,
        selectedKid,
      ];

  MentorTaskEditState reset() => const MentorTaskEditState();
}
