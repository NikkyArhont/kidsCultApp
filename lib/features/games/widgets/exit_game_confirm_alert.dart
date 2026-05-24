import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<bool?> showExitgameConfirmModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet<bool?>(
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
              text: 'exitGame'.tr(),
              size: 24,
              color: red,
              fw: FontWeight.w700,
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Transform.flip(
                    flipX: true,
                    child: Image.asset(
                      'assets/images/2186-min.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: LeftArrowBubleShape(
                    child: AppText(
                      text: 'exitGameConfirm'.tr(),
                      size: 20,
                      maxLine: 10,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            Row(
              children: [
                Expanded(
                  child: FilledSecondaryAppButton(
                    height: 84,
                    text: 'exitWithoutSave'.tr(),
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledAppButton(
                    height: 84,
                    text: 'continueGame'.tr(),
                    onTap: () => Navigator.pop(context, false),
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
