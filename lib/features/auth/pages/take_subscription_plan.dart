// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TakeSubscriptionPlanScreen extends StatefulWidget {
  const TakeSubscriptionPlanScreen({super.key});

  @override
  State<TakeSubscriptionPlanScreen> createState() => _TakeSubscriptionPlanScreenState();
}

class _TakeSubscriptionPlanScreenState extends State<TakeSubscriptionPlanScreen> {
  late ConfettiController _controllerTopCenter;

  @override
  void initState() {
    super.initState();
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 5));
    _controllerTopCenter.play();
  }

  @override
  void dispose() {
    _controllerTopCenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final date = DateFormat('dd MMMM yyyy', currentLocale).format(DateTime.now().add(const Duration(days: 30)));

    return Scaffold(
      backgroundColor: white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controllerTopCenter,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              shouldLoop: true,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 120),
                      CircleAvatar(
                        radius: 47,
                        backgroundColor: orange,
                        child: SvgPicture.asset('assets/images/crown.svg'),
                      ),
                      const SizedBox(height: 24),
                      AppText(
                        text: 'freePeriodTitle'.tr(),
                        size: 32,
                        fw: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AppText(
                          text: 'free_access_info'.tr(),
                          size: 16,
                          fw: FontWeight.normal,
                          textAlign: TextAlign.center,
                          maxLine: 5,
                        ),
                      ),
                      Container(
                        color: white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Divider(height: 48, thickness: 1, color: greyscale200),
                            AppText(
                              text: 'full_features_title'.tr(),
                              size: 24,
                              fw: FontWeight.w700,
                              textAlign: TextAlign.center,
                              maxLine: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/checkmark.svg',
                                  width: 24,
                                  color: greyscale900,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppText(
                                    text: 'track_progress'.tr(),
                                    size: 16,
                                    fw: FontWeight.w500,
                                    maxLine: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/checkmark.svg',
                                  width: 24,
                                  color: greyscale900,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppText(
                                    text: 'setup_goals_rewards'.tr(),
                                    size: 16,
                                    fw: FontWeight.w500,
                                    maxLine: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/checkmark.svg',
                                  width: 24,
                                  color: greyscale900,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppText(
                                    text: 'educational_games_activities'.tr(),
                                    size: 16,
                                    fw: FontWeight.w500,
                                    maxLine: 2,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 48, thickness: 1, color: greyscale200),
                            AppText(
                              text: '${'expires_on'.tr()}\n$date.',
                              size: 18,
                              fw: FontWeight.w500,
                              maxLine: 2,
                              color: greyscale800,
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  text: 'renewSubscription'.tr(),
                                  size: 16,
                                  fw: FontWeight.w500,
                                  maxLine: 1,
                                  color: greyscale800,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context.go('/mentor_profile');
                                  },
                                  child: AppText(
                                    text: ' ${'hereText'.tr()}',
                                    size: 18,
                                    fw: FontWeight.w700,
                                    color: primary900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: white,
                  border: Border(top: BorderSide(color: greyscale100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FilledAppButton(
                        text: 'startUsingButton'.tr(),
                        onTap: () {
                          context.read<FillDataCubit>().reset();
                          context.go('/mentor_task');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
