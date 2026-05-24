import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String name;
  final DocumentReference? owner;
  final DocumentReference? kid;
  final String? description;
  final String? photo;
  final DateTime? startDate;
  final DateTime? endDate;
  final TaskType? type;
  final DateTime? reminderDate;
  final TimeOfDay? reminderTime;
  final List<int>? reminderDays;
  final ReminderType? reminderType;
  final TaskStatus? status;
  final DateTime? createdAt;
  final DateTime? actionDate;
  final int? coin;
  final int usedCounter;
  final String? reasonOfCancel;

  TaskModel({
    required this.id,
    required this.name,
    this.owner,
    this.kid,
    this.description,
    this.type,
    this.photo,
    this.startDate,
    this.endDate,
    this.reminderDate,
    this.reminderTime,
    this.reminderDays,
    this.reminderType,
    this.status,
    this.createdAt,
    this.actionDate,
    this.coin,
    this.usedCounter = 0,
    this.reasonOfCancel,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      name: data['name'] ?? '',
      owner: data['owner'],
      kid: data['kid'],
      photo: data['photo'],
      description: data['description'],
      endDate: (data['end_date'] as Timestamp?)?.toDate(),
      startDate: (data['start_date'] as Timestamp?)?.toDate(),
      reminderDate: (data['reminder_date'] as Timestamp?)?.toDate(),
      reminderTime: (data['reminder_time'] as Timestamp?) == null
          ? null
          : TimeOfDay.fromDateTime((data['reminder_time'] as Timestamp).toDate()),
      reminderDays: (data['reminder_days'] as List?)?.map((e) => e as int).toList(),
      reminderType: data['reminder_type'] != null ? ReminderType.values.byName(data['reminder_type']) : null,
      type: data['type'] != null ? TaskType.values.byName(data['type']) : null,
      status: data['status'] != null ? TaskStatus.values.byName(data['status']) : null,
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      actionDate: data['action_date'] != null ? (data['action_date'] as Timestamp).toDate() : null,
      coin: data['coin'],
      usedCounter: data['used_counter'] ?? 0,
      reasonOfCancel: data['cancel_reason'],
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('tasks');

  DocumentReference get ref => collection.doc(id);
}
