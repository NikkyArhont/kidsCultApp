import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MentorTasksWidget extends StatelessWidget {
  final List<TaskModel> tasks;
  final KidTaskChip selectedKidChip;
  final UserModel me;
  final DateTime selectedDay;
  const MentorTasksWidget({
    super.key,
    required this.tasks,
    required this.selectedKidChip,
    required this.me,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: KidTaskChip.values
                .map((e) => TaskChip(
                      label: kidTaskChipRusName(e),
                      chip: e,
                      selected: selectedKidChip == e,
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            final tasksCopy = List.of(tasks);
            late List<TaskModel> result;
            if (selectedKidChip == KidTaskChip.progress) {
              result = tasksCopy
                  .where((task) =>
                      task.status == TaskStatus.inProgress ||
                      task.status == TaskStatus.onReview ||
                      task.status == TaskStatus.needsRework)
                  .toList();
            } else if (selectedKidChip == KidTaskChip.completed) {
              result = tasksCopy.where((task) => task.status == TaskStatus.completed).toList();
            } else if (selectedKidChip == KidTaskChip.canceled) {
              result = tasksCopy.where((task) => task.status == TaskStatus.canceled).toList();
            } else {
              result = tasksCopy;
            }

            result = result.where((task) => isSameDay(selectedDay, task.startDate)).toList();

            return KidTaskList(tasks: result, me: me);
          }),
        ),
      ],
    );
  }
}
