import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChatCard extends StatelessWidget {
  final ChatModel chat;
  final String me;
  const ChatCard({super.key, required this.chat, required this.me});

  @override
  Widget build(BuildContext context) {
    int unreads = chat.getUnreadCount(me);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/chat_room', extra: chat.ref),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (chat.isGroup)
              _GroupContent(chat: chat, me: me)
            else if (chat.type == ChatType.support)
              _SupportContent(chat: chat, me: me)
            else
              _PrivateContent(chat: chat, me: me),
            const SizedBox(width: 12),
            Padding(
              padding: EdgeInsets.only(bottom: (unreads > 0) ? 8 : 4, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: unreads > 0 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
                children: [
                  AppText(
                    text: dateToHHmm(chat.lastEditTime),
                    color: greyscale700,
                    size: 14,
                    fw: FontWeight.w500,
                  ),
                  if (unreads > 0)
                    const CircleAvatar(
                      radius: 6,
                      backgroundColor: primary900,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupContent extends StatelessWidget {
  final ChatModel chat;
  final String me;
  const _GroupContent({required this.chat, required this.me});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            if (chat.photo == null) {
              return const CachedClickableImage(
                height: 60,
                width: 60,
                circularRadius: 100,
              );
            } else {
              bool isEmoji = chat.photo!.startsWith('emoji:');
              return CachedClickableImage(
                height: 60,
                width: 60,
                circularRadius: 100,
                emojiFontSize: 35,
                emoji: isEmoji ? chat.photo!.replaceAll('emoji:', '') : null,
                imageUrl: isEmoji ? null : chat.photo,
              );
            }
          }),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: chat.name ?? '-',
                  fw: FontWeight.w700,
                ),
                const SizedBox(height: 3),
                AppText(
                  text: chat.lastMessage?.text ?? '-',
                  size: 14,
                  fw: FontWeight.w500,
                  color: greyscale700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateContent extends StatelessWidget {
  final ChatModel chat;
  final String me;
  const _PrivateContent({required this.chat, required this.me});

  @override
  Widget build(BuildContext context) {
    final DocumentReference? secondUserRef = chat.secondUserRef(me);
    if (secondUserRef == null) return Container();
    return Expanded(
      child: FutureBuilder<UserModel>(
          future: context.read<UserCubit>().getUserByRef(secondUserRef),
          builder: (context, snapshot) {
            final secondUser = snapshot.data;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CachedClickableImage(
                  height: 60,
                  width: 60,
                  circularRadius: 100,
                  imageUrl: secondUser?.photo,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: secondUser?.name ?? '...',
                        fw: FontWeight.w700,
                      ),
                      const SizedBox(height: 3),
                      AppText(
                        text: chat.lastMessage?.text ?? '-',
                        size: 14,
                        fw: FontWeight.w500,
                        color: greyscale700,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}

class _SupportContent extends StatelessWidget {
  final ChatModel chat;
  final String me;
  const _SupportContent({required this.chat, required this.me});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CachedClickableImage(
            height: 60,
            width: 60,
            circularRadius: 100,
            emojiFontSize: 35,
            emoji: '🤖',
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: 'support'.tr(),
                  fw: FontWeight.w700,
                ),
                const SizedBox(height: 3),
                AppText(
                  text: chat.lastMessage?.text ?? 'supportText'.tr(),
                  size: 14,
                  fw: FontWeight.w500,
                  color: greyscale700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
