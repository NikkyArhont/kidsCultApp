import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DairyScreen extends StatelessWidget {
  final UserModel user;
  const DairyScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: white,
          );
        }
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () => context.pop(),
            ),
            title:  AppText(text: 'my_diary'.tr(), size: 24, fw: FontWeight.w700),
            centerTitle: true,
            actions: [
              if (user.id == me.id)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/setting.svg',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    onPressed: () {
                      context.push('/dairy/setting');
                    },
                  ),
                ),
            ],
          ),
          floatingActionButton: (user.id != me.id)
              ? null
              : SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    onPressed: () {
                      context.push('/dairy/add');
                    },
                    elevation: 4,
                    backgroundColor: primary900,
                    shape: const CircleBorder(),
                    child: const Icon(CupertinoIcons.add, color: white, size: 28),
                  ),
                ),
          body: StreamBuilder<List<DairyModel>>(
            stream: _stream(user.ref),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final dairies = snapshot.data ?? [];
              return Column(
                children: [
                  DairySummaryWidget(dairy: dairies),
                  DairyListWidget(
                    dairyList: dairies,
                    showMenu: (user.id == me.id),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

Stream<List<DairyModel>> _stream(DocumentReference kidRef) {
  final query = DairyModel.collection.where('kid', isEqualTo: kidRef).orderBy('created_at', descending: true);

  return query.snapshots().map((event) => event.docs.map((e) => DairyModel.fromFirestore(e)).toList());
}
