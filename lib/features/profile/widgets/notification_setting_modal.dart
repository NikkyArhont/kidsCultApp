import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

void showNotificationSettingModalBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return const _NotificationSettingModalContent();
    },
  );
}

class _NotificationSettingModalContent extends StatefulWidget {
  const _NotificationSettingModalContent();

  @override
  State<_NotificationSettingModalContent> createState() => __NotificationSettingModalContentState();
}

class __NotificationSettingModalContentState extends State<_NotificationSettingModalContent> {
  bool initialSetting = true;

  @override
  void initState() {
    initialSetting = context.read<UserCubit>().state?.notification ?? true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: greyscale200,
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          AppText(
            text: 'settings'.tr(),
            size: 24,
            fw: FontWeight.w700,
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFF5A5F).withOpacity(0.08),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/bell_fill.svg',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 20),
               Expanded(child: AppText(text: 'notifications'.tr(), size: 20, fw: FontWeight.w700)),
              const SizedBox(width: 10),
              CupertinoSwitch(
                value: initialSetting,
                thumbColor: white,
                trackColor: greyscale300,
                offLabelColor: greyscale300,
                onLabelColor: primary900,
                activeColor: primary900,
                onChanged: (value) {
                  setState(() {
                    initialSetting = value;
                  });
                },
              ),
            ],
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          FilledAppButton(
            text: 'apply'.tr(),
            onTap: () {
              context.read<UserCubit>().setNotification(initialSetting);
              context.pop();
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
