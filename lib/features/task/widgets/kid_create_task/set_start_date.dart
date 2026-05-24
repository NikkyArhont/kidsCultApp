import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KidCreateTaskSetStartDate extends StatelessWidget {
  const KidCreateTaskSetStartDate({super.key});

  void onDatePick(BuildContext context) async {
    final selectedDate = await showDatePickerModalBottomSheet(context);
    if (selectedDate != null && context.mounted) {
      context.read<KidTaskCreateCubit>().onChangeStartDate(selectedDate);
    }
  }

  void onTimePick(BuildContext context) async {
    final selectedTime = await showTimePickerModalBottomSheet(context);
    if (selectedTime != null && context.mounted) {
      context.read<KidTaskCreateCubit>().onChangeStartTime(selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KidTaskCreateCubit, KidTaskCreateState>(
      builder: (context, state) {
        final valid = state.startData != null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'when_to_start_task_prompt'.tr(),
                maskot: '2177-min',
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
                      label: 'start_date'.tr(),
                      hint: 'selectDataHint'.tr(),
                      date: state.startData,
                      onTap: () => onDatePick(context),
                    ),
                    const SizedBox(height: 16),
                    CustomTimeInput(
                      onTap: () => onTimePick(context), hint: 'selectTime'.tr(),
                      label: 'start_time_optional'.tr(),
                      time: getTimeFromDate(state.startData),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FilledAppButton(
                      text: state.isEditMode ? 'apply'.tr() : 'next'.tr(),
                      isActive: valid,
                      onTap: () {
                        if (valid) {
                          if (state.isEditMode) {
                            context.read<KidTaskCreateCubit>().onChangeMode(false);
                            context.read<KidTaskCreateCubit>().onJumpToPage(5);
                          } else {
                            context.read<KidTaskCreateCubit>().nextPage();
                          }
                        }
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
    );
  }

  TimeOfDay? getTimeFromDate(DateTime? date) {
    if (date == null) return null;
    if (date.hour == 0 && date.minute == 0) return null;
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }
}
