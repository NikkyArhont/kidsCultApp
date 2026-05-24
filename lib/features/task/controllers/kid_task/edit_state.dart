part of 'edit_kid_task_cubit.dart';

enum KidTaskEditStatus { initial, loading, success, error }

class KidTaskEditState extends Equatable {
  final String? errorMessage;
  final KidTaskEditStatus status;
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

  const KidTaskEditState({
    this.errorMessage,
    this.status = KidTaskEditStatus.initial,
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
  });

  KidTaskEditState copyWith({
    String? errorMessage,
    KidTaskEditStatus? status,
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
  }) {
    return KidTaskEditState(
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
      ];

  KidTaskEditState reset() => const KidTaskEditState();
}
