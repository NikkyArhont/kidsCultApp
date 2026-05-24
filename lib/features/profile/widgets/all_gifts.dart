// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AllGiftsScreen extends StatelessWidget {
  final List<DocumentSnapshot> orders;
  const AllGiftsScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyscale100,
      appBar: AppBar(
        backgroundColor: greyscale100,
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                  ],
                ),
                ...orders.map((order) => giftOrder(context, order)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget giftOrder(BuildContext context, DocumentSnapshot order) {
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
            onPress: () => context.pop(order),
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
