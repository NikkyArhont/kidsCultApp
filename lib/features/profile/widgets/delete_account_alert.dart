import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

void showDeleteAccountDialog(BuildContext context) async {
  final result = await showConfirmModalBottomSheet(
    context,
    isDestructive: true,
    confirmText: 'yesDelete'.tr(),
    title: 'deleteAccount'.tr(),
    cancelText: 'cancel'.tr(),
    message: 'confirmDeleteAccountMessage'.tr(),
  );

  if (result == true && context.mounted) {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      await currentUser?.delete();
      if (context.mounted) await context.read<UserCubit>().markAsDeleted();
      final StorageService storageService = sl();
      await storageService.clearAllStorage();
      if (context.mounted)  context.go('/logout_result', extra: 'accountDeleted'.tr());
    } on FirebaseAuthException catch (e) {
      print('Error deleting account: $e');
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          SnackBarSerive.showErrorSnackBar('deleteAccountNeedRelogin'.tr());
        }
      } else {
        if (context.mounted) SnackBarSerive.showErrorSnackBar('${"deleteAccountError".tr()}: ${e.message}');
      }
    } catch (e) {
      print('Unexpected error: $e');
      if (context.mounted) SnackBarSerive.showErrorSnackBar('${"defaultErrorText".tr()}: $e');
    }
  }
}
