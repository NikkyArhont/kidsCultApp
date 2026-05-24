import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class MentorCreateTaskSetName extends StatefulWidget {
  const MentorCreateTaskSetName({super.key});

  @override
  State<MentorCreateTaskSetName> createState() => _MentorCreateTaskSetNameState();
}

class _MentorCreateTaskSetNameState extends State<MentorCreateTaskSetName> {
  final FocusNode focus = FocusNode();
  final StreamController<bool> _inputFocusStreamController = StreamController<bool>();
  Stream<bool> get inputFocusStream => _inputFocusStreamController.stream;
  final TextEditingController controller = TextEditingController();

  final form = FormGroup({
    'name': FormControl<String>(
      validators: [
        Validators.required,
        Validators.minLength(3),
        Validators.maxLength(120),
      ],
    ),
    'description': FormControl<String>(),
  });

  @override
  void initState() {
    super.initState();
    final state = context.read<MentorTaskCreateCubit>().state;
    form.control('name').value = state.name ?? state.suggestTask?.name;
    focus.addListener(() {
      _inputFocusStreamController.add(focus.hasFocus);
    });
    _addInputListener();
  }

  void _addInputListener() {
    controller.addListener(() {
      if (mounted) {
        context.read<MentorTaskCreateCubit>().onDeleteSuggestTask();
      }
    });
  }

  @override
  void dispose() {
    focus.dispose();
    _inputFocusStreamController.close();
    controller.dispose();
    super.dispose();
  }

  void onTapSuggest(TaskModel task) {
    setState(() {
      form.control('name').value = task.name;
      focus.unfocus();
       context.read<MentorTaskCreateCubit>().onSelectSuggestTask(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MentorTaskCreateCubit, MentorTaskCreateState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: IntrinsicHeight(
                    child: ReactiveForm(
                      formGroup: form,
                      child: StreamBuilder<bool>(
                          stream: inputFocusStream,
                          initialData: focus.hasFocus,
                          builder: (context, snapshot) {
                            bool hasFocus = snapshot.data ?? false;
                            return Column(
                              children: [
                                Offstage(
                                  offstage: hasFocus,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                                    child: MaskotMessage(
                                      message: 'name_the_task_prompt'.tr(),
                                      maskot: '2186-min',
                                      flip: true,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: ReactiveCustomInput(
                                    formName: 'name',
                                    focus: focus,
                                    controller: controller,
                                    label: 'title'.tr(),
                                    hint: 'enter_title_hint'.tr(),
                                    inputType: TextInputType.text,
                                    textCapitalization: TextCapitalization.sentences,
                                    textInputAction: TextInputAction.next,
                                    maxLenght: 120,
                                    validationMessages: {
                                      'required': (error) => 'field_required_error'.tr(),
                                      'minLength': (error) => 'min_length_3'.tr(),
                                      'maxLength': (error) => 'max_120_chars_error'.tr(),
                                    },
                                  ),
                                ),
                                Visibility(
                                  visible: hasFocus,
                                  child: _SuggestionWidget(
                                    popularTasks: state.usedTasks,
                                    onTap: onTapSuggest,
                                  ),
                                ),
                                Offstage(
                                  offstage: hasFocus,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                    child: ReactiveCustomInput(
                                      formName: 'description',
                                      label: 'description_optional'.tr(),
                                      hint: 'enter_description_hint'.tr(),
                                      inputType: TextInputType.multiline,
                                      textCapitalization: TextCapitalization.sentences,
                                      textInputAction: TextInputAction.newline,
                                      minLines: 4,
                                      maxLines: 5,
                                      maxLenght: 500,
                                      validationMessages: {
                                        'minLength': (error) => 'min_length_3'.tr(),
                                        'maxLength': (error) => 'max_500_chars_error'.tr(),
                                      },
                                    ),
                                  ),
                                ),
                                // Offstage(offstage: hasFocus, child: const Spacer()),
                                Visibility(visible: !hasFocus, child: const Spacer()),
                                Offstage(
                                  offstage: hasFocus,
                                  child: ReactiveFormConsumer(
                                    builder: (context, formGroup, child) {
                                      final valid = formGroup.valid;
                                      return Container(
                                        decoration:
                                            const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 20),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 24),
                                              child: FilledAppButton(
                                                text: hasFocus || state.isEditMode ? 'apply'.tr() : 'next'.tr(),
                                                isActive: valid,
                                                onTap: () {
                                                  if (hasFocus) {
                                                    print('apply');
                                                  } else {
                                                    formGroup.markAllAsTouched();
                                                    if (valid) {
                                                      final suggest = state.suggestTask;
                                                      print('suggest?.id: ${suggest?.id}');

                                                      final name = formGroup.control('name').value;
                                                      final desc = formGroup.control('description').value;

                                                      context
                                                          .read<MentorTaskCreateCubit>()
                                                          .onChangeNameAndDescription(name, desc);
                                                      if (state.isEditMode) {
                                                        context.read<MentorTaskCreateCubit>().onChangeMode(false);
                                                        context.read<MentorTaskCreateCubit>().onJumpToPage(7);
                                                      } else {
                                                        context.read<MentorTaskCreateCubit>().nextPage();
                                                      }
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SuggestionWidget extends StatefulWidget {
  final List<TaskModel> popularTasks;
  final Function(TaskModel task) onTap;
  const _SuggestionWidget({required this.popularTasks, required this.onTap});

  @override
  State<_SuggestionWidget> createState() => __SuggestionStateWidget();
}

class __SuggestionStateWidget extends State<_SuggestionWidget> {
  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, formGroup, child) {
        final query = formGroup.findControl('name')?.value as String?;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (query != null && query.trim().isNotEmpty)
                    Builder(
                      builder: (context) {
                        final matched = widget.popularTasks
                            .where((task) => task.name.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                        final displayedItems = matched.length > 10 ? matched.sublist(0, 10) : matched;
                        if (displayedItems.isNotEmpty) {
                          return Column(
                            children: [
                              ...displayedItems.map((task) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      widget.onTap(task);
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: AppText(
                                            text: task.name,
                                            maxLine: 2,
                                            fw: FontWeight.w500,
                                            size: 20,
                                            color: greyscale700,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/coins.svg',
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(width: 6),
                                            AppText(
                                              text: (task.coin ?? 0).toString(),
                                              fw: FontWeight.w500,
                                              size: 18,
                                              color: greyscale700,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          text: 'most_popular_tasks'.tr(),
                          fw: FontWeight.w700,
                          size: 20,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final TaskModel? selectedTask =
                              await context.push('/popular_tasks', extra: widget.popularTasks);

                          if (selectedTask != null) {
                            widget.onTap(selectedTask);
                          }
                        },
                        child: AppText(
                          text: 'all'.tr(),
                          fw: FontWeight.w700,
                          size: 16,
                          color: primary900,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final displayedItems =
                          widget.popularTasks.length > 5 ? widget.popularTasks.sublist(0, 5) : widget.popularTasks;

                      return Column(
                        children: [
                          ...displayedItems.map((task) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  widget.onTap(task);
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: task.name,
                                        maxLine: 2,
                                        fw: FontWeight.w500,
                                        size: 20,
                                        color: greyscale700,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/images/coins.svg',
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 6),
                                        AppText(
                                          text: (task.coin ?? 0).toString(),
                                          fw: FontWeight.w500,
                                          size: 18,
                                          color: greyscale700,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
