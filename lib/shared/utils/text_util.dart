

import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';



class AppText extends StatelessWidget {
  final String text;
  final double size;
  final double? height;
  final Color color;
  final FontWeight fw;
  final int maxLine;
  final TextAlign? textAlign;
  final TextDecoration? decoration;

  const AppText({
    super.key,
    required this.text,
    this.size = 18,
    this.color = greyscale900,
    this.fw = FontWeight.w600,
    this.maxLine = 1,
    this.height = 1.6,
    this.textAlign,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: fw,
        decoration: decoration,
        decorationColor: color,
        decorationThickness: 1,
        fontFamily: Involve,
        height: height,
        letterSpacing: 0.1,
      ),
      textAlign: textAlign,
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
    );
  }
}
