

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.clear_circled, size: 70, color: red),
            const SizedBox(height: 8),
            AppText(text: 'youAreBanned'.tr(), size: 17, fw: FontWeight.w500),
          ],
        ),
      ),
    );
  }
}