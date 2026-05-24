import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class CustomDateInput extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? date;
  final String? errorText;
  final VoidCallback onTap;
  const CustomDateInput({
    super.key,
    required this.label,
    required this.hint,
    this.date,
    this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = date != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) AppText(text: label),
        if (label.isNotEmpty) const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: greyscale50,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppText(
                  text: isActive ? dateToStringDDMMYYYY(date) : hint,
                  fw: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? greyscale900 : greyscale500,
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: AppText(
              text: errorText!,
              size: 14,
              color: error,
              fw: FontWeight.normal,
              maxLine: 2,
            ),
          ),
      ],
    );
  }
}
