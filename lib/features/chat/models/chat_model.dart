import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

class ChatModel {
  final String id;
  final DateTime? lastEditTime;
  final LastMessage? lastMessage;
  final List<DocumentReference> members;
  String? name;
  final Map<String, bool> notification;
  final DocumentReference? owner;
  String? photo;
  final ChatType type;
  final List<DocumentReference> unmodifiedMembers;
  final Map<String, int> unreads;
  final DocumentReference? kid;
  final DocumentReference? mentor;

  ChatModel({
    required this.id,
    this.lastEditTime,
    this.lastMessage,
    this.members = const [],
    this.name,
    this.notification = const {},
    this.owner,
    this.photo,
    required this.type,
    this.unmodifiedMembers = const [],
    this.unreads = const {},
    this.kid,
    this.mentor,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      lastEditTime: (data['last_edit_time'] as Timestamp?)?.toDate(),
      lastMessage: data['last_message'] != null ? LastMessage.fromMap(data['last_message']) : null,
      members: List<DocumentReference>.from(data['members'] ?? []),
      name: data['name'],
      notification: Map<String, bool>.from(
        (data['notification'] ?? {}).map(
          (k, v) => MapEntry(k, (v ?? true) as bool),
        ),
      ),
      owner: data['owner'],
      photo: data['photo'],
      type: data['type'] != null ? ChatType.values.byName(data['type']) : ChatType.private,
      unmodifiedMembers: List<DocumentReference>.from(data['unmodified_members'] ?? []),
      unreads: Map<String, int>.from(
        (data['unreads'] ?? {}).map(
          (k, v) => MapEntry(k, (v ?? 0) as int),
        ),
      ),
      kid: data['kid'],
      mentor: data['mentor'],
    );
  }

  ChatModel copyWith({
    String? id,
    DateTime? lastEditTime,
    LastMessage? lastMessage,
    List<DocumentReference>? members,
    String? name,
    Map<String, bool>? notification,
    DocumentReference? owner,
    String? photo,
    ChatType? type,
    List<DocumentReference>? unmodifiedMembers,
    Map<String, int>? unreads,
    DocumentReference? kid,
    DocumentReference? mentor,
  }) {
    return ChatModel(
      id: id ?? this.id,
      lastEditTime: lastEditTime ?? this.lastEditTime,
      lastMessage: lastMessage ?? this.lastMessage,
      members: members ?? this.members,
      name: name ?? this.name,
      notification: notification ?? this.notification,
      owner: owner ?? this.owner,
      photo: photo ?? this.photo,
      type: type ?? this.type,
      unmodifiedMembers: unmodifiedMembers ?? this.unmodifiedMembers,
      unreads: unreads ?? this.unreads,
      kid: kid ?? this.kid,
      mentor: mentor ?? this.mentor,
    );
  }

  DocumentReference get ref => FirebaseFirestore.instance.collection('chats').doc(id);

  DocumentReference? secondUserRef(String me) =>
      isGroup ? null : members.firstWhereOrNull((element) => element.id != me);

  int getUnreadCount(String userId) => unreads[userId] ?? 0;
  bool getNotificationStatus(String userId) => notification[userId] ?? true;

  bool get isGroup => type == ChatType.group;
}

class LastMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;

  LastMessage({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      text: map['text'] ?? '',
      senderId: map['sender'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
