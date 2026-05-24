import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? errorText;
  const CustomErrorWidget({super.key, required this.errorText});

  @override
  Widget build(BuildContext context) {
    if (errorText == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFFE3323).withOpacity(0.08),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: error, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: AppText(
              text: errorText!,
              color: error,
              size: 14,
              fw: FontWeight.normal,
              maxLine: 2,
            ),
          ),
        ],
      ),
    );
  }
}
