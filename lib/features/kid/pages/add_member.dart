import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddMemberToDairyScreen extends StatelessWidget {
  const AddMemberToDairyScreen({super.key});

  void onAdd(BuildContext context, DocumentReference userRef) async {
    await context.read<UserCubit>().addDairyMember(userRef);
    SnackBarSerive.showSuccessSnackBar('member_added'.tr());
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
        title:  AppText(
          text: 'add_member'.tr(),
          size: 24,
          fw: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          final members = [me.ref, ...me.dairyMembers];
          final connections = me.connections;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: connections.length,
                  itemBuilder: (context, index) {
                    final userRef = connections[index];
                    return DairyMemberCard(
                      onDelete: null,
                      isAddedUser: members.contains(userRef),
                      isMe: me.id == userRef.id,
                      onAdd: () => onAdd(context, userRef),
                      userRef: userRef,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
