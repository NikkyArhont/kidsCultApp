// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LevelWidget extends StatelessWidget {
  final LevelModel level;
  final int index;
  final UserModel me;
  final bool available;
  const LevelWidget({super.key, required this.level, required this.index, required this.me, required this.available});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserGameModel>>(
        stream: getUserGamesStream(me),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                _LevelCard(
                  index: index,
                  level: level,
                  me: me,
                  available: available,
                ),
              ],
            );
          }
          final reversedGames = level.games.reversed.toList();
          final userGames = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 22),
              for (int i = 0; i < reversedGames.length; i++) ...[
                Builder(
                  builder: (context) {
                    final gameRef = reversedGames[i];
                    final userGame = userGames.firstWhereOrNull((g) => g.gameRef == gameRef);
                    bool isFirst = reversedGames.last.id == gameRef.id;
                    bool completed = !available ? false : userGame?.isCompleted ?? false;
                    bool isPrevCompleted = false;
                    if (reversedGames.length > i + 1) {
                      isPrevCompleted = userGames.any((g) => g.gameRef == reversedGames[i + 1]);
                    }

                    bool canPlay = (available && isFirst) || (available && isPrevCompleted);
                    final reversedIndex = reversedGames.length - 1 - i;
                    bool isNeedSpace = (reversedIndex == reversedGames.length - 1) && canPlay && !completed;

                    return Padding(
                      padding: EdgeInsets.only(top: isNeedSpace ? 30 : 0),
                      child: CustomRow(
                        allGamesCount: reversedGames.length,
                        index: reversedIndex,
                        showPlay: !completed && canPlay,
                        circle: _GameCircle(
                          level: level,
                          gameRef: gameRef,
                          canPlay: canPlay,
                          isCompleted: completed,
                        ),
                      ),
                    );
                  },
                )
              ],
              _LevelCard(
                index: index,
                level: level,
                me: me,
                available: available,
              ),
            ],
          );
        });
  }

  Stream<List<UserGameModel>> getUserGamesStream(UserModel me) {
    return me.userGamesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserGameModel.fromFirestore(doc)).toList();
    });
  }
}

class _LevelCard extends StatelessWidget {
  final LevelModel level;
  final int index;
  final UserModel me;
  final bool available;
  const _LevelCard({required this.level, required this.index, required this.me, required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: primary900,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      text: getTextByLocale(context, level.name, level.nameEng),
                      size: 20,
                      fw: FontWeight.w700,
                      maxLine: 2,
                      color: white,
                    ),
                    AppText(
                      text: '${"level".tr()} ${index + 1}',
                      size: 14,
                      fw: FontWeight.w500,
                      color: white,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(
                            value: (me.points) / (level.pointFrom ?? 0),
                            borderRadius: BorderRadius.circular(100),
                            backgroundColor: greyscale200,
                            color: orange,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          text: me.points >= (level.pointFrom ?? 0)
                              ? '${level.pointFrom ?? 0} / ${level.pointFrom ?? 0} ${'points'.tr()}'
                              : '${(me.points)} / ${(level.pointFrom ?? 0)} ${'points'.tr()}',
                          size: 14,
                          fw: FontWeight.w400,
                          color: white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!available)
                CircleAvatar(
                  radius: 40,
                  backgroundColor: white,
                  child: Center(
                    child: SvgPicture.asset('assets/images/lock_fill.svg'),
                  ),
                )
            ],
          ),
          if (level.trophey != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    SvgPicture.asset(
                      'assets/images/level_chevron.svg',
                      width: 25,
                      height: 25,
                      color: orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppText(
                        text: '${available ? 'chevron'.tr() : 'takeLevelAndGetChevron'.tr()} "${level.trophey}"',
                        size: 14,
                        fw: FontWeight.w500,
                        maxLine: 3,
                        height: 1.4,
                      ),
                    ),
                    if (available)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () {
                            if (available) {
                              context.push('/level_trophey_up', extra: level);
                            }
                          },
                          child: SizedBox(
                            width: 96,
                            child: FilledAppButton(
                              height: 34,
                              text: 'get'.tr(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCircle extends StatelessWidget {
  final DocumentReference gameRef;
  final LevelModel level;
  final bool isCompleted;
  final bool canPlay;
  const _GameCircle({required this.gameRef, required this.isCompleted, required this.canPlay, required this.level});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (canPlay && !isCompleted) {
          final data = {'gameRef': gameRef, 'level': level};
          context.push('/game_play', extra: data);
        }
      },
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? orange.withOpacity(0.2)
              : canPlay
                  ? primary900.withOpacity(0.2)
                  : greyscale500.withOpacity(0.2),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? orange
                : canPlay
                    ? primary900
                    : greyscale400,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, left: 10),
                  child: Transform.rotate(
                    angle: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lens,
                          size: 5,
                          color: white.withOpacity(0.32),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.lens,
                          size: 10,
                          color: white.withOpacity(0.32),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0, right: 15),
                  child: Transform.rotate(
                    angle: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.lens,
                          size: 5,
                          color: white.withOpacity(0.32),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.lens,
                          size: 10,
                          color: white.withOpacity(0.32),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (canPlay)
                SvgPicture.asset(
                  'assets/images/play_fill.svg',
                  width: 34,
                  height: 34,
                ),
              if (isCompleted)
                CircleAvatar(
                  radius: 17,
                  backgroundColor: white,
                  child: SvgPicture.asset(
                    'assets/images/checkmark.svg',
                    width: 22,
                    height: 22,
                    color: orange,
                  ),
                ),
              if (!canPlay && !isCompleted)
                SvgPicture.asset(
                  'assets/images/lock_fill.svg',
                  width: 40,
                  height: 40,
                  color: white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MascotWidget extends StatelessWidget {
  final String mascot;
  final double size;
  const MascotWidget({
    super.key,
    this.mascot = '2179-min',
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset('assets/images/$mascot.png'),
    );
  }
}

class PlayLabel extends StatelessWidget {
  const PlayLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayGameArrowBubleShape(text: 'playGame'.tr());
  }
}

class CustomRow extends StatelessWidget {
  final Widget circle;
  final int index;
  final bool showPlay;
  final int allGamesCount;
  const CustomRow({
    super.key,
    required this.circle,
    required this.index,
    this.showPlay = false,
    this.allGamesCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: allGamesCount > 2 ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: (index == 6) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          children: [
            if (index == 3 || index == 9) const MascotWidget(),
            Padding(
              padding: getZigzagPadding2(index, hasMascot: index == 3 || index == 9),
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  circle,
                  if (showPlay)
                    const Positioned(
                      top: -40,
                      child: PlayLabel(),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (index == 6)
          const Align(
            alignment: Alignment.centerRight,
            child: MascotWidget(
              mascot: '2189-min',
              size: 120,
            ),
          )
      ],
    );
  }

  double getPadding(int index) {
    double padding = 60;
    switch (index) {
      case 1:
        return padding * 1;
      case 2:
        return padding * 2;
      case 3:
        return padding * 3;
      default:
        return 0;
    }
  }
}

EdgeInsets getZigzagPadding2(int index, {double step = 60, bool hasMascot = false}) {
  final cycleIndex = index % 6;

  final levels = [0, 1, 2, 3, 2, 1];

  final level = levels[cycleIndex] - (hasMascot ? 2 : 0);
  return EdgeInsets.only(left: level * step);
}
