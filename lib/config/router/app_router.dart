import 'package:child_tracker/index.dart';
import 'package:child_tracker/config/router/startup_redirect.dart';
import 'package:child_tracker/config/router/data_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> kidEditTaskNavigatorKey = GlobalKey<NavigatorState>();

enum UserInitialStatus {
  noFound,
  fillProfileKid,
  fillProfileMentor,
  successKid,
  successMentor,
  banned,
}

Future<UserInitialStatus> getUserStatus(BuildContext context) async {
  try {
    final userCubit = context.read<UserCubit>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      userCubit.setUser(null);
      return UserInitialStatus.noFound;
    }
    UserModel? userModel = userCubit.state;

    if (userModel == null || userModel.id != user.uid) {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return UserInitialStatus.noFound;
      }

      if (!userSnap.exists) {
        await FirebaseAuth.instance.signOut();
        userCubit.setUser(null);
        return UserInitialStatus.noFound;
      }

      userModel = UserModel.fromFirestore(userSnap);
      userCubit.setUser(userModel);
    }

    if (userModel.banned) return UserInitialStatus.banned;
    if (userModel.profileFilled) {
      return userModel.isKid ? UserInitialStatus.successKid : UserInitialStatus.successMentor;
    } else {
      return userModel.isKid ? UserInitialStatus.fillProfileKid : UserInitialStatus.fillProfileMentor;
    }
  } catch (e, stack) {
    print('$defaultErrorText {getUserStatus}: $e');
    SnackBarSerive.showErrorSnackBar(defaultErrorText);
    if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stack);
    return UserInitialStatus.noFound;
  }
}

final ValueNotifier<bool> isRedirectLoading = ValueNotifier(false);

Future<void> redirectFunc(BuildContext context) async {
  if (isRedirectLoading.value || !isCheckingAuth.value) return;
  isRedirectLoading.value = true;
  try {
    final user = FirebaseAuth.instance.currentUser;
    final isAuth = user != null;

    if (isAuth) {
      final userStatus = await getUserStatus(context);
      initialRoute.value = getRouteForStatus(userStatus);
    } else {
      final storageService = sl<StorageService>();
      bool showed = storageService.isOnboardShowed();
      if (!showed) {
        initialRoute.value = '/onboarding';
      } else {
        initialRoute.value = '/auth';
      }
    }
  } catch (err, stack) {
    initialRoute.value = '/auth';
    SnackBarSerive.showErrorSnackBar(defaultErrorText);
    if (!kIsWeb) FirebaseCrashlytics.instance.recordError(err, stack);
  } finally {
    isRedirectLoading.value = false;
    isCheckingAuth.value = false;
    FlutterNativeSplash.remove();
  }
}

String? getRouteForStatus(UserInitialStatus status) {
  switch (status) {
    case UserInitialStatus.noFound:
      return '/auth';
    case UserInitialStatus.fillProfileKid:
      return '/auth/role';
    case UserInitialStatus.fillProfileMentor:
      return '/auth/role';
    case UserInitialStatus.successKid:
      return '/kid_task';
    case UserInitialStatus.successMentor:
      return '/mentor_task';
    case UserInitialStatus.banned:
      return '/banned';
  }
}

final ValueNotifier<bool> isCheckingAuth = ValueNotifier(true);
final ValueNotifier<String?> initialRoute = ValueNotifier(null);

GoRoute _dataRoute({
  required String path,
  required GoRouterWidgetBuilder builder,
  List<RouteBase> routes = const [],
}) =>
    DataRoute(
      path: path,
      builder: builder,
      routes: routes,
      missingDataBuilder: () => ErrorScreen(error: defaultErrorText),
    );

