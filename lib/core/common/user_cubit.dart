import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_tracker/index.dart';

class UserCubit extends Cubit<UserModel?> {
  final FirebaseFirestore _fs;

  UserCubit({
    required FirebaseFirestore fs,
  })  : _fs = fs,
        super(null);

  int _sessionGeneration = 0;

  void setUser(UserModel? newUser) {
    // A clear invalidates pending work even when profile loading has not yet
    // populated state. Logging back into the same UID starts a new session.
    if (newUser == null || state?.id != newUser.id) ++_sessionGeneration;
    emit(newUser);
  }

  bool _isCurrentSession(int generation, UserModel user) =>
      !isClosed && generation == _sessionGeneration && state?.id == user.id;

  void getUser() {
    _fs.app;
  }

  Future<void> getAndSet(User user) async {
    final generation = _sessionGeneration;
    try {
      final doc = await _fs.collection('users').doc(user.uid).get();
      if (isClosed || generation != _sessionGeneration) return;
      final userModel = UserModel.fromFirestore(doc);
      setUser(userModel);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return;
    final doc = await user.ref.get();
    if (_isCurrentSession(generation, user)) setUser(UserModel.fromFirestore(doc));
  }

  Future<void> setNotification(bool value) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return;
    await user.ref.update({'notification': value});
    if (_isCurrentSession(generation, user)) emit(state!.copyWith(notification: value));
  }

