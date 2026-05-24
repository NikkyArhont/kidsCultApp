import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GameLevelScreen extends StatelessWidget {
  const GameLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyscale100,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: white,
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(text: 'gameLevel'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          return StreamBuilder<List<LevelModel>>(
            stream: getLevels(me),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final levels = snapshot.data ?? [];
              if (levels.isEmpty) {
                return Center(
                  child: AppText(
                    text: 'noRaiting'.tr(),
                    size: 15,
                    color: greyscale500,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final reversed = levels.reversed.toList();
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = reversed[index];
                  final levelName = getTextByLocale(context, level.name, level.nameEng);
                  return GestureDetector(
                    onTap: () {
                      showLevelDetailModalBottomSheet(context, level, me);
                    },
                    child: LevelChevronWidget(
                      title: levelName,
                      size: 120,
                      isActive: me.isLevelCompleted(level.ref),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
