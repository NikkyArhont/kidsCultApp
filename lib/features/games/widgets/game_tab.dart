import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class GameTabWidget extends StatelessWidget {
  final UserModel me;
  const GameTabWidget({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LevelModel>>(
      stream: getLevels(me),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: AppText(
                  text: snapshot.error.toString(),
                  size: 12,
                  fw: FontWeight.normal,
                  color: greyscale500,
                  maxLine: 5,
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final levels = snapshot.data ?? [];
        if (levels.isEmpty) return const EmptyLevelsWidget();
        final LevelModel? minCalculateLevel = levels.fold<LevelModel?>(null, (currentMinObj, nextObj) {
          if (nextObj.pointFrom == null) return currentMinObj;

          if (currentMinObj == null || currentMinObj.pointFrom == null) return nextObj;

          if (nextObj.pointFrom! < currentMinObj.pointFrom!) return nextObj;

          return currentMinObj;
        });
        final LevelModel minLevel = minCalculateLevel ?? levels.first;
        final minLevelPoint = minLevel.pointFrom ?? 0;
        final myPoints = me.points;

        if (myPoints < minLevelPoint) return LevelNotAvailableWidget(points: minLevelPoint - myPoints);

        final reversedLevels = levels.reversed.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          reverse: true,
          child: Column(
            children: [
              for (int i = 0; i < reversedLevels.length; i++)
                Builder(builder: (context) {
                  final level = reversedLevels[i];

                  bool isFirstLevel = (i == reversedLevels.length - 1);

                  final reversedIndex = reversedLevels.length - 1 - i;

                  return LevelWidget(
                    level: level,
                    index: reversedIndex,
                    me: me,
                    available: isFirstLevel
                        ? true
                        : (me.isLevelCompleted(reversedLevels[i + 1].ref) && me.isLevelAvailable(level)),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

Stream<List<LevelModel>> getLevels(UserModel me) {
  final myAge = me.getAge;
  final query = LevelModel.collection
      .where('status', isEqualTo: LevelStatus.active.name)
      .where('age_from', isLessThanOrEqualTo: myAge)
      .where('age_to', isGreaterThanOrEqualTo: myAge)
      .orderBy('index', descending: false);

  return query.snapshots().map((event) => event.docs.map((e) => LevelModel.fromFirestore(e)).toList());
}