  Future<void> setDairyNotification(bool value) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return;
    await user.ref.update({'dairy_notification': value});
    if (_isCurrentSession(generation, user)) emit(state!.copyWith(dairyNotification: value));
  }

  Future<void> addDairyMember(DocumentReference ref) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return;
    await user.ref.update({
      'dairy_members': FieldValue.arrayUnion([ref])
    });
    if (_isCurrentSession(generation, user)) {
      emit(state!.copyWith(dairyMembers: List.from(state!.dairyMembers)..add(ref)));
    }
  }

  Future<void> deleteDairyMember(DocumentReference ref) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return;
    await user.ref.update({
      'dairy_members': FieldValue.arrayRemove([ref])
    });
    if (_isCurrentSession(generation, user)) {
      emit(state!.copyWith(dairyMembers: List.from(state!.dairyMembers)..remove(ref)));
    }
  }

  Future<void> onDeleteFcmToken() async {
    try {
      await state?.ref.update({'fcm_token': null});
    } catch (e) {
      print('Error onDeleteFcmToken: $e');
    }
  }

  Future<UserModel> getUserByRef(DocumentReference ref) async {
    final doc = await ref.get();
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel> getStreamUserByRef(DocumentReference ref) {
    return ref.snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  Future<bool> addRequestToConnection(DocumentReference kidRef) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return false;
    try {
      final batch = _fs.batch();
      batch.update(user.ref, {
        'connection_requests': FieldValue.arrayUnion([kidRef])
      });
      batch.update(kidRef, {
        'connection_requests': FieldValue.arrayUnion([user.ref])
      });
      await batch.commit();
      if (_isCurrentSession(generation, user)) {
        emit(state!.copyWith(connectionRequests: {...state!.connectionRequests, kidRef}.toList()));
      }
      return true;
    } catch (e) {
      print('error: {addRequestToConnection}: ${e.toString()}');
      return false;
    }
  }

  Future<bool> acceptConnection(DocumentReference mentorRef) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return false;
    try {
      final batch = _fs.batch();
      batch.update(user.ref, {
        'connections': FieldValue.arrayUnion([mentorRef]),
        'connection_requests': FieldValue.arrayRemove([mentorRef]),
      });
      batch.update(mentorRef, {
        'connections': FieldValue.arrayUnion([user.ref]),
        'connection_requests': FieldValue.arrayRemove([user.ref]),
      });
      await batch.commit();
      if (_isCurrentSession(generation, user)) {
        emit(state!.copyWith(
          connections: {...state!.connections, mentorRef}.toList(),
          connectionRequests: List.from(state!.connectionRequests)..remove(mentorRef),
        ));
      }
      return true;
    } catch (e) {
      print('error: {acceptConnection}: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteConnection(DocumentReference userRef) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) return false;
    try {
      final batch = _fs.batch();
      batch.update(user.ref, {
        'connections': FieldValue.arrayRemove([userRef]),
        'connection_requests': FieldValue.arrayRemove([userRef])
      });
      batch.update(userRef, {
        'connections': FieldValue.arrayRemove([user.ref]),
        'connection_requests': FieldValue.arrayRemove([user.ref])
      });
      await batch.commit();
      if (_isCurrentSession(generation, user)) {
        emit(state!.copyWith(
          connections: List.from(state!.connections)..remove(userRef),
          connectionRequests: List.from(state!.connectionRequests)..remove(userRef),
        ));
      }
      return true;
    } catch (e) {
      print('error: {acceptConnection}: ${e.toString()}');
      return false;
    }
  }

  Future<void> onChangePoint(int amount) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) throw StateError('Пользователь не найден.');
    final points = await _fs.runTransaction((transaction) async {
      final snapshot = await transaction.get(user.ref);
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) throw StateError('Пользователь не найден.');
      final balance = (data['points'] as int? ?? 0) + amount;
      if (balance < 0) throw StateError('Недостаточно баллов.');
      transaction.update(user.ref, {'points': balance});
      return balance;
    });
    if (_isCurrentSession(generation, user)) {
      emit(state!.copyWith(points: points));
    }
  }

  Future<void> onGameComplete(
    Map<String, dynamic> newGameDoc,
    int points,
    DocumentReference? level,
  ) async {
    final generation = _sessionGeneration;
    final user = state;
    if (user == null) throw StateError('Пользователь не найден.');
    final batch = _fs.batch();
    batch.set(user.userGamesCollection.doc(), newGameDoc);

    final newDoc = {
      'game_points': FieldValue.increment(points),
    };

    if (level != null) {
      newDoc['completed_levels'] = FieldValue.arrayUnion([level]);
    }

    batch.update(user.ref, newDoc);
    await batch.commit();
    if (!_isCurrentSession(generation, user)) return;

    final completedLevels = List<DocumentReference>.from(state!.completedLevels);
    if (level != null && !completedLevels.contains(level)) {
      completedLevels.add(level);
    }

    emit(state?.copyWith(
      gamePoints: state!.gamePoints + points,
      completedLevels: completedLevels,
    ));
  }

  Future<void> onPurchasePlan(Map<dynamic, dynamic> orderDoc) async {
    if (state == null) throw StateError('Пользователь не найден.');
    if (orderDoc['paid'] != true || orderDoc['fulfilled'] != true) {
      throw StateError('Оплата ещё не подтверждена сервером.');
    }
    // Entitlements are granted once by the verified server webhook. A snapshot
    // replay, reopened screen or modified client must never extend a plan.
    await refreshProfile();
  }

  Future<void> markAsDeleted() async {
    final user = state;
    if (user == null) throw StateError('Пользователь не найден.');
    final batch = _fs.batch();
    final myConnections = {...user.connections, ...user.connectionRequests};
    for (final connection in myConnections) {
      batch.update(connection, {
        'connections': FieldValue.arrayRemove([user.ref]),
        'connection_requests': FieldValue.arrayRemove([user.ref]),
      });
    }

    batch.update(user.ref, {
      'deleted': true,
      'banned': null,
      'photo': null,
      'type': null,
      'email': null,
      'phone': null,
      'profile_filled': false,
      'name': null,
      'connections': null,
      'connection_requests': null,
      'game_points': 0,
      'points': 0,
      'birth_date': null,
      'city': null,
      'completed_levels': null,
      'dairy_members': null,
      'dairy_notification': null,
      'notification': null,
      'trial_subscription': null,
      'premium_subscription': null,
      'fcm_token': null,
    });
    await batch.commit();
  }
}
