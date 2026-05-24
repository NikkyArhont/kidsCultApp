import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:table_calendar/table_calendar.dart';

Future<DateTime?> showDatePickerModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return const _CalendarContent();
    },
  );
}

class _CalendarContent extends StatefulWidget {
  const _CalendarContent();

  @override
  State<_CalendarContent> createState() => __CalendarContentState();
}

class __CalendarContentState extends State<_CalendarContent> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: greyscale200,
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          AppText(text: 'date'.tr(), size: 24, fw: FontWeight.w700),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: greyscale100,
                  width: 3.0,
                ),
              ),
              child: TableCalendar(
                locale: 'ru',
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  headerMargin: EdgeInsets.symmetric(horizontal: 16),
                  headerPadding: EdgeInsets.symmetric(vertical: 12),
                  leftChevronPadding: EdgeInsets.zero,
                  leftChevronMargin: EdgeInsets.only(left: 8),
                  leftChevronIcon: Icon(CupertinoIcons.chevron_left, size: 20),
                  rightChevronIcon: Icon(CupertinoIcons.chevron_right, size: 20),
                  rightChevronPadding: EdgeInsets.zero,
                  rightChevronMargin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: greyscale200)),
                  ),
                ),
                daysOfWeekHeight: 50,
                rowHeight: 50,
                daysOfWeekStyle: DaysOfWeekStyle(
                  dowTextFormatter: (date, locale) {
                    final String weekdayName = DateFormat.E(locale).format(date);
                    return weekdayName.substring(0, 1).toUpperCase() + weekdayName.substring(1);
                  },
                  weekdayStyle: const TextStyle(
                    color: greyscale900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: Involve,
                  ),
                  weekendStyle: const TextStyle(
                    color: greyscale900,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: Involve,
                  ),
                ),
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                    cellMargin: EdgeInsets.zero,
                    defaultTextStyle: TextStyle(
                      color: greyscale800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: Involve,
                    ),
                    selectedTextStyle: TextStyle(
                      color: white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: Involve,
                    ),
                    outsideTextStyle: TextStyle(
                      color: greyscale400,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: Involve,
                    ),
                    holidayTextStyle: TextStyle(
                      color: greyscale800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: Involve,
                    ),
                    weekendTextStyle: TextStyle(
                      color: greyscale800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: Involve,
                    ),
                    todayTextStyle: TextStyle(
                      color: greyscale800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: Involve,
                    ),
                    todayDecoration: BoxDecoration(shape: BoxShape.circle)),
                calendarBuilders: CalendarBuilders(
                  headerTitleBuilder: (context, day) {
                    return AppText(
                      text: getMonthYearInNominative(day),
                      fw: FontWeight.w700,
                      size: 20,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                firstDay: DateTime.now(),
                lastDay: DateTime.utc(2100, 3, 14),
                focusedDay: _focusedDay,
              ),
            ),
          ),
          const Divider(height: 40, thickness: 1, color: greyscale200),
          Row(
            children: [
              Expanded(
                child: FilledSecondaryAppButton(
                  text: 'cancel'.tr(),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledAppButton(
                  text: 'ok'.tr(),
                  isActive: _selectedDay != null,
                  onTap: _selectedDay == null ? null : () => Navigator.of(context).pop(_selectedDay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
