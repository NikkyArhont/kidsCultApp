import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LevelChevronWidget extends StatelessWidget {
  final String title;
  final double size;
  final bool isActive;
  const LevelChevronWidget({
    super.key,
    required this.title,
    required this.size,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = size * 0.1;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            color: isActive ? orange.withOpacity(0.2) : greyscale500.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isActive ? orange : greyscale400,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, left: 20),
                      child: Transform.rotate(
                        angle: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lens,
                              size: size * 0.04,
                              color: white.withOpacity(0.32),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.lens,
                              size: size * 0.08,
                              color: white.withOpacity(0.32),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/images/level_chevron.svg',
                      width: size * 0.25,
                      height: size * 0.25,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size * 0.7,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: primary900,
              borderRadius: BorderRadius.circular(size > 200
                  ? 20
                  : size == 140
                      ? 10
                      : 8),
            ),
            child: Center(
              child: AppText(
                text: title,
                size: size > 200
                    ? 33
                    : size == 140
                        ? 16
                        : 14,
                fw: FontWeight.w700,
                color: white,
                textAlign: TextAlign.center,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
