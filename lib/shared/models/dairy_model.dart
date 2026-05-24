import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class DairyModel {
  final String id;
  final DairyEmotion? emotion;
  final DocumentReference? kid;
  final DateTime? createdAt;
  final DateTime? time;
  final String? text;

  DairyModel({
    required this.id,
    this.emotion,
    this.text,
    this.kid,
    this.createdAt,
    this.time,
  });

  factory DairyModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DairyModel(
      id: doc.id,
      text: data['text'] ?? '',
      emotion: data['emotion'] != null ? DairyEmotion.values.byName(data['emotion']) : null,
      kid: data['kid'],
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      time: data['time'] != null ? (data['time'] as Timestamp).toDate() : null,
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('dairy');

  DocumentReference get ref => collection.doc(id);
}
