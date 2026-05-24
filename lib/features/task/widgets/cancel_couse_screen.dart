import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class TaskCancelReasonScreen extends StatefulWidget {
  final TaskModel task;
  const TaskCancelReasonScreen({super.key, required this.task});

  @override
  State<TaskCancelReasonScreen> createState() => _TaskCancelReasonScreenState();
}

class _TaskCancelReasonScreenState extends State<TaskCancelReasonScreen> {
  final form = FormGroup({
    'description': FormControl<String>(),
  });

  @override
  Widget build(BuildContext context) {
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
      body: BlocConsumer<TaskCubit, TaskState>(
        listener: (context, state) {
          if (state.status == TaskStateStatus.cancelError) {
            SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
          } else if (state.status == TaskStateStatus.cancelSuccess) {
            context.pop();
            context.pop();
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: IntrinsicHeight(
                        child: ReactiveForm(
                          formGroup: form,
                          child: Column(
                            children: [
                               Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: MaskotMessage(
                                  message: 'add_cancellation_reason_prompt'.tr(),
                                  maskot: '2185-min',
                                  flip: false,
                                ),
                              ),
                              const SizedBox(height: 40),
                               Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: ReactiveCustomInput(
                                  formName: 'description',
                                  label: 'cancellation_reason'.tr(),
                                  hint: 'enter'.tr(),
                                  inputType: TextInputType.multiline,
                                  textCapitalization: TextCapitalization.sentences,
                                  textInputAction: TextInputAction.newline,
                                  minLines: 4,
                                  maxLines: 5,
                                  maxLenght: 500,
                                ),
                              ),
                              const Spacer(),
                              ReactiveFormConsumer(
                                builder: (context, formGroup, child) {
                                  final text = formGroup.value['description'] as String? ?? '';
                                  final valid = text.trim().isNotEmpty;
                                  return Container(
                                    decoration:
                                        const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: FilledSecondaryAppButton(
                                            text: 'skip'.tr(),
                                            isLoading: state.status == TaskStateStatus.canceling && !valid,
                                            onTap: () {
                                              if (state.status == TaskStateStatus.canceling) return;
                                              context.read<TaskCubit>().cancelTask(widget.task,  null);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: FilledAppButton(
                                            text: 'add'.tr(),
                                            isActive: valid,
                                            isLoading: state.status == TaskStateStatus.canceling && valid,
                                            onTap: () {
                                              if (state.status == TaskStateStatus.canceling) return;
                                              if (valid) {
                                                context.read<TaskCubit>().cancelTask(widget.task, text);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
