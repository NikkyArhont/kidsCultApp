import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class FilledAppButton extends StatelessWidget {
  final double height;
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isActive;
  final double fontSize;
  final FontWeight fw;
  final Color fontColor;
  final Color activeColor;
  const FilledAppButton({
    super.key,
    this.height = 58,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isActive = true,
    this.fontSize = 16,
    this.fw = FontWeight.w700,
    this.fontColor = white,
    this.activeColor = primary900,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? activeColor : disabledColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : AppText(
                  text: text,
                  size: fontSize,
                  fw: fw,
                  color: fontColor,
                  maxLine: 2,
                  textAlign: height > 58 ? TextAlign.center : TextAlign.start,
                ),
        ),
      ),
    );
  }
}

class FilledSecondaryAppButton extends StatelessWidget {
  final double height;
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isActive;
  final double fontSize;
  final FontWeight fw;
  final Widget? icon;
  const FilledSecondaryAppButton({
    super.key,
    this.height = 58,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isActive = true,
    this.fontSize = 16,
    this.fw = FontWeight.w700,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE4E7FF) : disabledColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) icon!,
                    Flexible(
                      child: AppText(
                        text: text,
                        size: fontSize,
                        fw: fw,
                        color: primary900,
                        textAlign: TextAlign.center,
                        maxLine: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class FilledDestructiveAppButton extends StatelessWidget {
  final double height;
  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isActive;
  final double fontSize;
  final FontWeight fw;
  const FilledDestructiveAppButton({
    super.key,
    this.height = 58,
    required this.child,
    this.onTap,
    this.isLoading = false,
    this.isActive = true,
    this.fontSize = 16,
    this.fw = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFEFED) : disabledColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading ? const CircularProgressIndicator(color: Colors.white) : child,
        ),
      ),
    );
  }
}

class OutlinedAppButton extends StatelessWidget {
  final double height;
  final String text;
  final VoidCallback? onPress;
  final bool isLoading;
  final double fontSize;
  final FontWeight fw;
  final bool isActive;
  final Widget? icon;

  const OutlinedAppButton({
    super.key,
    this.height = 58,
    required this.text,
    this.onPress,
    this.isLoading = false,
    this.fontSize = 16,
    this.fw = FontWeight.w700,
    this.isActive = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: null,
          border: Border.all(color: isActive ? primary900 : primary900.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: primary900)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) icon!,
                    Flexible(
                      child: AppText(
                        text: text,
                        size: fontSize,
                        fw: fw,
                        color: isActive ? primary900 : primary900.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
