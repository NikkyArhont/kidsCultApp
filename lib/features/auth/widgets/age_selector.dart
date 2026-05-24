import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AgeSelector extends StatefulWidget {
  final Function(int age) onSelect;
  final int? selectedAge;
  const AgeSelector({super.key, required this.onSelect, this.selectedAge});

  @override
  State<AgeSelector> createState() => _AgeSelectorState();
}

class _AgeSelectorState extends State<AgeSelector> {
  final List<int> ages = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  int? selectedAge;

  void onTap(int age) {
    setState(() => selectedAge = age);
    widget.onSelect(age);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          for (var age in ages)
            GestureDetector(
              onTap: () => onTap(age),
              child: Container(
                width: double.infinity,
                height: 72,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: age == (widget.selectedAge ?? selectedAge) ? primary900 : greyscale200,
                    width: 3,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: AppText(text: '$age ${'ageInputYearsOld'.tr()}', size: 20, fw: FontWeight.w700)),
                    const SizedBox(width: 10),
                    if ( age == (widget.selectedAge ?? selectedAge)) SvgPicture.asset('assets/images/checkmark.svg', width: 24, height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
