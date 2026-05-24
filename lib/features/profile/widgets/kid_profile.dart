import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class KidProfileWidget extends StatelessWidget {
  final UserModel user;
  const KidProfileWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => context.push('/edit_profile'),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: Row(
                children: [
                  CachedClickableImage(
                    circularRadius: 100,
                    width: 80,
                    height: 80,
                    imageUrl: user.photo,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                      child: AppText(
                    text: user.name,
                    size: 20,
                    fw: FontWeight.w700,
                    maxLine: 2,
                  )),
                  const SizedBox(width: 10),
                  const Icon(CupertinoIcons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ProfileMenuCard(
            onTap: () => context.push('/dairy', extra: user),
            icon: 'diary',
            title: 'myDiary'.tr(),
            color: const Color(0xFF246BFD).withOpacity(0.08),
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          ProfileMenuCard(
            onTap: () => context.push('/kid_progress', extra: user),
            icon: 'progress',
            title: 'taskProgress'.tr(),
            color: const Color(0xFF246BFD).withOpacity(0.08),
          ),
          const SizedBox(height: 24),
          ProfileMenuCard(
            onTap: () => context.push('/kid_coins', extra: user),
            icon: 'coin',
            title: 'taskPoints'.tr(),
            color: orange.withOpacity(0.08),
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          ProfileMenuCard(
            onTap: () => context.push('/game_raiting'),
            icon: 'game_filled_tab',
            title: 'gameRating'.tr(),
            iconColor: green,
            color: green.withOpacity(0.08),
          ),
          const SizedBox(height: 24),
          ProfileMenuCard(
            onTap: () => context.push('/game_level'),
            icon: 'star',
            title: 'gameLevel'.tr(),
            color: yellow.withOpacity(0.08),
          ),
          const Divider(height: 48, thickness: 1, color: greyscale200),
          ProfileMenuCard(
            onTap: () {
              final Map<String, dynamic> extra = {
                'user': user,
                'canAdd': true,
                'showChat': true,
                'showDelete': true,
              };
              context.push('/connections', extra: extra);
            },
            icon: '3user',
            title: 'myMentors'.tr(),
            iconColor: blue,
            color: const Color(0xFF235DFF).withOpacity(0.08),
          ),
          const SizedBox(height: 24),
          ProfileMenuCard(
            onTap: () => context.push('/notification'),
            icon: 'bell_fill',
            title: 'notifications'.tr(),
            iconColor: red,
            color: const Color(0xFFFF5A5F).withOpacity(0.08),
          ),
          const SizedBox(height: 24),
          ProfileMenuCard(
            onTap: () => context.push('/change_lang'),
            icon: 'lang',
            title: context.tr('lang'),
            iconColor: success,
            color: success.withOpacity(0.08),
          ),
        ],
      ),
    );
  }
}
