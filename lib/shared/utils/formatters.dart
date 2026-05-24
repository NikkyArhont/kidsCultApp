import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String dateToStringDDMMYYYY(DateTime? date) =>
    date == null ? 'undefined'.tr() : DateFormat('dd.MM.yyyy', 'ru').format(date);

String dateToHHmm(DateTime? date) => date == null ? 'undefined'.tr() : DateFormat('HH:mm', 'ru').format(date);

Map<int, String> _russianMonthsNominative = {
  1: 'january'.tr(),
  2: 'february'.tr(),
  3: 'march'.tr(),
  4: 'april'.tr(),
  5: 'may'.tr(),
  6: 'june'.tr(),
  7: 'july'.tr(),
  8: 'august'.tr(),
  9: 'september'.tr(),
  10: 'october'.tr(),
  11: 'november'.tr(),
  12: 'december'.tr(),
};

List<String> russianWeekdaysNominative = [
  'mon'.tr(),
  'tue'.tr(),
  'wed'.tr(),
  'thu'.tr(),
  'fri'.tr(),
  'sat'.tr(),
  'sun'.tr(),
];

String getMonthYearInNominative(DateTime date) {
  final String month = _russianMonthsNominative[date.month]!;
  final String year = DateFormat('yyyy').format(date);
  return '$month $year';
}

String dateToChatDivider(DateTime date) {
  DateTime now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'today'.tr();
  } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
    return 'yesterday'.tr();
  } else {
    return DateFormat('d MMMM', 'ru').format(date);
  }
}

String taskDate(DateTime? date) {
  if (date == null) return '-';
  if (date.hour == 0 && date.minute == 0) return DateFormat('dd.MM.yyyy', 'ru').format(date);
  return DateFormat('dd.MM.yyyy,HH:mm', 'ru').format(date);
}

String formatTimeOfDay(BuildContext context, TimeOfDay? time) {
  if (time == null) return '-';
  return time.format(context);
}

String dateFormatDDMMYYYYHHMM(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd.MM.yyyy, HH:mm', 'ru').format(date);
}

final currencyFormatter = NumberFormat.simpleCurrency(locale: 'ru_RU', decimalDigits: 0);

String roubleFormat(int val) {
  return currencyFormatter.format(val);
}

extension DateOnly on DateTime {
  DateTime get dateOnly {
    return DateTime(year, month, day);
  }
}
