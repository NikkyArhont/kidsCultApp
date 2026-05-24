import 'package:cloud_firestore/cloud_firestore.dart';

enum LevelStatus { active, achieved }

class LevelModel {
  final int index;
  final String id;
  final String name;
  final String nameEng;
  final DateTime? createdAt;
  final int? ageFrom;
  final int? ageTo;
  final int? pointFrom;
  final int? pointTo;
  final LevelStatus status;
  final String? trophey;
  final List<DocumentReference> games;

  LevelModel({
    required this.id,
    required this.name,
    required this.nameEng,
    this.createdAt,
    this.ageFrom,
    this.ageTo,
    this.pointFrom,
    this.pointTo,
    this.index = 0,
    this.status = LevelStatus.active,
    this.games = const [],
    this.trophey,
  });

  factory LevelModel.fromFirestore(DocumentSnapshot snapshot) {
    final json = snapshot.data()! as Map<String, dynamic>;
    return LevelModel(
      id: snapshot.id,
      name: json['name'] ?? '-',
      nameEng: json['name_eng'] ?? '-',
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      ageFrom: json['age_from'] as int?,
      ageTo: json['age_to'] as int?,
      pointFrom: json['point_from'] as int?,
      pointTo: json['point_to'] as int?,
      index: json['index'] as int,
      trophey: json['trophey'] as String?,
      status: json['status'] != null ? LevelStatus.values.byName(json['status'] as String) : LevelStatus.active,
      games: (json['games'] as List<dynamic>?)?.map((e) => e as DocumentReference).toList() ?? [],
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('levels');
  DocumentReference get ref => collection.doc(id);

  DocumentReference userRef(String userId) => ref.collection('users').doc(userId);
}
