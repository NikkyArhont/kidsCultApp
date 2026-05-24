import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddDairySuccessScreen extends StatelessWidget {
  const AddDairySuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 BottomArrowBubleShape(
                  child: AppText(
                    text: 'accountReadyTitle'.tr(),
                    size: 24,
                    fw: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'assets/images/2184-min.png',
                  fit: BoxFit.contain,
                  width: 240,
                ),
                const SizedBox(height: 16),
                 AppText(
                  text: 'review_added'.tr(),
                  size: 32,
                  fw: FontWeight.w700,
                  color: primary900,
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FilledAppButton(
                    text: 'ok'.tr(),
                    onTap: () {
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
