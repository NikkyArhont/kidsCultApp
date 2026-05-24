import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> showFirstDoPriorityTaskModalBottomSheet(BuildContext context, TaskModel task) {
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
              text: 'confirm_of_complete'.tr(),
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
                    )),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: LeftArrowBubleShape(
                    child: AppText(
                      text: 'first_complete_task'.tr(),
                      size: 20,
                      maxLine: 10,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BlocBuilder<UserCubit, UserModel?>(
              builder: (context, me) {
                if(me == null) return const SizedBox();
                return TaskCard(task: task, me: me, hasBorder: true);
              },
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            Row(
              children: [
                Expanded(
                  child: FilledSecondaryAppButton(
                    text: 'maybe_later'.tr(),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledAppButton(
                    text: 'go_to'.tr(),
                    onTap: () {
                      Navigator.pop(context, true);
                      final data = {'task': task, 'taskRef': task.ref};
                      context.push('/task_detail', extra: data);
                    },
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
