import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class TabChips extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int index) onTap;
  const TabChips({
    super.key,
    required this.onTap,
    required this.tabs,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          children: tabs
              .map(
                (e) => GestureDetector(
                  onTap: () => onTap(tabs.indexOf(e)),
                  child: chip(e, e == tabs[selectedIndex]),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget chip(String text, bool selected) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: selected ? primary900 : null,
        borderRadius: BorderRadius.circular(100),
        border: selected ? null : Border.all(color: primary900, width: 1.5),
      ),
      child: Center(
        child: AppText(
          text: text,
          size: 16,
          color: selected ? white : primary900,
        ),
      ),
    );
  }
}
