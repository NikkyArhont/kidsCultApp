import 'package:cloud_firestore/cloud_firestore.dart';

class CoinChangeModel {
  final String id;
  final DocumentReference? mentor;
  final DocumentReference? kid;
  final DateTime? createdAt;
  final int coin;
  final String? name;

  CoinChangeModel({
    required this.id,
    this.name,
    this.mentor,  
    this.kid,
    this.createdAt,
    this.coin = 0,
  });

  factory CoinChangeModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CoinChangeModel(
      id: doc.id,
      name: data['name'] ?? '',
      mentor: data['mentor'],
      kid: data['kid'],
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      coin: data['coin'],
    );
  }

  static CollectionReference  get collection => FirebaseFirestore.instance.collection('coin_changes');

  DocumentReference get ref => collection.doc(id);
}
