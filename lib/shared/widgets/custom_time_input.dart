import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class CustomTimeInput extends StatelessWidget {
  final String label;
  final String hint;
  final TimeOfDay? time;
  final String? errorText;
  final VoidCallback onTap;
  final bool enable;
  const CustomTimeInput({
    super.key,
    required this.label,
    required this.hint,
    this.time,
    this.errorText,
    required this.onTap,
    this.enable = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = time != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) AppText(text: label),
        if (label.isNotEmpty) const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enable ? () => onTap() : null,
          child: Container(
            width: double.infinity,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: enable ? greyscale50 : greyscale100,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppText(
                  text: isActive ? formatTimeOfDay(context, time) : hint,
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
              size: 16,
              color: error,
              fw: FontWeight.normal,
            ),
          ),
      ],
    );
  }
}
