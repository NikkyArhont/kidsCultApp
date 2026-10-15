import 'package:child_tracker/index.dart';
import 'package:child_tracker/shared/services/session_cleanup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void showLogoutDialog(BuildContext context) async {
  final result = await showConfirmModalBottomSheet(
    context,
    isDestructive: true,
    confirmText: 'yesLogout'.tr(),
    title: 'confirmLogoutTitle'.tr(),
    message: 'confirmLogoutMessage'.tr(),
    cancelText: 'cancel'.tr(),
  );

  if (result == true) {
    try {
      await sl<FirebaseMessaginService>().stop();
      await sl<UserCubit>().onDeleteFcmToken();
    } catch (e) {
      print('Error during logout preparation: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out from FirebaseAuth: $e');
      await sl<FirebaseMessaginService>().setupFCM();
      if (context.mounted) SnackBarSerive.showErrorSnackBar(defaultErrorText);
      return;
    }

    try {
      await clearLocalSession();
    } catch (e) {
      print('Error clearing local session: $e');
    }

    if (context.mounted) {
      context.go('/logout_result', extra: 'loggingOut'.tr());
    }
  }
}
