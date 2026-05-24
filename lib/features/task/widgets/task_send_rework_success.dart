
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TaskSendReworkSuccessScreen extends StatelessWidget {
  const TaskSendReworkSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           SvgPicture.asset('assets/images/moon_star_bg.svg'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/2187-min.png',
                    fit: BoxFit.contain,
                    width: 270,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: 'task_in_revision'.tr(),
                    size: 32,
                    maxLine: 2,
                    fw: FontWeight.w700,
                    color: primary900,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 60),
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
                    onTap: () => context.pop(true),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
