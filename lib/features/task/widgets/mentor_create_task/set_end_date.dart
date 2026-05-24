import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MentorCreateTaskSetEndDate extends StatefulWidget {
  const MentorCreateTaskSetEndDate({super.key});

  @override
  State<MentorCreateTaskSetEndDate> createState() => _MentorCreateTaskSetEndDateState();
}

class _MentorCreateTaskSetEndDateState extends State<MentorCreateTaskSetEndDate> {
  String? dateError;

  void onDatePick(BuildContext context) async {
    final selectedDate = await showDatePickerModalBottomSheet(context);
    if (selectedDate != null && context.mounted) {
      final startDate = context.read<MentorTaskCreateCubit>().state.startData;
      if (startDate != null && selectedDate.isBefore(startDate)) {
        setState(() {
          dateError = 'end_date_before_start_error'.tr();
        });
      } else {
        if (dateError != null) setState(() => dateError = null);
        context.read<MentorTaskCreateCubit>().onChangeEndDate(selectedDate);
      }
    }
  }

  void onTimePick(BuildContext context) async {
    final selectedTime = await showTimePickerModalBottomSheet(context);
    if (selectedTime != null && context.mounted) {
      context.read<MentorTaskCreateCubit>().onChangeEndTime(selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MentorTaskCreateCubit, MentorTaskCreateState>(
      builder: (context, state) {
        final valid = state.endData != null;
        return Column(
          children: [
             Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'deadline_prompt'.tr(),
                maskot: '2186-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    CustomDateInput(
                      label: 'end_date_optional'.tr(),
                      hint: 'selectDataHint'.tr(),
                      date: state.endData,
                      errorText: dateError,
                      onTap: () => onDatePick(context),
                    ),
                    const SizedBox(height: 16),
                    CustomTimeInput(
                      onTap: () => onTimePick(context),
                      label: 'end_time_optional'.tr(),
                      hint: 'selectTime'.tr(),
                      enable: state.endData != null,
                      time: getTimeFromDate(state.endData),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (!state.isEditMode)
                          Expanded(
                            child: FilledSecondaryAppButton(
                              text: 'buttonSkip'.tr(),
                              onTap: () {
                                context.read<MentorTaskCreateCubit>().onChangeEndDate(null);
                                context.read<MentorTaskCreateCubit>().nextPage();
                              },
                            ),
                          ),
                        if (!state.isEditMode) const SizedBox(width: 24),
                        Expanded(
                          child: FilledAppButton(
                            text: state.isEditMode ? 'apply'.tr() : 'add'.tr(),
                            isActive: valid,
                            onTap: () {
                              if (valid) {
                                if (state.isEditMode) {
                                  context.read<MentorTaskCreateCubit>().onChangeMode(false);
                                  context.read<MentorTaskCreateCubit>().onJumpToPage(7);
                                } else {
                                  context.read<MentorTaskCreateCubit>().nextPage();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TimeOfDay? getTimeFromDate(DateTime? date) {
    if (date == null) return null;
    if (date.hour == 0 && date.minute == 0) return null;
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }
}
