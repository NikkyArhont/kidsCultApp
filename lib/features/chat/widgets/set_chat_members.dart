import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SetChatMembers extends StatelessWidget {
  const SetChatMembers({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewChatCubit, NewChatState>(
      builder: (context, state) {
        final valid = state.members.isNotEmpty;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'who_to_add_to_chat'.tr(),
                maskot: '2186-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<UserCubit, UserModel?>(
                builder: (context, user) {
                  if (user == null) return const SizedBox.shrink();
                  if (user.connections.isEmpty) return NoMembersWidget(isKid: user.isKid);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        for (var member in user.connections)
                          FutureBuilder<UserModel>(
                              future: context.read<UserCubit>().getUserByRef(member),
                              builder: (context, snapshot) {
                                final isSelected = state.members.contains(member);
                                return GestureDetector(
                                  onTap: () => context.read<NewChatCubit>().onAddMember(member),
                                  child: Container(
                                    width: double.infinity,
                                    height: 92,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? primary900 : greyscale200, width: 3),
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        if (snapshot.connectionState == ConnectionState.waiting ||
                                            snapshot.data == null) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        final memberModel = snapshot.data!;
                                        return Row(
                                          children: [
                                            CachedClickableImage(
                                              width: 60,
                                              height: 60,
                                              imageUrl: memberModel.photo,
                                              circularRadius: 100,
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                                child: AppText(text: memberModel.name, size: 20, fw: FontWeight.w600)),
                                            const SizedBox(width: 10),
                                            if (isSelected)
                                              SvgPicture.asset('assets/images/checkmark.svg', width: 24, height: 24),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
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
                      text: 'buttonNext'.tr(),
                      isActive: valid,
                      onTap: () {
                        if (valid) {
                          context.read<NewChatCubit>().nextPage();
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
