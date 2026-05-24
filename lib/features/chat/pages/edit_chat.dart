// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class EditChatScreen extends StatelessWidget {
  final ChatModel chat;
  const EditChatScreen({super.key, required this.chat});

  void onDeleteChat(BuildContext context) async {
    final result = await showConfirmModalBottomSheet(
      context,
      isDestructive: true,
      confirmText: 'yesDelete'.tr(),
      title: 'delete_chat'.tr(),
      message: 'confirm_delete_chat'.tr(),
      cancelText: 'cancel'.tr(),
    );

    if (result == true && context.mounted) {
      await chat.ref.delete();
      if (context.mounted) {
        context.pop();
        context.pop();
      }
    }
  }

  void onLeaveChat(BuildContext context, DocumentReference me) async {
    final result = await showConfirmModalBottomSheet(
      context,
      isDestructive: true,
      confirmText: 'yes_leave'.tr(),
      title: 'leave_chat'.tr(),
      message: 'confirm_leave_chat'.tr(),
      cancelText: 'cancel'.tr(),
    );

    if (result == true && context.mounted) {
      await leaveChat(me);
      if (context.mounted) {
        context.pop();
        context.pop();
      }
    }
  }

  Future<void> leaveChat(DocumentReference me) async {
    await chat.ref.update({
      'members': FieldValue.arrayRemove([me]),
    });
  }

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
        title: AppText(
          text: 'settings'.tr(),
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
              Expanded(
                child: chat.isGroup ? _GroupChatSetting(chat: chat, me: me) : _PrivateChatSetting(chat: chat, me: me),
              ),
              if (chat.isGroup)
                Container(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      if (chat.owner != me.ref)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: FilledDestructiveAppButton(
                            onTap: () => onLeaveChat(context, me.ref),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/images/logout.svg', width: 20, height: 20),
                                const SizedBox(width: 20),
                                AppText(
                                  text: 'exitGroup'.tr(),
                                  size: 16,
                                  color: error,
                                  fw: FontWeight.w700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (chat.owner == me.ref)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: FilledDestructiveAppButton(
                            onTap: () => onDeleteChat(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/images/delete.svg', width: 20, height: 20),
                                const SizedBox(width: 20),
                                AppText(
                                  text: 'delete_chat'.tr(),
                                  size: 16,
                                  color: error,
                                  fw: FontWeight.w700,
                                ),
                              ],
                            ),
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

class _PrivateChatSetting extends StatefulWidget {
  final ChatModel chat;
  final UserModel me;
  const _PrivateChatSetting({required this.chat, required this.me});

  @override
  State<_PrivateChatSetting> createState() => _PrivateChatSettingState();
}

class _PrivateChatSettingState extends State<_PrivateChatSetting> {
  bool notification = true;
  late ChatModel chat;

  @override
  void initState() {
    chat = widget.chat;
    notification = widget.chat.notification[widget.me.ref.id] ?? true;
    super.initState();
  }

  Future<void> changeNotificationStatus(bool val) async {
    final notificationUpdate = Map<String, bool>.from(chat.notification);
    notificationUpdate.update(widget.me.id, (_) => val);
    await chat.ref.update({'notification': notificationUpdate});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: greyscale100,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/bubble.svg',
                  width: 40,
                  height: 40,
                  color: greyscale600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppText(
          text: 'privateChat'.tr(),
          size: 24,
          fw: FontWeight.w700,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/bell.svg', width: 24, height: 24),
              const SizedBox(width: 20),
              Expanded(child: AppText(text: 'notifications'.tr(), size: 16, fw: FontWeight.w700)),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: notification,
                  thumbColor: white,
                  trackColor: greyscale300,
                  offLabelColor: greyscale300,
                  onLabelColor: primary900,
                  activeColor: primary900,
                  onChanged: (v) async {
                    setState(() {
                      notification = v;
                    });
                    changeNotificationStatus(v);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupChatSetting extends StatefulWidget {
  final ChatModel chat;
  final UserModel me;
  const _GroupChatSetting({required this.chat, required this.me});

  @override
  State<_GroupChatSetting> createState() => _GroupChatSettingState();
}

class _GroupChatSettingState extends State<_GroupChatSetting> {
  bool notification = true;
  late ChatModel chat;

  @override
  void initState() {
    chat = widget.chat;
    notification = widget.chat.notification[widget.me.ref.id] ?? true;
    super.initState();
  }

  Future<void> changeNotificationStatus(bool val) async {
    final notificationUpdate = Map<String, bool>.from(chat.notification);
    notificationUpdate.update(widget.me.id, (_) => val);
    await chat.ref.update({'notification': notificationUpdate});
  }

  void onMembersTap() {
    context.push('/chat_room/members', extra: chat);
  }

  void onNameTap() {
    if (chat.owner == widget.me.ref) {
      context.push('/chat_room/edit_name', extra: chat);
    }
  }

  void onPhotoTap() {
    if (chat.owner == widget.me.ref) {
      context.push('/chat_room/edit_photo', extra: chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Builder(builder: (context) {
                  if (chat.photo == null) {
                    return const CachedClickableImage(
                      height: 120,
                      width: 120,
                      circularRadius: 300,
                    );
                  } else {
                    bool isEmoji = chat.photo!.startsWith('emoji:');
                    return CachedClickableImage(
                      height: 120,
                      width: 120,
                      circularRadius: 300,
                      emojiFontSize: 70,
                      emoji: isEmoji ? chat.photo!.replaceAll('emoji:', '') : null,
                      imageUrl: isEmoji ? null : chat.photo,
                    );
                  }
                }),
                if (chat.owner == widget.me.ref)
                  GestureDetector(
                    onTap: onPhotoTap,
                    child: SvgPicture.asset('assets/images/edit_blue_fill.svg', width: 24, height: 24),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 30, right: 30),
          child: GestureDetector(
            onTap: onNameTap,
            child: Row(
              children: [
                if ((chat.owner == widget.me.ref)) const SizedBox(width: 22),
                Expanded(
                  child: AppText(
                    text: chat.name ?? '-',
                    size: 24,
                    fw: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                ),
                if ((chat.owner == widget.me.ref))
                  const Icon(CupertinoIcons.chevron_right, size: 22, color: greyscale900),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 30, bottom: 28),
          child: GestureDetector(
            onTap: onMembersTap,
            child: Row(
              children: [
                SvgPicture.asset('assets/images/members.svg', width: 24, height: 24),
                const SizedBox(width: 20),
                Expanded(child: AppText(text: 'chat_members'.tr(), size: 16, fw: FontWeight.w700)),
                const Icon(CupertinoIcons.chevron_right, size: 22, color: greyscale900),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              SvgPicture.asset('assets/images/bell.svg', width: 24, height: 24),
              const SizedBox(width: 20),
              Expanded(child: AppText(text: 'notifications'.tr(), size: 16, fw: FontWeight.w700)),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: notification,
                  thumbColor: white,
                  trackColor: greyscale300,
                  offLabelColor: greyscale300,
                  onLabelColor: primary900,
                  activeColor: primary900,
                  onChanged: (v) async {
                    setState(() {
                      notification = v;
                    });
                    changeNotificationStatus(v);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
