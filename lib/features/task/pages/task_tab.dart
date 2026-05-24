import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TaskTabScreen extends StatefulWidget {
  const TaskTabScreen({super.key});

  @override
  State<TaskTabScreen> createState() => _TaskTabScreenState();
}

class _TaskTabScreenState extends State<TaskTabScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TaskCubit>().init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) {
          return Container(
            constraints: const BoxConstraints(),
            color: white,
          );
        }
        return BlocConsumer<TaskCubit, TaskState>(
          listener: (context, state) {
            if (state.status == TaskStateStatus.error) {
              SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: greyscale100,
              appBar: AppBar(
                backgroundColor: white,
                automaticallyImplyLeading: false,
                toolbarHeight: 72,
                leadingWidth: 0,
                title: me.isKid ? KidAppBarWidget(me: me, selectedMentor: state.selectedMentor) : MentorAppbarWidget(selectedKid: state.selectedKid),
              ),
              floatingActionButton: SizedBox(
                width: 56,
                height: 56,
                child: FloatingActionButton(
                  onPressed: () async {
                    // if (me.isKid) {
                    //   context.push('/kid_create_task');
                    // } else {
                    //   context.push('/mentor_create_task');

                    // }

                    if (me.hasSubscription()) {
                      context.push('/mentor_create_task');
                    } else {
                      bool? confirm = await showPlanExpiredModalBottomSheet(context, 'get_subs_for_action'.tr());
                      if (confirm == true && context.mounted) {
                        context.push('/current_subscription');
                      }
                    }
                  },
                  elevation: 4,
                  backgroundColor: primary900,
                  shape: const CircleBorder(),
                  child: const Icon(CupertinoIcons.add, color: white, size: 28),
                ),
              ),
              body: state.status == TaskStateStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        CustomCalendar(tasks: state.tasks),
                        Expanded(
                          child: me.isKid
                              ? KidTasksWidget(
                                  tasks: state.tasks,
                                  selectedKidChip: state.selectedKidChip,
                                  me: me,
                                  selectedDay: state.currentDay,
                                )
                              : MentorTasksWidget(
                                  tasks: state.tasks,
                                  selectedKidChip: state.selectedKidChip,
                                  me: me,
                                  selectedDay: state.currentDay,
                                ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
