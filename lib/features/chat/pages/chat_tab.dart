import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: white,
        leadingWidth: 62,
        automaticallyImplyLeading: false,
        leading: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(
            'assets/images/logo_min.svg',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
        title:  AppText(text: 'chats'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                context.push('/add_chat');
              },
              icon: const Icon(CupertinoIcons.add, size: 30),
            ),
          ),
        ],
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, user) {
          if (user == null) return const Center(child: CircularProgressIndicator());
          return StreamBuilder<List<ChatModel>>(
            stream: getChats(user.ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Center(child: AppText(text: snapshot.error.toString(), color: red));
              final chats = snapshot.data!;
              if (chats.isEmpty) return const EmptyChatsWidget();
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                separatorBuilder: (context, index) => const SizedBox(height: 32),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return ChatCard(chat: chat, me: user.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

Stream<List<ChatModel>> getChats(DocumentReference ref) {
  final Query query = FirebaseFirestore.instance
      .collection('chats')
      .where('members', arrayContains: ref)
      .orderBy('last_edit_time', descending: true);

  return query.snapshots().map((query) => query.docs.map((doc) => ChatModel.fromFirestore(doc)).toList());
}
