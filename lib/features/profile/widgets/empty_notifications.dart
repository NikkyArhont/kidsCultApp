import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/moon_star_bg.svg'),
                const SizedBox(height: 40),
                Image.asset(
                  'assets/images/2187-min.png',
                  fit: BoxFit.contain,
                  width: 270,
                ),
                const SizedBox(height: 16),
                 AppText(
                  text: 'noNotifications'.tr(),
                  size: 32,
                  fw: FontWeight.w700,
                  color: primary900,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                 AppText(
                  text: 'restMessage'.tr(),
                  size: 16,
                  fw: FontWeight.normal,
                  color: greyscale800,
                  textAlign: TextAlign.center,
                  maxLine: 2,
                ), const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                FilledAppButton(
                  text: 'ok'.tr(),
                  onTap: () => context.pop(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
