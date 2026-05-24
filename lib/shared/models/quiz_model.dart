import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final DocumentReference? gameRef;
  final String? question;
  final String? questionEng;
  final int? index;
  final DateTime? createdAt;
  final List<AnswerModel> answers;
  final String? image;
  AnswerModel? selectedAnswer;

  QuizModel({
    required this.id,
    this.gameRef,
    this.question,
    this.questionEng,
    this.index,
    this.createdAt,
    this.image,
    this.answers = const [],
    this.selectedAnswer,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    return QuizModel(
      id: doc.id,
      gameRef: json['game'] as DocumentReference?,
      question: json['question'] as String?,
      questionEng: json['question_eng'] as String?,
      index: json['index'] as int?,
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      answers:
          (json['answers'] as List<dynamic>? ?? []).map((e) => AnswerModel.fromMap(e as Map<String, dynamic>)).toList(),
      image: json['image'] as String?,
    );
  }

  DocumentReference get ref => FirebaseFirestore.instance.collection('quizzes').doc(id);
}

class AnswerModel {
  final String answer;
  final String answerEng;
  final bool isCorrect;

  AnswerModel({
    this.answer = '',
    this.answerEng = '',
    this.isCorrect = false,
  });

  factory AnswerModel.fromMap(Map<String, dynamic> map) {
    return AnswerModel(
      answer: map['answer'] as String? ?? '',
      answerEng: map['answer_eng'] as String? ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }
}
