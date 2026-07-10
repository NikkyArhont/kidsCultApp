import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      final StorageService storageService = sl();
      final LocalNotificationService fcm = sl();
      await storageService.clearAllStorage();
      await fcm.cancelAllNotifications();
      if (context.mounted) {
        await context.read<UserCubit>().onDeleteFcmToken();
      }
    } catch (e) {
      print('Error during logout preparation: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out from FirebaseAuth: $e');
    }
    
    if (context.mounted) {
      context.go('/logout_result', extra: 'loggingOut'.tr());
    }
  }
}
