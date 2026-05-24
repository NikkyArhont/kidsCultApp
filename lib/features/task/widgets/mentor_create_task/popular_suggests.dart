import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class PopularSuggestsScreen extends StatelessWidget {
  final List<TaskModel> popularTasks;
  const PopularSuggestsScreen({super.key, required this.popularTasks});

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
        title: AppText(
          text: 'most_popular_tasks'.tr(),
          size: 24,
          fw: FontWeight.w700,
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: popularTasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final task = popularTasks[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.pop(task),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    text: task.name,
                    maxLine: 2,
                    fw: FontWeight.w500,
                    size: 20,
                    color: greyscale700,
                  ),
                ),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/coins.svg',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      text: (task.coin ?? 0).toString(),
                      fw: FontWeight.w500,
                      size: 18,
                      color: greyscale700,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
