import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TaskExecutionDialogScreen extends StatefulWidget {
  final DocumentReference taskRef;
  final TaskModel? task;
  const TaskExecutionDialogScreen({super.key, required this.taskRef, this.task});

  @override
  State<TaskExecutionDialogScreen> createState() => _TaskExecutionDialogScreenState();
}

class _TaskExecutionDialogScreenState extends State<TaskExecutionDialogScreen> {
  late TaskModel task;
  bool loading = false;
  List<TaskDialogModel> dialogs = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (widget.task != null) {
      task = widget.task!;
      getDialogs(task);
    } else {
      setState(() => loading = true);
      final doc = await widget.taskRef.get();
      task = TaskModel.fromFirestore(doc);
      setState(() => loading = false);
      getDialogs(task);
    }
  }

  void getDialogs(TaskModel task) async {
    setState(() {
      loading = true;
    });

    try {
      final collection = task.ref.collection('dialogs');

      final docs = await collection.orderBy('time', descending: true).get();

      final result = docs.docs.map((doc) => TaskDialogModel.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          dialogs = result;
          loading = false;
        });
      }
    } catch (e) {
      print('error: {getDialogs} ${e.toString()}');
      setState(() {
        loading = false;
      });
      SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
    }
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
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) {
            return Container(
              constraints: const BoxConstraints.expand(),
              color: white,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return BlocConsumer<TaskCubit, TaskState>(
            listener: (context, state) {
              if (state.status == TaskStateStatus.mentorCompletingSuccess) {
                final extra = {
                  "name": state.currentTaskKid?.name ?? '',
                  "coin": task.coin ?? 0,
                };
                context.replace('/task_complete_success', extra: extra);
              } else if (state.status == TaskStateStatus.mentorCompletingError) {
                SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          MaskotMessage(
                            message: 'check_it_title'.tr(),
                            flip: true,
                          ),
                          const SizedBox(height: 40),
                          if (dialogs.isEmpty)
                            const _NoMaterialsWidget()
                          else
                            ...dialogs.map((dialog) => _Dialog(dialog: dialog)),
                        ],
                      ),
                    ),
                  ),
                  if (me.isKid)
                   task.status == TaskStatus.canceled
                        ? const SizedBox()
                        : Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: greyscale100)),
                        color: white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.status == TaskStatus.inProgress)
                              FilledAppButton(
                                text: 'task_done_button'.tr(),
                                isLoading: state.status == TaskStateStatus.mentorCompleting,
                                onTap: () async {
                                  final confrim = await showConfirmModalBottomSheet(
                                    context,
                                    title: 'task_completed'.tr(),
                                    isDestructive: false,
                                    cancelText: 'cancel'.tr(),
                                    confirmText: 'yesConfirm'.tr(),
                                    message: 'is_everything_ready_confirm'.tr(),
                                  );
                                  if (confrim == true && context.mounted) {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.replace('/task_dialog', extra: data);
                                  }
                                },
                              ),
                            if (task.status == TaskStatus.needsRework)
                              FilledAppButton(
                                text: 'confirm_of_complete'.tr(),
                                onTap: () async {
                                  final confrim = await showConfirmModalBottomSheet(
                                    context,
                                    title: 'task_completed'.tr(),
                                    isDestructive: false,
                                    cancelText: 'cancel'.tr(),
                                    confirmText: 'yesConfirm'.tr(),
                                    message: 'is_everything_ready_confirm'.tr(),
                                  );
                                  if (confrim == true && context.mounted) {
                                    final data = {'task': task, 'taskRef': task.ref};
                                    context.replace('/task_dialog', extra: data);
                                  }
                                },
                              ),
                            // const SizedBox(height: 24),
                            if (task.status == TaskStatus.onReview)
                              OutlinedAppButton(
                                text: '${'in_review'.tr()}...',
                              ),
                            if (task.status == TaskStatus.completed)
                              OutlinedAppButton(
                                text: 'completion_confirmed'.tr(),
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.done, color: primary900, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    task.status == TaskStatus.canceled
                        ? const SizedBox()
                        : Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: greyscale100)),
                              color: white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.status == TaskStatus.inProgress || task.status == TaskStatus.needsRework)
                                    FilledAppButton(
                                      text: 'task_done_button'.tr(),
                                      isLoading: state.status == TaskStateStatus.mentorCompleting,
                                      onTap: () async {
                                        final confrim = await showConfirmModalBottomSheet(
                                          context,
                                          title: 'task_completed'.tr(),
                                          isDestructive: false,
                                          cancelText: 'cancel'.tr(),
                                          confirmText: 'yesConfirm'.tr(),
                                          message: 'is_everything_ready_confirm'.tr(),
                                        );
                                        if (confrim == true && context.mounted) {
                                          context.read<TaskCubit>().completeByMentor(task);
                                        }
                                      },
                                    ),
                                  if (task.status == TaskStatus.completed)
                                    OutlinedAppButton(
                                      text: 'completion_confirmed'.tr(),
                                      icon: const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(Icons.done, color: primary900, size: 20),
                                      ),
                                    ),
                                  if (task.status == TaskStatus.onReview)
                                    Column(
                                      children: [
                                        FilledAppButton(
                                          text: 'confirm_of_complete'.tr(),
                                          isLoading: state.status == TaskStateStatus.mentorCompleting,
                                          onTap: () async {
                                            final confrim = await showConfirmModalBottomSheet(
                                              context,
                                              title: 'task_completed'.tr(),
                                              isDestructive: false,
                                              cancelText: 'cancel'.tr(),
                                              confirmText: 'yesConfirm'.tr(),
                                              message: 'is_everything_ready_confirm'.tr(),
                                            );
                                            if (confrim == true && context.mounted) {
                                              context.read<TaskCubit>().completeByMentor(task);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        OutlinedAppButton(
                                          onPress: () {
                                            final data = {'task': task, 'taskRef': task.ref, 'is_rework': true};
                                            context.replace('/task_dialog', extra: data);
                                          },
                                          text: 'for_revision'.tr(),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  final TaskDialogModel dialog;
  const _Dialog({required this.dialog});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dialog.user != null)
          FutureBuilder<UserModel>(
            future: context.read<UserCubit>().getUserByRef(dialog.user!),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Row(
                children: [
                  CachedClickableImage(
                    height: 48,
                    width: 48,
                    imageUrl: user?.photo,
                    circularRadius: 100,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: user?.name ?? '...',
                        size: 16,
                        fw: FontWeight.w700,
                      ),
                      AppText(
                        text: taskDate(dialog.time),
                        size: 14,
                        fw: FontWeight.normal,
                        color: greyscale700,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        if (dialog.comment != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AppText(
              text: dialog.comment!,
              size: 18,
              color: greyscale800,
              fw: FontWeight.normal,
              maxLine: 30,
            ),
          ),
        if (dialog.files.isNotEmpty) DialogPhotoOrVideos(files: dialog.files),
        const Divider(height: 40, thickness: 1, color: greyscale200),
      ],
    );
  }
}

class _NoMaterialsWidget extends StatelessWidget {
  const _NoMaterialsWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Image.asset(
          'assets/images/2187-min.png',
          width: 160,
          height: 160,
        ),
        AppText(
          text: 'no_materials'.tr(),
          size: 24,
          fw: FontWeight.w600,
          maxLine: 2,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
