import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MentorProfileWidget extends StatelessWidget {
  final UserModel user;
  const MentorProfileWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          const Divider(height: 48, thickness: 1, color: greyscale200),
          if (!user.isDemoAccount)
            Builder(
              builder: (context) {
                bool hasSubscription = user.hasSubscription();
                bool isTrial = user.isSubscriptionTrial();
                return StreamBuilder<SubscriptionModel?>(
                  stream: (hasSubscription && !isTrial) ? sl<PaymentService>().getTariffStreamByRef(user.premiumSubscriptionRef!) : null,
                  builder: (context, snapshot) {
                    final plan = snapshot.data;
                    return ProfileMenuCard(
                      onTap: () => context.push('/current_subscription'),
                      icon: 'crown',
                      iconColor: primary900,
                      title: (hasSubscription && !isTrial) ? getTextByLocale(context, plan?.title ?? '...', plan?.titleEn ?? '...') : 'buy_premium'.tr(),
                      description:
                          !hasSubscription ? 'no_subscription'.tr() : '${isTrial ? "fremium_period".tr() : "premium_period".tr()} ${user.currentSubscriptionValidDate(context.locale.languageCode)}',
                    );
                  },
                );
              },
            ),
          if (!user.isDemoAccount) const SizedBox(height: 24),
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
            title: 'myKids'.tr(),
            iconColor: blue,
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
