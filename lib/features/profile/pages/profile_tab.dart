// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  bool loading = false;

  void onScanQr(UserModel me) async {
    if (!me.hasSubscription()) {
      bool? confirm = await showPlanExpiredModalBottomSheet(context, 'get_subs_for_action2'.tr());
      if (confirm == true && mounted) {
        context.push('/current_subscription');
      }
    } else {
      final canAdd = await sl<PaymentService>().canAddKid();

      if (!mounted) return;
      if (!canAdd) {
        bool? confirm = await showMaxConnectionModalBottomSheet(context);
        if (confirm == true && mounted) {
          context.push('/current_subscription');
        }
      } else {
        final UserModel? kid = await context.push<UserModel?>(
          '/mentor_profile/scan_qr',
        );

        if (kid != null) {
          debugPrint('connection kid: ${kid.id}');
          if (me.connections.contains(kid.ref)) {
            SnackBarSerive.showErrorSnackBar('kidAlreadyAdded'.tr());
            return;
          } else if (me.connectionRequests.contains(kid.ref)) {
            SnackBarSerive.showErrorSnackBar('requestAlreadySent'.tr());
            return;
          } else {
            if (mounted) {
              setState(() {
                loading = true;
              });
              final bool result = await context.read<UserCubit>().addRequestToConnection(kid.ref);
              if (mounted) {
                setState(() {
                  loading = false;
                });
                if (result) {
                  SnackBarSerive.showSuccessSnackBar('requestSent'.tr());
                } else {
                  SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
                }
              }
            }
          }
        }
      }
    }
  }

  void onShowQr(String id) {
    showQRModalBottomSheet(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, user) {
        if (user == null) return const Center(child: CircularProgressIndicator());
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            toolbarHeight: 72,
            backgroundColor: white,
            leadingWidth: 62,
            automaticallyImplyLeading: false,
            leading: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                'assets/images/logo_min.svg',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            title: AppText(text: context.tr('profileTitle'), size: 24, fw: FontWeight.w700),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: () {
                    if (user.isKid) {
                      onShowQr(user.id);
                    } else {
                      onScanQr(user);
                    }
                  },
                  icon: SvgPicture.asset(
                    'assets/images/${user.isKid ? 'qr' : 'scan_q'}.svg',
                    color: greyscale900,
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (loading) return const Center(child: CircularProgressIndicator());
              if (user.isKid) return KidProfileWidget(user: user);
              return MentorProfileWidget(user: user);
            },
          ),
        );
      },
    );
  }
}
