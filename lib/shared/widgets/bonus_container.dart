import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class BonusContainer extends StatelessWidget {
  final String title;
  final Color color;
  final EdgeInsets padding;
  final Widget child;
  const BonusContainer({
    super.key,
    required this.title,
    this.color = orange,
    this.padding = const EdgeInsets.all(20),
    this.child = const Placeholder(),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              color: color,
            ),
            child: Center(child: AppText(text: title, color: white)),
          ),
          Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border.all(color: color, width: 3),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
