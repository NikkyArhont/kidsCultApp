import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showTaskTypesInfoModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return const _TaskTypesInfoContent();
    },
  );
}

class _TaskTypesInfoContent extends StatefulWidget {
  const _TaskTypesInfoContent();

  @override
  State<_TaskTypesInfoContent> createState() => _TaskTypesInfoContentState();
}

class _TaskTypesInfoContentState extends State<_TaskTypesInfoContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: SingleChildScrollView(
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
            AppText(text: 'info'.tr(), size: 24, fw: FontWeight.w700),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: greyscale200),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/images/2177-min.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 5,
                    child: LeftArrowBubleShape(
                      child: AppText(
                        text: 'task_type_message'.tr(),
                        size: 18,
                        maxLine: 10,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            card('task_without_point', 'task_without_point'.tr(), 'task_without_point_desc'.tr()),
            card('task_with_point', 'task_with_point'.tr(), 'task_with_point_desc'.tr()),
            card('task_of_day', 'task_of_day'.tr(), 'task_of_day_desc'.tr()),
            const SizedBox(height: 4),
            const Divider(height: 1, thickness: 1, color: greyscale200),
            const SizedBox(height: 24),
            FilledAppButton(
              text: 'ok'.tr(),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget card(String icon, String title, String desc) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: greyscale300),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/$icon.svg',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(text: title, fw: FontWeight.w600, size: 20, maxLine: 2),
                AppText(text: desc, fw: FontWeight.w400, size: 14, color: greyscale700, maxLine: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
