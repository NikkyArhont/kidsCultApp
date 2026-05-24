
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<bool?> showMaxConnectionModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
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
              text: 'maximum_children_alert'.tr(),
              size: 24,
              color: red,
              fw: FontWeight.w700,
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            MaskotMessage(
              message: 'maximum_children_text'.tr(),
              maskot: '2186-min',
              flip: true,
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FilledSecondaryAppButton(
                    onTap: () => context.pop(false),
                    text: 'cancel'.tr(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledAppButton(
                    onTap: () => context.pop(true),
                    text: 'refresh_subs'.tr(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      );
    },
  );
}
