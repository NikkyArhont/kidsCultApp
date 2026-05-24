import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final DocumentReference? user;
  final String? body;
  final bool isRead;
  final DateTime? time;
  final Map? payload;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    this.time,
    this.isRead = false,
    this.user,
    this.body,
    this.payload,
    this.type = NotificationType.other,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      user: json['user'] as DocumentReference?,
      body: json['body'] as String?,
      title: json['title'] as String? ?? '-',
      isRead: json['is_read'] as bool? ?? false,
      time: (json['time'] as Timestamp?)?.toDate(),
      payload: json['payload'] as Map?,
      type: notificationTypeFromString(json['type'] as String?),
    );
  }

  DocumentReference get ref => FirebaseFirestore.instance.collection('notifications').doc(id);
}
