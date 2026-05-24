// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameRaitingCard extends StatelessWidget {
  final UserModel kid;
  final int index;
  final bool isMe;
  const GameRaitingCard({super.key, required this.kid, required this.index, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: (index == 0 || index == 1 || index == 2)
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/place_flag.svg',
                      fit: BoxFit.contain,
                      width: 32,
                      height: 32,
                      color: getIndexColor(index),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: AppText(
                        text: '${index + 1}',
                        color: greyscale800,
                        size: 12,
                        fw: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: AppText(
                    text: index.toString(),
                    color: greyscale800,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        CachedClickableImage(
          width: 60,
          height: 60,
          circularRadius: 100,
          imageUrl: kid.photo,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppText(
            text: kid.name,
            fw: FontWeight.bold,
            color: isMe ? primary900 : greyscale900,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        AppText(
          text: 'gamePointsCount'.plural(kid.gamePoints),
          color: isMe ? primary900 : greyscale900,
        ),
      ],
    );
  }

  Color getIndexColor(int i) {
    if (i == 0) {
      return const Color(0xFFFFC02D);
    } else if (i == 1) {
      return const Color(0xFFB2C0DB);
    } else {
      return const Color(0xFFD79961);
    }
  }
}
