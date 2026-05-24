import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EmptyChatsWidget extends StatelessWidget {
  const EmptyChatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/2187-min.png',
                fit: BoxFit.contain,
                width: 160,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            text: 'no_chats'.tr(),
            size: 24,
            fw: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
           AppText(
            text: 'add_chat_button'.tr(),
            fw: FontWeight.normal,
            color: greyscale700,
            textAlign: TextAlign.center,
            maxLine: 2,
          ),
        ],
      ),
    );
  }
}
