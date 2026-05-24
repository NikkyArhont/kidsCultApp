// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameScaffoldWidget extends StatelessWidget {
  final QuizModel quiz;
  final Function(AnswerModel answer) onAnswerSelected;
  final AnswerModel? selectedAnswer;
  const GameScaffoldWidget({super.key, required this.quiz, required this.onAnswerSelected, this.selectedAnswer});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          if (quiz.image != null)
            CachedClickableImage(
              imageUrl: quiz.image,
              width: double.infinity,
              height: 150,
              circularRadius: 6,
              fit: BoxFit.contain,
            ),
          AppText(
            text: getTextByLocale(context, quiz.question ?? '', quiz.questionEng ?? ''),
            size: 24,
            fw: FontWeight.w700,
            textAlign: TextAlign.center,
            maxLine: 10,
          ),
          ...quiz.answers.map(
            (answer) => GestureDetector(
              onTap: () => onAnswerSelected(answer),
              child: _AnswerCard(
                isSelected: selectedAnswer == answer,
                text: getTextByLocale(context, answer.answer, answer.answerEng),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final bool isSelected;
  final String text;
  const _AnswerCard({required this.isSelected, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? primary900 : greyscale200, width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              text: text,
              size: 24,
              fw: FontWeight.w700,
              maxLine: 3,
            ),
          ),
          if (isSelected)
            SvgPicture.asset(
              'assets/images/checkmark.svg',
              width: 24,
              height: 24,
              color: primary900,
            ),
        ],
      ),
    );
  }
}
