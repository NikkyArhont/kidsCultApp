import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDialogModel {
  final String id;
  final DocumentReference? user;
  final DateTime? time;
  final String? comment;
  final List<String> files;

  TaskDialogModel({
    required this.id,
    this.comment,
    this.user,
    this.time,
    this.files = const [],
  });

  factory TaskDialogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TaskDialogModel(
      id: doc.id,
      comment: data['comment'],
      user: data['user'],
      time: data['time'] != null ? (data['time'] as Timestamp).toDate() : null,
      files:  (data['files'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }
}
