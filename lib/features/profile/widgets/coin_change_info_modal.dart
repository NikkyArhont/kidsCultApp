import 'package:child_tracker/index.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void showCoinChangeInfoModalBottomSheet(BuildContext context, int amount) {
  showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (BuildContext context) {
      return _ShowCoinChangeInfoModalBottom(amount);
    },
  );
}

class _ShowCoinChangeInfoModalBottom extends StatelessWidget {
  final int amount;
  const _ShowCoinChangeInfoModalBottom(this.amount);

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
          AppText(
            text: 'information'.tr(),
            size: 24,
            fw: FontWeight.w700,
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          MaskotMessage(
            maskot: '2177-min',
            flip: true,
            message: 'decreaseMaxCouseText'.plural(amount),
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          FilledAppButton(
            text: 'ok'.tr(),
            onTap: () {
              context.pop();
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
