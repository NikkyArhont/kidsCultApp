import 'dart:async';
import 'dart:developer';

import 'package:child_tracker/index.dart';
import 'package:child_tracker/shared/services/notification_deduplicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;

class FirebaseMessaginService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _fs;
  final UserCubit _userCubit;
  final cf.FirebaseFunctions _functions;
  final LocalNotificationService _localPush;
  final CurrentChatCubit _currentChatCubit;

  FirebaseMessaginService({
    required FirebaseMessaging fcm,
    required FirebaseFirestore fs,
    required UserCubit appUserCubit,
    required cf.FirebaseFunctions functions,
    required LocalNotificationService localNotificationService,
    required CurrentChatCubit currentChatCubit,
  })  : _fs = fs,
        _fcm = fcm,
        _localPush = localNotificationService,
        _userCubit = appUserCubit,
        _currentChatCubit = currentChatCubit,
        _functions = functions;

  final NotificationDeduplicator _delivered = NotificationDeduplicator();
  final NotificationDeduplicator _opened = NotificationDeduplicator();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  Future<void>? _setupFuture;
  String? _activeUserId;
  int _sessionGeneration = 0;
  bool _readInitialMessage = false;

  /// Own one set of listeners per signed-in session, independently of shell pages.
  Future<void> setupFCM() {
    final userId = _userCubit.state?.id;
    if (userId == null) return Future.value();
    if (_activeUserId == userId && _setupFuture != null) return _setupFuture!;
    _activeUserId = userId;
    final generation = ++_sessionGeneration;
    return _setupFuture = _setupFCM(userId, generation);
  }

  bool _isCurrentSession(String userId, int generation) =>
      generation == _sessionGeneration && _activeUserId == userId && _userCubit.state?.id == userId;

  Future<void> _setupFCM(String userId, int generation) async {
    await _cancelSubscriptions();
    if (!_isCurrentSession(userId, generation)) return;
    _delivered.clear();
    _opened.clear();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      if (_isCurrentSession(userId, generation)) {
        _onForegroundMessage(message, userId, generation);
      }
    });
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (_isCurrentSession(userId, generation)) _openMessage(message);
    });
    _tokenSubscription = _fcm.onTokenRefresh.listen((token) {
      unawaited(_setFCMToken(token, userId, generation));
    }, onError: (Object error) {
      log('FCM token refresh failed', error: error);
    });

    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      if (!_isCurrentSession(userId, generation)) return;
      await _setFCMToken(await _fcm.getToken(), userId, generation);
    } catch (error) {
      // Notification permission/token failures must not break the app shell.
      log('FCM setup failed', error: error);
    }
    if (!_isCurrentSession(userId, generation)) return;

    if (!_readInitialMessage) {
      try {
        final message = await _fcm.getInitialMessage();
        _readInitialMessage = true;
        if (message != null && _isCurrentSession(userId, generation)) {
          _openMessage(message);
        }
      } catch (error) {
        log('FCM initial message failed', error: error);
      }
    }

    if (!kIsWeb && _isCurrentSession(userId, generation) && _userCubit.state?.isKid == true) {
      try {
        await _localPush.setDailyDiaryReminder(_userCubit.state?.dairyNotification ?? true);
      } catch (error) {
        log('Diary notification setup failed', error: error);
      }
    }
  }

  void _onForegroundMessage(RemoteMessage message, String userId, int generation) {
    final notification = message.notification;
    if (notification == null || !_delivered.accept(message.messageId)) return;
    final type = notificationTypeFromString(message.data['type']);
    if (type == NotificationType.chat && _currentChatCubit.state == message.data['chat_id']) {
      return;
    }
    if (type == NotificationType.gift) {
      unawaited(_refreshProfile());
    }
    SnackBarSerive.showSnackBarOnReceivePushNotification(
      notification.title ?? 'Notification',
      notification.body,
      () {
        // A toast from a previous login must not open data in the next session.
        if (_isCurrentSession(userId, generation)) _openMessage(message);
      },
    );
  }

  Future<void> _refreshProfile() async {
    try {
      await _userCubit.refreshProfile();
    } catch (error) {
      log('Profile refresh after notification failed', error: error);
    }
  }

  void _openMessage(RemoteMessage message) {
    final user = _userCubit.state;
    if (user == null || navigatorKey.currentState == null) return;
    final data = message.data;
    final type = notificationTypeFromString(data['type']);
    final taskTypes = {
      NotificationType.reminder,
      NotificationType.taskComplete,
      NotificationType.taskRework,
      NotificationType.taskCanceled,
      NotificationType.taskDeleted,
      NotificationType.taskCreated,
      NotificationType.taskReview,
    };
    final bonusTypes = {
      NotificationType.bonusCreated,
      NotificationType.bonusNeedApprove,
      NotificationType.bonusCanceled,
      NotificationType.bonusRejected,
      NotificationType.bonusApproved,
      NotificationType.bonusRequested,
      NotificationType.bonusRequestApproved,
    };
    // Receiving a foreground notification and opening it are separate events.
    if (!_opened.accept(message.messageId)) return;
    if (taskTypes.contains(type)) {
      final id = data['task_id'];
      if (id is! String || id.isEmpty || id.contains('/')) return;
      router.push('/task_detail', extra: {'task': null, 'taskRef': _fs.collection('tasks').doc(id)});
    } else if (bonusTypes.contains(type)) {
      final id = data['bonus_id'];
      if (id is! String || id.isEmpty || id.contains('/')) return;
      router.push('/bonus_detail', extra: {'bonus': null, 'bonusRef': _fs.collection('bonuses').doc(id)});
    } else if (type == NotificationType.coinChange) {
      router.push('/kid_coins', extra: user);
    } else if (type == NotificationType.chat) {
      final id = data['chat_id'];
      if (id is! String || id.isEmpty || id.contains('/')) return;
      router.push('/chat_room', extra: _fs.collection('chats').doc(id));
    } else if (type == NotificationType.gift) {
      router.go(user.isKid ? '/kid_profile' : '/mentor_profile');
    }
  }

  Future<void> stop() async {
    ++_sessionGeneration;
    _activeUserId = null;
    _setupFuture = null;
    _delivered.clear();
    _opened.clear();
    await _cancelSubscriptions();
  }

  Future<void> _cancelSubscriptions() async {
    final message = _messageSubscription;
    final opened = _openedSubscription;
    final token = _tokenSubscription;
    _messageSubscription = null;
    _openedSubscription = null;
    _tokenSubscription = null;
    await Future.wait([
      if (message != null) message.cancel(),
      if (opened != null) opened.cancel(),
      if (token != null) token.cancel(),
    ]);
  }

  Future<void> _setFCMToken(String? token, String userId, int generation) async {
    if (token == null || !_isCurrentSession(userId, generation)) return;
    try {
      await _userCubit.state?.ref.update({'fcm_token': token});
    } catch (error) {
      log('Saving FCM token failed', error: error);
    }
  }

  //Пуш ребенку, когда ментор подтверждает выполнение
  void sendPushToKidOnTaskComplete(TaskModel task) async {
    final DocumentReference? receiver = task.kid;

    if (receiver == null) {
      print('Receiver not found');
      return;
    }

    const String title = 'Задание выполнено';
    final String taskName = task.name;
    final int coin = task.coin ?? 0;
    final String body = 'Задание "$taskName" проверено и выполнено.${coin > 0 ? '\nТы получил +$coin баллов!' : ''}';
    final Map<String, dynamic> payload = {
      "type": NotificationType.taskComplete.name,
      "task_id": task.id,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.taskComplete, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnTaskComplete} error: $e');
    }
  }

  //Пуш ребенку, когда ментор отправляет на доработку
  void sendPushToKidOnTaskRework(TaskModel task) async {
    final DocumentReference? receiver = task.kid;

    if (receiver == null) {
      print('Receiver not found');
      return;
    }

    const String title = 'Задание нужно доработать';
    final String taskName = task.name;
    final String body = 'Задание "$taskName" нужно доработать';
    final Map<String, dynamic> payload = {
      "type": NotificationType.taskRework.name,
      "task_id": task.id,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.taskRework, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnTaskComplete} error: $e');
    }
  }

  //Пуш ребенку, когда ментор отменяет задачу
  void sendPushToKidOnTaskCanceled(TaskModel task) async {
    final DocumentReference? receiver = task.kid;

    if (receiver == null) {
      print('Receiver not found');
      return;
    }

    const String title = 'Задание отменена';
    final String taskName = task.name;
    final String body = 'Задание "$taskName" была отменена';
    final Map<String, dynamic> payload = {
      "type": NotificationType.taskCanceled.name,
      "task_id": task.id,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.taskCanceled, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnTaskComplete} error: $e');
    }
  }

  //Пуш ребенку, когда ментор удаляет задачу
  void sendPushToKidOnTaskDeleted(TaskModel task) async {
    final DocumentReference? receiver = task.kid;

    if (receiver == null) {
      print('Receiver not found');
      return;
    }

    const String title = 'Задание удалено';
    final String taskName = task.name;
    final String body = 'Задание "$taskName" было удалено';
    final Map<String, dynamic> payload = {
      "type": NotificationType.taskDeleted.name,
      "task_id": task.id,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.taskDeleted, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnTaskComplete} error: $e');
    }
  }

  //Пуш ребенку, когда ментор создает задачу
  void sendPushToKidOnTaskCreated(DocumentReference kid, String taskName, String taskId) async {
    final DocumentReference receiver = kid;

    const String title = 'Новое задание';
    final String body = 'Наставник добавил тебе задание: "$taskName"';
    final Map<String, dynamic> payload = {
      "type": NotificationType.taskCreated.name,
      "task_id": taskId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.taskCreated, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnTaskCreated} error: $e');
    }
  }

  //Пуш ментору, когда ребенок отправил задачу на проверку
  void sendPushToMentorOnTaskSentToReview(TaskModel task) async {
    final DocumentReference? receiver = task.owner;

    if (receiver == null) {
      print('Receiver not found');
      return;
    }

    const String title = 'Проверь задание';
    final String taskName = task.name;
    final String body = 'Ребенок отправил задание "$taskName" на проверку';
    final Map<String, dynamic> payload = {
      "type": NotificationType.taskReview.name,
      "task_id": task.id,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.taskReview, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToMentorOnTaskSentToReview} error: $e');
    }
  }

  //Пуш ребенку, когда ментор списал/добавил баллы
  void sendPushToKidOnCoinChanged(UserModel mentor, DocumentReference kid, int amount) async {
    final DocumentReference receiver = kid;

    String title = amount.isNegative ? 'Списание баллов' : 'Добавление баллов';
    final String mentorName = mentor.name;
    final String body = 'Наставник $mentorName ${amount.isNegative ? 'списал' : 'добавил'} $amount баллов';
    final Map<String, dynamic> payload = {
      "type": NotificationType.coinChange.name,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.coinChange, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnTaskCreated} error: $e');
    }
  }

  /////////////////Bonuses

  //Пуш ребенку, когда ментор создает бонус
  void sendPushToKidOnBonusCreated(DocumentReference kid, String bonusName, String bonusId) async {
    final DocumentReference receiver = kid;

    const String title = 'Новый бонус';
    final String body = 'Появился новый бонус: "$bonusName"\nУспей накопить баллы!';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusCreated.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusCreated, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnBonusCreated} error: $e');
    }
  }

  //Пуш ментору, когда ребенок создает бонус и ждет подтверждения
  void sendPushToMentorOnBonusNeedApprove(
      DocumentReference mentor, String kidName, String bonusName, String bonusId) async {
    final DocumentReference receiver = mentor;

    String title = '$kidName создал новый бонус';
    final String body = '$kidName ждёт подтверждения по бонусу: "$bonusName"';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusNeedApprove.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusNeedApprove, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToMentorOnBonusNeedApprove} error: $e');
    }
  }

  //Пуш ребенку, когда ментор отменил бонус
  void sendPushToKidOnBonusCanceled(DocumentReference kid, String bonusName, String bonusId) async {
    final DocumentReference receiver = kid;

    const String title = 'Бонус отменён';
    final String body = 'Бонус "$bonusName" отменён';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusCanceled.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusCanceled, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnBonusCanceled} error: $e');
    }
  }

  //Пуш ребенку, когда ментор отклонил бонус
  void sendPushToKidOnBonusRejected(DocumentReference kid, String bonusName, String bonusId) async {
    final DocumentReference receiver = kid;

    const String title = 'Бонус отклонён';
    final String body = 'Запрос на бонус "$bonusName" отклонён. Попробуй позже или выбери другой бонус';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusRejected.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusRejected, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnBonusRejected} error: $e');
    }
  }

  //Пуш ребенку, когда ментор принял бонус
  void sendPushToKidOnBonusApproved(DocumentReference kid, String bonusName, String bonusId) async {
    final DocumentReference receiver = kid;

    const String title = 'Бонус подтверждён';
    final String body = 'Ура! Твой бонус "$bonusName" одобрен!';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusApproved.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusApproved, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnBonusApproved} error: $e');
    }
  }

  //Пуш ребенку, когда ментор подтвердил получения
  void sendPushToKidOnBonusRequestApproved(DocumentReference kid, String bonusName, String bonusId) async {
    final DocumentReference receiver = kid;

    const String title = 'Бонус получён!';
    final String body = 'Ура! Ты получил бонус: "$bonusName"';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusRequestApproved.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusRequestApproved, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToKidOnBonusRequestApproved} error: $e');
    }
  }

  //Пуш ментору, когда ребенок попросил получить бонус
  void sendPushToMentorOnBonusRequested(
      DocumentReference mentor, String kidName, String bonusName, String bonusId) async {
    final DocumentReference receiver = mentor;

    const String title = 'Подтвердите получение бонуса';
    final String body = '$kidName попросил бонус: "$bonusName"';
    final Map<String, dynamic> payload = {
      "type": NotificationType.bonusRequested.name,
      "bonus_id": bonusId,
    };

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.bonusRequested, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToMentorOnBonusRequested} error: $e');
    }
  }

  //Пуш для чата
  void sendPushToChatMember(DocumentReference receiver, String message, String chatId) async {
    const String title = 'Новое сообщение в чате';
    final String body = message;
    final Map<String, dynamic> payload = {
      "type": NotificationType.chat.name,
      "chat_id": chatId,
    };

    try {
      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToChatMember} error: $e');
    }
  }

  //Пуш ментору о подарке
  void sendPushToMentorForGift(DocumentReference receiver, String senderName) async {
    String title = '$senderName подарил Вам подписку!';
    const String body = 'Теперь вы можете создавать задания и бонусы в течение 1 месяца';
    final Map<String, dynamic> payload = {"type": NotificationType.gift.name};

    try {
      await _createSystemNotificationDoc(receiver, title, body, NotificationType.gift, payload);

      await _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToMentorForGift} error: $e');
    }
  }

  Future<void> _callSendPushCallback(String userId, String title, String body, Map payload) async {
    try {
      final cf.HttpsCallable callable = _functions.httpsCallable('sendPushNotificationToUser');
      final response = await callable.call(<String, dynamic>{
        'userId': userId,
        'title': title,
        'body': body,
        'data': payload,
      });
      print('Результат вызова функции: ${response.data}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createSystemNotificationDoc(
    DocumentReference receiver,
    String title,
    String body,
    NotificationType type,
    Map payload,
  ) async {
    final notificationRef = _fs.collection('notifications').doc();

    final notificationData = {
      "user": receiver,
      "time": FieldValue.serverTimestamp(),
      "title": title,
      "body": body,
      "type": type.name,
      "payload": payload,
      "is_read": false,
    };

    await notificationRef.set(notificationData);
  }
}
