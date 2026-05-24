import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MentorCreateTaskSelectKid extends StatelessWidget {
  const MentorCreateTaskSelectKid({super.key});

  void onInfoTap(BuildContext context){
    showTaskTypesInfoModalBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MentorTaskCreateCubit, MentorTaskCreateState>(
      builder: (context, state) {
        final valid = state.selectedKid != null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'who_assign_task'.tr(),
                maskot: '2186-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: BlocBuilder<UserCubit, UserModel?>(
                builder: (context, me) {
                  if (me == null) return const SizedBox();
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        ...me.connections.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: FutureBuilder<UserModel>(
                                future: context.read<UserCubit>().getUserByRef(e),
                                builder: (context, snapshot) {
                                  final user = snapshot.data;
                                  if (user == null) {
                                    return const SizedBox(
                                      width: double.infinity,
                                      height: 90,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  return UserSelector(
                                    onTap: () {
                                      context.read<MentorTaskCreateCubit>().onChangeKid(user);
                                    },
                                    image: user.photo,
                                    isSelected: state.selectedKid?.id == e.id,
                                    name: user.name,
                                  );
                                }),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => onInfoTap(context),
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE4E7FF),
                    ),
                    child: Center(child: SvgPicture.asset('assets/images/info_square_filled.svg'),),
                  ),
                ),
              ],
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
                      text: state.isEditMode ? 'apply'.tr() : 'next'.tr(),
                      isActive: valid,
                      onTap: () {
                        if (valid) {
                          if (state.isEditMode) {
                            context.read<MentorTaskCreateCubit>().onChangeMode(false);
                            context.read<MentorTaskCreateCubit>().onJumpToPage(7);
                          } else {
                            context.read<MentorTaskCreateCubit>().nextPage();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
