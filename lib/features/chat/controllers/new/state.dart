part of 'new_chat_cubit.dart';

enum NewChatStatus { initial, loading, success, error }

class NewChatState extends Equatable {
  final String? errorMessage;
  final NewChatStatus status;
  final List<DocumentReference> members;
  final String? name;
  final String? emoji;
  final XFile? photo;
  final int step;
  final DocumentReference? chatRef;

  const NewChatState({
    this.errorMessage,
    this.status = NewChatStatus.initial,
    this.members = const [],
    this.name,
    this.photo,
    this.step = 0,
    this.emoji,
    this.chatRef,
  });

  NewChatState copyWith({
    String? errorMessage,
    NewChatStatus? status,
    List<DocumentReference>? members,
    String? name,
    XFile? photo,
    int? step,
    String? emoji,
    DocumentReference? chatRef,
  }) {
    return NewChatState(
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      members: members ?? this.members,
      name: name ?? this.name,
      photo: photo == null
          ? this.photo
          : photo.path == 'delete'
              ? null
              : photo,
      step: step ?? this.step,
      emoji: emoji == null
          ? this.emoji
          : emoji == 'delete'
              ? null
              : emoji,
      chatRef: chatRef ?? this.chatRef,
    );
  }

  @override
  List<Object?> get props => [
        errorMessage,
        status,
        members,
        name,
        photo,
        step,
        emoji,
        chatRef,
      ];

  NewChatState reset() => const NewChatState();
}
