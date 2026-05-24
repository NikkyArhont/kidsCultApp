import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    redirectFunc(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary900,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/android12splash.png',
            width: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                text: APPNAME,
                size: 30,
                fw: FontWeight.w700,
                color: white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
