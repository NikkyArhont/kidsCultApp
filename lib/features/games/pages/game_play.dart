import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GamePlayScreen extends StatefulWidget {
  final LevelModel level;
  final LevelModel? nextLevel;
  final DocumentReference gameRef;
  const GamePlayScreen({
    super.key,
    required this.level,
    required this.gameRef,
    this.nextLevel,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> with AutomaticKeepAliveClientMixin {
  late final SoundPlayerService _soundPlayer;
  PageController controller = PageController();
  List<QuizModel> quizzes = [];
  late GameModel game;
  bool initialized = true;
  int selectedIndex = 0;
  int correctAnswers = 0;

  void init() async {
    try {
      await _getGame();
    } catch (e) {
      print('Error initializing game: $e');
      SnackBarSerive.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          print('initialized: $initialized');
          initialized = false;
        });
      }
    }
  }

  void onExitGame() async {
    final confirm = await showExitgameConfirmModalBottomSheet(context);
    if (confirm == true && mounted) {
      context.pop();
    }
  }

  Future<void> _getGame() async {
    final doc = await widget.gameRef.get();
    game = GameModel.fromFirestore(doc);
    await _getQuizzes(game);
  }

  Future<void> _getQuizzes(GameModel game) async {
    final quizzesRef = game.quizzes;
    for (final ref in quizzesRef) {
      final quizData = await ref.get();
      final quiz = QuizModel.fromFirestore(quizData);
      quizzes.add(quiz);
    }
  }

  @override
  initState() {
    super.initState();
    _soundPlayer = sl<SoundPlayerService>();
    init();
  }

  void onTapAnswer(QuizModel quiz, AnswerModel answer) {
    setState(() {
      quiz.selectedAnswer = answer;
    });
  }

  void onTapConfirm() {
    final selectedQuiz = quizzes[selectedIndex];
    if (selectedQuiz.selectedAnswer == null) return;

    if (selectedQuiz.selectedAnswer!.isCorrect) {
      setState(() {
        correctAnswers++;
      });
      _soundPlayer.playCorrect();
      SnackBarSerive.showCorrectAnswerAlert(onDone);
    } else {
      final AnswerModel correctAnswer = selectedQuiz.answers.firstWhere((a) => a.isCorrect);

      final String correctAnswerText = getTextByLocale(
        context,
        correctAnswer.answer,
        correctAnswer.answerEng,
      );
      _soundPlayer.playWrong();
      SnackBarSerive.showWrongAnswerAlert(onDone, correctAnswerText);
    }
  }

  void onDone() {
    if (quizzes.length - 1 == selectedIndex) {
      print('Game completed!');
      context.replace(
        '/game_complete',
        extra: {
          'level': widget.level,
          'game': game,
          'correctAnswers': correctAnswers,
        },
      );
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (initialized) {
      return const GameLoadingWidget();
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onExitGame();
        }
      },
      child: Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          leadingWidth: 70,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.arrow_left),
            onPressed: onExitGame,
          ),
          title: Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: StepProgressWidget(
                  currentStep: selectedIndex,
                  plusStep: 0,
                  totalSteps: game.quizzes.length,
                  showStepCount: false,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ExitGamePopupMenuButton(onExit: onExitGame),
            ),
          
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.flip(
                    flipX: true,
                    child: Image.asset(
                      'assets/images/2177-min.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: LeftArrowBubleShape(
                      padding: const EdgeInsets.fromLTRB(40, 5, 10, 5),
                      child: AppText(
                        text: 'selectCorrectAnswer'.tr(),
                        size: 16,
                        fw: FontWeight.w500,
                        maxLine: 2,
                        color: greyscale800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: quizzes
                    .map((q) => GameScaffoldWidget(
                          quiz: q,
                          onAnswerSelected: (answer) => onTapAnswer(q, answer),
                          selectedAnswer: q.selectedAnswer,
                        ))
                    .toList(),
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Builder(builder: (context) {
                    bool isActive = quizzes.isEmpty ? false : quizzes[selectedIndex].selectedAnswer != null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FilledAppButton(
                        text: 'apply'.tr(),
                        isActive: isActive,
                        onTap: isActive ? onTapConfirm : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
