import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class BonusCard extends StatelessWidget {
  final BonusModel bonus;
  final UserModel me;
  const BonusCard({super.key, required this.bonus, required this.me});

  @override
  Widget build(BuildContext context) {
    final isKidBonus = bonus.owner?.id == bonus.kid?.id;
    return GestureDetector(
      onTap: () {
        final data = {'bonus': bonus, 'bonusRef': bonus.ref};
        context.push('/bonus_detail', extra: data);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: white,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  if (bonus.photo == null) {
                    return const CachedClickableImage(
                      circularRadius: 10,
                      width: 80,
                      height: 80,
                    );
                  } else {
                    bool isEmoji = bonus.photo!.startsWith('emoji:');
                    return CachedClickableImage(
                      circularRadius: 8,
                      width: 80,
                      height: 80,
                      emojiFontSize: 30,
                      emoji: isEmoji ? bonus.photo!.replaceAll('emoji:', '') : null,
                      emojiWidget: Container(
                        width: 80,
                        height: 80,
                        color: greyscale100,
                        child: Center(
                          child: Text(
                            bonus.photo!.replaceAll('emoji:', ''),
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      imageUrl: isEmoji ? null : bonus.photo,
                    );
                  }
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              text: bonus.name,
                              size: 20,
                              fw: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          return FutureBuilder<UserModel>(
                            initialData: (bonus.kid?.id == me.id) ? me : null,
                            future:
                                (bonus.kid?.id == me.id) ? null : context.read<UserCubit>().getUserByRef(bonus.kid!),
                            builder: (context, snapshot) {
                              final kid = snapshot.data;
                              return AppText(
                                text:
                                    '${'roleSelectionKid'.tr()}: ${kid?.name ?? '...'} ${isKidBonus ? 'creator'.tr() : ''}',
                                size: 12,
                                fw: FontWeight.normal,
                                color: greyscale700,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final isMentorBonus = bonus.owner?.id == bonus.mentor?.id;
                          return FutureBuilder<UserModel>(
                            initialData: (bonus.mentor?.id == me.id) ? me : null,
                            future: (bonus.mentor?.id == me.id)
                                ? null
                                : context.read<UserCubit>().getUserByRef(bonus.mentor!),
                            builder: (context, snapshot) {
                              final mentor = snapshot.data;
                              return AppText(
                                text:
                                    '${'roleSelectionMentor'.tr()}: ${mentor?.name ?? '...'} ${isMentorBonus ? 'creator'.tr() : ''}',
                                size: 12,
                                fw: FontWeight.normal,
                                color: greyscale700,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if ((bonus.status == BonusStatus.active ||
                              bonus.status == BonusStatus.readyToReceive ||
                              bonus.status == BonusStatus.received))
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/coin.svg',
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 5),
                                AppText(
                                  text: (bonus.point ?? 0).toString(),
                                  size: 14,
                                  fw: FontWeight.w600,
                                  height: 1,
                                ),
                              ],
                            )
                          else
                            const SizedBox(),
                          Builder(
                            builder: (context) {
                              if (bonus.status == BonusStatus.received) {
                                return const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    color: success,
                                    size: 20,
                                  ),
                                );
                              } else if (bonus.status == BonusStatus.needApprove) {
                                return Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4E7FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AppText(
                                    text: me.isKid ? 'awaiting_approval'.tr() : 'approve'.tr(),
                                    size: 10,
                                    color: info,
                                  ),
                                );
                              } else if (bonus.status == BonusStatus.readyToReceive) {
                                return Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBF8F3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AppText(
                                    text: me.isKid ? 'awaiting_approval'.tr() : 'confirm_of_receive'.tr(),
                                    size: 10,
                                    color: success,
                                  ),
                                );
                              } else {
                                return const SizedBox();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
