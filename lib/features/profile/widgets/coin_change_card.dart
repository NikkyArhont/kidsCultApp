import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CoinChangeCard extends StatelessWidget {
  final CoinChangeModel coinChange;
  const CoinChangeCard({super.key, required this.coinChange});

  @override
  Widget build(BuildContext context) {
    bool isNegative = coinChange.coin.isNegative;
    return Container(
      width: double.infinity,
      height: 102,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: isNegative ? error : success, width: 3)),
        color: white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(text: dateFormatDDMMYYYYHHMM(coinChange.createdAt), size: 16),
                const SizedBox(height: 4),
                if (coinChange.mentor != null)
                  FutureBuilder<UserModel>(
                    future: context.read<UserCubit>().getUserByRef(coinChange.mentor!),
                    builder: (context, snapshot) {
                      final mentor = snapshot.data;

                      return AppText(
                        text: '${'mentor'.tr()} ${mentor?.name ?? '...'}',
                        size: 12,
                        fw: FontWeight.normal,
                        color: greyscale700,
                      );
                    },
                  ),
                const SizedBox(height: 4),
                if (coinChange.name != null)
                  AppText(
                    text: '${"reason".tr()} ${coinChange.name}',
                    size: 12,
                    fw: FontWeight.normal,
                    color: greyscale700,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppText(text: '${coinChange.coin.isNegative ? '' : '+'}${coinChange.coin} ${"points".tr()}', size: 16, fw: FontWeight.w700),
        ],
      ),
    );
  }
}
