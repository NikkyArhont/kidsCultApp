part of 'chat_room_cubit.dart';

enum ChatRoomStatus { initial, loading, success, error, sendingMessage, messageSent, messageSentError }

class ChatRoomState extends Equatable {
  const ChatRoomState({
    this.chat,
    this.status = ChatRoomStatus.initial,
    this.errorMessage,
    this.members = const [],
  });

  final ChatModel? chat;
  final String? errorMessage;
  final ChatRoomStatus status;
  final List<UserModel> members;

  ChatRoomState copyWith({
    ChatModel? chat,
    ChatRoomStatus? status,
    String? errorMessage,
    List<UserModel>? members,
  }) {
    return ChatRoomState(
      chat: chat ?? this.chat,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [
        chat,
        errorMessage,
        status,
        members,
      ];
}
