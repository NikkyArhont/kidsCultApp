import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BonusEditKidOrMentorScreen extends StatefulWidget {
  const BonusEditKidOrMentorScreen({super.key});

  @override
  State<BonusEditKidOrMentorScreen> createState() => _BonusEditKidOrMentorScreenState();
}

class _BonusEditKidOrMentorScreenState extends State<BonusEditKidOrMentorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: BlocBuilder<EditBonusCubit, EditBonusState>(
        builder: (context, state) {
            final valid = state.kid != null || state.mentor != null;
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
                                        context.read<EditBonusCubit>().onChangeKid(user);
                                      },
                                      image: user.photo,
                                      isSelected: state.kid?.id == e.id,
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
                        text: 'apply'.tr(),
                        isActive: valid,
                        onTap: () {
                          if (valid) {
                            context.pop();
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
      ),
    );
  }
}
