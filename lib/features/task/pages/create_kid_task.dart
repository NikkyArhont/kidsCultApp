import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateKidTaskScreen extends StatelessWidget {
  const CreateKidTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KidTaskCreateCubit(userCubit: sl()),
      child: Builder(builder: (context) {
        return BlocConsumer<KidTaskCreateCubit, KidTaskCreateState>(
          listener: (context, state) {
            if (state.status == KidTaskCreateStatus.error) {
              SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
            } else if (state.status == KidTaskCreateStatus.success) {
              context.replace('/kid_create_task/success');
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
                    if (state.isEditMode) {
                      //back to prewiew page
                      context.read<KidTaskCreateCubit>().onChangeMode(false);
                      context.read<KidTaskCreateCubit>().onJumpToPage(5);
                    } else {
                      if (state.step == 0) {
                        context.pop();
                      } else {
                        context.read<KidTaskCreateCubit>().prevPage();
                      }
                    }
                  },
                ),
                title: state.isEditMode
                    ? null
                    : Row(
                        children: [
                          const SizedBox(width: 20),
                          Expanded(child: StepProgressWidget(currentStep: state.step, totalSteps: 6)),
                        ],
                      ),
              ),
              body: Builder(
                builder: (context) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: PageView(
                      controller: context.read<KidTaskCreateCubit>().pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        KidCreateTaskSetPhoto(),
                        KidCreateTaskSetName(),
                        KidCreateTaskSetStartDate(),
                        KidCreateTaskSetEndDate(),
                        KidCreateTaskSetReminder(),
                        KidCreateTaskPreview(),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
