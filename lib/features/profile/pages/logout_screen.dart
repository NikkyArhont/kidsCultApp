import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LogoutResultScreen extends StatelessWidget {
  final String message;
  const LogoutResultScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: white,
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     BottomArrowBubleShape(
                      child: AppText(
                        text: 'oh'.tr(),
                        size: 24,
                        fw: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Image.asset(
                      'assets/images/2191-min.png',
                      fit: BoxFit.contain,
                      width: 270,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      text: message,
                      size: 30,
                      fw: FontWeight.w700,
                      color: primary900,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    FilledAppButton(
                      text: 'ok'.tr(),
                      onTap: () => context.go('/auth'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
