// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AddConnectionScreen extends StatefulWidget {
  const AddConnectionScreen({super.key});

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen> {
  bool loading = false;
  void onAddMentor(UserModel me, DocumentReference mentorRef) async {
    if (me.connections.contains(mentorRef)) {
      SnackBarSerive.showErrorSnackBar('mentorAlreadyAdded'.tr());
      return;
    }
    setState(() {
      loading = true;
    });
    final bool result = await context.read<UserCubit>().acceptConnection(mentorRef);
    setState(() {
      loading = false;
    });
    if (result) {
      SnackBarSerive.showSuccessSnackBar('mentorAdded'.tr());
    } else {
      SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
    }
  }

  void onShowQr(String id) {
    showQRModalBottomSheet(context, id);
  }

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
          '/connections/add_connection/scan_qr',
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) return const SizedBox();
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () => context.pop(),
            ),
            title: AppText(text: me.isKid ? 'add_mentor'.tr() : 'add_kid'.tr(), size: 24, fw: FontWeight.w700),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              StreamBuilder<UserModel>(
                  initialData: me,
                  stream: me.ref.snapshots().map((doc) => UserModel.fromFirestore(doc)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final streamUser = snapshot.data!;
                    return Column(
                      children: [
                        if (streamUser.isKid)
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: streamUser.connectionRequests.length,
                              itemBuilder: (context, index) {
                                final userRef = streamUser.connectionRequests[index];
                                return ConnectionCard(
                                  onDelete: () {},
                                  onChat: () {},
                                  onAdd: () => onAddMentor(streamUser, userRef),
                                  isAdd: true,
                                  isAddedUser: streamUser.hasInConnections(userRef),
                                  userRef: userRef,
                                );
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              itemCount: streamUser.connectionRequests.length,
                              itemBuilder: (context, index) {
                                final userRef = streamUser.connectionRequests[index];
                                return ConnectionCard(
                                  onDelete: () {},
                                  onChat: () {},
                                  onAdd: () {},
                                  isAdd: true,
                                  isAddedUser: streamUser.hasInConnections(userRef),
                                  isRequestedUser: streamUser.hasInConnections(userRef) ? false : true,
                                  userRef: userRef,
                                );
                              },
                            ),
                          ),
                        Container(
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 18),
                                RichText(
                                  text: TextSpan(
                                    text: '${'add_new_member_description'.tr()}, ${streamUser.isKid ? '${'share_your'.tr()} ' : '${'scan_his'.tr()} '} ',
                                    style: const TextStyle(
                                      color: greyscale800,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      fontFamily: Involve,
                                      height: 1.6,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: streamUser.isKid ? 'qr_code'.tr() : 'qr_code_simple'.tr(),
                                        style: const TextStyle(
                                          color: greyscale800,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          fontFamily: Involve,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                FilledSecondaryAppButton(
                                  text: !streamUser.isKid ? 'scan_qr_code'.tr() : 'share_qr_code'.tr(),
                                  icon: Padding(
                                    padding: const EdgeInsets.only(right: 15),
                                    child: !streamUser.isKid
                                        ? SvgPicture.asset('assets/images/scan_q.svg', color: primary900, width: 20, height: 20)
                                        : SvgPicture.asset('assets/images/qr.svg', color: primary900, width: 20, height: 20),
                                  ),
                                  onTap: () {
                                    if (streamUser.isKid) {
                                      onShowQr(streamUser.id);
                                    } else {
                                      onScanQr(streamUser);
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
              if (loading)
                Container(
                  constraints: const BoxConstraints.expand(),
                  color: black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: white),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppText(text: 'loading'.tr(), size: 18, fw: FontWeight.w700),
                            const SizedBox(height: 16),
                            const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
