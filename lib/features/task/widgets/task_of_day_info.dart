import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';


Future<void> showTaskOfDayInfoModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return const _TaskOfDayInfoContent();
    },
  );
}

class _TaskOfDayInfoContent extends StatelessWidget {
  const _TaskOfDayInfoContent();

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
          AppText(text: 'info'.tr(), size: 24, fw: FontWeight.w700),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: MaskotMessage(
              message: 'task_of_day_desc_info'.tr(),
              maskot: '2177-min',
              flip: true,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          const SizedBox(height: 24),
          FilledAppButton(
            text: 'ok'.tr(),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
