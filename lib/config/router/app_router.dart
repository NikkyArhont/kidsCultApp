import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
    UserModel? userModel = context.read<UserCubit>().state;
    late DocumentSnapshot userSnap;

    if (userModel == null) {
      final User user = FirebaseAuth.instance.currentUser!;
      userSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userSnap.exists) {
        await FirebaseAuth.instance.signOut();
        return UserInitialStatus.noFound;
      }

      userModel = UserModel.fromFirestore(userSnap);
      if (context.mounted) context.read<UserCubit>().setUser(userModel);
    }

    if (userModel.banned) return UserInitialStatus.banned;
    if (userModel.profileFilled) {
      userModel = UserModel.fromFirestore(userSnap);
      if (context.mounted) context.read<UserCubit>().setUser(userModel);
      return userModel.isKid ? UserInitialStatus.successKid : UserInitialStatus.successMentor;
    } else {
      return userModel.isKid ? UserInitialStatus.fillProfileKid : UserInitialStatus.fillProfileMentor;
    }
  } catch (e) {
    print('$defaultErrorText {getUserStatus}: $e');
    SnackBarSerive.showErrorSnackBar(defaultErrorText);
    FirebaseCrashlytics.instance.recordError(e, null);
    return UserInitialStatus.noFound;
  }
}

final ValueNotifier<bool> isRedirectLoading = ValueNotifier(false);

Future<void> redirectFunc(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final isAuth = user != null;

    if (isAuth) {
      final userStatus = await getUserStatus(context);
      FlutterNativeSplash.remove();
      initialRoute.value = getRouteForStatus(userStatus);
    } else {
      final storageService = sl<StorageService>();
      bool showed = storageService.isOnboardShowed();
      FlutterNativeSplash.remove();
      if (!showed) {
        initialRoute.value = '/onboarding';
      } else {
        initialRoute.value = null;
      }
    }

    isCheckingAuth.value = false;
    isFirstRedirect.value = false;
  } catch (err) {
    FlutterNativeSplash.remove();
    SnackBarSerive.showErrorSnackBar(defaultErrorText);
    FirebaseCrashlytics.instance.recordError(err, null);
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
    default:
      return '/error_screen';
  }
}

final ValueNotifier<bool> isCheckingAuth = ValueNotifier(true);
final ValueNotifier<bool> isFirstRedirect = ValueNotifier(true);
final ValueNotifier<String?> initialRoute = ValueNotifier(null);

