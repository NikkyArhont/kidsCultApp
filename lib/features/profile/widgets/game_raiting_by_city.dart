import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GameRaitingByCity extends StatelessWidget {
  final List<UserModel> kids;
  final UserModel me;
  const GameRaitingByCity({super.key, required this.kids, required this.me});

  @override
  Widget build(BuildContext context) {
    if (kids.isEmpty) {
      return Center(
        child: AppText(
          text: 'noRaitingParticipants'.tr(),
          size: 15,
          color: greyscale500,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: kids.length,
      separatorBuilder: (context, index) => const Divider(color: greyscale200, thickness: 1, height: 32),
      itemBuilder: (context, index) {
        final kid = kids[index];
        final isMe = kid.id == me.id;
        return GameRaitingCard(index: index, kid: kid, isMe: isMe);
      },
    );
  }
}
