import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final int price;
  final int count;
  final String appleId;
  SubscriptionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.titleEn,
    required this.descriptionEn,
    required this.count,
    required this.appleId,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      titleEn: data['title_en'] ?? '',
      descriptionEn: data['description_en'] ?? '',
      price: data['price'] ?? 0,
      count: data['count'] ?? 0,
      appleId: data['apple_id'] ?? '',
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('tariffs');

  DocumentReference get ref => collection.doc(id);
}
