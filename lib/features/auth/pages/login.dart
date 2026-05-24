import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        centerTitle: true,
      ),
      body: const PhoneInputWidget(),
    );
  }
}
