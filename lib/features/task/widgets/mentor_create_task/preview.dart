import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MentorCreateTaskPreview extends StatelessWidget {
  const MentorCreateTaskPreview({super.key});

  void onChangeMode(BuildContext context, int index) {
    context.read<MentorTaskCreateCubit>().onChangeMode(true);
    context.read<MentorTaskCreateCubit>().onJumpToPage(index);
  }

  void onInfoTap(BuildContext context) {
    showTaskOfDayInfoModalBottomSheet(context);
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
                          padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
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
                                        onTap: () => onChangeMode(context, 2),
                                        imageFile: state.photo != null ? File(state.photo!.path) : null,
                                        emoji: state.emoji,
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: GestureDetector(
                                          onTap: () => onChangeMode(context, 2),
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
                                    const SizedBox(width: 20),
                                  ],
                                ),
                              ),
                              if (state.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10, right: 20),
                                  child: AppText(
                                    text: state.description!.trim(),
                                    fw: FontWeight.normal,
                                    color: greyscale700,
                                    maxLine: 3,
                                  ),
                                ),
                              const Divider(height: 40, thickness: 1, color: greyscale200),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: 'child'.tr(),
                                        size: 16,
                                        fw: FontWeight.w500,
                                        color: greyscale800,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    AppText(
                                      text: state.selectedKid?.name ?? '-',
                                      size: 16,
                                      textAlign: TextAlign.end,
                                    ),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                    const SizedBox(width: 20),
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
                                        text: 'points_optional'.tr(),
                                        size: 16,
                                        fw: FontWeight.w500,
                                        color: greyscale800,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Row(
                                      children: [
                                        SvgPicture.asset('assets/images/coin.svg', width: 20, height: 20),
                                        const SizedBox(width: 6),
                                        AppText(
                                          text: state.point != null ? state.point.toString() : '0',
                                          size: 16,
                                          textAlign: TextAlign.end,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                    const SizedBox(width: 20),
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
                                    const SizedBox(width: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 5),
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
                                    const SizedBox(width: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 6),
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
                                    const SizedBox(width: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () => onChangeMode(context, 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          AppText(
                                            text: 'priority'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => onInfoTap(context),
                                            child: SvgPicture.asset('assets/images/info_square.svg'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    SvgPicture.asset(
                                      'assets/images/red_flag.svg',
                                      fit: BoxFit.contain,
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    AppText(
                                      text: 'task_of_the_day'.tr(),
                                      size: 16,
                                      fw: FontWeight.w500,
                                      textAlign: TextAlign.end,
                                    ),
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        onChanged: (value) {
                                          if (value != null) {
                                            context.read<MentorTaskCreateCubit>().onChangeTaskOfDay(value);
                                          }
                                        },
                                        value: state.isTaskOfDay,
                                        activeColor: primary900,
                                        checkColor: white,
                                        side: const BorderSide(color: primary900, width: 3),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
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
                                  text: 'send_to_do'.tr(),
                                  isLoading: state.status == MentorTaskCreateStatus.loading,
                                  onTap: () {
                                    if (state.status == MentorTaskCreateStatus.loading) return;
                                    context.read<MentorTaskCreateCubit>().createTask();
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
