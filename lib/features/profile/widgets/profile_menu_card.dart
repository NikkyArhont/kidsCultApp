// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileMenuCard extends StatelessWidget {
  final String title;
  final String? description;
  final String icon;
  final VoidCallback onTap;
  final Color color;
  final Color? iconColor;
  const ProfileMenuCard({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.color = const Color.fromRGBO(36, 107, 253, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/$icon.svg',
                width: 24,
                height: 24,
                color: iconColor,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(text: title, size: 20, fw: FontWeight.w700),
                if (description != null)
                  AppText(
                    text: description!,
                    size: 12,
                    fw: FontWeight.w500,
                    color: greyscale700,
                    maxLine: 2,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(CupertinoIcons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
