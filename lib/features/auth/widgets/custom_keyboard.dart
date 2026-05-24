// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class CustomKeyboard extends StatelessWidget {
  final Function(int i) onTap;
  final VoidCallback onRemove;
  const CustomKeyboard({super.key, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      fit: FlexFit.loose,
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          if (index == 9) return const SizedBox();
          return InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            splashFactory: InkRipple.splashFactory,
            splashColor: primary900.withOpacity(0.2),
            onTap: () {
              if (index == 11) {
                onRemove();
              } else {
                onTap(index == 10 ? 0 : (index + 1));
              }
            },
            child: Ink(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: secondary200,
              ),
              // color: secondary,
              child: Center(child: getContent(index, context)),
            ),
          );
        },
      ),
    );
  }

  Widget getContent(int i, BuildContext context) {
    if (i == 11) {
      return const Icon(CupertinoIcons.clear);
    }
    return AppText(
      text: i == 10 ? '0' : (i + 1).toString(),
      size: 24,
      fw: FontWeight.w500,
      height: 1,
    );
  }
}
