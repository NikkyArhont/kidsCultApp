import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginOtpScreen extends StatelessWidget {
  final String phone;
  const LoginOtpScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(CupertinoIcons.arrow_left, color: greyscale900),
        ),
      ),
      body: PhoneOtpInput(phone: phone),
    );
  }
}
