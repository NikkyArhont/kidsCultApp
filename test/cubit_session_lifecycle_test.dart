import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _PausedFirestore firestore;
  late UserCubit user;
  late _PushRecorder pushes;

  setUp(() {
    firestore = _PausedFirestore();
    pushes = _PushRecorder();
    user = UserCubit(fs: firestore)..setUser(_user(firestore, 'mentor', isKid: false));
  });

  tearDown(() => user.close());

  test('profile loading cannot restore a user after logout while state was null', () async {
    firestore.pauseRead = true;
    user.setUser(null);
    final pending = user.getAndSet(_AuthUser('kid'));
    await firestore.readStarted.future;
    user.setUser(null);
    firestore.resumeRead.complete();
    await pending;
    expect(user.state, isNull);
  });

  test('old profile refresh cannot overwrite a new login with the same UID', () async {
    firestore.pauseRead = true;
    user.setUser(_user(firestore, 'kid', isKid: true));
    final pending = user.refreshProfile();
    await firestore.readStarted.future;
    user.setUser(null);
    user.setUser(_user(firestore, 'kid', isKid: true, points: 900));
    firestore.resumeRead.complete();
    await pending;
    expect(user.state!.points, 900);
  });

  for (final action in ['notification', 'diaryNotification']) {
    test('late $action update cannot change a new login with the same UID', () async {
      firestore.pauseWrite = true;
      user.setUser(_user(firestore, 'kid', isKid: true));
      final pending = action == 'notification' ? user.setNotification(false) : user.setDairyNotification(false);
      await firestore.writeStarted.future;
      user.setUser(null);
      user.setUser(_user(firestore, 'kid', isKid: true));
      firestore.resumeWrite.complete();
      await pending;

      expect(user.state!.notification, isTrue);
      expect(user.state!.dairyNotification, isTrue);
    });
  }

  test('same-session settings write still updates the profile', () async {
    user.setUser(_user(firestore, 'kid', isKid: true));
    await user.setNotification(false);
    expect(user.state!.notification, isFalse);
  });

  test('old balance result cannot overwrite a new login with the same UID', () async {
    firestore.pauseCommit = true;
    user.setUser(_user(firestore, 'kid', isKid: true));
    final pending = user.onChangePoint(20);
    await firestore.commitStarted.future;
    user.setUser(null);
    user.setUser(_user(firestore, 'kid', isKid: true, points: 900));
    firestore.resumeCommit.complete();
    await pending;
    expect(user.state!.points, 900);
  });

  test('logout during task status read prevents write and stale error', () async {
    firestore.pauseRead = true;
    final cubit = TaskCubit(userCubit: user, fs: firestore, fcm: pushes);
    addTearDown(cubit.close);
    final pending = cubit.cancelTask(_task(), null);
    await firestore.readStarted.future;
    user.setUser(null);
    await cubit.reset();
    user.setUser(_user(firestore, 'next', isKid: false));
    firestore.resumeRead.complete();
    await pending;

    expect(firestore.documents['tasks/task']!['status'], 'inProgress');
    expect(cubit.state.status, TaskStateStatus.initial);
    expect(pushes.count, 0);
  });

  test('completed old-session task commit does not repopulate a new session', () async {
    firestore.pauseCommit = true;
    final cubit = TaskCubit(userCubit: user, fs: firestore, fcm: pushes);
    addTearDown(cubit.close);
    final pending = cubit.cancelTask(_task(), null);
    await firestore.commitStarted.future;
    user.setUser(null);
    await cubit.reset();
    user.setUser(_user(firestore, 'next', isKid: false));
    firestore.resumeCommit.complete();
    await pending;

    expect(firestore.documents['tasks/task']!['status'], 'canceled');
    expect(cubit.state.status, TaskStateStatus.initial);
    expect(pushes.count, 0);
  });

  test('resubscribing in the same session keeps legitimate operation success', () async {
    firestore.pauseCommit = true;
    final cubit = TaskCubit(userCubit: user, fs: firestore, fcm: pushes);
    addTearDown(cubit.close);
    final pending = cubit.cancelTask(_task(), null);
    await firestore.commitStarted.future;
    await cubit.init();
    firestore.resumeCommit.complete();
    await pending;

    expect(cubit.state.status, TaskStateStatus.cancelSuccess);
    expect(pushes.count, 1);
  });

  for (final failCommit in [false, true]) {
    test('bonus purchase ${failCommit ? 'failure' : 'success'} after logout cannot affect next user', () async {
      firestore.pauseCommit = true;
      firestore.failCommit = failCommit;
      user.setUser(_user(firestore, 'kid', isKid: true));
      final cubit = BonusCubit(userCubit: user, fs: firestore, fcm: pushes);
      addTearDown(cubit.close);
      final pending = cubit.requestBonusByKid(_bonus(firestore));
      await firestore.commitStarted.future;
      user.setUser(null);
      await cubit.reset();
      user.setUser(_user(firestore, 'next', isKid: true, points: 700));
      firestore.resumeCommit.complete();
      await pending;

      expect(user.state!.id, 'next');
      expect(user.state!.points, 700);
      expect(cubit.state.status, BonusStateStatus.initial);
      expect(pushes.count, 0);
    });
  }

  test('reset also invalidates operations when the same user logs in again', () async {
    firestore.pauseRead = true;
    final cubit = BonusCubit(userCubit: user, fs: firestore, fcm: pushes);
    addTearDown(cubit.close);
    final pending = cubit.cancelBonus(_bonus(firestore), null);
    await firestore.readStarted.future;
    await cubit.reset();
    user.setUser(_user(firestore, 'mentor', isKid: false));
    firestore.resumeRead.complete();
    await pending;

    expect(firestore.documents['bonuses/bonus']!['status'], 'active');
    expect(cubit.state.status, BonusStateStatus.initial);
    expect(pushes.count, 0);
  });
}

