import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class KidCoinsScreen extends StatelessWidget {
  final UserModel kid;
  const KidCoinsScreen({super.key, required this.kid});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) return const SizedBox();
        return Scaffold(
          backgroundColor: greyscale100,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () => context.pop(),
            ),
            title: AppText(text: 'taskPoints'.tr(), size: 24, fw: FontWeight.w700),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(me.isKid ? 125 : 173),
              child: KidCoinsHeader(kid: kid, me: me),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: AppText(
                  text: 'changeHistory'.tr(),
                  size: 20,
                  fw: FontWeight.w700,
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: _stream(kid.ref),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final data = snapshot.data!;
                    if (data.isEmpty) {
                      return Center(
                        child: AppText(
                          text: 'noChanges'.tr(),
                          fw: FontWeight.normal,
                          color: greyscale500,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: data.length,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => CoinChangeCard(coinChange: data[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class KidCoinsHeader extends StatelessWidget {
  final UserModel kid;
  final UserModel me;
  const KidCoinsHeader({super.key, required this.kid, required this.me});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
        stream: context.read<UserCubit>().getStreamUserByRef(kid.ref),
        initialData: kid,
        builder: (context, snapshot) {
          final kidStream = snapshot.data ?? kid;
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 45,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    color: orange,
                  ),
                  child: Center(
                    child: AppText(
                      text: 'currentBalance'.tr(),
                      color: white,
                      fw: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    border: Border.all(color: orange, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/images/coin.svg', width: 32, height: 32),
                          const SizedBox(width: 8),
                          AppText(text: kidStream.points.toString(), size: 20, fw: FontWeight.w700),
                        ],
                      ),
                      if (!me.isKid)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final data = {"kid": kid, "isIncrease": true};
                                    context.push('/kid_coins/change', extra: data);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: success,
                                    ),
                                    child: Center(
                                      child: AppText(
                                        text: 'increase'.tr(),
                                        size: 10,
                                        color: white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final data = {"kid": kid, "isIncrease": false};
                                    context.push('/kid_coins/change', extra: data);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: error,
                                    ),
                                    child: Center(
                                      child: AppText(
                                        text: 'decrease'.tr(),
                                        size: 10,
                                        color: white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

Stream<List<CoinChangeModel>> _stream(DocumentReference kidRef) {
  return CoinChangeModel.collection
      .where('kid', isEqualTo: kidRef)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((event) => event.docs.map((e) => CoinChangeModel.fromFirestore(e)).toList());
}
