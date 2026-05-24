import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EmptyLevelsWidget extends StatelessWidget {
  const EmptyLevelsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF04060F).withOpacity(0.08),
                blurRadius: 60,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              Transform.flip(
                flipX: true,
                child: Image.asset(
                  'assets/images/2177-min.png',
                  fit: BoxFit.contain,
                  width: 140,
                  height: 140,
                ),
              ),
              const SizedBox(height: 28),
              AppText(
                text: 'hiExplorer'.tr(),
                size: 24,
                textAlign: TextAlign.center,
                maxLine: 2,
              ),
              const SizedBox(height: 16),
              AppText(
                text: 'noLevels'.tr(),
                fw: FontWeight.w400,
                color: greyscale700,
                textAlign: TextAlign.center,
                maxLine: 4,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}
