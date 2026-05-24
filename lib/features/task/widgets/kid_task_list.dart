import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class KidTaskList extends StatelessWidget {
  final List<TaskModel> tasks;
  final UserModel me;
  const KidTaskList({super.key, required this.tasks, required this.me});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const TaskEmptyWidget();
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => TaskCard(task: tasks[index], me: me),
    );
  }
}
