import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DairyMembersScreen extends StatelessWidget {
  const DairyMembersScreen({super.key});

  void onDelete(BuildContext context, DocumentReference userRef) async {
    await context.read<UserCubit>().deleteDairyMember(userRef);
    SnackBarSerive.showSuccessSnackBar('member_deleted'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(
          text: 'diary_members'.tr(),
          size: 24,
          fw: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          final members = [me.ref, ...me.dairyMembers];

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final userRef = members[index];
                    return DairyMemberCard(
                      onDelete: () => onDelete(context, userRef),
                      isAddedUser: false,
                      isMe: me.id == userRef.id,
                      onAdd: null,
                      userRef: userRef,
                    );
                  },
                ),
              ),
              Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FilledSecondaryAppButton(
                        onTap: () => context.push('/dairy/add_member'),
                        text: 'add_member_button'.tr(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
