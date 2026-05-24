import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class CalendarTabScreen extends StatelessWidget {
  const CalendarTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        title: const AppText(text: 'Calendar'),
      ),
    );
  }
}