TaskModel _task() => TaskModel(id: 'task', name: 'Task', status: TaskStatus.inProgress);

BonusModel _bonus(_PausedFirestore firestore) => BonusModel(
      id: 'bonus',
      name: 'Book',
      status: BonusStatus.active,
      mentor: firestore.collection('users').doc('mentor'),
      kid: firestore.collection('users').doc('kid'),
      point: 40,
    );

UserModel _user(
  _PausedFirestore firestore,
  String id, {
  required bool isKid,
  int points = 100,
}) =>
    _User(firestore, id, isKid, points);

class _User extends UserModel {
  final _PausedFirestore firestore;
  _User(this.firestore, String id, bool isKid, int points)
      : super(id: id, name: id, userType: isKid ? UserType.kid : UserType.mentor, points: points);

  @override
  DocumentReference get ref => firestore.collection('users').doc(id);
}

class _AuthUser implements auth.User {
  @override
  final String uid;
  _AuthUser(this.uid);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PushRecorder implements FirebaseMessaginService {
  int count = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    count++;
    return null;
  }
}

/// Pauses the real transaction callback at read/commit boundaries. This tests
/// Cubit ownership across logout; BalanceService's atomicity is tested separately.
class _PausedFirestore implements FirebaseFirestore {
  late final documents = <String, Map<String, dynamic>>{
    'tasks/task': {'status': 'inProgress'},
    'users/kid': {'points': 100},
    'bonuses/bonus': {
      'status': 'active',
      'kid': collection('users').doc('kid'),
      'mentor': collection('users').doc('mentor'),
      'point': 40,
      'name': 'Book',
    },
  };
  bool pauseRead = false;
  bool pauseWrite = false;
  bool pauseCommit = false;
  bool failCommit = false;
  final readStarted = Completer<void>();
  final resumeRead = Completer<void>();
  final writeStarted = Completer<void>();
  final resumeWrite = Completer<void>();
  final commitStarted = Completer<void>();
  final resumeCommit = Completer<void>();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Collection(this, path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = _Transaction(this);
    final result = await handler(transaction);
    if (!commitStarted.isCompleted) commitStarted.complete();
    if (pauseCommit) await resumeCommit.future;
    if (failCommit) throw StateError('Simulated commit failure');
    for (final write in transaction.writes.entries) {
      documents[write.key] = {...?documents[write.key], ...write.value};
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test doubles deliberately implement the SDK's sealed interfaces.
// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  @override
  final _PausedFirestore firestore;
  @override
  final String path;
  _Collection(this.firestore, this.path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Document(firestore, '${this.path}/$path');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where || invocation.memberName == #orderBy) return this;
    if (invocation.memberName == #snapshots) return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    return super.noSuchMethod(invocation);
  }
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  @override
  final _PausedFirestore firestore;
  @override
  final String path;
  _Document(this.firestore, this.path);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      firestore.collection(path.substring(0, path.lastIndexOf('/')));

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final data = firestore.documents[path];
    final snapshot = data == null ? null : Map<String, dynamic>.from(data);
    if (!firestore.readStarted.isCompleted) firestore.readStarted.complete();
    if (firestore.pauseRead) await firestore.resumeRead.future;
    return _Snapshot(snapshot, id);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (!firestore.writeStarted.isCompleted) firestore.writeStarted.complete();
    if (firestore.pauseWrite) await firestore.resumeWrite.future;
    firestore.documents[path]?.addAll(data.cast<String, dynamic>());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot<T extends Object?> implements DocumentSnapshot<T> {
  final T? value;
  @override
  final String id;
  _Snapshot(this.value, [this.id = '']);

  @override
  T? data() => value;

  @override
  bool get exists => value != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  final _PausedFirestore firestore;
  final writes = <String, Map<String, dynamic>>{};
  _Transaction(this.firestore);

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> documentReference) async {
    if (!firestore.readStarted.isCompleted) firestore.readStarted.complete();
    if (firestore.pauseRead) await firestore.resumeRead.future;
    return _Snapshot<T>(firestore.documents[documentReference.path] as T?);
  }

  @override
  Transaction update(DocumentReference documentReference, Map<String, dynamic> data) {
    writes[documentReference.path] = data;
    return this;
  }

  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) {
    writes[documentReference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
