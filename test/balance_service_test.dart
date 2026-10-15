import 'package:child_tracker/shared/services/balance_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryFirestore firestore;
  late BalanceService service;
  late DocumentReference kid;
  late DocumentReference mentor;

  setUp(() {
    firestore = _MemoryFirestore();
    service = BalanceService(firestore);
    kid = firestore.collection('users').doc('kid');
    mentor = firestore.collection('users').doc('mentor');
    firestore.documents.addAll({
      kid.path: {'points': 100},
      mentor.path: {'points': 7},
      'tasks/task': {
        'owner': mentor,
        'kid': kid,
        'coin': 30,
        'name': 'Read',
        'status': 'onReview',
      },
      'bonuses/bonus': {
        'mentor': mentor,
        'kid': kid,
        'point': 40,
        'name': 'Book',
        'status': 'active',
      },
    });
  });

  test('concurrent completion retries award and history exactly once', () async {
    final results = await Future.wait([
      service.completeTask('task', 'mentor'),
      service.completeTask('task', 'mentor'),
    ]);
    expect(results.where((result) => result.changed), hasLength(1));
    expect(firestore.documents[kid.path]!['points'], 130);
    expect(firestore.documents['tasks/task']!['status'], 'completed');
    expect(firestore.history, hasLength(1));
    expect(firestore.history.single['coin'], 30);
    expect(firestore.transactionAttempts, greaterThan(2));
  });

  test('already completed legacy task never awards again', () async {
    firestore.documents['tasks/task']!['status'] = 'completed';
    final result = await service.completeTask('task', 'mentor');
    expect(result.changed, isFalse);
    expect(firestore.documents[kid.path]!['points'], 100);
    expect(firestore.history, isEmpty);
  });

  test('failed task commit leaves status, balance and history unchanged', () async {
    firestore.failNextCommit = true;
    await expectLater(service.completeTask('task', 'mentor'), throwsStateError);
    expect(firestore.documents['tasks/task']!['status'], 'onReview');
    expect(firestore.documents[kid.path]!['points'], 100);
    expect(firestore.history, isEmpty);
    await service.completeTask('task', 'mentor');
    expect(firestore.documents[kid.path]!['points'], 130);
  });

  test('missing reward recipient cannot mark a task completed', () async {
    firestore.documents.remove(kid.path);
    await expectLater(service.completeTask('task', 'mentor'), throwsStateError);
    expect(firestore.documents['tasks/task']!['status'], 'onReview');
    expect(firestore.history, isEmpty);
  });

  test('insufficient points cannot change bonus status or write history', () async {
    firestore.documents[kid.path]!['points'] = 20;
    await expectLater(service.purchaseBonus('bonus', 'kid'), throwsStateError);
    expect(firestore.documents[kid.path]!['points'], 20);
    expect(firestore.documents['bonuses/bonus']!['status'], 'active');
    expect(firestore.history, isEmpty);
  });

  test('concurrent purchase cannot charge the same bonus twice', () async {
    final results = await Future.wait([
      service.purchaseBonus('bonus', 'kid'),
      service.purchaseBonus('bonus', 'kid'),
    ]);
    expect(results.where((result) => result.changed), hasLength(1));
    expect(firestore.documents[kid.path]!['points'], 60);
    expect(firestore.history.single['coin'], -40);
  });

  test('concurrent different purchases cannot spend the same balance', () async {
    firestore.documents['bonuses/second'] = {
      ...firestore.documents['bonuses/bonus']!,
      'point': 80,
    };
    final results = await Future.wait([
      service.purchaseBonus('bonus', 'kid').then<Object>((value) => value).catchError((Object error) => error),
      service.purchaseBonus('second', 'kid').then<Object>((value) => value).catchError((Object error) => error),
    ]);
    expect(results.whereType<BalanceChange>(), hasLength(1));
    expect(results.whereType<StateError>(), hasLength(1));
    expect(firestore.documents[kid.path]!['points'], greaterThanOrEqualTo(0));
    expect(firestore.history, hasLength(1));
  });

  test('refund uses original child and debit, and runs only once', () async {
    await service.purchaseBonus('bonus', 'kid');
    firestore.documents['bonuses/bonus']!.addAll({'kid': mentor, 'point': 900});
    await Future.wait([
      service.refundBonus('bonus', 'mentor', 'Unavailable'),
      service.refundBonus('bonus', 'mentor', 'Unavailable'),
    ]);
    expect(firestore.documents[kid.path]!['points'], 100);
    expect(firestore.documents[mentor.path]!['points'], 7);
    expect(firestore.history, hasLength(2));
    expect(firestore.documents['coin_changes/bonus_refund_bonus']!['coin'], 40);
    expect(firestore.documents['bonuses/bonus']!['status'], 'rejected');
  });

  test('failed refund keeps the paid request and balance intact', () async {
    await service.purchaseBonus('bonus', 'kid');
    firestore.failNextCommit = true;
    await expectLater(service.refundBonus('bonus', 'mentor', null), throwsStateError);
    expect(firestore.documents[kid.path]!['points'], 60);
    expect(firestore.documents['bonuses/bonus']!['status'], 'readyToReceive');
    expect(firestore.history, hasLength(1));
  });

  test('legacy paid bonus can be refunded without new metadata', () async {
    firestore.documents['bonuses/bonus']!['status'] = 'readyToReceive';
    firestore.documents[kid.path]!['points'] = 60;
    await service.refundBonus('bonus', 'mentor', null);
    expect(firestore.documents[kid.path]!['points'], 100);
    expect(firestore.documents[mentor.path]!['points'], 7);
  });

  test('received bonus cannot be refunded and wrong actors cannot charge', () async {
    await expectLater(service.purchaseBonus('bonus', 'mentor'), throwsStateError);
    await expectLater(service.completeTask('task', 'kid'), throwsStateError);
    firestore.documents['bonuses/bonus']!['status'] = 'received';
    await expectLater(service.refundBonus('bonus', 'mentor', null), throwsStateError);
    expect(firestore.documents[kid.path]!['points'], 100);
    expect(firestore.history, isEmpty);
  });
}

