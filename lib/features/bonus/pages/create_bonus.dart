import 'package:child_tracker/features/bonus/widgets/create/select_kid_or_mentor.dart';
import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateBonusScreen extends StatelessWidget {
  const CreateBonusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateBonusCubit(userCubit: sl(), fcm: sl()),
      child: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          bool isKidBonus = me.isKid;
          return Builder(builder: (context) {
            return BlocConsumer<CreateBonusCubit, CreateBonusState>(
              listener: (context, state) {
                if (state.status == CreateBonusStatus.error) {
                  SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
                } else if (state.status == CreateBonusStatus.success) {
                  context.replace('/create_bonus/success');
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
                          context.read<CreateBonusCubit>().onChangeMode(false);
                          context.read<CreateBonusCubit>().onJumpToPage(5);
                        } else {
                          if (state.step == 0) {
                            context.pop();
                          } else {
                            context.read<CreateBonusCubit>().prevPage();
                          }
                        }
                      },
                    ),
                    title: state.isEditMode
                        ? null
                        : Row(
                            children: [
                              const SizedBox(width: 20),
                              Expanded(
                                  child: StepProgressWidget(currentStep: state.step, totalSteps: isKidBonus ? 5 : 6)),
                            ],
                          ),
                  ),
                  body: Builder(
                    builder: (context) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                        child: PageView(
                          controller: context.read<CreateBonusCubit>().pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            CreateBonusSelectKidOrMentor(me: me),
                            CreateBonusSetPhoto(isKidBonus: isKidBonus),
                             CreateBonusSetName(isKidBonus: isKidBonus),
                             CreateBonusSetLink(isKidBonus: isKidBonus),
                            if (!isKidBonus)  CreateBonusSetPoint(isKidBonus: isKidBonus),
                             CreateBonusPreview(me: me),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          });
        },
      ),
    );
  }
}
