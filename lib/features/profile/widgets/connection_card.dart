import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConnectionCard extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onChat;
  final VoidCallback onAdd;
  final DocumentReference userRef;
  final bool isAdd;
  final bool isAddedUser;
  final bool isRequestedUser;
  const ConnectionCard({
    super.key,
    this.onDelete,
    this.onChat,
    required this.onAdd,
    required this.userRef,
    this.isAdd = false,
    this.isAddedUser = false,
    this.isRequestedUser = false,
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
                                ? '${user.getAge} ${"ageInputYearsOld".tr()}, ${user.city}'
                                : 'roleSelectionMentor'.tr(),
                        size: 14,
                        color: greyscale700,
                        fw: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (isAdd) {
                      if (isAddedUser || isRequestedUser) {
                        return  SizedBox(
                          width: 106,
                          child: OutlinedAppButton(
                            height: 34,
                            fontSize: 14,
                            fw: FontWeight.w600,
                            text: isRequestedUser ? 'sent'.tr() : 'added'.tr(),
                          ),
                        );
                      } else {
                        return SizedBox(
                          width: 103,
                          child: FilledAppButton(
                            onTap: onAdd,
                            height: 34,
                            fontSize: 14,
                            fw: FontWeight.w600,
                            text: 'add'.tr(),
                          ),
                        );
                      }
                    } else {
                      return Row(
                        children: [
                          if (onChat != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: GestureDetector(
                                onTap: onChat,
                                child: SvgPicture.asset(
                                  'assets/images/bubble.svg',
                                  height: 24,
                                  width: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          if (onDelete != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: GestureDetector(
                                onTap: onDelete,
                                child: SvgPicture.asset(
                                  'assets/images/delete.svg',
                                  height: 24,
                                  width: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                  },
                ),
              ],
            );
          }),
    );
  }
}
