import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserModel {
  final String id;
  final String name;
  final String? photo;
  final UserType? userType;
  final bool profileFilled;
  final bool banned;
  final DateTime? createdAt;
  final String? phone;
  final String? fcmToken;
  final String? city;

  final bool notification;
  final bool dairyNotification;
  final List<DocumentReference> connections;
  final List<DocumentReference> connectionRequests;
  final List<DocumentReference> dairyMembers;
  final DateTime? trialSubscriptionPlan;
  final DateTime? premiumSubscriptionPlan;
  final DocumentReference? premiumSubscriptionRef;
  final int points;
  final int gamePoints;
  final List<DocumentReference> completedLevels;
  final bool deleted;
  final DateTime? birthDate;

  UserModel({
    required this.name,
    required this.id,
    this.photo,
    this.userType,
    this.profileFilled = false,
    this.banned = false,
    this.createdAt,
    this.phone,
    this.fcmToken,
    this.city,
    this.notification = true,
    this.dairyNotification = true,
    this.connections = const [],
    this.connectionRequests = const [],
    this.dairyMembers = const [],
    this.trialSubscriptionPlan,
    this.premiumSubscriptionPlan,
    this.premiumSubscriptionRef,
    this.points = 0,
    this.gamePoints = 0,
    this.completedLevels = const [],
    this.deleted = false,
    this.birthDate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      photo: data['photo'],
      userType: data['type'] != null ? UserType.values.byName(data['type']) : null,
      profileFilled: data['profile_filled'] ?? false,
      banned: data['banned'] ?? false,
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
      phone: data['phone'],
      fcmToken: data['fcm_token'],
      city: data['city'],
      notification: data['notification'] ?? true,
      dairyNotification: data['dairy_notification'] ?? true,
      connections: (data['connections'] as List<dynamic>? ?? []).map((e) => e as DocumentReference).toList(),
      connectionRequests: (data['connection_requests'] as List<dynamic>? ?? []).map((e) => e as DocumentReference).toList(),
      dairyMembers: (data['dairy_members'] as List<dynamic>? ?? []).map((e) => e as DocumentReference).toList(),
      trialSubscriptionPlan: data['trial_subscription'] != null ? (data['trial_subscription'] as Timestamp).toDate() : null,
      premiumSubscriptionPlan: data['premium_subscription'] != null ? (data['premium_subscription'] as Timestamp).toDate() : null,
      premiumSubscriptionRef: data['premium_subscription_ref'],
      completedLevels: (data['completed_levels'] as List<dynamic>? ?? []).map((e) => e as DocumentReference).toList(),
      points: data['points'] ?? 0,
      gamePoints: data['game_points'] ?? 0,
      deleted: data['deleted'] ?? false,
      birthDate: data['birth_date'] != null ? (data['birth_date'] as Timestamp).toDate() : null,
    );
  }

  bool get isKid => userType == UserType.kid;

  CollectionReference get collection => FirebaseFirestore.instance.collection('users');

  DocumentReference get ref => collection.doc(id);

  CollectionReference get userGamesCollection => collection.doc(id).collection('games');

  bool hasInConnections(DocumentReference ref) => connections.contains(ref);

  bool get isDemoAccount => id == 'phone_99364424525';

  bool hasSubscription() {
    if (isDemoAccount) return true;
    final now = DateTime.now();
    if (trialSubscriptionPlan != null && trialSubscriptionPlan!.isAfter(now)) {
      return true;
    }
    if (premiumSubscriptionPlan != null && premiumSubscriptionPlan!.isAfter(now) && premiumSubscriptionRef != null) {
      return true;
    }
    return false;
  }

  bool isSubscriptionTrial() {
    final now = DateTime.now();
    if (trialSubscriptionPlan != null && trialSubscriptionPlan!.isAfter(now)) {
      return true;
    }
    return false;
  }

  String currentSubscriptionValidDate(String currentLocale, {bool short = false}) {
    if (!hasSubscription()) return '-';
    final now = DateTime.now();

    String format = short ? 'dd.MM.yyyy' : 'dd MMMM yyyy';

    if (trialSubscriptionPlan != null && trialSubscriptionPlan!.isAfter(now)) {
      return DateFormat(format, currentLocale).format(trialSubscriptionPlan!);
    }
    if (premiumSubscriptionPlan != null && premiumSubscriptionPlan!.isAfter(now) && premiumSubscriptionRef != null) {
      return DateFormat(format, currentLocale).format(premiumSubscriptionPlan!);
    }
    return '-';
  }

  bool isLevelCompleted(DocumentReference levelRef) {
    return completedLevels.any((ref) => ref.id == levelRef.id);
  }

  bool isLevelAvailable(LevelModel level) {
    return (level.pointFrom ?? 0) <= points;
  }

  int get getAge => DateTime.now().year - (birthDate?.year ?? 0);

  UserModel copyWith({
    String? id,
    String? name,
    String? photo,
    UserType? userType,
    bool? profileFilled,
    String? phone,
    bool? banned,
    DateTime? createdAt,
    String? fcmToken,
    String? city,
    bool? notification,
    bool? dairyNotification,
    List<DocumentReference>? connections,
    List<DocumentReference>? connectionRequests,
    List<DocumentReference>? dairyMembers,
    DateTime? trialSubscriptionPlan,
    DateTime? premiumSubscriptionPlan,
    DocumentReference? premiumSubscriptionRef,
    int? points,
    int? gamePoints,
    List<DocumentReference>? completedLevels,
    bool? deleted,
    DateTime? birthDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      userType: userType ?? this.userType,
      profileFilled: profileFilled ?? this.profileFilled,
      banned: banned ?? this.banned,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
      city: city ?? this.city,
      notification: notification ?? this.notification,
      dairyNotification: dairyNotification ?? this.dairyNotification,
      connections: connections ?? this.connections,
      connectionRequests: connectionRequests ?? this.connectionRequests,
      dairyMembers: dairyMembers ?? this.dairyMembers,
      trialSubscriptionPlan: trialSubscriptionPlan ?? this.trialSubscriptionPlan,
      premiumSubscriptionPlan: premiumSubscriptionPlan ?? this.premiumSubscriptionPlan,
      premiumSubscriptionRef: premiumSubscriptionRef ?? this.premiumSubscriptionRef,
      points: points ?? this.points,
      gamePoints: gamePoints ?? this.gamePoints,
      completedLevels: completedLevels ?? this.completedLevels,
      deleted: deleted ?? this.deleted,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}

class UserGameModel {
  final String id;
  final int points;
  final DocumentReference? gameRef;
  final DocumentReference? levelRef;
  final DateTime? createdAt;
  final bool isCompleted;

  UserGameModel({
    required this.id,
    this.points = 0,
    this.gameRef,
    this.levelRef,
    this.createdAt,
    this.isCompleted = false,
  });

  factory UserGameModel.fromFirestore(DocumentSnapshot snapshot) {
    final json = snapshot.data()! as Map<String, dynamic>;
    return UserGameModel(
      id: snapshot.id,
      points: json['points'] as int? ?? 0,
      gameRef: json['game'] as DocumentReference?,
      levelRef: json['level'] as DocumentReference?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'points': points,
        'game': gameRef,
        'level': levelRef,
        'is_completed': isCompleted,
        'created_at': FieldValue.serverTimestamp(),
      };
}
