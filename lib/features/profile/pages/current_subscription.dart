// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class CurrentSubscriptionScreen extends StatefulWidget {
  const CurrentSubscriptionScreen({super.key});

  @override
  State<CurrentSubscriptionScreen> createState() => _CurrentSubscriptionScreenState();
}

class _CurrentSubscriptionScreenState extends State<CurrentSubscriptionScreen> {
  bool loading = false;
  late InAppPurchasesProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = InAppPurchasesProvider();
  }

  void onTapPurchase(UserModel me) async {
    final SubscriptionModel? selectedPlan = await context.push('/select_plan');

    if (selectedPlan != null && mounted) {
      try {
        setState(() {
          loading = true;
        });

        final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && me.id == 'phone_99364424525';

        if (isIos) {
          final result = await _provider.buySubs(selectedPlan.appleId);
          if (result && mounted) {
            final Map orderDoc = {
              "is_gift": false,
              "tariff": selectedPlan.ref,
              "paid": false,
              "price": selectedPlan.price,
              "user": me.ref,
            };
            await context.read<UserCubit>().onPurchasePlan(orderDoc);
            bool isGift = orderDoc['is_gift'] ?? false;
            if (isGift && mounted) {
              final receiver = await context.read<UserCubit>().getUserByRef(orderDoc['user']);
              if (mounted) context.replace('/payment_success', extra: receiver.name);
            } else {
              if (mounted) context.replace('/payment_success');
            }
          }
        } else {
          final service = sl<PaymentService>();
          final Map? data = await service.createPayment(tariff: selectedPlan);

          print('Payment data: $data');
          if (data != null && mounted) {
            setState(() {
              loading = false;
            });

            context.replace('/purchase_plan', extra: data);
          }
        }
      } catch (e) {
        SnackBarSerive.showErrorSnackBar(e.toString());
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    }
  }

  void onTapGifts() async {
    final SubscriptionModel? selectedPlan = await context.push('/select_plan');
    print('selectedPlan: ${selectedPlan?.id}');
    if (selectedPlan != null && mounted) {
      final UserModel? selectedUser = await context.push('/select_user_for_gift');
      print('selectedUser: ${selectedUser?.name}');
      try {
        setState(() {
          loading = true;
        });

        final service = sl<PaymentService>();
        final Map? data = await service.sendGift(tariff: selectedPlan, user: selectedUser!);

        print('Payment data: $data');
        if (data != null && mounted) {
          setState(() {
            loading = false;
          });

          context.replace('/purchase_plan', extra: data);
        }
      } catch (e) {
        SnackBarSerive.showErrorSnackBar(e.toString());
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    }
  }

  void onReplayGift(DocumentSnapshot order) async {
    try {
      setState(() {
        loading = true;
      });
      final service = sl<PaymentService>();

      final selectedPlan = await service.getTariffByRef(order['tariff']);
      late UserModel selectedUser;

      if (mounted) {
        selectedUser = await context.read<UserCubit>().getUserByRef(order['user']);
      }

      final Map? data = await service.sendGift(tariff: selectedPlan, user: selectedUser);

      print('Payment data: $data');
      if (data != null && mounted) {
        setState(() {
          loading = false;
        });

        context.replace('/purchase_plan', extra: data);
      }
    } catch (e) {
      SnackBarSerive.showErrorSnackBar(e.toString());
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void onTapAllGifts(orders) async {
    DocumentSnapshot? order = await context.push('/all_gifts', extra: orders);
    if (order != null) {
      onReplayGift(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyscale100,
      appBar: AppBar(
        backgroundColor: greyscale100,
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: loading ? null : () => context.pop(),
        ),
        title: AppText(text: 'yourPlan'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          bool hasSubscription = me.hasSubscription();
          bool isTrial = me.isSubscriptionTrial();
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: white,
                        ),
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/crown.svg',
                                  color: primary900,
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                AppText(
                                  text: 'current_tariff'.tr(),
                                  size: 20,
                                ),
                              ],
                            ),
                            const Divider(height: 32, thickness: 1, color: greyscale200),
                            !hasSubscription
                                ? AppText(text: 'subs_is_expired'.tr(), fw: FontWeight.w500)
                                : isTrial
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppText(text: 'fremium'.tr(), fw: FontWeight.w700),
                                          AppText(
                                            text:
                                                '${'fremium_period'.tr()} ${me.currentSubscriptionValidDate(context.locale.languageCode)}',
                                            fw: FontWeight.w400,
                                            size: 14,
                                            color: greyscale700,
                                            maxLine: 2,
                                          ),
                                        ],
                                      )
                                    : FutureBuilder<SubscriptionModel>(
                                        future: sl<PaymentService>().getTariffByRef(me.premiumSubscriptionRef!),
                                        builder: (context, snapshot) {
                                          final tariff = snapshot.data;
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    AppText(
                                                      text: getTextByLocale(
                                                          context, tariff?.title ?? '...', tariff?.titleEn ?? '...'),
                                                      fw: FontWeight.w700,
                                                    ),
                                                    AppText(
                                                      text: getTextByLocale(context, tariff?.description ?? '...',
                                                          tariff?.descriptionEn ?? '...'),
                                                      fw: FontWeight.w400,
                                                      size: 14,
                                                      color: greyscale700,
                                                      maxLine: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              AppText(
                                                text: roubleFormat(tariff?.price ?? 0),
                                                fw: FontWeight.w700,
                                              ),
                                            ],
                                          );
                                        }),
                          ],
                        ),
                      ),
                      FutureBuilder<List<DocumentSnapshot>>(
                        future: getGifts(me.ref),
                        builder: (context, snapshot) {
                          final orders = snapshot.data;

                          if (orders == null) return const SizedBox();
                          if (orders.isEmpty) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: '${'gifted_plans'.tr()} (${orders.length})',
                                        fw: FontWeight.w700,
                                        size: 20,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        onTapAllGifts(orders);
                                      },
                                      child: AppText(
                                        text: 'all'.tr(),
                                        fw: FontWeight.w700,
                                        size: 16,
                                        color: primary900,
                                      ),
                                    ),
                                  ],
                                ),
                                ...orders.map((order) => giftOrder(order)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                color: white,
                child: Column(
                  children: [
                    if (hasSubscription)
                      AppText(
                        text: "subs_date_of"
                            .tr(args: [me.currentSubscriptionValidDate(context.locale.languageCode, short: true)]),
                        fw: FontWeight.w500,
                        color: greyscale800,
                        textAlign: TextAlign.center,
                        maxLine: 2,
                      ),
                    if (hasSubscription)
                      RichText(
                        text: TextSpan(
                          text: 'refresh_here'.tr(),
                          style: const TextStyle(
                            color: greyscale800,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            fontSize: 18,
                            fontFamily: Involve,
                          ),
                          children: [
                            TextSpan(
                              text: ' ${'here'.tr()}',
                              recognizer: TapGestureRecognizer()..onTap = () => onTapPurchase(me),
                              style: const TextStyle(
                                color: primary900,
                                fontWeight: FontWeight.w700,
                                height: 1.6,
                                fontSize: 18,
                                fontFamily: Involve,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    if (hasSubscription) const SizedBox(height: 24),
                    FilledAppButton(
                      text: 'subscribe'.tr(),
                      onTap:()=> onTapPurchase(me),
                    ),
                    const SizedBox(height: 24),
                    FilledSecondaryAppButton(
                      onTap: onTapGifts,
                      text: 'gift_subs'.tr(),
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 4),
                        child: SvgPicture.asset(
                          'assets/images/share.svg',
                          color: primary900,
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget giftOrder(DocumentSnapshot order) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: taskDate((order['time'] as Timestamp?)?.toDate()),
            size: 16,
            fw: FontWeight.w500,
            color: greyscale700,
          ),
          const SizedBox(height: 12),
          FutureBuilder<UserModel?>(
            future: context.read<UserCubit>().getUserByRef(order['user']),
            builder: (context, snapshot) {
              final receiver = snapshot.data;
              return Row(
                children: [
                  Flexible(
                    child: AppText(
                      text: receiver?.name ?? '...',
                      fw: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppText(
                    text: '(${receiver?.phone ?? '...'})',
                    color: greyscale700,
                    size: 16,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<SubscriptionModel?>(
            future: sl<PaymentService>().getTariffByRef(order['tariff']),
            builder: (context, snapshot) {
              final tariff = snapshot.data;
              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/crown.svg',
                          width: 20,
                          height: 20,
                          color: primary900,
                        ),
                        const SizedBox(width: 8),
                        AppText(
                          text: getTextByLocale(context, tariff?.title ?? '...', tariff?.titleEn ?? '...'),
                          size: 14,
                          color: greyscale700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      text: dateToStringDDMMYYYY((order['time'] as Timestamp?)?.toDate().add(const Duration(days: 30))),
                      size: 14,
                      color: greyscale700,
                      fw: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedAppButton(
            onPress: () => onReplayGift(order),
            height: 46,
            text: 'replay_gift'.tr(),
            icon: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 4),
              child: SvgPicture.asset(
                'assets/images/share.svg',
                color: primary900,
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<DocumentSnapshot>> getGifts(DocumentReference me) async {
  final collection = FirebaseFirestore.instance.collection('orders');

  final docs = await collection
      .where('sender', isEqualTo: me)
      .where('paid', isEqualTo: true)
      .orderBy('time', descending: true)
      .get();

  return docs.docs.map((doc) => doc).toList();
}