final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/auth',
  debugLogDiagnostics: false,
  refreshListenable: isCheckingAuth,
  redirect: (context, state) async {
    if (isCheckingAuth.value) return '/splash';
    return isFirstRedirect.value ? initialRoute.value : null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardScreen(),
    ),
    GoRoute(
      path: '/banned',
      builder: (context, state) => const BannedScreen(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
      routes: [
        GoRoute(
          path: 'verify',
          builder: (context, state) => LoginOtpScreen(phone: state.extra as String),
        ),
        GoRoute(
          path: 'role',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: 'fill_data',
          builder: (context, state) => const FillDataScreen(),
        ),
        GoRoute(
          path: 'city_search',
          builder: (context, state) => CitySearchScreen(onSelected: state.extra as Function(String)),
        ),
        GoRoute(
          path: 'take_subscription_plan',
          builder: (context, state) => const TakeSubscriptionPlanScreen(),
        ),
        GoRoute(
          path: 'kid_signup_success',
          builder: (context, state) => const KidSignupSuccessScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => KidMainScreen(state: state, child: child),
      routes: [
        GoRoute(
          path: '/kid_bonus',
          builder: (context, state) => const BonusTabScreen(),
        ),
        GoRoute(
          path: '/kid_task',
          builder: (context, state) => const TaskTabScreen(),
        ),
        GoRoute(
          path: '/kid_games',
          builder: (context, state) => const GamesTabScreen(),
        ),
        GoRoute(
          path: '/kid_chat',
          builder: (context, state) => const ChatTabScreen(),
        ),
        GoRoute(
          path: '/kid_profile',
          builder: (context, state) => const ProfileTabScreen(),
          routes: [
            GoRoute(
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
        GoRoute(
          path: '/mentor_task',
          builder: (context, state) => const TaskTabScreen(),
        ),
        GoRoute(
          path: '/mentor_bonus',
          builder: (context, state) => const BonusTabScreen(),
        ),
        GoRoute(
          path: '/mentor_chat',
          builder: (context, state) => const ChatTabScreen(),
        ),
        GoRoute(
          path: '/mentor_profile',
          builder: (context, state) => const ProfileTabScreen(),
          routes: [
            GoRoute(
              path: 'scan_qr',
              builder: (context, state) => const ScanQRScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/current_subscription',
      builder: (context, state) => const CurrentSubscriptionScreen(),
    ),
    GoRoute(
      path: '/edit_profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/notification',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
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
        GoRoute(
          path: 'add_connection',
          builder: (context, state) => const AddConnectionScreen(),
          routes: [
            GoRoute(
              path: 'scan_qr',
              builder: (context, state) => const ScanQRScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/city_search',
      builder: (context, state) => CitySearchScreen(onSelected: state.extra as Function(String)),
    ),
    GoRoute(
      path: '/logout_result',
      builder: (context, state) => LogoutResultScreen(message: state.extra as String),
    ),
    GoRoute(
      path: '/add_chat',
      builder: (context, state) => const AddChatScreen(),
    ),
    GoRoute(
      path: '/new_chat_success',
      builder: (context, state) => NewChatSuccessCreateScreen(ref: state.extra as DocumentReference),
    ),
    GoRoute(
      path: '/chat_room',
      builder: (context, state) => ChatRoomScreen(chatRef: state.extra as DocumentReference),
      routes: [
        GoRoute(
          path: '/edit_chat',
          builder: (context, state) => EditChatScreen(chat: state.extra as ChatModel),
        ),
        GoRoute(
          path: '/members',
          builder: (context, state) => EditChatMembersScreen(chat: state.extra as ChatModel),
        ),
        GoRoute(
          path: '/add_member',
          builder: (context, state) => EditChatAddMembersScreen(chat: state.extra as ChatModel),
        ),
        GoRoute(
          path: '/edit_photo',
          builder: (context, state) => EditChatPhotoScreen(chat: state.extra as ChatModel),
        ),
        GoRoute(
          path: '/edit_name',
          builder: (context, state) => EditChatNameScreen(chat: state.extra as ChatModel),
        ),
      ],
    ),
    GoRoute(
      path: '/kid_create_task',
      builder: (context, state) => const CreateKidTaskScreen(),
      routes: [
        GoRoute(
          path: 'success',
          builder: (context, state) => const CreateTaskSuccessScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/mentor_create_task',
      builder: (context, state) => const CreateMentorTaskScreen(),
      routes: [
        GoRoute(
          path: 'success',
          builder: (context, state) => const CreateTaskSuccessScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        final task = state.extra as TaskModel;
        return BlocProvider(
          create: (context) => KidTaskEditCubit(userCubit: sl(), task: task)..init(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/edit_create_task',
          builder: (context, state) => EditKidTaskScreen(task: state.extra as TaskModel),
          routes: [
            GoRoute(
              path: 'name',
              builder: (context, state) => const KidTaskEditNameScreen(),
            ),
            GoRoute(
              path: 'photo',
              builder: (context, state) => const KidTaskEditPhotoScreen(),
            ),
            GoRoute(
              path: 'startDate',
              builder: (context, state) => const KidTaskEditStartDateScreen(),
            ),
            GoRoute(
              path: 'endDate',
              builder: (context, state) => const KidTaskEditEndDateScreen(),
            ),
            GoRoute(
              path: 'reminer',
              builder: (context, state) => const KidTaskEditReminderScreen(),
            ),
          ],
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        final task = state.extra as TaskModel;
        return BlocProvider(
          create: (context) => MentorTaskEditCubit(userCubit: sl(), task: task)..init(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/edit_mentor_create_task',
          builder: (context, state) => EditMentorTaskScreen(task: state.extra as TaskModel),
          routes: [
            GoRoute(
              path: 'name',
              builder: (context, state) => const MentorTaskEditNameScreen(),
            ),
            GoRoute(
              path: 'photo',
              builder: (context, state) => const MentorTaskEditPhotoScreen(),
            ),
            GoRoute(
              path: 'startDate',
              builder: (context, state) => const MentorTaskEditStartDateScreen(),
            ),
            GoRoute(
              path: 'endDate',
              builder: (context, state) => const MentorTaskEditEndDateScreen(),
            ),
            GoRoute(
              path: 'reminer',
              builder: (context, state) => const MentorTaskEditReminderScreen(),
            ),
            GoRoute(
              path: 'kid',
              builder: (context, state) => const MentorTaskEditKidScreen(),
            ),
            GoRoute(
              path: 'point',
              builder: (context, state) => const MentorTaskEditPointScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/task_detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final taskRef = extra['taskRef'] as DocumentReference;
        final task = extra['task'] as TaskModel?;
        return TaskDetailScreen(taskRef: taskRef, task: task);
      },
    ),
    GoRoute(
      path: '/task_dialog',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final taskRef = extra['taskRef'] as DocumentReference;
        final task = extra['task'] as TaskModel?;
        final isRework = extra['is_rework'] as bool? ?? false;
        return TaskDialogScreen(taskRef: taskRef, task: task, isRework: isRework);
      },
    ),
    GoRoute(
      path: '/task_execution_dialog',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final taskRef = extra['taskRef'] as DocumentReference;
        final task = extra['task'] as TaskModel?;
        return TaskExecutionDialogScreen(taskRef: taskRef, task: task);
      },
    ),
    GoRoute(
      path: '/task_send_review_success',
      builder: (context, state) => const TaskSendReviewSuccessScreen(),
    ),
    GoRoute(
      path: '/task_send_rework_success',
      builder: (context, state) => const TaskSendReworkSuccessScreen(),
    ),
    GoRoute(
      path: '/task_cancel_reason',
      builder: (context, state) => TaskCancelReasonScreen(task: state.extra as TaskModel),
    ),
    GoRoute(
      path: '/popular_tasks',
      builder: (context, state) => PopularSuggestsScreen(popularTasks: state.extra as List<TaskModel>),
    ),
    GoRoute(
      path: '/task_delete_success',
      builder: (context, state) => const DeleteTaskSuccessScreen(),
    ),
    GoRoute(
      path: '/task_complete_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final name = extra['name'] as String?;
        final coin = extra['coin'] as int?;
        return TaskCompleteSuccessScreen(userName: name, coin: coin);
      },
    ),
    GoRoute(
      path: '/kid_detail',
      builder: (context, state) => KidDetailScreen(kidRef: state.extra as DocumentReference),
    ),
    GoRoute(
      path: '/kid_coins',
      builder: (context, state) => KidCoinsScreen(kid: state.extra as UserModel),
      routes: [
        GoRoute(
          path: 'change',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            bool isIncrease = data['isIncrease'] as bool;
            UserModel kid = data['kid'] as UserModel;
            return ChangeKidPointScreen(isIncrease: isIncrease, kid: kid);
          },
        ),
        GoRoute(
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
    GoRoute(
      path: '/kid_progress',
      builder: (context, state) => KidProgressScreen(kid: state.extra as UserModel),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return BlocProvider(create: (context) => DairyCubit(userCubit: sl()), child: child);
      },
      routes: [
        GoRoute(
          path: '/dairy',
          builder: (context, state) => DairyScreen(user: state.extra as UserModel),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddDairyScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) => EditDairyScreen(dairy: state.extra as DairyModel),
            ),
            GoRoute(
              path: 'setting',
              builder: (context, state) => const DairySettingScreen(),
            ),
            GoRoute(
              path: 'members',
              builder: (context, state) => const DairyMembersScreen(),
            ),
            GoRoute(
              path: 'add_member',
              builder: (context, state) => const AddMemberToDairyScreen(),
            ),
            GoRoute(
              path: 'dairy_success',
              builder: (context, state) => const AddDairySuccessScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/game_raiting',
      builder: (context, state) => const GameRaitingScreen(),
    ),
    GoRoute(
      path: '/game_level',
      builder: (context, state) => const GameLevelScreen(),
    ),
    GoRoute(
      path: '/level_detail',
      builder: (context, state) => ArticleDetailScreen(article: state.extra as ArticleModel),
    ),
    GoRoute(
      path: '/game_play',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final gameRef = data['gameRef'] as DocumentReference;
        final level = data['level'] as LevelModel;
        final nextLevel = data['next_level'] as LevelModel?;

        return GamePlayScreen(gameRef: gameRef, level: level, nextLevel: nextLevel);
      },
    ),
    GoRoute(
      path: '/game_complete',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        final game = data['game'] as GameModel;
        final level = data['level'] as LevelModel;
        final correctAnswers = data['correctAnswers'] as int;

        return GameCompleteScreen(game: game, level: level, correctAnswers: correctAnswers);
      },
    ),
    GoRoute(
      path: '/level_up',
      builder: (context, state) => LevelUpScreen(level: state.extra as LevelModel),
    ),
    GoRoute(
      path: '/level_trophey_up',
      builder: (context, state) => LevelTokenUpScreen(level: state.extra as LevelModel),
    ),
    GoRoute(
      path: '/change_lang',
      builder: (context, state) => const ChangeLangScreen(),
    ),
    GoRoute(
      path: '/create_bonus',
      builder: (context, state) => const CreateBonusScreen(),
      routes: [
        GoRoute(
          path: 'success',
          builder: (context, state) => const CreateBonusSuccessScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) {
        final bonus = state.extra as BonusModel;
        return BlocProvider(
          create: (context) => EditBonusCubit(userCubit: sl(), bonus: bonus)..init(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/edit_bonus',
          builder: (context, state) => EditBonusScreen(bonus: state.extra as BonusModel),
          routes: [
            GoRoute(
              path: 'name',
              builder: (context, state) => const BonusEditNameScreen(),
            ),
            GoRoute(
              path: 'photo',
              builder: (context, state) => const BonusEditPhotoScreen(),
            ),
            GoRoute(
              path: 'link',
              builder: (context, state) => const BonusEditLinkScreen(),
            ),
            GoRoute(
              path: 'point',
              builder: (context, state) => const BonusEditPointScreen(),
            ),
            GoRoute(
              path: 'mentor_or_kid',
              builder: (context, state) => const BonusEditKidOrMentorScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/bonus_cancel_reason',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final bonus = extra['bonus'] as BonusModel;
        final isCancel = extra['isCancel'] as bool? ?? false;
        return BonusCancelReasonScreen(bonus: bonus, isCancel: isCancel);
      },
    ),
    GoRoute(
      path: '/approve_bonus_set_point',
      builder: (context, state) => ApproveBonusSetPointScreen(bonus: state.extra as BonusModel),
    ),
    GoRoute(
      path: '/bonus_delete_success',
      builder: (context, state) => const DeleteBonusSuccessScreen(),
    ),
    GoRoute(
      path: '/bonus_detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final bonusRef = extra['bonusRef'] as DocumentReference;
        final bonus = extra['bonus'] as BonusModel?;
        return BonusDetailScreen(bonusRef: bonusRef, bonus: bonus);
      },
    ),
    GoRoute(
      path: '/bonus_request_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final mentorRef = extra['mentorRef'] as DocumentReference;
        final bonusName = extra['bonusName'] as String;
        return RequestBonusSentSuccessScreen(bonusName: bonusName, mentorRef: mentorRef);
      },
    ),
    GoRoute(
      path: '/bonus_received_success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final mentorRef = extra['mentorRef'] as DocumentReference;
        final kidRef = extra['kidRef'] as DocumentReference;
        final bonusName = extra['bonusName'] as String;
        return BonusReceivedSuccessScreen(bonusName: bonusName, mentorRef: mentorRef, kidRef: kidRef);
      },
    ),
    GoRoute(
      path: '/select_plan',
      builder: (context, state) => const SelectPlanScreen(),
    ),
    GoRoute(
      path: '/select_user_for_gift',
      builder: (context, state) => const SelectUserForGiftScreen(),
    ),
    GoRoute(
      path: '/purchase_plan',
      builder: (context, state) {
        final data = state.extra as Map;
        final url = data['url'];
        final orderId = data['order_id'];
        return PurchasePaymentScreen(url: url, orderId: orderId);
      },
    ),
    GoRoute(
      path: '/all_gifts',
      builder: (context, state) => AllGiftsScreen(orders: state.extra as List<DocumentSnapshot>),
    ),
    GoRoute(
      path: '/payment_success',
      builder: (context, state) => PaymentSuccessScreen(receiver: state.extra as String?),
    ),
    GoRoute(
      path: '/error_screen',
      builder: (context, state) => ErrorScreen(error: state.extra as String? ?? defaultErrorText),
    ),
  ],
  errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),
);
