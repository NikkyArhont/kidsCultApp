import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class BonusDetailScreen extends StatefulWidget {
  final DocumentReference bonusRef;
  final BonusModel? bonus;
  const BonusDetailScreen({super.key, required this.bonusRef, this.bonus});

  @override
  State<BonusDetailScreen> createState() => _BonusDetailScreenState();
}

class _BonusDetailScreenState extends State<BonusDetailScreen> {
  late BonusModel bonus;
  bool loading = false;
  StreamSubscription? _bonusStreamSubscription;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (widget.bonus != null) {
      bonus = widget.bonus!;
    } else {
      setState(() => loading = true);
      final doc = await widget.bonusRef.get();
      bonus = BonusModel.fromFirestore(doc);
      setState(() => loading = false);
    }
    initSubscriptions();
  }

  void initSubscriptions() {
    _bonusStreamSubscription = widget.bonusRef.snapshots().listen((doc) {
      final bonus = BonusModel.fromFirestore(doc);
      if (mounted) {
        setState(() {
          this.bonus = bonus;
        });
      }
    });
  }

  void onCancel() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'cancelIt'.tr(),
      isDestructive: true,
      cancelText: 'no_dont_cancel'.tr(),
      confirmText: 'yes_cancel'.tr(),
      message: 'changed_your_mind'.tr(),
    );
    if (confrim == true && mounted) {
      final extra = {'bonus': bonus, 'isCancel': true};
      context.push('/bonus_cancel_reason', extra: extra);
    }
  }

  void onEdit() {
    String route = '/edit_bonus';
    context.push(route, extra: bonus);
  }

  void onDelete() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'delete'.tr(),
      isDestructive: true,
      cancelText: 'cancel'.tr(),
      confirmText: 'yes_delete'.tr(),
      message: 'are_you_sure_delete'.tr(),
    );
    if (confrim == true && mounted) {
      final result = await context.read<BonusCubit>().deleteBonus(bonus);
      if (result && mounted) {
        context.replace('/bonus_delete_success');
      } else {
        SnackBarSerive.showErrorSnackBar('failed_to_delete_bonus'.tr());
      }
    }
  }

  void onOpenLink(String link) async {
    if (link.isEmpty) return;
    await launchUrl(Uri.parse(link));
  }

  void onRequestBonusByKid(UserModel me) async {
    int bonusPoints = bonus.point ?? 0;
    int kidPoints = me.points;

    if (kidPoints >= bonusPoints) {
      final needPointCount = 'pointsCount'.plural(bonusPoints);

      final confrim = await showConfirmModalBottomSheet(
        context,
        title: 'request_bonus_by_kid'.tr(),
        isDestructive: false,
        cancelText: 'cancel'.tr(),
        confirmText: 'request_bonus_btn'.tr(),
        message: 'request_bonus_by_kid_text'.tr(args: [needPointCount]),
      );
      if (confrim == false || confrim == null) return;

      if (mounted) {
        context.read<BonusCubit>().requestBonusByKid(bonus);
      }
    } else {
      String title = 'cant_request_bonus_by_kid_text'.tr(args: ['pointsCount'.plural(bonusPoints)]);
      showNotEnoughtPointForBonusModalBottomSheet(context, title);
    }
  }

  void onRejectRequest() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'reject_bonus'.tr(),
      isDestructive: true,
      cancelText: 'no_not_reject'.tr(),
      confirmText: 'yes_reject'.tr(),
      message: 'hmm_dont_like_idea'.tr(),
    );
    if (confrim == true && mounted) {
      final extra = {'bonus': bonus, 'isCancel': false};
      context.push('/bonus_cancel_reason', extra: extra);
    }
  }

  void onRejectBonus() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'reject_bonus'.tr(),
      isDestructive: true,
      cancelText: 'no_not_reject'.tr(),
      confirmText: 'yes_reject'.tr(),
      message: 'hmm_dont_like_idea'.tr(),
    );
    if (confrim == true && mounted) {
      final extra = {'bonus': bonus, 'isCancel': false};
      context.push('/bonus_cancel_reason', extra: extra);
    }
  }

  void onApproveRequest() async {
    final kid = await context.read<UserCubit>().getUserByRef(bonus.kid!);
    if(!mounted) return;
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'request_gift'.tr(),
      isDestructive: false,
      cancelText: 'cancel'.tr(),
      confirmText: 'yesConfirm'.tr(),
      message: '${kid.name} ${'want_receive_gift'.tr()} "${bonus.name}"',
    );
    if (confrim == true && mounted) {
      context.read<BonusCubit>().approveRequest(bonus);
    }
  }

  void onApproveBonus() async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'approve_bonus'.tr(),
      isDestructive: false,
      cancelText: 'reject_bonus'.tr(),
      confirmText: 'yesConfirm2'.tr(),
      message: 'tap_approve'.tr(),
    );
    if (confrim == true && mounted) {
      context.push('/approve_bonus_set_point', extra: bonus);
    }
  }

  @override
  dispose() {
    _bonusStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        constraints: const BoxConstraints.expand(),
        color: white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () {
                context.pop();
              },
            ),
            actions: ((me.id != bonus.owner?.id) ||
                    bonus.status == BonusStatus.canceled ||
                    bonus.status == BonusStatus.deleted ||
                    bonus.status == BonusStatus.received ||
                    bonus.status == BonusStatus.rejected ||
                    bonus.status == BonusStatus.readyToReceive)
                ? null
                : [
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/cancel.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: onCancel,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/edit.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/delete.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: IntrinsicHeight(
                      child: BlocConsumer<BonusCubit, BonusState>(
                        listener: (context, state) {
                          if (state.status == BonusStateStatus.requestReceiveError ||
                              state.status == BonusStateStatus.requestApproveError) {
                            SnackBarSerive.showErrorSnackBar(state.errorMessage ?? 'defaultErrorText'.tr());
                          } else if (state.status == BonusStateStatus.requestReceiveSuccess) {
                            final data = {"mentorRef": bonus.mentor, "bonusName": bonus.name};
                            context.push('/bonus_request_success', extra: data);
                          } else if (state.status == BonusStateStatus.requestApproveSuccess) {
                            final data = {
                              "mentorRef": bonus.mentor,
                              "kidRef": bonus.kid,
                              "bonusName": bonus.name,
                            };
                            context.push('/bonus_received_success', extra: data);
                          }
                        },
                        builder: (context, state) {
                          bool isKidBonus = bonus.owner?.id == bonus.kid?.id;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: BonusContainer(
                                  color: bonusCardColor(bonus.status),
                                  title: bonusDetailCardStatusText(bonus.status),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Builder(builder: (context) {
                                            if (bonus.photo == null) {
                                              return const CachedClickableImage(
                                                height: 120,
                                                width: 120,
                                                circularRadius: 300,
                                              );
                                            } else {
                                              bool isEmoji = bonus.photo!.startsWith('emoji:');
                                              return CachedClickableImage(
                                                height: 120,
                                                width: 120,
                                                circularRadius: 300,
                                                emojiFontSize: 60,
                                                emoji: isEmoji ? bonus.photo!.replaceAll('emoji:', '') : null,
                                                imageUrl: isEmoji ? null : bonus.photo,
                                              );
                                            }
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: bonus.name,
                                              size: 24,
                                              fw: FontWeight.bold,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 40, thickness: 1, color: greyscale200),
                                      Builder(
                                        builder: (context) {
                                          return FutureBuilder<UserModel>(
                                            initialData: (bonus.kid?.id == me.id) ? me : null,
                                            future: (bonus.kid?.id == me.id)
                                                ? null
                                                : context.read<UserCubit>().getUserByRef(bonus.kid!),
                                            builder: (context, snapshot) {
                                              final kid = snapshot.data;
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    child: AppText(
                                                      text:
                                                          '${'roleSelectionKid'.tr()} ${isKidBonus ? 'creator'.tr() : ''}',
                                                      size: 16,
                                                      fw: FontWeight.w500,
                                                      color: greyscale800,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: AppText(
                                                      text: kid?.name ?? '...',
                                                      size: 16,
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
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
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    child: AppText(
                                                      text:
                                                          '${'roleSelectionMentor'.tr()} ${isMentorBonus ? 'creator'.tr() : ''}',
                                                      size: 16,
                                                      fw: FontWeight.w500,
                                                      color: greyscale800,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: AppText(
                                                      text: mentor?.name ?? '...',
                                                      size: 16,
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          AppText(
                                            text: 'link_opt'.tr(),
                                            size: 16,
                                            fw: FontWeight.w500,
                                            color: greyscale800,
                                          ),
                                          const SizedBox(width: 2),
                                          const Spacer(),
                                          if (bonus.link != null && bonus.link!.isNotEmpty)
                                            GestureDetector(
                                              onTap: () => onOpenLink(bonus.link!),
                                              child: Container(
                                                height: 34,
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(100),
                                                  border: Border.all(color: primary900, width: 1.5),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/images/link.svg',
                                                      width: 14,
                                                      height: 14,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    AppText(
                                                      text: 'link'.tr(),
                                                      size: 14,
                                                      color: primary900,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (bonus.link == null || (bonus.link?.isEmpty ?? true))
                                            const AppText(text: '-'),
                                        ],
                                      ),
                                      if ((bonus.point ?? 0) > 0) const SizedBox(height: 16),
                                      if ((bonus.point ?? 0) > 0)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AppText(
                                                text: 'execution_conditions'.tr(),
                                                size: 16,
                                                fw: FontWeight.w500,
                                                color: greyscale800,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/images/coin.svg',
                                                  width: 20,
                                                  height: 20,
                                                ),
                                                const SizedBox(width: 6),
                                                AppText(
                                                  text: bonus.point?.toString() ?? '0',
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              //когда отменено или отклонен
                              if ((bonus.status == BonusStatus.canceled || bonus.status == BonusStatus.rejected) &&
                                  bonus.reasonOfCancel != null)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: greyscale200, width: 3)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        text: bonus.status == BonusStatus.rejected
                                            ? 'reject_reason'.tr()
                                            : 'couse_of_cancel'.tr(),
                                        size: 16,
                                        fw: FontWeight.w500,
                                        color: greyscale800,
                                      ),
                                      const Divider(height: 36, thickness: 1, color: greyscale200),
                                      AppText(text: bonus.reasonOfCancel ?? ''),
                                    ],
                                  ),
                                ),
                              ////////////////////////////////////
                              const Spacer(),
                              const SizedBox(height: 24),
                              // Для ребенка - когда в ожидания
                              if ((bonus.status == BonusStatus.needApprove) && bonus.kid?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      OutlinedAppButton(
                                        text: 'wait_for_approve'.tr(),
                                      ),
                                      const SizedBox(height: 24),
                                      FilledDestructiveAppButton(
                                        onTap: onDelete,
                                        child: AppText(
                                          text: 'delete'.tr(),
                                          color: error,
                                          fw: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Для ментора - когда в ожидания
                              if ((bonus.status == BonusStatus.needApprove) && bonus.mentor?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FilledAppButton(
                                        onTap: onApproveBonus,
                                        text: 'approve_bonus'.tr(),
                                      ),
                                      const SizedBox(height: 24),
                                      FilledDestructiveAppButton(
                                        onTap: onRejectBonus,
                                        child: AppText(
                                          text: 'reject_bonus'.tr(),
                                          color: error,
                                          fw: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Для ментора - когда в ожидания получения
                              if ((bonus.status == BonusStatus.readyToReceive) && bonus.mentor?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FilledAppButton(
                                        onTap: onApproveRequest,
                                        text: 'confirm_of_receive'.tr(),
                                      ),
                                      // const SizedBox(height: 24),
                                      // FilledDestructiveAppButton(
                                      //   onTap: onRejectRequest,
                                      //   child: AppText(
                                      //     text: 'reject_bonus'.tr(),
                                      //     color: error,
                                      //     fw: FontWeight.w700,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              // Для ребенка - когда активная
                              if ((bonus.status == BonusStatus.active) && bonus.kid?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FilledAppButton(
                                        isLoading: state.status == BonusStateStatus.requestingReceive,
                                        onTap: () => onRequestBonusByKid(me),
                                        text: 'request_bonus_btn'.tr(),
                                      ),
                                    ],
                                  ),
                                ),
                              // Для ребенка - когда в ожидания апрува бонуса
                              if ((bonus.status == BonusStatus.readyToReceive) && bonus.kid?.id == me.id)
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      OutlinedAppButton(
                                        text: 'wait_for_approve'.tr(),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
