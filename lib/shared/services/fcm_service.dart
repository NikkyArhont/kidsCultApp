import 'dart:developer';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  List<String> receivedNotificationIds = [];

  Future<void> setupFCM(BuildContext context) async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await _fcm.getToken();
    await _setFCMToken(token);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Message: ${message.messageId} TITLE: ${message.notification?.title}:  BODY: ${message.notification?.body} \n DATA: ${message.data}');
      final notification = message.notification;
      if (notification != null) {
        bool alreadyView = isNotificationReceived(message.messageId ?? '');
        if (alreadyView) {
          log('Message already viewed: ${message.messageId}');
          return;
        }

        final Map<String, dynamic> notificationData = message.data;
        NotificationType type = notificationTypeFromString(notificationData['type']);

        onTap() {
          if (type == NotificationType.reminder ||
              type == NotificationType.taskComplete ||
              type == NotificationType.taskRework ||
              type == NotificationType.taskCanceled ||
              type == NotificationType.taskDeleted ||
              type == NotificationType.taskCreated ||
              type == NotificationType.taskReview) {
            final String? taskId = notificationData['task_id'];
            if (taskId == null) return;
            final taskRef = _fs.collection('tasks').doc(taskId);
            final data = {'task': null, 'taskRef': taskRef};
            if (context.mounted) {
              context.push('/task_detail', extra: data);
            }
          } else if (type == NotificationType.bonusCreated ||
              type == NotificationType.bonusNeedApprove ||
              type == NotificationType.bonusCanceled ||
              type == NotificationType.bonusRejected ||
              type == NotificationType.bonusApproved ||
              type == NotificationType.bonusRequested ||
              type == NotificationType.bonusRequestApproved) {
            final String? bonusId = notificationData['bonus_id'];
            if (bonusId == null) return;
            final bonusRef = _fs.collection('bonuses').doc(bonusId);
            final data = {'bonus': null, 'bonusRef': bonusRef};
            if (context.mounted) {
              context.push('/bonus_detail', extra: data);
            }
          } else if (type == NotificationType.coinChange) {
            context.push('/kid_coins', extra: _userCubit.state);
          } else if (type == NotificationType.chat) {
            final String? chatId = notificationData['chat_id'];
            if (chatId == null) return;
            final chatRef = _fs.collection('chats').doc(chatId);
            context.push('/chat_room', extra: chatRef);
            return;
          } else if (type == NotificationType.gift) {
            context.go('/mentor_profile');
            return;
          } else {
            return;
          }
        }

        if (type == NotificationType.chat) {
          final String? chatId = notificationData['chat_id'];
          if (chatId == null) return;
          if (_currentChatCubit.state == chatId) return;
        }

        if (type == NotificationType.gift) {
          _userCubit.refreshProfile();
        }

        SnackBarSerive.showSnackBarOnReceivePushNotification(
          notification.title ?? 'Notification',
          notification.body,
          onTap,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Message: ${message.messageId} TITLE: ${message.notification?.title}:  BODY: ${message.notification?.body} \n DATA: ${message.data}');
      final notification = message.notification;
      if (notification != null) {
        bool alreadyView = isNotificationReceived(message.messageId ?? '');
        if (alreadyView) {
          log('Message already viewed: ${message.messageId}');
          return;
        }

        final Map<String, dynamic> notificationData = message.data;
        NotificationType type = notificationTypeFromString(notificationData['type']);

        onTap() {
          if (type == NotificationType.reminder ||
              type == NotificationType.taskComplete ||
              type == NotificationType.taskRework ||
              type == NotificationType.taskCanceled ||
              type == NotificationType.taskDeleted ||
              type == NotificationType.taskCreated ||
              type == NotificationType.taskReview) {
            final String? taskId = notificationData['task_id'];
            if (taskId == null) return;
            final taskRef = _fs.collection('tasks').doc(taskId);
            final data = {'task': null, 'taskRef': taskRef};
            if (context.mounted) {
              context.push('/task_detail', extra: data);
            }
          } else if (type == NotificationType.bonusCreated ||
              type == NotificationType.bonusNeedApprove ||
              type == NotificationType.bonusCanceled ||
              type == NotificationType.bonusRejected ||
              type == NotificationType.bonusApproved ||
              type == NotificationType.bonusRequested ||
              type == NotificationType.bonusRequestApproved) {
            final String? bonusId = notificationData['bonus_id'];
            if (bonusId == null) return;
            final bonusRef = _fs.collection('bonuses').doc(bonusId);
            final data = {'bonus': null, 'bonusRef': bonusRef};
            if (context.mounted) {
              context.push('/bonus_detail', extra: data);
            }
          } else if (type == NotificationType.coinChange) {
            context.push('/kid_coins', extra: _userCubit.state);
          } else if (type == NotificationType.chat) {
            final String? chatId = notificationData['chat_id'];
            if (chatId == null) return;
            final chatRef = _fs.collection('chats').doc(chatId);
            context.push('/chat_room', extra: chatRef);
            return;
          } else if (type == NotificationType.gift) {
            context.go('/mentor_profile');
            return;
          } else {
            return;
          }
        }

        if (context.mounted) {
          onTap();
        }
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (!context.mounted) return;
      if (message == null) return;

      final Map<String, dynamic> notificationData = message.data;
      NotificationType type = notificationTypeFromString(notificationData['type']);

      onTap() {
        if (type == NotificationType.reminder ||
            type == NotificationType.taskComplete ||
            type == NotificationType.taskRework ||
            type == NotificationType.taskCanceled ||
            type == NotificationType.taskDeleted ||
            type == NotificationType.taskCreated ||
            type == NotificationType.taskReview) {
          final String? taskId = notificationData['task_id'];
          if (taskId == null) return;
          final taskRef = _fs.collection('tasks').doc(taskId);
          final data = {'task': null, 'taskRef': taskRef};
          if (context.mounted) {
            context.push('/task_detail', extra: data);
          }
        } else if (type == NotificationType.bonusCreated ||
            type == NotificationType.bonusNeedApprove ||
            type == NotificationType.bonusCanceled ||
            type == NotificationType.bonusRejected ||
            type == NotificationType.bonusApproved ||
            type == NotificationType.bonusRequested ||
            type == NotificationType.bonusRequestApproved) {
          final String? bonusId = notificationData['bonus_id'];
          if (bonusId == null) return;
          final bonusRef = _fs.collection('bonuses').doc(bonusId);
          final data = {'bonus': null, 'bonusRef': bonusRef};
          if (context.mounted) {
            context.push('/bonus_detail', extra: data);
          }
        } else if (type == NotificationType.coinChange) {
          context.push('/kid_coins', extra: _userCubit.state);
        } else if (type == NotificationType.chat) {
          final String? chatId = notificationData['chat_id'];
          if (chatId == null) return;
          final chatRef = _fs.collection('chats').doc(chatId);
          context.push('/chat_room', extra: chatRef);
          return;
        } else if (type == NotificationType.gift) {
          context.go('/mentor_profile');
          return;
        } else {
          return;
        }
      }

      if (context.mounted) {
        onTap();
      }
    });

    if (_userCubit.state?.isKid == true) {
      _localPush.setDailyDiaryReminder(_userCubit.state?.dairyNotification ?? true);
    }
  }

  bool isNotificationReceived(String id) => receivedNotificationIds.contains(id);

  Future<void> _setFCMToken(String? token) async {
    if (token == null) return;
    await _userCubit.state?.ref.update({'fcm_token': token});
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
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
      _callSendPushCallback(receiver.id, title, body, payload);
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

      _callSendPushCallback(receiver.id, title, body, payload);
    } catch (e) {
      print('{sendPushToMentorForGift} error: $e');
    }
  }

  void _callSendPushCallback(String userId, String title, String body, Map payload) async {
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


//  Message: 0:1753783382232457%a1133c67a1133c67 TITLE: Время выполнить задание::  BODY: "Будет увед в 12 10" 
//        DATA: {task_id: UQzZuZXND0lf6Lng6x5D, type: reminder}

// Message: 0:1753852724489856%a1133c67a1133c67 TITLE: Новое задание:  BODY: Наставник добавил тебе задание: "Только для теста " 
//        DATA: {task_id: T1N8hkvpu53Au5BxZ8ZY, type: taskCreated}