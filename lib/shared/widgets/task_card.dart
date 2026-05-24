// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final UserModel me;
  final bool hasBorder;
  const TaskCard({super.key, required this.task, required this.me, this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final data = {'task': task, 'taskRef': task.ref};
        context.push('/task_detail', extra: data);
      },
      child: Container(
        width: double.infinity,
        height: 115,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: taskCardBorderColor(task.status), width: 3),
          ),
          color: white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Builder(builder: (context) {
              if (task.photo == null) {
                return const CachedClickableImage(
                  circularRadius: 8,
                  width: 42,
                  height: 42,
                );
              } else {
                bool isEmoji = task.photo!.startsWith('emoji:');
                return CachedClickableImage(
                  circularRadius: 8,
                  width: 42,
                  height: 42,
                  emojiFontSize: 25,
                  emoji: isEmoji ? task.photo!.replaceAll('emoji:', '') : null,
                  emojiWidget: Container(
                    width: 42,
                    height: 42,
                     color: greyscale100,
                    child: Center(
                      child: Text(
                        task.photo!.replaceAll('emoji:', ''),
                        style: const TextStyle(fontSize: 35),
                      ),
                    ),
                  ),
                  imageUrl: isEmoji ? null : task.photo,
                );
              }
            }),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: task.name,
                    size: 20,
                    fw: FontWeight.w700,
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final isKidTask = task.owner?.id == task.kid?.id;
                      return FutureBuilder<UserModel>(
                        initialData: isKidTask ? me : null,
                        future: isKidTask
                            ? null
                            : context.read<UserCubit>().getUserByRef(me.isKid ? task.owner! : task.kid!),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          late String text;
                          if (isKidTask) {
                            text = '${"createFrom".tr()}: ${me.name} (${"amI".tr()})';
                          } else {
                            if (me.isKid) {
                              text = '${"mentor".tr()} ${user?.name ?? '...'}';
                            } else {
                              text = '${"child".tr()}: ${user?.name ?? '...'}';
                            }
                          }
                          return AppText(
                            text: text,
                            size: 12,
                            fw: FontWeight.normal,
                            color: greyscale700,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/time_circle.svg',
                              width: 14,
                              height: 14,
                              color: greyscale700,
                            ),
                            const SizedBox(width: 5),
                            AppText(
                              text: reminderText(context),
                              size: 12,
                              fw: FontWeight.normal,
                              color: greyscale700,
                              height: 1,
                            ),
                            if (task.coin != null && task.coin! > 0)
                              Row(
                                children: [
                                  const SizedBox(width: 12),
                                  SvgPicture.asset(
                                    'assets/images/coin.svg',
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  AppText(
                                    text: task.coin.toString(),
                                    size: 12,
                                    fw: FontWeight.normal,
                                    color: greyscale700,
                                    height: 1,
                                  ),
                                ],
                              ),
                            if (task.type == TaskType.priority)
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: SvgPicture.asset(
                                  'assets/images/red_flag.svg',
                                  width: 14,
                                  height: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: taskCardStatusColor(task.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppText(
                          text: taskCardStatusText(task.status, isKid: me.isKid),
                          size: 10,
                          color: taskCardStatusTextColor(task.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String reminderText(BuildContext context) {
    if (task.reminderType == ReminderType.daily && task.reminderTime != null) {
      return task.reminderTime!.format(context);
    } else if (task.reminderType == ReminderType.single && task.reminderDate != null) {
      return dateToHHmm(task.reminderDate!);
    } else {
      return 'no'.tr();
    }
  }
}
