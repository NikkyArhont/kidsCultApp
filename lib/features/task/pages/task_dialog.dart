import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';

class TaskDialogScreen extends StatefulWidget {
  final DocumentReference taskRef;
  final TaskModel? task;
  final bool isRework;
  const TaskDialogScreen({super.key, required this.taskRef, this.task, this.isRework = false});

  @override
  State<TaskDialogScreen> createState() => _TaskDialogScreenState();
}

class _TaskDialogScreenState extends State<TaskDialogScreen> {
  late TaskModel task;
  bool loading = false;
  List<XFile> files = [];
  bool isRework = false;

  final form = FormGroup({
    'comment': FormControl<String>(),
  });

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    isRework = widget.isRework;
    if (widget.task != null) {
      task = widget.task!;
    } else {
      setState(() => loading = true);
      final doc = await widget.taskRef.get();
      task = TaskModel.fromFirestore(doc);
      setState(() => loading = false);
    }
  }

  void onAddFile(XFile file) {
    files.add(file);
    setState(() {});
  }

  void onRemoveFile(XFile file) {
    files.remove(file);
    setState(() {});
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
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ReactiveForm(
          formGroup: form,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      MaskotMessage(
                        message: isRework ? 'for_revision_title'.tr() : 'want_to_show_task'.tr(),
                        flip: true,
                      ),
                      const SizedBox(height: 40),
                      ReactiveCustomInput(
                        formName: 'comment',
                        label: 'comment'.tr(),
                        hint: 'comment_enter'.tr(),
                        inputType: TextInputType.multiline,
                        textInputAction: TextInputAction.done,
                        maxLenght: 400,
                        minLines: 4,
                        maxLines: 6,
                        validationMessages: {
                          'required': (error) => 'field_required_error'.tr(),
                          'minLength': (error) => 'min_length_3'.tr(),
                        },
                      ),
                      const SizedBox(height: 16),
                      AppText(text: 'add_photo_video'.tr()),
                      PhotoVideoPicker(
                        files: files,
                        onAdd: onAddFile,
                        onRemove: onRemoveFile,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: greyscale100)),
                    color: white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        BlocConsumer<TaskCubit, TaskState>(
                          listener: (context, state) {
                            if (state.status == TaskStateStatus.kidCompletingError ||
                                state.status == TaskStateStatus.mentorSendReworkError) {
                              SnackBarSerive.showErrorSnackBar(state.errorMessage ?? 'defaultErrorText'.tr());
                            } else if (state.status == TaskStateStatus.kidCompletingSuccess) {
                              context.replace('/task_send_review_success');
                            } else if (state.status == TaskStateStatus.mentorSendReworkSuccess) {
                              context.replace('/task_send_rework_success');
                            }
                          },
                          builder: (context, state) {
                            if (isRework) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: FilledSecondaryAppButton(
                                      text: 'buttonSkip'.tr(),
                                      onTap: () {
                                        context.read<TaskCubit>().reworkByMentorSkip(task);
                                      },
                                      isLoading: state.status == TaskStateStatus.mentorSendReworkSkip,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ReactiveFormConsumer(
                                    builder: (context, formGroup, child) {
                                      final comment = formGroup.value['comment'] as String?;
                                      bool isValid = (comment ?? '').trim().isNotEmpty || files.isNotEmpty;
                                      return Expanded(
                                        child: FilledAppButton(
                                          text: 'add'.tr(),
                                          onTap: () {
                                            if (isValid) {
                                              context.read<TaskCubit>().reworkByMentor(task, comment, files);
                                            }
                                          },
                                          isActive: isValid,
                                          isLoading: state.status == TaskStateStatus.mentorSendRework,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(
                                    child: FilledSecondaryAppButton(
                                      text: 'buttonSkip'.tr(),
                                      onTap: () {
                                        context.read<TaskCubit>().completeByKidSkip(task);
                                      },
                                      isLoading: state.status == TaskStateStatus.kidCompletingSkip,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ReactiveFormConsumer(
                                    builder: (context, formGroup, child) {
                                      final comment = formGroup.value['comment'] as String?;
                                      bool isValid = (comment ?? '').trim().isNotEmpty || files.isNotEmpty;
                                      return Expanded(
                                        child: FilledAppButton(
                                          text: 'add'.tr(),
                                          onTap: () {
                                            if (isValid) {
                                              context.read<TaskCubit>().completeByKid(task, comment, files);
                                            }
                                          },
                                          isActive: isValid,
                                          isLoading: state.status == TaskStateStatus.kidCompleting,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
