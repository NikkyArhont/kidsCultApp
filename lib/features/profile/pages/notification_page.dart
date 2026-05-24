import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../widgets/notification_card.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
        title: AppText(text: 'notifications'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/images/setting.svg',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              onPressed: () {
                showNotificationSettingModalBottomSheet(context);
              },
            ),
          ),
        ],
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, user) {
          if (user == null) return const SizedBox();
          return StreamBuilder<List<NotificationModel>>(
              stream: getNotifications(user.ref),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final notifications = snapshot.data!;
                if (notifications.isEmpty) return const EmptyNotificationsWidget();

                final groupedNotifications = groupNotificationsByDate(notifications);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: groupedNotifications.length,
                  itemBuilder: (context, index) {
                    final group = groupedNotifications[index];
                    final date = group.key;
                    final notifications = group.value..sort((a, b) => b.time!.compareTo(a.time!));

                    return Column(
                      children: [
                        groupHeader(date),
                        ...notifications.map((notification) => NotificationCard(notification: notification)),
                      ],
                    );
                  },
                );
              });
        },
      ),
    );
  }

  Widget groupHeader(DateTime time) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          AppText(
            text: dateToChatDivider(time),
            size: 14,
            color: greyscale500,
          ),
          const SizedBox(width: 16),
          const Expanded(child: Divider(height: 1, thickness: 1, color: greyscale200)),
        ],
      ),
    );
  }
}

List<MapEntry<DateTime, List<NotificationModel>>> groupNotificationsByDate(List<NotificationModel> notifications) {
  List<MapEntry<DateTime, List<NotificationModel>>> grouped = [];

  grouped = notifications
      .where((n) => n.time != null)
      .groupBy((n) => DateTime(n.time!.year, n.time!.month, n.time!.day))
      .entries
      .toList()
    ..sort((a, b) => b.key.compareTo(a.key));

  return grouped;
}

extension IterableExtension<T> on Iterable<T> {
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) => fold(
        <K, List<T>>{},
        (Map<K, List<T>> map, T element) {
          final key = keyFunction(element);
          map.putIfAbsent(key, () => <T>[]).add(element);
          return map;
        },
      );
}

Stream<List<NotificationModel>> getNotifications(DocumentReference ref) {
  final fs = FirebaseFirestore.instance;
  return fs
      .collection('notifications')
      .where('user', isEqualTo: ref)
      .orderBy('time', descending: true)
      .snapshots()
      .map((docs) => docs.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
}
