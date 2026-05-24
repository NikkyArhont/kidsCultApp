import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class KidTaskEditReminderScreen extends StatelessWidget {
  const KidTaskEditReminderScreen({super.key});

  void onDatePick(BuildContext context) async {
    final selectedDate = await showDatePickerModalBottomSheet(context);
    if (selectedDate != null && context.mounted) {
      context.read<KidTaskEditCubit>().onChangeReminderDate(selectedDate);
    }
  }

  void onTimePick(BuildContext context) async {
    final selectedTime = await showTimePickerModalBottomSheet(context);
    if (selectedTime != null && context.mounted) {
      context.read<KidTaskEditCubit>().onChangeReminderTime(selectedTime);
    }
  }

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
      body: BlocBuilder<KidTaskEditCubit, KidTaskEditState>(
        builder: (context, state) {
          final valid = state.reminderType == ReminderType.single &&
                  state.reminderDate != null &&
                  state.reminderDate!.hour != 0 ||
              state.reminderType == ReminderType.daily && state.reminderDays.isNotEmpty && state.reminderTime != null;
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 34, right: 24),
                  child: MaskotMessage(
                    message: 'add_reminder_prompt'.tr(),
                    maskot: '2182-min',
                    flip: true,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  height: 42,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: greyscale100),
                  child: TabBar(
                    onTap: (value) {
                      ReminderType type = value == 0 ? ReminderType.single : ReminderType.daily;
                      context.read<KidTaskEditCubit>().onChangeReminderType(type);
                    },
                    dividerHeight: 0,
                    dividerColor: greyscale100,
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: greyscale900,
                      fontFamily: Involve,
                      height: 1.6,
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: white,
                      fontFamily: Involve,
                      height: 1.6,
                    ),
                    unselectedLabelColor: greyscale900,
                    labelColor: white,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(borderRadius: BorderRadius.circular(6), color: primary900),
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    splashBorderRadius: BorderRadius.circular(6),
                    tabs: [
                      Text('one_time'.tr()),
                      Text('repeat'.tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            CustomDateInput(
                              date: state.reminderDate,
                              label: 'date'.tr(),
                              hint: 'selectDataHint'.tr(),
                              onTap: () => onDatePick(context),
                            ),
                            const SizedBox(height: 16),
                            CustomTimeInput(
                              onTap: () => onTimePick(context), hint: 'selectTime'.tr(),
                              label: 'reminder_time'.tr(),
                              enable: state.reminderDate != null,
                              time: getTimeFromDate(state.reminderDate),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(text: 'repeat_days'.tr()),
                            const SizedBox(height: 16),
                            LayoutBuilder(builder: (context, constraints) {
                              final double maxWidth = constraints.maxWidth;
                              final int numberOfCircles = russianWeekdaysNominative.length;
                              final double availableWidthForCircles = maxWidth - ((numberOfCircles - 1) * 7);
                              final double circleSize = availableWidthForCircles / numberOfCircles;

                              final double effectiveCircleSize =
                                  circleSize.isFinite && circleSize > 0 ? circleSize : 0.0;

                              return Row(
                                children: List.generate(numberOfCircles, (index) {
                                  final isSelected = state.reminderDays.contains(index);
                                  return GestureDetector(
                                    onTap: () {
                                      context.read<KidTaskEditCubit>().onChangeReminderDayTap(index);
                                    },
                                    child: Container(
                                      width: effectiveCircleSize,
                                      height: effectiveCircleSize,
                                      margin: EdgeInsets.only(right: index == numberOfCircles - 1 ? 0.0 : 7),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: dark5, width: 1.5),
                                        color: isSelected ? primary900 : null,
                                      ),
                                      child: Center(
                                        child: AppText(
                                          text: russianWeekdaysNominative[index],
                                          color: isSelected ? white : greyscale700,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                            const SizedBox(height: 32),
                            CustomTimeInput(
                              onTap: () => onTimePick(context), hint: 'selectTime'.tr(),
                              label: 'reminder_time'.tr(),
                              time: state.reminderTime,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            Expanded(
                              child: FilledAppButton(
                                text: 'apply'.tr(),
                                isActive: valid,
                                onTap: () {
                                  if (valid) {
                                    context.pop();
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
            ),
          );
        },
      ),
    );
  }

  TimeOfDay? getTimeFromDate(DateTime? date) {
    if (date == null) return null;
    if (date.hour == 0 && date.minute == 0) return null;
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }
}
