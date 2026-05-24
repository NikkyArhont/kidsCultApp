import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> showNotEnoughtPointForBonusModalBottomSheet(BuildContext context, String title) {
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
              text: 'cant_request_bonus_by_kid'.tr(),
              size: 24,
              color: red,
              maxLine: 2,
              fw: FontWeight.w700,
              textAlign: TextAlign.center,
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
                      'assets/images/2182-min.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: LeftArrowBubleShape(
                    child: AppText(
                      text: title,
                      size: 20,
                      maxLine: 10,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            FilledAppButton(
              text: 'ok'.tr(),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 28),
          ],
        ),
      );
    },
  );
}
