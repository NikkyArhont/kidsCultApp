import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MyConnectionsScreen extends StatefulWidget {
  final UserModel user;
  final bool showChat;
  final bool showDelete;
  final bool canAdd;
  const MyConnectionsScreen({
    super.key,
    required this.user,
    this.showChat = true,
    this.showDelete = true,
    this.canAdd = true,
  });

  @override
  State<MyConnectionsScreen> createState() => _MyConnectionsScreenState();
}

class _MyConnectionsScreenState extends State<MyConnectionsScreen> {
  bool loading = false;
  void onDelete(UserModel me, DocumentReference userRef) async {
    final confirm = await showConfirmModalBottomSheet(
      context,
      isDestructive: true,
      title: '${"delete".tr()} ${me.isKid ? 'mentorA'.tr() : 'kidsA'.tr()}',
      message: '${'confirmDeleteConnection'.tr()} ${me.isKid ? 'mentorA'.tr() : 'kidsA'.tr()}',
      confirmText: 'yesDelete'.tr(),
      cancelText: 'cancel'.tr(),
    );

    if (confirm == true && mounted) {
      setState(() {
        loading = true;
      });
      final bool result = await context.read<UserCubit>().deleteConnection(userRef);
      setState(() {
        loading = false;
      });
      if (result) {
        SnackBarSerive.showSuccessSnackBar('${me.isKid ? 'roleSelectionMentor'.tr() : 'roleSelectionKid'.tr()} ${"deleted".tr()}');
      } else {
        SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
      }
    }
  }

  void onChat(DocumentReference ref) async {
    setState(() {
      loading = true;
    });
    try {
      DocumentReference? chatRef = await context.read<NewChatCubit>().createOrReturnPrivateChat(ref);
      setState(() {
        loading = false;
      });
      if (chatRef != null) {
        if (mounted) context.push('/chat_room', extra: chatRef);
      }
    } catch (e) {
      SnackBarSerive.showErrorSnackBar(e.toString());
    }
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
        title: AppText(text: widget.user.isKid ? 'myMentors'.tr() : 'myKids'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<UserModel>(
                    initialData: widget.user,
                    stream: widget.user.ref.snapshots().map((doc) => UserModel.fromFirestore(doc)),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final streamUser = snapshot.data!;
                      if (streamUser.connections.isEmpty) {
                        return Center(
                          child: AppText(
                            text: streamUser.isKid ? 'no_mentors'.tr() : 'no_kids'.tr(),
                            color: greyscale500,
                            fw: FontWeight.w400,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: streamUser.connections.length,
                        itemBuilder: (context, index) {
                          final userRef = streamUser.connections[index];
                          return GestureDetector(
                            onTap: () {
                              if(streamUser.isKid)return;
                              context.push('/kid_detail', extra: userRef);
                            },
                            child: ConnectionCard(
                              onDelete: widget.showDelete ? () => onDelete(streamUser, userRef) : null,
                              onChat: widget.showChat ? () => onChat(userRef) : null,
                              onAdd: () {},
                              userRef: userRef,
                            ),
                          );
                        },
                      );
                    }),
              ),
              if (widget.canAdd)
                Container(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        FilledSecondaryAppButton(
                          text: widget.user.isKid ? 'add_mentor'.tr() : 'add_kid'.tr(),
                          onTap: () => context.push('/connections/add_connection'),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(CupertinoIcons.add, color: primary900, size: 20),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (loading)
            Container(
              constraints: const BoxConstraints.expand(),
              color: black.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: white),
                  child:  Center(
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
  }
}
