import 'package:child_tracker/index.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LevelTokenUpScreen extends StatefulWidget {
  final LevelModel level;
  const LevelTokenUpScreen({super.key, required this.level});

  @override
  State<LevelTokenUpScreen> createState() => _LevelTokenUpScreenState();
}

class _LevelTokenUpScreenState extends State<LevelTokenUpScreen> with AutomaticKeepAliveClientMixin {
  late ConfettiController _controllerTopCenter;
  late final SoundPlayerService _soundPlayer;

  @override
  void initState() {
    super.initState();
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 5));
    _controllerTopCenter.play();
    _soundPlayer = sl<SoundPlayerService>();
    _soundPlayer.playWinLevel();
  }

  void onExit() => context.pop();

  void onRequestTrophey() {
    context.pop();
    SnackBarSerive.showSuccessSnackBar('trophey_requested'.tr());
  }

  @override
  void dispose() {
    _controllerTopCenter.dispose();
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final levelName = getTextByLocale(context, widget.level.name, widget.level.nameEng);
    return Scaffold(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BottomArrowBubleShape(
                        child: AppText(
                          text: 'accountReadyTitle'.tr(),
                          size: 24,
                          fw: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/images/2184-min.png',
                        height: 250,
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      AppText(
                        text: "congratulations".tr(),
                        size: 32,
                        fw: FontWeight.w700,
                        color: primary900,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppText(
                        text: '${"congratulationsText".tr()} "$levelName"',
                        fw: FontWeight.w400,
                        color: greyscale800,
                        textAlign: TextAlign.center,
                        maxLine: 5,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledSecondaryAppButton(
                            height: 84,
                            text: 'cancel'.tr(),
                            onTap: onExit,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledAppButton(
                            height: 84,
                            text: 'requestGift'.tr(),
                            onTap: onRequestTrophey,
                          ),
                        ),
                      ],
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
