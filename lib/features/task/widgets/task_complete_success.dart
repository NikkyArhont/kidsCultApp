import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskCompleteSuccessScreen extends StatelessWidget {
  final String? userName;
  final int? coin;
  const TaskCompleteSuccessScreen({super.key, this.userName, this.coin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BottomArrowBubleShape(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppText(
                        text: 'hooray'.tr(),
                        size: 24,
                        maxLine: 2,
                        fw: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Image.asset(
                      'assets/images/2189-min.png',
                      fit: BoxFit.contain,
                      width: 240,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: 'task_completed_exclamation'.tr(),
                    size: 32,
                    fw: FontWeight.w700,
                    color: primary900,
                  ),
                  if (userName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          text: '$userName',
                          style: const TextStyle(
                            color: greyscale800,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: Involve,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(
                              text: "completed_the_task_suffix".tr(),
                              style: const TextStyle(
                                color: greyscale800,
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                                fontFamily: Involve,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (coin != null)
                    RichText(
                      text: TextSpan(
                        text: 'and_gets'.tr(),
                        style: const TextStyle(
                          color: greyscale800,
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          fontFamily: Involve,
                          height: 1.6,
                        ),
                        children: [
                          TextSpan(
                            text: ' +$coin ',
                            style: const TextStyle(
                              color: greyscale800,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              fontFamily: Involve,
                              height: 1.6,
                            ),
                          ),
                          TextSpan(
                            text: 'points_exclamation'.tr(),
                            style: const TextStyle(
                              color: greyscale800,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                              fontFamily: Involve,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FilledAppButton(
                    text: 'ok'.tr(),
                    onTap: () {
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
