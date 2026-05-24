import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BonusModel {
  final String id;
  final String name;
  final DocumentReference? owner;
  final DocumentReference? kid;
  final DocumentReference? mentor;
  final String? link;
  final String? photo;
  final BonusStatus? status;
  final DateTime? createdAt;
  final int? point;
  final String? reasonOfCancel;

  BonusModel({
    required this.id,
    required this.name,
    this.owner,
    this.kid,
    this.mentor,
    this.link,
    this.photo,
    this.status,
    this.createdAt,
    this.point,
    this.reasonOfCancel,
  });

  factory BonusModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BonusModel(
      id: doc.id,
      name: data['name'] ?? '',
      owner: data['owner'],
      kid: data['kid'],
      mentor: data['mentor'],
      photo: data['photo'],
      link: data['link'],
      status: data['status'] != null ? BonusStatus.values.byName(data['status']) : null,
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      point: data['point'],
      reasonOfCancel: data['cancel_reason'],
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('bonuses');

  DocumentReference get ref => collection.doc(id);
}
