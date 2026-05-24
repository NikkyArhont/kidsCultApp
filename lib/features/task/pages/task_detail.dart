import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TaskDetailScreen extends StatefulWidget {
  final DocumentReference taskRef;
  final TaskModel? task;
  const TaskDetailScreen({super.key, required this.taskRef, this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel task;
  bool loading = false;
  StreamSubscription? _taskStreamSubscription;

  @override
  void initState() {
    super.initState();
    init();
  }

  void onInfoTap(BuildContext context) {
    showTaskOfDayInfoModalBottomSheet(context);
  }

  void init() async {
    if (widget.task != null) {
      task = widget.task!;
    } else {
      setState(() => loading = true);
      final doc = await widget.taskRef.get();
      task = TaskModel.fromFirestore(doc);
      setState(() => loading = false);
    }
    initSubscriptions();
  }

  void initSubscriptions() {
    _taskStreamSubscription = widget.taskRef.snapshots().listen((doc) {
      final task = TaskModel.fromFirestore(doc);
      if (mounted) {
        setState(() {
          this.task = task;
        });
      }
    });
  }

  void onCancel() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'cancelIt'.tr(),
      isDestructive: true,
      cancelText: 'no_dont_cancel'.tr(),
      confirmText: 'yes_cancel'.tr(),
      message: 'changed_your_mind'.tr(),
    );
    if (confrim == true && mounted) {
      context.push('/task_cancel_reason', extra: task);
    }
  }

  void onEdit() async {
    String route = task.type == TaskType.kid ? '/edit_create_task' : '/edit_mentor_create_task';
    final bool? refresh = await context.push(route, extra: task);
    if (refresh == true) {
      setState(() => loading = true);
      final doc = await widget.taskRef.get();
      task = TaskModel.fromFirestore(doc);
      setState(() => loading = false);
    }
  }

  void onDelete() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'delete'.tr(),
      isDestructive: true,
      cancelText: 'cancel'.tr(),
      confirmText: 'yes_delete'.tr(),
      message: 'are_you_sure_delete'.tr(),
    );
    if (confrim == true && mounted) {
      final result = await context.read<TaskCubit>().deleteTask(task);
      if (result && mounted) {
        context.replace('/task_delete_success');
      } else {
        SnackBarSerive.showErrorSnackBar('failed_to_delete_task'.tr());
      }
    }
  }

  void onComplete(UserModel me) async {
    TaskModel? priorityTask = canCompleteTask(me);

    if (priorityTask != null) {
      SnackBarSerive.showFirstDoTaskOfTheDayAlert(
        priorityTask.name,
        () => showFirstDoPriorityTaskModalBottomSheet(context, priorityTask),
      );
    } else {
      final confrim = await showConfirmModalBottomSheet(
        context,
        title: 'task_completed'.tr(),
        isDestructive: false,
        cancelText: 'cancel'.tr(),
        confirmText: 'yesConfirm'.tr(),
        message: 'is_everything_ready_confirm'.tr(),
      );
      if (confrim == false || confrim == null) return;

      if (mounted) {
        if ((me.isKid) && me.id == task.owner?.id) {
          bool complete = await context.read<TaskCubit>().completeTask(task);
          if (complete && mounted) {
            final extra = {"name": me.name, "coin": null};
            context.push('/task_complete_success', extra: extra);
          }
        } else if (!(me.isKid) && me.id == task.owner?.id) {
          // parent task | confirming
          context.read<TaskCubit>().completeByMentor(task);
        } else if (me.id == task.kid?.id && mounted) {
          // parents task | send to review
          final data = {'task': task, 'taskRef': task.ref};
          context.push('/task_dialog', extra: data);
        }
      }
    }
  }

  TaskModel? canCompleteTask(UserModel me) {
    if (!me.isKid) return null;
    if (task.type == TaskType.kid || task.type == TaskType.priority) return null;

    final tasks = context
        .read<TaskCubit>()
        .state
        .tasks
        .where((e) =>
            e.type == TaskType.priority &&
            task.kid?.id == e.kid?.id &&
            (e.status == TaskStatus.inProgress ||
                e.status == TaskStatus.needsRework ||
                e.status == TaskStatus.onReview))
        .toList();

    print(tasks.length);

    if (tasks.isNotEmpty) {
      return tasks.first;
    } else {
      return null;
    }
  }

  @override
  dispose() {
    _taskStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        constraints: const BoxConstraints.expand(),
        color: white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () {
                context.pop();
              },
            ),
            actions: ((me.id != task.owner?.id) ||
                    task.status == TaskStatus.canceled ||
                    task.status == TaskStatus.deleted ||
                    task.status == TaskStatus.completed)
                ? null
                : [
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/cancel.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: onCancel,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/edit.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/delete.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: IntrinsicHeight(
                      child: BlocConsumer<TaskCubit, TaskState>(
                        listener: (context, state) {
                          if (state.status == TaskStateStatus.mentorCompletingSuccess) {
                            final extra = {
                              "name": state.currentTaskKid?.name ?? '',
                              "coin": task.coin ?? 0,
                            };
                            context.push('/task_complete_success', extra: extra);
                          } else if (state.status == TaskStateStatus.mentorCompletingError) {
                            SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
                          }
                        },
                        builder: (context, state) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: BonusContainer(
                                  color: taskCardBorderColor(task.status),
                                  title: taskDetailCardStatusText(task.status),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Builder(builder: (context) {
                                            if (task.photo == null) {
                                              return const CachedClickableImage(
                                                height: 100,
                                                width: 100,
                                                circularRadius: 300,
                                              );
                                            } else {
                                              bool isEmoji = task.photo!.startsWith('emoji:');
                                              return CachedClickableImage(
                                                height: 100,
                                                width: 100,
                                                circularRadius: 300,
                                                emojiFontSize: 35,
                                                emoji: isEmoji ? task.photo!.replaceAll('emoji:', '') : null,
                                                imageUrl: isEmoji ? null : task.photo,
                                              );
                                            }
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: task.name,
                                              size: 24,
                                              fw: FontWeight.bold,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (task.description != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: AppText(
                                            text: task.description!.trim(),
                                            fw: FontWeight.normal,
                                            color: greyscale700,
                                            maxLine: 10,
                                          ),
                                        ),
                                      const Divider(height: 40, thickness: 1, color: greyscale200),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text:
                                                  '${"roleSelectionKid".tr()} ${task.type == TaskType.kid ? "creator".tr() : ''}',
                                              size: 16,
                                              fw: FontWeight.w500,
                                              color: greyscale800,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          if (task.kid != null)
                                            Expanded(
                                              child: FutureBuilder<UserModel>(
                                                future: context.read<UserCubit>().getUserByRef(task.kid!),
                                                builder: (context, snapshot) {
                                                  return AppText(
                                                    text: snapshot.data?.name ?? '...',
                                                    size: 16,
                                                    textAlign: TextAlign.end,
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (task.type != TaskType.kid)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: AppText(
                                                  text: "roleSelectionMentor".tr(),
                                                  size: 16,
                                                  fw: FontWeight.w500,
                                                  color: greyscale800,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              if (task.owner != null)
                                                Expanded(
                                                  flex: 2,
                                                  child: FutureBuilder<UserModel>(
                                                    future: context.read<UserCubit>().getUserByRef(task.owner!),
                                                    builder: (context, snapshot) {
                                                      return AppText(
                                                        text: snapshot.data?.name ?? '...',
                                                        size: 16,
                                                        textAlign: TextAlign.end,
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      if ((task.coin ?? 0) > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: Row(
                                            children: [
                                              AppText(
                                                text: 'points_optional'.tr(),
                                                size: 16,
                                                fw: FontWeight.w500,
                                                color: greyscale800,
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/images/coin.svg',
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    AppText(
                                                      text: task.coin.toString(),
                                                      size: 16,
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: 'start'.tr(),
                                              size: 16,
                                              fw: FontWeight.w500,
                                              color: greyscale800,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          AppText(
                                            text: taskDate(task.startDate),
                                            size: 16,
                                            textAlign: TextAlign.end,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: 'end_optional'.tr(),
                                              size: 16,
                                              fw: FontWeight.w500,
                                              color: greyscale800,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          AppText(
                                            text: taskDate(task.endDate),
                                            size: 16,
                                            textAlign: TextAlign.end,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: 'reminder_optional'.tr(),
                                              size: 16,
                                              fw: FontWeight.w500,
                                              color: greyscale800,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          AppText(
                                            text: task.reminderType == ReminderType.single
                                                ? taskDate(task.reminderDate)
                                                : formatTimeOfDay(context, task.reminderTime),
                                            size: 16,
                                            textAlign: TextAlign.end,
                                          ),
                                        ],
                                      ),
                                      if (task.type == TaskType.priority)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  children: [
                                                    AppText(
                                                      text: 'priority'.tr(),
                                                      size: 16,
                                                      fw: FontWeight.w500,
                                                      color: greyscale800,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    GestureDetector(
                                                      onTap: () => onInfoTap(context),
                                                      child: SvgPicture.asset(
                                                        'assets/images/info_square.svg',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/images/red_flag.svg',
                                                      width: 24,
                                                      height: 24,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    AppText(
                                                      text: 'task_of_the_day'.tr(),
                                                      size: 16,
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              //Для ментора - когда в процессе
                              if ((task.status == TaskStatus.inProgress ||
                                      task.status == TaskStatus.needsRework ||
                                      task.status == TaskStatus.canceled) &&
                                  task.type != TaskType.kid &&
                                  task.owner?.id == me.id)
                                GestureDetector(
                                  onTap: () {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.push('/task_execution_dialog', extra: data);
                                  },
                                  child: Container(
                                    height: 66,
                                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: greyscale200, width: 3)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: AppText(
                                            text: 'execution'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                        ),
                                        const Icon(CupertinoIcons.chevron_right, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              //Для ребенка - когда в процессе
                              if ((task.status == TaskStatus.inProgress || task.status == TaskStatus.canceled) &&
                                  task.type != TaskType.kid &&
                                  task.kid?.id == me.id)
                                GestureDetector(
                                  onTap: () {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.push('/task_execution_dialog', extra: data);
                                  },
                                  child: Container(
                                    height: 66,
                                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: greyscale200, width: 3)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: AppText(
                                            text: 'execution'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                        ),
                                        const Icon(CupertinoIcons.chevron_right, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              //Для ребенка - когда на проверке
                              if ((task.status == TaskStatus.onReview) && task.kid?.id == me.id)
                                GestureDetector(
                                  onTap: () {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.push('/task_execution_dialog', extra: data);
                                  },
                                  child: Container(
                                    height: 66,
                                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: greyscale200, width: 3)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: AppText(
                                            text: 'execution'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            AppText(
                                              text: '${'in_review'.tr()}...',
                                              size: 16,
                                              fw: FontWeight.w600,
                                              color: greyscale500,
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(CupertinoIcons.chevron_right, size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              //Для ребенка - когда на дороботке
                              if ((task.status == TaskStatus.needsRework) && task.kid?.id == me.id)
                                GestureDetector(
                                  onTap: () {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.push('/task_execution_dialog', extra: data);
                                  },
                                  child: Container(
                                    height: 66,
                                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: orange, width: 3),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: AppText(
                                            text: 'execution'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            AppText(
                                              text: 'rework'.tr(),
                                              size: 16,
                                              fw: FontWeight.w600,
                                              color: primary900,
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(CupertinoIcons.chevron_right, size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              //Для ментора - когда на проверке
                              if ((task.status == TaskStatus.onReview) &&
                                  task.type != TaskType.kid &&
                                  task.owner?.id == me.id)
                                GestureDetector(
                                  onTap: () {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.push('/task_execution_dialog', extra: data);
                                  },
                                  child: Container(
                                    height: 66,
                                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: greyscale200, width: 3)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: AppText(
                                            text: 'execution'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            AppText(
                                              text: 'check_it'.tr(),
                                              size: 16,
                                              fw: FontWeight.w600,
                                              color: primary900,
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(CupertinoIcons.chevron_right, size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // выполнено
                              if ((task.status == TaskStatus.completed))
                                GestureDetector(
                                  onTap: () {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.push('/task_execution_dialog', extra: data);
                                  },
                                  child: Container(
                                    height: 66,
                                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: success, width: 3)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: AppText(
                                            text: 'execution'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            AppText(
                                              text: 'confirmed'.tr(),
                                              size: 16,
                                              fw: FontWeight.w600,
                                              color: greyscale500,
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(CupertinoIcons.chevron_right, size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              //когда отменено
                              if ((task.status == TaskStatus.canceled) && task.reasonOfCancel != null)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: greyscale200, width: 3)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: 'couse_of_cancel'.tr(),
                                        size: 16,
                                        fw: FontWeight.w500,
                                        color: greyscale800,
                                      ),
                                      const Divider(height: 36, thickness: 1, color: greyscale200),
                                      AppText(
                                        text: task.reasonOfCancel == 'out_of_deadline'
                                            ? 'out_of_deadline'.tr()
                                            : task.reasonOfCancel ?? '',
                                      ),
                                    ],
                                  ),
                                ),

                              const Spacer(),
                              const SizedBox(height: 24),
                              // Для ребенка - когда в процессе
                              if ((task.status == TaskStatus.inProgress || task.status == TaskStatus.needsRework) &&
                                  task.kid?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: FilledAppButton(
                                          text: 'task_done_button'.tr(),
                                          onTap: () {
                                            onComplete(me);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              //Для ментора - когда в процессе
                              if ((task.status == TaskStatus.inProgress ||
                                      task.status == TaskStatus.needsRework ||
                                      task.status == TaskStatus.onReview) &&
                                  task.type != TaskType.kid &&
                                  task.owner?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: FilledAppButton(
                                          text: 'task_done_button'.tr(),
                                          isLoading: state.status == TaskStateStatus.mentorCompleting,
                                          onTap: () {
                                            onComplete(me);
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
