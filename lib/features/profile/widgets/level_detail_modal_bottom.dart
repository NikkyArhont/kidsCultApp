import 'package:child_tracker/index.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void showLevelDetailModalBottomSheet(
  BuildContext context,
  LevelModel level,
  final UserModel me,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (BuildContext context) {
      return _ShowLevelDetailModalBottom(level: level, me: me);
    },
  );
}

class _ShowLevelDetailModalBottom extends StatelessWidget {
  final LevelModel level;
  final UserModel me;
  const _ShowLevelDetailModalBottom({required this.level, required this.me});

  @override
  Widget build(BuildContext context) {
    final levelName = getTextByLocale(context, level.name, level.nameEng);
    return Container(
      decoration: const BoxDecoration(
        color: greyscale100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 382,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LevelChevronWidget(
                        title: levelName,
                        size: 140,
                        isActive: me.isLevelCompleted(level.ref),
                      ),
                    ],
                  ),
                ),
                AppText(
                  text: '${level.pointFrom ?? 0} - ${level.pointTo ?? 0} ${'points'.tr()}',
                  size: 27,
                  fw: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                if (me.isLevelCompleted(level.ref))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FutureBuilder<DateTime?>(
                      future: getLevelDate(level, me),
                      builder: (context, snapshot) {
                        if (snapshot.data == null) return const SizedBox();
                        return AppText(
                          text: dateToStringDDMMYYYY(snapshot.data),
                          size: 16,
                          fw: FontWeight.w600,
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledAppButton(
            text: 'ok'.tr(),
            onTap: () {
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  Future<DateTime?> getLevelDate(LevelModel level, UserModel me) async {
    final gameDocs = await me.userGamesCollection.get();
    final gameModels = gameDocs.docs.map((e) => UserGameModel.fromFirestore(e)).toList();

    final game = gameModels.firstWhereOrNull((game) => game.levelRef?.id == level.id);
    return game?.createdAt;
  }
}
