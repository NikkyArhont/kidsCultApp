import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final mentorPages = [
  const SetNameView(),
  const SetPhotoView(),
];

final kidPages = [
  const SetNameView(),
  const SetAgeView(),
  const SetCityView(),
  const SetPhotoView(),
  const SetQRView(),
];

class FillDataScreen extends StatelessWidget {
  const FillDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FillDataCubit, FillDataState>(
      listener: (context, state) {
        if (state.status == FillDataStatus.error) {
          SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
        } else if (state.status == FillDataStatus.success) {
          if (state.userType == UserType.kid) {
            context.go('/auth/kid_signup_success');
          } else if (state.userType == UserType.mentor) {
            context.read<FillDataCubit>().reset();
            context.go('/mentor_task');
            // context.go('/auth/take_subscription_plan');
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () {
                if (state.step == 0) {
                  context.pop();
                } else {
                  context.read<FillDataCubit>().prevPage();
                }
              },
            ),
            title: state.userType == UserType.mentor
                ? null
                : Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(child: StepProgressWidget(currentStep: state.step, totalSteps: 5)),
                    ],
                  ),
          ),
          body: Builder(
            builder: (context) {
              if (state.userType == null) return const SizedBox();
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: PageView(
                  controller: context.read<FillDataCubit>().pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: state.userType == UserType.kid ? kidPages : mentorPages,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
