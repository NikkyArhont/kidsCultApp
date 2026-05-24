import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DairySummaryWidget extends StatelessWidget {
  final List<DairyModel> dairy;
  const DairySummaryWidget({super.key, required this.dairy});

  @override
  Widget build(BuildContext context) {
    final count = dairy.length;
    final badEmotions = dairy.where((d) => d.emotion == DairyEmotion.bad).length;
    final sadEmotions = dairy.where((d) => d.emotion == DairyEmotion.sad).length;
    final normalEmotions = dairy.where((d) => d.emotion == DairyEmotion.normal).length;
    final goodEmotions = dairy.where((d) => d.emotion == DairyEmotion.good).length;
    final joyfulEmotions = dairy.where((d) => d.emotion == DairyEmotion.joyful).length;

    final Map<DairyEmotion, int> emotionCounts = {
      DairyEmotion.bad: badEmotions,
      DairyEmotion.sad: sadEmotions,
      DairyEmotion.normal: normalEmotions,
      DairyEmotion.joyful: joyfulEmotions,
      DairyEmotion.good: goodEmotions,
    };

    final maxEmotionEntry = emotionCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    final DairyEmotion mostFrequentEmotion = maxEmotionEntry.key;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 132,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/${dairyEmotionIcon(mostFrequentEmotion)}.svg',
                        width: 55,
                        height: 55,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppText(
                    text: '${'emotion'.plural(count)} - ${'reviews'.plural(count)}',
                    size: 12,
                    fw: FontWeight.normal,
                    color: greyscale700,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 132,
            color: greyscale200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/images/em_joyful_filled.svg'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: greyscale100,
                        color: primary900,
                        value: count == 0 ? 0 : (joyfulEmotions / count),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset('assets/images/em_good_filled.svg'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: greyscale100,
                        color: primary900,
                        value: count == 0 ? 0 : (goodEmotions / count),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset('assets/images/em_normal_filled.svg'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: greyscale100,
                        color: primary900,
                        value: count == 0 ? 0 : (normalEmotions / count),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset('assets/images/em_sad_filled.svg'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: greyscale100,
                        color: primary900,
                        value: count == 0 ? 0 : (sadEmotions / count),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset('assets/images/em_bad_filled.svg'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: greyscale100,
                        color: primary900,
                        value: count == 0 ? 0 : (badEmotions / count),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
