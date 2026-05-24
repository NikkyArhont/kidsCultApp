import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class EditChatMembersScreen extends StatelessWidget {
  final ChatModel chat;

  const EditChatMembersScreen({super.key, required this.chat});

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
          text: 'chat_members'.tr(),
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
              if (chat.owner?.id == me.id)
                Container(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FilledSecondaryAppButton(
                          onTap: () => context.push('/chat_room/add_member', extra: chat),
                          icon: const Icon(CupertinoIcons.add, size: 18, color: primary900),
                          text: '  ${"add_member".tr()}',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
  void onDelete(BuildContext context, DocumentReference userRef) async {
    final result = await showConfirmModalBottomSheet(
      context,
      isDestructive: true,
      confirmText: 'yes_delete'.tr(),
      title: 'delete_member'.tr(),
      message: 'confirm_delete_member'.tr(),
      cancelText: 'cancel'.tr(),
    );

    if (result == true && context.mounted) {
      await widget.chat.ref.update({
        'members': FieldValue.arrayRemove([userRef])
      });

      if (mounted) {
        setState(() {
          widget.chat.members.remove(userRef);
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    bool isOwner = (widget.chat.owner?.id == widget.me.id);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: widget.chat.members.length,
      itemBuilder: (context, index) {
        final memberRef = widget.chat.members[index];
        return MemberCard(
          onDelete: isOwner
              ? (memberRef.id == widget.chat.owner?.id)
                  ? null
                  : () => onDelete(context, memberRef)
              : null,
          onAdd: null,
          isMe: memberRef.id == widget.me.id,
          userRef: memberRef,
        );
      },
    );
  }
}
