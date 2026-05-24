import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class StepProgressWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool showStepCount;
  final int plusStep;
  const StepProgressWidget({
    super.key,
    this.currentStep = 0,
    this.totalSteps = 1,
    this.plusStep = 1,
    this.showStepCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: (currentStep + plusStep) / totalSteps,
            backgroundColor: greyscale200,
            color: primary900,
            minHeight: 12,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(width: 30),
        if (showStepCount)
          AppText(
            text: '0${currentStep + 1}/0$totalSteps',
            size: 20,
          ),
      ],
    );
  }
}
