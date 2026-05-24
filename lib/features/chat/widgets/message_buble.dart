import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final DocumentReference me;
  final UserModel? sender;
  const MessageBubble({super.key, required this.message, required this.me, required this.sender});

  @override
  Widget build(BuildContext context) {
    bool isMine = message.senderId == me.id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMine)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 6),
            child: CachedClickableImage(
              width: 32,
              height: 32,
              circularRadius: 100,
              imageUrl: sender?.photo,
            ),
          ),
        Flexible(
          child: IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              margin: EdgeInsets.only(bottom: 24, left: isMine ? 80 : 0, right: isMine ? 0 : 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isMine ? primary900 : greyscale100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              text: sender?.name ?? '-',
                              size: 14,
                              color: primary900,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppText(
                    text: message.text,
                    fw: FontWeight.w500,
                    color: isMine ? white : greyscale900,
                    maxLine: 50,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 0),
                      AppText(
                        text: dateToHHmm(message.timestamp),
                        fw: FontWeight.w500,
                        color: isMine ? white : greyscale600,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
