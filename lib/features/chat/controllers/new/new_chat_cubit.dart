import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'state.dart';

class NewChatCubit extends Cubit<NewChatState> {
  final FirebaseFirestore _fs;
  final UserCubit _userCubit;
  final PageController pageController;
  NewChatCubit({required FirebaseFirestore fs, required UserCubit userCubit})
      : _fs = fs,
        _userCubit = userCubit,
        pageController = PageController(initialPage: 0),
        super(const NewChatState());

  Future<DocumentReference?> createOrReturnPrivateChat(DocumentReference user) async {
    if (_userCubit.state == null) {
      throw Exception('userNotFound'.tr());
    }

    if (_userCubit.state!.ref.id == user.id) {
      throw Exception('cantWriteYourself'.tr());
    }

    final DocumentReference kidRef = _userCubit.state!.isKid ? _userCubit.state!.ref : user;
    final DocumentReference mentorRef = _userCubit.state!.isKid ? user : _userCubit.state!.ref;

    print('Kid id: ${kidRef.id}, Mentor id: ${mentorRef.id}');

    try {
      final QuerySnapshot query = await _fs
          .collection('chats')
          .where('kid', isEqualTo: kidRef)
          .where('mentor', isEqualTo: mentorRef)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.reference;
      } else {
        
        final newChatRef = _fs.collection('chats').doc();

        final newMessage = LastMessage(
          text: 'writeFirstMessage'.tr(),
          senderId: _userCubit.state!.ref.id,
          timestamp: DateTime.now(),
        );

        final members = [kidRef, mentorRef];
        final unreads = {for (var member in members) member.id: 0};
        final notification = {for (var member in members) member.id: true};

        final Map<String, dynamic> newChatData = {
          'members': members,
          'unmodified_members': members,
          'type': ChatType.private.name,
          'last_message': newMessage.toMap(),
          'last_edit_time': FieldValue.serverTimestamp(),
          'unreads': unreads,
          'notification': notification,
          'kid': kidRef,
          'mentor': mentorRef,
        };

        await newChatRef.set(newChatData);

        return newChatRef;
      }
    } catch (e) {
      print('Error {createOrReturnPrivateChat}: $e');
      rethrow;
    }
  }

  Future<void> createGroupChat() async {
    if (_userCubit.state == null) {
      emit(state.copyWith(status: NewChatStatus.error, errorMessage: 'userNotFound'.tr()));
      return;
    }

    emit(state.copyWith(status: NewChatStatus.loading));

    try {
      final newChatRef = _fs.collection('chats').doc();

      final newMessage =
          LastMessage(text: 'writeFirstMessage'.tr(), senderId: _userCubit.state!.id, timestamp: DateTime.now());

      final members = [_userCubit.state!.ref, ...state.members];
      final unreads = {for (var member in members) member.id: 0};
      final notification = {for (var member in members) member.id: true};

      final Map<String, dynamic> newChatData = {
        'members': members,
        'unmodified_members': members,
        'type': ChatType.group.name,
        'last_message': newMessage.toMap(),
        'last_edit_time': FieldValue.serverTimestamp(),
        'unreads': unreads,
        'owner': _userCubit.state!.ref,
        'name': state.name,
        'notification': notification,
      };

      if (state.photo != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(
          file: state.photo!,
          type: UploadType.chat,
          uid: newChatRef.id,
        );
        if (photoUrl == null) {
          emit(state.copyWith(status: NewChatStatus.error, errorMessage: 'photoUploadError'.tr()));
          return;
        } else {
          newChatData['photo'] = photoUrl;
        }
      } else if (state.emoji != null) {
        newChatData['photo'] = 'emoji:${state.emoji}';
      } else {
        emit(state.copyWith(status: NewChatStatus.error, errorMessage: 'photoUploadError'.tr()));
      }

      await newChatRef.set(newChatData);

      emit(state.copyWith(status: NewChatStatus.success, chatRef: newChatRef));
    } catch (e) {
      print('Error {createGroupChat}: $e');
      emit(state.copyWith(status: NewChatStatus.error, errorMessage: e.toString()));
    }
  }

  void onAddMember(DocumentReference ref) {
    final isExist = state.members.firstWhereOrNull((element) => element.id == ref.id) != null;
    if (isExist) {
      emit(state.copyWith(members: List.from(state.members)..remove(ref)));
    } else {
      emit(state.copyWith(members: List.from(state.members)..add(ref)));
    }
  }

  void onChangeName(String name) {
    emit(state.copyWith(name: name));
  }

  void onChangePhoto(XFile photo) {
    emit(state.copyWith(photo: photo, emoji: 'delete'));
  }

  void onChangeEmoji(String emoji) {
    emit(state.copyWith(emoji: emoji, photo: XFile('delete')));
  }

  void nextPage() {
    if (state.step == 2) {
      createGroupChat();
    } else {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      emit(state.copyWith(step: state.step + 1));
    }
  }

  void prevPage() {
    if (state.step == 0) return;
    pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    emit(state.copyWith(step: state.step - 1));
  }

  void reset() => emit(state.reset());

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }
}
