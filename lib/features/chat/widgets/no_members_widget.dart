import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

class NoMembersWidget extends StatelessWidget {
  final bool isKid;
  const NoMembersWidget({super.key, required this.isKid});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/2187-min.png',
                fit: BoxFit.contain,
                width: 180,
              ),
            ],
          ),
          const SizedBox(height: 32),
          AppText(
            text: isKid ? 'no_mentors'.tr() : 'no_kids'.tr(),
            size: 24,
            fw: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
