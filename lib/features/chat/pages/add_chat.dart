import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final pages = [
  const SetChatMembers(),
  const SetChatPhoto(),
  const SetChatName(),
];

class AddChatScreen extends StatelessWidget {
  const AddChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewChatCubit, NewChatState>(
      listener: (context, state) {
        if (state.status == NewChatStatus.error) {
          SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
        } else if (state.status == NewChatStatus.success) {
          final chatRef = state.chatRef;
          context.read<NewChatCubit>().reset();
          context.replace('/new_chat_success', extra: chatRef);
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
                  context.read<NewChatCubit>().reset();
                  context.pop();
                } else {
                  context.read<NewChatCubit>().prevPage();
                }
              },
            ),
            title: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(child: StepProgressWidget(currentStep: state.step, totalSteps: 3)),
              ],
            ),
          ),
          body: Builder(
            builder: (context) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: PageView(
                  controller: context.read<NewChatCubit>().pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: pages,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
