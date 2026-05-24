import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

Future<bool?> showConfirmModalBottomSheet(BuildContext context,
    {required String title,
    bool isDestructive = false,
    required String confirmText,
    required String cancelText,
    String message = '',
    String defaultmascot = '2179-min'}) async {
  return showModalBottomSheet<bool?>(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      final mascot = isDestructive ? 'assets/images/2186-min.png' : 'assets/images/$defaultmascot.png';
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
              text: title,
              size: 24,
              color: isDestructive ? red : secondary900,
              fw: FontWeight.w700,
              maxLine: 2,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: isDestructive
                      ? Transform.flip(
                          flipX: true,
                          child: Image.asset(
                            mascot,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          mascot,
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: LeftArrowBubleShape(
                    child: AppText(
                      text: message,
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
                    text: cancelText,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledAppButton(
                    text: confirmText,
                    onTap: () => Navigator.pop(context, true),
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
