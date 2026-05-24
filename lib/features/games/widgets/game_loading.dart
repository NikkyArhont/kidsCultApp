import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameLoadingWidget extends StatefulWidget {
  const GameLoadingWidget({super.key});

  @override
  State<GameLoadingWidget> createState() => _GameLoadingWidgetState();
}

class _GameLoadingWidgetState extends State<GameLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        constraints: const BoxConstraints.expand(),
        color: white,
        child: Column(
          children: [
            const SizedBox(height: 24),
            SvgPicture.asset('assets/images/hearts_bg.svg'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/2184-min.png',
                      height: 300,
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      text: 'startGame'.tr(),
                      maxLine: 2,
                      size: 32,
                      color: primary900,
                      fw: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    LinearProgressIndicator(
                      value: _animation.value,
                      backgroundColor: greyscale200,
                      color: primary900,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
