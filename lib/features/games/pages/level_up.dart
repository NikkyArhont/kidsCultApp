import 'package:child_tracker/index.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LevelUpScreen extends StatefulWidget {
  final LevelModel level;
  const LevelUpScreen({super.key, required this.level});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> with AutomaticKeepAliveClientMixin {
  late final SoundPlayerService _soundPlayer;
  late ConfettiController _controllerTopCenter;
  bool canPlay = false;

  void _determineCanPlay() {
    final me = context.read<UserCubit>().state;

    if (me == null) return;

    if (widget.level.games.isEmpty) return;

    final myPoints = me.points;
    final levelMinPoints = widget.level.pointFrom ?? 0;

    canPlay = myPoints >= levelMinPoints;
  }

  @override
  void initState() {
    _determineCanPlay();
    super.initState();
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 5));
    _controllerTopCenter.play();
    _soundPlayer = sl<SoundPlayerService>();
    _soundPlayer.playWinLevel();
  }

  void onExit() => context.pop();

  void onNextGame() {
    final extra = {
      'gameRef': widget.level.games.first,
      'level': widget.level,
    };
    context.replace('/game_play', extra: extra);
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
    final size = MediaQuery.of(context).size;
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LevelChevronWidget(
                      size: size.width * 0.7,
                      title: levelName,
                      isActive: true,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      text: '${"hoorayYouLelelUp".tr()} $levelName!',
                      size: 24,
                      fw: FontWeight.w600,
                      maxLine: 3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      text: "hoorayYouLelelUpDesc".tr(),
                      fw: FontWeight.w400,
                      color: greyscale700,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/images/coin.svg'),
                        const SizedBox(width: 6),
                        AppText(
                          text: (widget.level.pointFrom ?? 0).toString(),
                          size: 20,
                          fw: FontWeight.w700,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
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
                            text: 'exitGame'.tr(),
                            onTap: onExit,
                          ),
                        ),
                        if (canPlay) const SizedBox(width: 16),
                        if (canPlay)
                          Expanded(
                            child: FilledAppButton(
                              text: 'continue'.tr(),
                              onTap: onNextGame,
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
