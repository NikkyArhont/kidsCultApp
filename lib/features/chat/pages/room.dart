import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ChatRoomScreen extends StatefulWidget {
  final DocumentReference chatRef;
  const ChatRoomScreen({super.key, required this.chatRef});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController controller = TextEditingController();
  late DocumentReference? senderRef;

  @override
  void initState() {
    senderRef = sl<UserCubit>().state?.ref;
    super.initState();
    context.read<CurrentChatCubit>().setChat(widget.chatRef.id);
  }

  @override
  Widget build(BuildContext context) {
    if (senderRef == null) return const Center(child: CircularProgressIndicator());
    return BlocProvider(
      create: (_) => ChatCubit(fcm: sl(), chatId: widget.chatRef.id, sender: senderRef!)..getCurrentChat(),
      child: BlocConsumer<ChatCubit, ChatRoomState>(
        listener: (context, state) {
          if (state.status == ChatRoomStatus.messageSentError || state.status == ChatRoomStatus.error) {
            SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
          }
        },
        builder: (context, state) {
          if (state.status == ChatRoomStatus.loading) {
            return Container(
              constraints: const BoxConstraints.expand(),
              color: white,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          if (state.status == ChatRoomStatus.error) {
            return Container(
              constraints: const BoxConstraints.expand(),
              color: white,
              child: Center(
                child: AppText(
                  text: state.errorMessage ?? defaultErrorText,
                  color: red,
                  textAlign: TextAlign.center,
                  maxLine: 10,
                  size: 16,
                  fw: FontWeight.w500,
                ),
              ),
            );
          }
          if (state.chat == null) return const Center(child: CircularProgressIndicator());
          final chat = state.chat!;
          return Scaffold(
            backgroundColor: white,
            appBar: AppBar(
              leadingWidth: 70,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.arrow_left),
                onPressed: () {
                  context.read<CurrentChatCubit>().clearChat();
                  context.pop();
                },
              ),
              title: AppText(
                text: chat.type == ChatType.support
                    ? 'support'.tr()
                    : chat.isGroup
                        ? chat.name ?? '-'
                        : state.members.firstWhere((m) => m.id != senderRef!.id).name,
                size: 24,
                fw: FontWeight.w700,
              ),
              centerTitle: true,
              actions: chat.type == ChatType.support
                  ? []
                  : [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: SvgPicture.asset(
                            'assets/images/setting.svg',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                          onPressed: () {
                            context.push('/chat_room/edit_chat', extra: chat);
                          },
                        ),
                      ),
                    ],
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: context.read<ChatCubit>().getMessageStream(),
                      builder: (context, snapshot) {
                        // if (snapshot.connectionState == ConnectionState.waiting) {
                        //   return const Center(child: CircularProgressIndicator());
                        // }
                        if (snapshot.hasError) {
                          return Center(
                            child: AppText(text: defaultErrorText, color: secondary900),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: AppText(
                              text: 'writeFirstMessage'.tr(),
                              color: greyscale400,
                              fw: FontWeight.normal,
                              size: 16,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        final messages = snapshot.data!;

                        Map<String, List<MessageModel>> groupedMessages = {};

                        for (var message in messages) {
                          String dateKey = DateFormat('yyyy-MM-dd').format(message.timestamp);
                          if (groupedMessages.containsKey(dateKey)) {
                            groupedMessages[dateKey]?.add(message);
                          } else {
                            groupedMessages[dateKey] = [message];
                          }
                        }

                        List<String> sortedDates = groupedMessages.keys.toList()..sort((a, b) => b.compareTo(a));

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          reverse: true,
                          itemCount: groupedMessages.length,
                          itemBuilder: (context, index) {
                            String date = sortedDates[index];
                            List<MessageModel> dayMessages = groupedMessages[date]!
                              ..sort((a, b) => (a.timestamp).compareTo(b.timestamp));
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                groupDivider(dateToChatDivider(DateTime.parse(date))),
                                ...dayMessages.map(
                                  (message) => MessageBubble(
                                    message: message,
                                    me: senderRef!,
                                    sender: state.members.firstWhereOrNull((m) => m.id == message.senderId),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  RoomInputWidget(
                    controller: controller,
                    onSend: context.read<ChatCubit>().sendMessage,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget groupDivider(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [AppText(text: date, size: 14, color: greyscale400)],
      ),
    );
  }
}
