import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class CoinChangeSuccessScreen extends StatelessWidget {
  final String kidName;
  final int coinAmount;
  const CoinChangeSuccessScreen({super.key, required this.kidName, required this.coinAmount});

  @override
  Widget build(BuildContext context) {
    bool isIncrease = coinAmount > 0;
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SvgPicture.asset('assets/images/${isIncrease ? 'hearts_bg' : 'rain_bg'}.svg'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    isIncrease ? 'assets/images/2184-min.png' : 'assets/images/2191-min.png',
                    fit: BoxFit.contain,
                    width: 250,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: isIncrease ? 'pointsIncreased'.tr() : 'pointsDecreased'.tr(),
                    size: 32,
                    fw: FontWeight.w700,
                    color: primary900,
                    textAlign: TextAlign.center,
                    maxLine: 2,
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      text: 'balance'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: Involve,
                        fontWeight: FontWeight.w400,
                        color: greyscale800,
                        height: 1.6,
                      ),
                      children: [
                        TextSpan(
                          text: ' $kidName ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: Involve,
                            fontWeight: FontWeight.w700,
                            color: greyscale800,
                            height: 1.6,
                          ),
                        ),
                        TextSpan(
                          text: isIncrease ? 'increased'.tr() : 'decreased'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: Involve,
                            fontWeight: FontWeight.w400,
                            color: greyscale800,
                            height: 1.6,
                          ),
                        ),
                        TextSpan(
                          text: ' ${'pointsCount'.plural(coinAmount.abs())}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: Involve,
                            fontWeight: FontWeight.w700,
                            color: greyscale800,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  FilledAppButton(
                    text: 'ok'.tr(),
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
