import 'package:child_tracker/index.dart';

/// Clear app-scoped objects after authentication has ended. They are reused by
/// the next login, so cancelling listeners alone is not enough.
Future<void> clearLocalSession() async {
  sl<UserCubit>().setUser(null);
  sl<FillDataCubit>().reset();
  sl<NewChatCubit>().reset();
  sl<CurrentChatCubit>().clearChat();
  await Future.wait([
    sl<FirebaseMessaginService>().stop(),
    sl<TaskCubit>().reset(),
    sl<BonusCubit>().reset(),
    sl<LocalNotificationService>().cancelAllNotifications(),
    sl<StorageService>().clearAllStorage(),
  ]);
}
