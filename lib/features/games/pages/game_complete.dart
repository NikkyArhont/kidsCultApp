import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class GameCompleteScreen extends StatefulWidget {
  final LevelModel level;
  final GameModel game;
  final int correctAnswers;

  const GameCompleteScreen({
    super.key,
    required this.level,
    required this.game,
    required this.correctAnswers,
  });

  @override
  State<GameCompleteScreen> createState() => _GameCompleteScreenState();
}

class _GameCompleteScreenState extends State<GameCompleteScreen> {
  int winPoints = 0;
  bool hasNextGame = false;
  DocumentReference? nextGameRef;
  LevelModel? nextLevel;

  void _determineNextGameExist() {
    final List<DocumentReference> allGameRefs = widget.level.games;
    final currentGameRef = widget.game.ref;
    final int currentIndex = allGameRefs.indexOf(currentGameRef);

    if (currentIndex != -1 && currentIndex < allGameRefs.length - 1) {
      // Текущая игра найдена, и это не последний элемент в списке
      hasNextGame = true;
      nextGameRef = allGameRefs[currentIndex + 1];
    } else {
      // Текущая игра либо не найдена, либо является последним элементом
      hasNextGame = false;
      nextGameRef = null;
    }

    // Теперь вы можете использовать переменные hasNextGame и nextGameRef
    print('Текущая игра является последней: ${!hasNextGame}');
    if (hasNextGame) {
      print('Ссылка на следующую игру: ${nextGameRef!.path}');
    } else {
      print('Следующей игры нет.');
    }
  }

  void _determineWinPoints() {
    int gamePoints = widget.game.points;
    int gameQuizs = widget.game.quizzes.length;
    int correctAnswers = widget.correctAnswers;

    double pointsPerQuestion = gamePoints / gameQuizs;
    int roundedPointsPerQuestion = pointsPerQuestion.round();

    winPoints = roundedPointsPerQuestion * correctAnswers;

    print('Баллов за каждый вопрос: $roundedPointsPerQuestion');
    print('Набрано баллов: $winPoints');
  }

  void _determineNextLevel() async {
    await Future.delayed(const Duration(milliseconds: 300));

    _addScoreToUser();

    if (!mounted) return;

    if (winPoints == 0) return;

    final me = context.read<UserCubit>().state;
    final List<LevelModel> allLevelsList = await _getLevels(me);
    final LevelModel currentLevel = widget.level;

    // 1. Находим индекс текущего уровня в списке всех уровней
    final int currentIndex = allLevelsList.indexWhere((level) => level.ref == currentLevel.ref);

    if (!hasNextGame) {
      nextLevel = allLevelsList[currentIndex + 1];
    } else {
      nextLevel = null;
    }

    if (nextLevel != null) {
      print('Ссылка на следующий уровень: ${nextLevel!.id}');
    } else {
      print('Нет следующего уровня.');
    }
  }

  void _addScoreToUser() async {
    if (winPoints == 0) return;
    final gameModel = UserGameModel(
      id: '',
      points: winPoints,
      gameRef: widget.game.ref,
      isCompleted: true,
      levelRef: hasNextGame ? null : widget.level.ref,
    );
    final newGameDoc = gameModel.toFirestore();

    await context.read<UserCubit>().onGameComplete(
          newGameDoc,
          winPoints,
          hasNextGame ? null : widget.level.ref,
        );
  }

  @override
  void initState() {
    _determineWinPoints();
    _determineNextGameExist();
    super.initState();

    _determineNextLevel();
  }

  void onExit() {
    if (nextLevel != null) {
      context.replace('/level_up', extra: nextLevel);
    } else {
      context.pop();
    }
  }

  void onNextGame() {
    if (hasNextGame && nextGameRef != null) {
      final data = {'gameRef': nextGameRef, 'level': widget.level};
      context.replace('/game_play', extra: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: winPoints == 0
                ? const _LoseGameWidget()
                : _WinGameWidget(
                    winCoins: winPoints,
                    hasNextGame: hasNextGame,
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
                    if (hasNextGame && winPoints != 0) const SizedBox(width: 16),
                    if (hasNextGame && winPoints != 0)
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
    );
  }

  Future<List<LevelModel>> _getLevels(UserModel? me) async {
    final myAge = me?.getAge ?? 0;
    final query = LevelModel.collection
        .where('status', isEqualTo: LevelStatus.active.name)
        .where('age_from', isLessThanOrEqualTo: myAge)
        .where('age_to', isGreaterThanOrEqualTo: myAge)
        .orderBy('index', descending: false);

    final levels = await query.get().then((event) => event.docs.map((e) => LevelModel.fromFirestore(e)).toList());
    // return levels.reversed.toList();
    return levels;
  }
}

class _WinGameWidget extends StatefulWidget {
  final int winCoins;
  final bool hasNextGame;
  const _WinGameWidget({required this.winCoins, required this.hasNextGame});

  @override
  State<_WinGameWidget> createState() => _WinGameWidgetState();
}

class _WinGameWidgetState extends State<_WinGameWidget> with AutomaticKeepAliveClientMixin {
  late ConfettiController _controllerTopCenter;
  late final SoundPlayerService _soundPlayer;

  @override
  void initState() {
    super.initState();
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 5));
    _controllerTopCenter.play();
    _soundPlayer = sl<SoundPlayerService>();
    _soundPlayer.playWinGame();
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
    _controllerTopCenter.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/2189-min.png',
                width: 250,
                height: 300,
                fit: BoxFit.contain,
              ),
              AppText(
                text: 'hoorayYouWin'.tr(),
                size: 24,
                fw: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppText(
                text: widget.hasNextGame ? 'youHaveWon'.tr() : 'youHaveWon2'.tr(),
                fw: FontWeight.w400,
                color: greyscale700,
                textAlign: TextAlign.center,
                maxLine: 5,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/images/points.svg'),
                  const SizedBox(width: 6),
                  AppText(
                    // text: widget.winCoins.toString(),
                    text: 'gamePointsCount'.plural(widget.winCoins),
                    size: 20,
                    fw: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoseGameWidget extends StatelessWidget {
  const _LoseGameWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/2191-min.png',
            width: 250,
            height: 300,
            fit: BoxFit.contain,
          ),
          AppText(
            text: 'ohYouLose'.tr(),
            size: 24,
            fw: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppText(
            text: 'ohYouLoseText'.tr(),
            fw: FontWeight.w400,
            color: greyscale700,
            textAlign: TextAlign.center,
            maxLine: 5,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/images/coin.svg'),
              const SizedBox(width: 6),
              const AppText(
                text: '0',
                size: 20,
                fw: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
