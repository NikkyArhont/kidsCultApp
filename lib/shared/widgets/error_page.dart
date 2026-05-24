import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    print(error);
    return Scaffold(
      appBar: AppBar(
        title:  Text('error'.tr()),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           AppText(
            text: "defaultErrorText".tr(),
            size: 17,
            fw: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppText(
            text: error,
            textAlign: TextAlign.center,
            color: secondary900,
          ),
        ],
      ),
    );
  }
}