// Implements only the Firestore API used by BalanceService. A version conflict
// reruns the real transaction callback; writes become visible only at commit.
// These are unit tests of our transaction boundaries, not Firestore rule tests.
class _MemoryFirestore implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  int _version = 0;
  int transactionAttempts = 0;
  bool failNextCommit = false;

  Iterable<Map<String, dynamic>> get history =>
      documents.entries.where((entry) => entry.key.startsWith('coin_changes/')).map((entry) => entry.value);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _Collection(this, path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      transactionAttempts++;
      final version = _version;
      final transaction = _Transaction(documents);
      final result = await transactionHandler(transaction);
      if (version != _version) continue;
      if (failNextCommit) {
        failNextCommit = false;
        throw StateError('Simulated commit failure');
      }
      documents
        ..clear()
        ..addAll(transaction.documents);
      _version++;
      return result;
    }
    throw StateError('Transaction retries exhausted');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test doubles deliberately implement the SDK's sealed interfaces.
// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  @override
  final _MemoryFirestore firestore;
  @override
  final String path;
  _Collection(this.firestore, this.path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Document(firestore, '${this.path}/$path');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  @override
  final _MemoryFirestore firestore;
  @override
  final String path;
  _Document(this.firestore, this.path);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      firestore.collection(path.substring(0, path.lastIndexOf('/')));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot<T extends Object?> implements DocumentSnapshot<T> {
  final T? value;
  _Snapshot(this.value);

  @override
  T? data() => value;

  @override
  bool get exists => value != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  final Map<String, Map<String, dynamic>> documents;
  bool _hasWrites = false;

  _Transaction(Map<String, Map<String, dynamic>> original)
      : documents = original.map((key, value) => MapEntry(key, Map.of(value)));

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> documentReference) async {
    if (_hasWrites) throw StateError('Firestore requires all reads before writes');
    return _Snapshot<T>(documents[documentReference.path] as T?);
  }

  @override
  Transaction update(DocumentReference documentReference, Map<String, dynamic> data) {
    _hasWrites = true;
    final existing = documents[documentReference.path];
    if (existing == null) throw StateError('Document does not exist');
    existing.addAll(data);
    return this;
  }

  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) {
    _hasWrites = true;
    documents[documentReference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
