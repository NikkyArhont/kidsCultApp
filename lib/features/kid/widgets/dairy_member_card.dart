import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DairyMemberCard extends StatelessWidget {
  final DocumentReference userRef;
  final VoidCallback? onDelete;
  final VoidCallback? onAdd;
  final bool isAddedUser;
  final bool isMe;
  const DairyMemberCard({
    super.key,
    required this.userRef,
    this.onDelete,
    this.onAdd,
    this.isAddedUser = false,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: greyscale200)),
      ),
      child: FutureBuilder<UserModel>(
          future: context.read<UserCubit>().getUserByRef(userRef),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return Row(
              children: [
                CachedClickableImage(
                  height: 60,
                  width: 60,
                  circularRadius: 100,
                  imageUrl: user?.photo,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(text: user?.name ?? '...', size: 16, fw: FontWeight.w700),
                      AppText(
                        text: user == null
                            ? '...'
                            : user.isKid
                                ? '${"roleSelectionKid".tr()} ${isMe ? '(${'amI'.tr()})' : ''}'
                                : 'roleSelectionMentor'.tr(),
                        size: 14,
                        color: greyscale700,
                        fw: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (onDelete == null && isAddedUser)
                       SizedBox(
                        width: 106,
                        child: OutlinedAppButton(
                          height: 34,
                          fontSize: 14,
                          fw: FontWeight.w600,
                          text: 'added'.tr(),
                        ),
                      ),
                    if (onDelete == null && !isAddedUser)
                      SizedBox(
                        width: 103,
                        child: FilledAppButton(
                          onTap: onAdd,
                          height: 34,
                          fontSize: 14,
                          fw: FontWeight.w600,
                          text: 'add'.tr(),
                        ),
                      ),
                    if (onDelete != null && !isMe)
                      GestureDetector(
                        onTap: onDelete,
                        child: SvgPicture.asset(
                          'assets/images/delete.svg',
                          height: 24,
                          width: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),
    );
  }
}
