import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateBonusSelectKidOrMentor extends StatelessWidget {
  final UserModel me;
  const CreateBonusSelectKidOrMentor({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    bool isKidBonus = me.isKid;
    return BlocBuilder<CreateBonusCubit, CreateBonusState>(
      builder: (context, state) {
        final valid = (isKidBonus ? state.mentor != null : state.kid != null);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: isKidBonus ? 'who_will_get_bonus2'.tr() : 'who_will_get_bonus'.tr(),
                maskot: '2186-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Builder(
                builder: (context) {
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
                                      if (isKidBonus) {
                                        context.read<CreateBonusCubit>().onChangeMentor(user);
                                      } else {
                                        context.read<CreateBonusCubit>().onChangeKid(user);
                                      }
                                    },
                                    image: user.photo,
                                    isSelected: (isKidBonus ? state.mentor?.id : state.kid?.id) == e.id,
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
                            context.read<CreateBonusCubit>().onChangeMode(false);
                            context.read<CreateBonusCubit>().onJumpToPage(7);
                          } else {
                            context.read<CreateBonusCubit>().nextPage();
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
