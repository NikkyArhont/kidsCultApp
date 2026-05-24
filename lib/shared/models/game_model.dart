import 'package:cloud_firestore/cloud_firestore.dart';

enum GameStatus { active, achieved }

class GameModel {
  final String id;
  final String name;
  final String nameEng;
  final DateTime? createdAt;
  final int? ageFrom;
  final int? ageTo;
  final int points;
  final GameStatus status;
  final List<DocumentReference> quizzes;

  GameModel({
    required this.id,
    required this.name,
    required this.nameEng,
    this.createdAt,
    this.ageFrom,
    this.ageTo,
    this.points = 0,
    this.status = GameStatus.active,
    this.quizzes = const [],
  });

  factory GameModel.fromFirestore(DocumentSnapshot snapshot) {
    final json = snapshot.data()! as Map<String, dynamic>;
    return GameModel(
      id: snapshot.id,
      name: json['name'] ?? '-',
      nameEng: json['name_eng'] ?? '-',
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      ageFrom: json['age_from'] as int?,
      ageTo: json['age_to'] as int?,
      points: json['points'] as int? ?? 0,
      status: json['status'] != null ? GameStatus.values.byName(json['status'] as String) : GameStatus.active,
      quizzes: (json['quizzes'] as List<dynamic>?)?.map((e) => e as DocumentReference).toList() ?? [],
    );
  }

  static CollectionReference get collection => FirebaseFirestore.instance.collection('games');

  DocumentReference get ref => collection.doc(id);
}