final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/auth',
  debugLogDiagnostics: false,
  refreshListenable: isCheckingAuth,
  redirect: (context, state) => startupRedirect(
    isCheckingAuth: isCheckingAuth.value,
    location: state.uri.path,
    initialRoute: initialRoute.value,
  ),
  routes: [
    _dataRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardScreen(),
    ),
    _dataRoute(
      path: '/banned',
      builder: (context, state) => const BannedScreen(),
    ),
    _dataRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    _dataRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
      routes: [
        _dataRoute(
          path: 'verify',
          builder: (context, state) => LoginOtpScreen(phone: state.extra as String),
        ),
        _dataRoute(
          path: 'role',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        _dataRoute(
          path: 'fill_data',
          builder: (context, state) => const FillDataScreen(),
        ),
        _dataRoute(
          path: 'city_search',
          builder: (context, state) => CitySearchScreen(onSelected: state.extra as Function(String)),
        ),
        _dataRoute(
          path: 'take_subscription_plan',
          builder: (context, state) => const TakeSubscriptionPlanScreen(),
        ),
        _dataRoute(
          path: 'kid_signup_success',
          builder: (context, state) => const KidSignupSuccessScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => KidMainScreen(state: state, child: child),
      routes: [
        _dataRoute(
          path: '/kid_bonus',
          builder: (context, state) => const BonusTabScreen(),
        ),
        _dataRoute(
          path: '/kid_task',
          builder: (context, state) => const TaskTabScreen(),
        ),
        _dataRoute(
          path: '/kid_games',
          builder: (context, state) => const GamesTabScreen(),
        ),
        _dataRoute(
          path: '/kid_chat',
          builder: (context, state) => const ChatTabScreen(),
        ),
        _dataRoute(
          path: '/kid_profile',
          builder: (context, state) => const ProfileTabScreen(),
          routes: [
            _dataRoute(
              path: 'edit',
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => MentorMainScreen(state: state, child: child),
      routes: [
        _dataRoute(
          path: '/mentor_task',
          builder: (context, state) => const TaskTabScreen(),
        ),
        _dataRoute(
          path: '/mentor_bonus',
          builder: (context, state) => const BonusTabScreen(),
        ),
        _dataRoute(
          path: '/mentor_chat',
          builder: (context, state) => const ChatTabScreen(),
        ),
        _dataRoute(
          path: '/mentor_profile',
          builder: (context, state) => const ProfileTabScreen(),
          routes: [
            _dataRoute(
              path: 'scan_qr',
              builder: (context, state) => const ScanQRScreen(),
            ),
          ],
        ),
      ],
    ),
    _dataRoute(
      path: '/current_subscription',
      builder: (context, state) => const CurrentSubscriptionScreen(),
    ),
    _dataRoute(
      path: '/edit_profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    _dataRoute(
      path: '/notification',
      builder: (context, state) => const NotificationScreen(),
    ),
    _dataRoute(
      path: '/connections',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        final user = extra['user'] as UserModel;
        final canAdd = extra['canAdd'] as bool? ?? true;
        final showChat = extra['showChat'] as bool? ?? true;
        final showDelete = extra['showDelete'] as bool? ?? true;
        return MyConnectionsScreen(
          user: user,
          canAdd: canAdd,
          showChat: showChat,
          showDelete: showDelete,
        );
      },
      routes: [
        _dataRoute(
          path: 'add_connection',
          builder: (context, state) => const AddConnectionScreen(),
          routes: [
            _dataRoute(
              path: 'scan_qr',
              builder: (context, state) => const ScanQRScreen(),
            ),
          ],
        ),
      ],
    ),
    _dataRoute(
      path: '/city_search',
      builder: (context, state) => CitySearchScreen(onSelected: state.extra as Function(String)),
    ),
    _dataRoute(
      path: '/logout_result',
      builder: (context, state) => LogoutResultScreen(message: state.extra as String),
    ),
    _dataRoute(
      path: '/add_chat',
      builder: (context, state) => const AddChatScreen(),
    ),
    _dataRoute(
      path: '/new_chat_success',
      builder: (context, state) => NewChatSuccessCreateScreen(ref: state.extra as DocumentReference),
    ),
    _dataRoute(
      path: '/chat_room',
      builder: (context, state) => ChatRoomScreen(chatRef: state.extra as DocumentReference),
      routes: [
        _dataRoute(
          path: '/edit_chat',
          builder: (context, state) => EditChatScreen(chat: state.extra as ChatModel),
        ),
        _dataRoute(
          path: '/members',
          builder: (context, state) => EditChatMembersScreen(chat: state.extra as ChatModel),
        ),
        _dataRoute(
          path: '/add_member',
          builder: (context, state) => EditChatAddMembersScreen(chat: state.extra as ChatModel),
        ),
        _dataRoute(
          path: '/edit_photo',
          builder: (context, state) => EditChatPhotoScreen(chat: state.extra as ChatModel),
        ),
        _dataRoute(
          path: '/edit_name',
          builder: (context, state) => EditChatNameScreen(chat: state.extra as ChatModel),
        ),
      ],
    ),
    _dataRoute(
      path: '/kid_create_task',
      builder: (context, state) => const CreateKidTaskScreen(),
      routes: [
        _dataRoute(
          path: 'success',
          builder: (context, state) => const CreateTaskSuccessScreen(),
        ),
      ],
    ),
    _dataRoute(
      path: '/mentor_create_task',
      builder: (context, state) => const CreateMentorTaskScreen(),
      routes: [
        _dataRoute(
          path: 'success',
          builder: (context, state) => const CreateTaskSuccessScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        final task = state.extra;
        if (task is! TaskModel) return ErrorScreen(error: defaultErrorText);
        return BlocProvider(
          create: (context) => KidTaskEditCubit(userCubit: sl(), task: task)..init(),
          child: child,
        );
      },
      routes: [
        _dataRoute(
          path: '/edit_create_task',
          builder: (context, state) => EditKidTaskScreen(task: state.extra as TaskModel),
          routes: [
            _dataRoute(
              path: 'name',
              builder: (context, state) => const KidTaskEditNameScreen(),
            ),
            _dataRoute(
              path: 'photo',
              builder: (context, state) => const KidTaskEditPhotoScreen(),
            ),
            _dataRoute(
              path: 'startDate',
              builder: (context, state) => const KidTaskEditStartDateScreen(),
            ),
            _dataRoute(
              path: 'endDate',
              builder: (context, state) => const KidTaskEditEndDateScreen(),
            ),
            _dataRoute(
              path: 'reminer',
              builder: (context, state) => const KidTaskEditReminderScreen(),
            ),
          ],
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        final task = state.extra;
        if (task is! TaskModel) return ErrorScreen(error: defaultErrorText);
        return BlocProvider(
          create: (context) => MentorTaskEditCubit(userCubit: sl(), task: task)..init(),
          child: child,
        );
      },
      routes: [
        _dataRoute(
          path: '/edit_mentor_create_task',
          builder: (context, state) => EditMentorTaskScreen(task: state.extra as TaskModel),
          routes: [
            _dataRoute(
              path: 'name',
              builder: (context, state) => const MentorTaskEditNameScreen(),
            ),
            _dataRoute(
              path: 'photo',
              builder: (context, state) => const MentorTaskEditPhotoScreen(),
            ),
            _dataRoute(
              path: 'startDate',
              builder: (context, state) => const MentorTaskEditStartDateScreen(),
            ),
            _dataRoute(
              path: 'endDate',
              builder: (context, state) => const MentorTaskEditEndDateScreen(),
            ),
            _dataRoute(
              path: 'reminer',
              builder: (context, state) => const MentorTaskEditReminderScreen(),
            ),
            _dataRoute(
              path: 'kid',
              builder: (context, state) => const MentorTaskEditKidScreen(),
            ),
            _dataRoute(
              path: 'point',
              builder: (context, state) => const MentorTaskEditPointScreen(),
            ),
          ],
        ),
      ],
    ),
    _dataRoute(
      path: '/task_detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final taskRef = extra['taskRef'] as DocumentReference;
        final task = extra['task'] as TaskModel?;
        return TaskDetailScreen(taskRef: taskRef, task: task);
      },
    ),
    _dataRoute(
      path: '/task_dialog',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final taskRef = extra['taskRef'] as DocumentReference;
        final task = extra['task'] as TaskModel?;
        final isRework = extra['is_rework'] as bool? ?? false;
        return TaskDialogScreen(taskRef: taskRef, task: task, isRework: isRework);
      },
    ),
    _dataRoute(
      path: '/task_execution_dialog',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final taskRef = extra['taskRef'] as DocumentReference;
        final task = extra['task'] as TaskModel?;
        return TaskExecutionDialogScreen(taskRef: taskRef, task: task);
      },
    ),
    _dataRoute(
      path: '/task_send_review_success',
      builder: (context, state) => const TaskSendReviewSuccessScreen(),
    ),
    _dataRoute(
      path: '/task_send_rework_success',
      builder: (context, state) => const TaskSendReworkSuccessScreen(),
    ),
    _dataRoute(
      path: '/task_cancel_reason',
      builder: (context, state) => TaskCancelReasonScreen(task: state.extra as TaskModel),
    ),
    _dataRoute(
      path: '/popular_tasks',
      builder: (context, state) => PopularSuggestsScreen(popularTasks: state.extra as List<TaskModel>),
    ),
    _dataRoute(
      path: '/task_delete_success',
      builder: (context, state) => const DeleteTaskSuccessScreen(),
    ),
    _dataRoute(
      path: '/task_complete_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final name = extra['name'] as String?;
        final coin = extra['coin'] as int?;
        return TaskCompleteSuccessScreen(userName: name, coin: coin);
      },
    ),
    _dataRoute(
      path: '/kid_detail',
      builder: (context, state) => KidDetailScreen(kidRef: state.extra as DocumentReference),
    ),
    _dataRoute(
      path: '/kid_coins',
      builder: (context, state) => KidCoinsScreen(kid: state.extra as UserModel),
      routes: [
        _dataRoute(
          path: 'change',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            bool isIncrease = data['isIncrease'] as bool;
            UserModel kid = data['kid'] as UserModel;
            return ChangeKidPointScreen(isIncrease: isIncrease, kid: kid);
          },
        ),
        _dataRoute(
          path: 'success',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            int amount = data['amount'] as int;
            String kidName = data['kidName'] as String;
            return CoinChangeSuccessScreen(kidName: kidName, coinAmount: amount);
          },
        ),
      ],
    ),
    _dataRoute(
      path: '/kid_progress',
      builder: (context, state) => KidProgressScreen(kid: state.extra as UserModel),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(create: (context) => DairyCubit(userCubit: sl()), child: child);
      },
      routes: [
        _dataRoute(
          path: '/dairy',
          builder: (context, state) => DairyScreen(user: state.extra as UserModel),
          routes: [
            _dataRoute(
              path: 'add',
              builder: (context, state) => const AddDairyScreen(),
            ),
            _dataRoute(
              path: 'edit',
              builder: (context, state) => EditDairyScreen(dairy: state.extra as DairyModel),
            ),
            _dataRoute(
              path: 'setting',
              builder: (context, state) => const DairySettingScreen(),
            ),
            _dataRoute(
              path: 'members',
              builder: (context, state) => const DairyMembersScreen(),
            ),
            _dataRoute(
              path: 'add_member',
              builder: (context, state) => const AddMemberToDairyScreen(),
            ),
            _dataRoute(
              path: 'dairy_success',
              builder: (context, state) => const AddDairySuccessScreen(),
            ),
          ],
        ),
      ],
    ),
    _dataRoute(
      path: '/game_raiting',
      builder: (context, state) => const GameRaitingScreen(),
    ),
    _dataRoute(
      path: '/game_level',
      builder: (context, state) => const GameLevelScreen(),
    ),
    _dataRoute(
      path: '/level_detail',
      builder: (context, state) => ArticleDetailScreen(article: state.extra as ArticleModel),
    ),
    _dataRoute(
      path: '/game_play',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final gameRef = data['gameRef'] as DocumentReference;
        final level = data['level'] as LevelModel;
        final nextLevel = data['next_level'] as LevelModel?;

        return GamePlayScreen(gameRef: gameRef, level: level, nextLevel: nextLevel);
      },
    ),
    _dataRoute(
      path: '/game_complete',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final game = data['game'] as GameModel;
        final level = data['level'] as LevelModel;
        final correctAnswers = data['correctAnswers'] as int;

        return GameCompleteScreen(game: game, level: level, correctAnswers: correctAnswers);
      },
    ),
    _dataRoute(
      path: '/level_up',
      builder: (context, state) => LevelUpScreen(level: state.extra as LevelModel),
    ),
    _dataRoute(
      path: '/level_trophey_up',
      builder: (context, state) => LevelTokenUpScreen(level: state.extra as LevelModel),
    ),
    _dataRoute(
      path: '/change_lang',
      builder: (context, state) => const ChangeLangScreen(),
    ),
    _dataRoute(
      path: '/create_bonus',
      builder: (context, state) => const CreateBonusScreen(),
      routes: [
        _dataRoute(
          path: 'success',
          builder: (context, state) => const CreateBonusSuccessScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        final bonus = state.extra;
        if (bonus is! BonusModel) return ErrorScreen(error: defaultErrorText);
        return BlocProvider(
          create: (context) => EditBonusCubit(userCubit: sl(), bonus: bonus)..init(),
          child: child,
        );
      },
      routes: [
        _dataRoute(
          path: '/edit_bonus',
          builder: (context, state) => EditBonusScreen(bonus: state.extra as BonusModel),
          routes: [
            _dataRoute(
              path: 'name',
              builder: (context, state) => const BonusEditNameScreen(),
            ),
            _dataRoute(
              path: 'photo',
              builder: (context, state) => const BonusEditPhotoScreen(),
            ),
            _dataRoute(
              path: 'link',
              builder: (context, state) => const BonusEditLinkScreen(),
            ),
            _dataRoute(
              path: 'point',
              builder: (context, state) => const BonusEditPointScreen(),
            ),
            _dataRoute(
              path: 'mentor_or_kid',
              builder: (context, state) => const BonusEditKidOrMentorScreen(),
            ),
          ],
        ),
      ],
    ),
    _dataRoute(
      path: '/bonus_cancel_reason',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final bonus = extra['bonus'] as BonusModel;
        final isCancel = extra['isCancel'] as bool? ?? false;
        return BonusCancelReasonScreen(bonus: bonus, isCancel: isCancel);
      },
    ),
    _dataRoute(
      path: '/approve_bonus_set_point',
      builder: (context, state) => ApproveBonusSetPointScreen(bonus: state.extra as BonusModel),
    ),
    _dataRoute(
      path: '/bonus_delete_success',
      builder: (context, state) => const DeleteBonusSuccessScreen(),
    ),
    _dataRoute(
      path: '/bonus_detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final bonusRef = extra['bonusRef'] as DocumentReference;
        final bonus = extra['bonus'] as BonusModel?;
        return BonusDetailScreen(bonusRef: bonusRef, bonus: bonus);
      },
    ),
    _dataRoute(
      path: '/bonus_request_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final mentorRef = extra['mentorRef'] as DocumentReference;
        final bonusName = extra['bonusName'] as String;
        return RequestBonusSentSuccessScreen(bonusName: bonusName, mentorRef: mentorRef);
      },
    ),
    _dataRoute(
      path: '/bonus_received_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final mentorRef = extra['mentorRef'] as DocumentReference;
        final kidRef = extra['kidRef'] as DocumentReference;
        final bonusName = extra['bonusName'] as String;
        return BonusReceivedSuccessScreen(bonusName: bonusName, mentorRef: mentorRef, kidRef: kidRef);
      },
    ),
    _dataRoute(
      path: '/select_plan',
      builder: (context, state) => const SelectPlanScreen(),
    ),
    _dataRoute(
      path: '/select_user_for_gift',
      builder: (context, state) => const SelectUserForGiftScreen(),
    ),
    _dataRoute(
      path: '/purchase_plan',
      builder: (context, state) {
        final data = state.extra as Map;
        final url = data['url'];
        final orderId = data['order_id'];
        return PurchasePaymentScreen(url: url, orderId: orderId);
      },
    ),
    _dataRoute(
      path: '/all_gifts',
      builder: (context, state) => AllGiftsScreen(orders: state.extra as List<DocumentSnapshot>),
    ),
    _dataRoute(
      path: '/payment_success',
      builder: (context, state) => PaymentSuccessScreen(receiver: state.extra as String?),
    ),
    _dataRoute(
      path: '/error_screen',
      builder: (context, state) => ErrorScreen(error: state.extra as String? ?? defaultErrorText),
    ),
  ],
  errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),
);
