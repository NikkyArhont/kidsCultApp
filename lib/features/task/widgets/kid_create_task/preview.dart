import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KidCreateTaskPreview extends StatelessWidget {
  const KidCreateTaskPreview({super.key});

  void onChangeMode(BuildContext context, int index) {
    context.read<KidTaskCreateCubit>().onChangeMode(true);
    context.read<KidTaskCreateCubit>().onJumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KidTaskCreateCubit, KidTaskCreateState>(
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
                    child: Column(
                      children: [
                         Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: MaskotMessage(
                            message: 'check_task_details_prompt'.tr(),
                            maskot: '2177-min',
                            flip: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: greyscale200, width: 3),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CachedClickableImage(
                                        width: 100,
                                        height: 100,
                                        circularRadius: 300,
                                        emojiFontSize: 60,
                                        onTap: () => onChangeMode(context, 0),
                                        imageFile: state.photo != null ? File(state.photo!.path) : null,
                                        emoji: state.emoji,
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: GestureDetector(
                                          onTap: () => onChangeMode(context, 0),
                                          child: SvgPicture.asset('assets/images/edit_blue_fill.svg'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 1),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: AppText(
                                        text: state.name ?? '-',
                                        size: 24,
                                        fw: FontWeight.bold,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                  ],
                                ),
                              ),
                              if (state.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: AppText(
                                    text: state.description!.trim(),
                                    fw: FontWeight.normal,
                                    color: greyscale700,
                                    maxLine: 3,
                                  ),
                                ),
                              const Divider(height: 40, thickness: 1, color: greyscale200),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 2),
                                child: Row(
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
                                      text: taskDate(state.startData),
                                      size: 16,
                                      textAlign: TextAlign.end,
                                    ),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 3),
                                child: Row(
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
                                      text: taskDate(state.endData),
                                      size: 16,
                                      textAlign: TextAlign.end,
                                    ),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 4),
                                child: Row(
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
                                      text: state.reminderType == ReminderType.single
                                          ? taskDate(state.reminderDate)
                                          : formatTimeOfDay(context, state.reminderTime),
                                      size: 16,
                                      textAlign: TextAlign.end,
                                    ),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        Container(
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: FilledAppButton(
                                  text: 'create'.tr(),
                                  isLoading: state.status == KidTaskCreateStatus.loading,
                                  onTap: () {
                                    if (state.status == KidTaskCreateStatus.loading) return;
                                    context.read<KidTaskCreateCubit>().createTask();
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
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

  Widget _leftArrow() {
    return const SizedBox(
      width: 24,
      child: Align(
        alignment: Alignment.centerRight,
        child: Icon(
          CupertinoIcons.chevron_right,
          color: dark5,
          size: 20,
        ),
      ),
    );
  }
}
