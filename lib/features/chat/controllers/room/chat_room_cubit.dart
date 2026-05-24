import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'state.dart';

class ChatCubit extends Cubit<ChatRoomState> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final String chatId;
  final DocumentReference sender;
  final FirebaseMessaginService _fcm;

  ChatCubit({
    required this.chatId,
    required this.sender,
    required FirebaseMessaginService fcm,
  })  : assert(chatId.isNotEmpty),
        _fcm = fcm,
        super(const ChatRoomState());
  StreamSubscription<DocumentSnapshot>? _chatSubscription;

  Future<void> getCurrentChat() async {
    emit(state.copyWith(status: ChatRoomStatus.loading));
    try {
      final doc = await _fs.collection('chats').doc(chatId).get();
      final chat = ChatModel.fromFirestore(doc);
      final memberRefs = chat.unmodifiedMembers.where((member) => member.id != sender.id).toList();
      final members = await Future.wait(
          memberRefs.map((ref) async => await ref.get().then((doc) => UserModel.fromFirestore(doc))).toList());

      final unreadUpdate = Map<String, int>.from(chat.unreads);
      final myUnreadCount = unreadUpdate[sender.id] ?? 0;
      if (myUnreadCount > 0) {
        unreadUpdate.update(sender.id, (_) => 0);
        await chat.ref.update({'unreads': unreadUpdate});
      }
      emit(state.copyWith(chat: chat, members: members, status: ChatRoomStatus.success));
      _listenToChatUpdates();
    } catch (e) {
      print('Error getting current chat: $e');
      emit(state.copyWith(status: ChatRoomStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    if (state.chat == null) {
      emit(state.copyWith(errorMessage: 'chatNotFound'.tr(), status: ChatRoomStatus.messageSentError));
      return;
    }

    emit(state.copyWith(status: ChatRoomStatus.sendingMessage));

    try {
      final chatRef = state.chat!.ref;

      final newMessage = LastMessage(text: message, senderId: sender.id, timestamp: DateTime.now());

      await chatRef.collection('messages').add(newMessage.toMap());

      await _fs.runTransaction((transaction) async {
        final chatSnap = await transaction.get(chatRef);
        final newestchat = ChatModel.fromFirestore(chatSnap);
        final unreadUpdate = Map<String, int>.from(newestchat.unreads);
        unreadUpdate.updateAll((key, value) => key == sender.id ? value : value + 1);
        transaction.update(chatRef, {
          'last_message': newMessage.toMap(),
          'last_edit_time': FieldValue.serverTimestamp(),
          'unreads': unreadUpdate,
        });
      });

      _sendPushNotification(state.chat!, message);

      emit(state.copyWith(status: ChatRoomStatus.messageSent));
    } catch (e) {
      print('Error sending message: $e');
      emit(state.copyWith(status: ChatRoomStatus.messageSentError, errorMessage: e.toString()));
    }
  }

  void _listenToChatUpdates() {
    _chatSubscription = state.chat!.ref.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final chat = ChatModel.fromFirestore(snapshot);
      emit(state.copyWith(chat: chat));

      final unreads = Map<String, dynamic>.from(snapshot.get('unreads') ?? {});
      final myUnreadCount = unreads[sender.id] as int? ?? 0;

      if (myUnreadCount > 0) {
        _resetMyUnreadCount(unreads);
      }
    });
  }

  Future<void> _resetMyUnreadCount(Map<String, dynamic> unreads) async {
    final unreadUpdate = Map<String, int>.from(unreads);
    unreadUpdate.update(sender.id, (_) => 0);
    await state.chat!.ref.update({'unreads': unreadUpdate});
  }

  Stream<List<MessageModel>> getMessageStream() {
    if (state.chat == null) {
      return const Stream.empty();
    }
    return state.chat!.ref.collection('messages').orderBy('timestamp', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromFirestore(doc);
        }).toList();
      },
    );
  }

  void _sendPushNotification(ChatModel chat, String message) {
    if (chat.type == ChatType.support) return;

    final notificationSetting = chat.notification;

    final members = chat.members.where((member) => member.id != sender.id).toList();
    if (members.isEmpty) return;

    for (final member in members) {
      if (notificationSetting[member.id] == true) {
        _fcm.sendPushToChatMember(member, message, chat.id);
      }
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
