import 'package:cloud_firestore/cloud_firestore.dart';

enum ArticleStatus { active, achieved }

class ArticleModel {
  final int index;
  final String id;
  final String name;
  final String nameEng;
  final DateTime? createdAt;
  final ArticleStatus status;
  final String? description;
  final String? descriptionEng;
  final String? photo;

  ArticleModel({
    required this.id,
    required this.name,
    required this.nameEng,
    this.createdAt,
    this.index = 0,
    this.status = ArticleStatus.active,
    this.description,
    this.descriptionEng,
    this.photo,
  });

  factory ArticleModel.fromFirestore(DocumentSnapshot doc) {
    Map json = doc.data() as Map<String, dynamic>;
    return ArticleModel(
      id: doc.id,
      name: json['name'] ?? '-',
      nameEng: json['name_eng'] ?? '-',
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      index: json['index'] as int,
      status: json['status'] != null ? ArticleStatus.values.byName(json['status'] as String) : ArticleStatus.active,
      description: json['description'] as String?,
      descriptionEng: json['description_eng'] as String?,
      photo: json['photo'] as String?,
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('articles');

  DocumentReference get ref => collection.doc(id);
}
