import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';

Future<DateTime?> showWheelDatePickerModalBottomSheet(
  BuildContext context, {
  DateTime? firstDay,
  DateTime? lastDay,
  DateTime? selectedDate,
}) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return _WheelDateTimeContent(
        firstDay: firstDay ?? DateTime.utc(1900),
        lastDay: lastDay ?? DateTime.now().subtract(const Duration(days: 5 * 365)),
        selectedDate: selectedDate,
      );
    },
  );
}

class _WheelDateTimeContent extends StatefulWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime? selectedDate;
  const _WheelDateTimeContent({
    required this.firstDay,
    required this.lastDay,
    this.selectedDate,
  });

  @override
  State<_WheelDateTimeContent> createState() => _WheelDateTimeContentState();
}

class _WheelDateTimeContentState extends State<_WheelDateTimeContent> {
  late DateTime _selectedDate;

  @override
  void initState() {
    _selectedDate = widget.selectedDate ?? widget.lastDay;
    super.initState();
  }

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
          AppText(text: 'selectDataHint'.tr(), size: 24, fw: FontWeight.w700),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          SizedBox(
            height: 250,
            child: ScrollDatePicker(
              selectedDate: _selectedDate,
              locale: EasyLocalization.of(context)?.locale,
              indicator: Container(
                height: 60,
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border.symmetric(vertical: BorderSide(color: greyscale200, width: 1)),
                ),
              ),
              minimumDate: widget.firstDay,
              maximumDate: widget.lastDay,
              options: const DatePickerOptions(
                backgroundColor: white,
                itemExtent: 60,
                diameterRatio: 5,
                isLoop: true,
              ),
              scrollViewOptions: const DatePickerScrollViewOptions(
                day: ScrollViewDetailOptions(
                  textStyle: TextStyle(
                    fontFamily: Involve,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: greyscale900,
                  ),
                  selectedTextStyle: TextStyle(
                    fontFamily: Involve,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: greyscale900,
                  ),
                  alignment: Alignment.center,
                ),
                month: ScrollViewDetailOptions(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  label: '',
                  textStyle: TextStyle(
                    fontFamily: Involve,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: greyscale900,
                  ),
                  selectedTextStyle: TextStyle(
                    fontFamily: Involve,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: greyscale900,
                  ),
                  alignment: Alignment.center,
                ),
                year: ScrollViewDetailOptions(
                  isLoop: false,
                  textStyle: TextStyle(
                    fontFamily: Involve,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: greyscale900,
                  ),
                  selectedTextStyle: TextStyle(
                    fontFamily: Involve,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: greyscale900,
                  ),
                  alignment: Alignment.center,
                ),
              ),
              viewType: const [
                DatePickerViewType.day,
                DatePickerViewType.month,
                DatePickerViewType.year,
              ],
              onDateTimeChanged: (DateTime value) {
                setState(() {
                  _selectedDate = value;
                });
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          const SizedBox(height: 20),
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
                  isActive: true,
                  onTap: () {
                    Navigator.of(context).pop(_selectedDate);
                  },
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
