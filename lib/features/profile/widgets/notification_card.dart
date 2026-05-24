import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const NotificationCard({super.key, required this.notification});

  void onTap()async{
    notification.ref.update({'is_read': true});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: GestureDetector(behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    text: notification.title,
                    maxLine: 2,
                  ),
                ),
                if (!notification.isRead)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.lens,
                      color: primary900,
                      size: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            if (notification.body != null)
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: AppText(
                  text: notification.body!,
                  size: 14,
                  fw: FontWeight.w500,
                  color: greyscale800,
                  maxLine: 10,
                ),
              ),
            const SizedBox(height: 3),
            AppText(
              text: dateToHHmm(notification.time),
              size: 12,
              fw: FontWeight.w500,
              color: greyscale700,
              maxLine: 10,
            ),
          ],
        ),
      ),
    );
  }
}
