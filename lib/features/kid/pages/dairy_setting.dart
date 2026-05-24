import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DairySettingScreen extends StatefulWidget {
  const DairySettingScreen({super.key});

  @override
  State<DairySettingScreen> createState() => _DairySettingScreenState();
}

class _DairySettingScreenState extends State<DairySettingScreen> {
  bool notification = true;

  Future<void> changeNotificationStatus(bool val) async {
    context.read<UserCubit>().setDairyNotification(val);
    final localPush = sl<LocalNotificationService>();
    localPush.toggleDailyDiaryReminders(val);
  }

  void onMembersTap() {
    context.push('/dairy/members');
  }

  @override
  void initState() {
    notification = context.read<UserCubit>().state?.dairyNotification ?? true;
    super.initState();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 30, bottom: 28, top: 24),
            child: GestureDetector(
              onTap: onMembersTap,
              child: Row(
                children: [
                  SvgPicture.asset('assets/images/members.svg', width: 24, height: 24),
                  const SizedBox(width: 20),
                  Expanded(child: AppText(text: 'diary_members'.tr(), size: 16, fw: FontWeight.w700)),
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
      ),
    );
  }
}
