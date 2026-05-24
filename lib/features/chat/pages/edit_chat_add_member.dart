import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EditChatAddMembersScreen extends StatelessWidget {
  final ChatModel chat;

  const EditChatAddMembersScreen({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title:  AppText(
          text: 'add_member'.tr(),
          size: 24,
          fw: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          return Column(
            children: [
              Expanded(child: _ChatMemebersList(chat: chat, me: me)),
            ],
          );
        },
      ),
    );
  }
}

class _ChatMemebersList extends StatefulWidget {
  final ChatModel chat;
  final UserModel me;
  const _ChatMemebersList({required this.chat, required this.me});

  @override
  State<_ChatMemebersList> createState() => _ChatMemebersListState();
}

class _ChatMemebersListState extends State<_ChatMemebersList> {
  void onAdd(BuildContext context, DocumentReference userRef) async {
    await widget.chat.ref.update({
      'members': FieldValue.arrayUnion([userRef])
    });

    if (mounted) {
      setState(() {
        widget.chat.members.add(userRef);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: widget.me.connections.length,
      itemBuilder: (context, index) {
        final memberRef = widget.me.connections[index];
        bool alreadyHas = widget.chat.members.firstWhereOrNull((element) => element.id == memberRef.id) != null;
        return MemberCard(
          isMember: alreadyHas,
          onAdd: !alreadyHas ? () => onAdd(context, memberRef) : null,
          isMe: memberRef.id == widget.me.id,
          userRef: memberRef,
        );
      },
    );
  }
}
