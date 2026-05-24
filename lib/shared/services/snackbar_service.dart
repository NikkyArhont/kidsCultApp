// ignore_for_file: deprecated_member_use

import 'package:bot_toast/bot_toast.dart';
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SnackBarSerive {
  static const Duration duration = Duration(seconds: 6);

  static showSuccessSnackBar(String title) {
    BotToast.showCustomNotification(
      duration: duration,
      toastBuilder: (cancelFunc) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: greyscale200),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                color: const Color(0xFFC4AC88).withOpacity(0.32),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.check_mark, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  text: title,
                  size: 16,
                  fw: FontWeight.w600,
                  color: greyscale900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static showErrorSnackBar(String title) {
    BotToast.showCustomNotification(
      duration: duration,
      toastBuilder: (cancelFunc) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: greyscale200),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                color: const Color(0xFFC4AC88).withOpacity(0.32),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.clear_circled, color: red),
              const SizedBox(width: 10),
              Expanded(
                child: AppText(
                  text: title,
                  size: 16,
                  fw: FontWeight.w600,
                  color: greyscale900,
                  maxLine: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static showBottomSnackBar(String title) {
    BotToast.showText(
      text: title,
      align: Alignment.bottomCenter,
      contentColor: greyscale900,
    );
  }

  static showSnackBarOnReceivePushNotification(
    String title,
    String? body,
    VoidCallback? onTap,
  ) {
    BotToast.showCustomNotification(
      duration: duration,
      crossPage: true,
      toastBuilder: (cancelFunc) {
        return Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: white,
            border: const Border.symmetric(
              vertical: BorderSide(color: greyscale200),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                color: const Color(0xFF04060F).withOpacity(0.12),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/bell.svg',
                width: 24,
                height: 24,
                color: primary900,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: title,
                      size: 18,
                      fw: FontWeight.w600,
                      maxLine: 2,
                    ),
                    if (body != null)
                      AppText(
                        text: body,
                        size: 16,
                        fw: FontWeight.w500,
                        maxLine: 3,
                      ),
                  ],
                ),
              ),
              if (onTap != null) const SizedBox(width: 12),
              if (onTap != null)
                SizedBox(
                  width: 94,
                  child: FilledAppButton(
                    height: 34,
                    onTap: () {
                      cancelFunc();
                      onTap();
                    },
                    fontSize: 14,
                    fw: FontWeight.w600,
                    fontColor: white,
                    text: 'go_to'.tr(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static showNewCodeSendNotification() {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 3),
      align: Alignment.bottomCenter,
      crossPage: true,
      toastBuilder: (cancelFunc) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 114),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: greyscale200),
              boxShadow: [
                BoxShadow(
                  blurRadius: 32,
                  color: const Color(0xFF04060F).withOpacity(0.08),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/done_fill.svg',
                      width: 28,
                      height: 28,
                      color: orange,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppText(
                        text: 'newCodeSent'.tr(),
                        size: 20,
                        fw: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static showCorrectAnswerAlert(VoidCallback onClose) {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 2),
      align: Alignment.bottomCenter,
      crossPage: true,
      onClose: onClose,
      toastBuilder: (cancelFunc) {
        return GestureDetector(
          onTap: cancelFunc,
          behavior: HitTestBehavior.translucent,
          child: Container(
            height: 98,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(24),
            color: success,
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/done_fill.svg',
                  width: 28,
                  height: 28,
                  color: white,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppText(
                    text: 'correct'.tr(),
                    size: 24,
                    fw: FontWeight.w700,
                    color: white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static showWrongAnswerAlert(VoidCallback onClose, String correctAnswer) {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 60),
      animationReverseDuration: const Duration(milliseconds: 100),
      align: Alignment.bottomCenter,
      crossPage: true,
      onClose: onClose,
      toastBuilder: (cancelFunc) {
        return GestureDetector(
          onTap: cancelFunc,
          behavior: HitTestBehavior.translucent,
          child: Container(
            // height: 98,
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(24),
            color: error,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: white,
                        ),
                        child: const Center(child: Icon(Icons.close, color: red))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppText(
                        text: 'littleFail'.tr(),
                        size: 24,
                        fw: FontWeight.w700,
                        color: white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppText(
                  text: 'correctAnswerIs'.tr(),
                  size: 20,
                  fw: FontWeight.w700,
                  color: white,
                ),
                const SizedBox(height: 8),
                AppText(
                  text: correctAnswer,
                  size: 18,
                  fw: FontWeight.w500,
                  color: white,
                ),
                const SizedBox(height: 24),
                FilledAppButton(
                  onTap: cancelFunc,
                  activeColor: white,
                  text: 'ok'.tr(),
                  fontColor: error,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static showFirstDoTaskOfTheDayAlert(String taskName, VoidCallback onGo) {
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 6),
      align: Alignment.topCenter,
      crossPage: true,
      toastBuilder: (cancelFunc) {
        return GestureDetector(
          onTap: cancelFunc,
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: const EdgeInsets.only(top: 60),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: white,
              border: const Border.symmetric(
                vertical: BorderSide(color: greyscale200),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 32,
                  color: const Color(0xFF04060F).withOpacity(0.12),
                ),
              ],
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/bell_fill.svg',
                  width: 28,
                  height: 28,
                  color: orange,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppText(
                    text: '${'first_complete_task'.tr()}: "$taskName"',
                    size: 16,
                    maxLine: 10,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 94,
                  child: FilledAppButton(
                    height: 34,
                    onTap: () {
                      cancelFunc();
                      onGo();
                    },
                    fontSize: 14,
                    fw: FontWeight.w600,
                    fontColor: white,
                    text: 'go_to'.tr(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
