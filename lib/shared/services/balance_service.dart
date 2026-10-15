import 'package:cloud_firestore/cloud_firestore.dart';

/// Keeps a balance change, its source status and its history in one commit.
/// Firestore rules must still enforce authorization for untrusted clients.
class BalanceService {
  final FirebaseFirestore _fs;

  BalanceService(this._fs);

  Future<BalanceChange> completeTask(String taskId, String mentorId) {
    final taskRef = _fs.collection('tasks').doc(taskId);
    final historyRef = _fs.collection('coin_changes').doc('task_$taskId');
    return _fs.runTransaction((transaction) async {
      final task = _data(await transaction.get(taskRef));
      _requireUser(task['owner'], mentorId);
      final kidRef = _userRef(task['kid']);
      final kid = _data(await transaction.get(kidRef));
      final balance = _points(kid['points']);
      if (task['status'] == 'completed' || task['reward_credited'] == true) {
        return BalanceChange(false, kidRef.id, balance);
      }
      if (!['inProgress', 'onReview', 'needsRework'].contains(task['status'])) {
        throw StateError('Задание уже изменено. Обновите страницу.');
      }
      final amount = _points(task['coin']);
      transaction.update(taskRef, {
        'status': 'completed',
        'action_date': FieldValue.serverTimestamp(),
        'reward_credited': true,
      });
      transaction.update(kidRef, {'points': balance + amount});
      transaction.set(historyRef, {
        'kid': kidRef,
        'mentor': task['owner'],
        'created_at': FieldValue.serverTimestamp(),
        'coin': amount,
        'name': 'Выполнение задания: ${task['name'] ?? ''}',
      });
      return BalanceChange(true, kidRef.id, balance + amount);
    });
  }

  Future<BalanceChange> purchaseBonus(String bonusId, String kidId) {
    final bonusRef = _fs.collection('bonuses').doc(bonusId);
    final historyRef = _fs.collection('coin_changes').doc('bonus_purchase_$bonusId');
    return _fs.runTransaction((transaction) async {
      final bonus = _data(await transaction.get(bonusRef));
      _requireUser(bonus['kid'], kidId);
      final kidRef = _userRef(bonus['kid']);
      final kid = _data(await transaction.get(kidRef));
      final balance = _points(kid['points']);
      if (['readyToReceive', 'received'].contains(bonus['status'])) {
        return BalanceChange(false, kidRef.id, balance);
      }
      if (bonus['status'] != 'active' || bonus['purchased_points'] != null) {
        throw StateError('Бонус уже изменен. Обновите страницу.');
      }
      final amount = _points(bonus['point']);
      if (balance < amount) {
        throw StateError('Недостаточно баллов для покупки бонуса.');
      }
      transaction.update(bonusRef, {
        'status': 'readyToReceive',
        // Freeze the actual debit and recipient for a later refund.
        'purchased_points': amount,
        'purchased_kid': kidRef,
      });
      transaction.update(kidRef, {'points': balance - amount});
      transaction.set(historyRef, {
        'kid': kidRef,
        'mentor': bonus['mentor'],
        'created_at': FieldValue.serverTimestamp(),
        'coin': -amount,
        'name': 'Покупка бонуса "${bonus['name'] ?? ''}"',
      });
      return BalanceChange(true, kidRef.id, balance - amount);
    });
  }

  Future<BalanceChange> refundBonus(String bonusId, String mentorId, String? reason) {
    final bonusRef = _fs.collection('bonuses').doc(bonusId);
    final historyRef = _fs.collection('coin_changes').doc('bonus_refund_$bonusId');
    return _fs.runTransaction((transaction) async {
      final bonus = _data(await transaction.get(bonusRef));
      _requireUser(bonus['mentor'], mentorId);
      final kidRef = _userRef(bonus['purchased_kid'] ?? bonus['kid']);
      final kid = _data(await transaction.get(kidRef));
      final balance = _points(kid['points']);
      if (bonus['status'] == 'rejected') {
        return BalanceChange(false, kidRef.id, balance);
      }
      if (bonus['status'] != 'readyToReceive' || bonus['points_refunded'] == true) {
        throw StateError('Запрос бонуса уже изменен. Обновите страницу.');
      }
      // Older purchases do not have purchased_points yet.
      final amount = _points(bonus['purchased_points'] ?? bonus['point']);
      transaction.update(bonusRef, {
        'status': 'rejected',
        'cancel_reason': reason,
        'points_refunded': true,
      });
      transaction.update(kidRef, {'points': balance + amount});
      transaction.set(historyRef, {
        'kid': kidRef,
        'mentor': bonus['mentor'],
        'created_at': FieldValue.serverTimestamp(),
        'coin': amount,
        'name': 'Возврат за бонус "${bonus['name'] ?? ''}"',
      });
      return BalanceChange(true, kidRef.id, balance + amount);
    });
  }

  Map<String, dynamic> _data(DocumentSnapshot snapshot) {
    final data = snapshot.data();
    if (!snapshot.exists || data is! Map<String, dynamic>) {
      throw StateError('Запись не найдена. Обновите страницу.');
    }
    return data;
  }

  int _points(Object? value) {
    if (value == null) return 0;
    if (value is! int || value < 0) {
      throw StateError('Некорректное количество баллов.');
    }
    return value;
  }

  DocumentReference _userRef(Object? value) {
    if (value is! DocumentReference || value.parent.path != 'users') {
      throw StateError('Пользователь не найден.');
    }
    return value;
  }

  void _requireUser(Object? value, String userId) {
    if (_userRef(value).id != userId) {
      throw StateError('Операция недоступна для текущего пользователя.');
    }
  }
}

class BalanceChange {
  final bool changed;
  final String kidId;
  final int points;

  const BalanceChange(this.changed, this.kidId, this.points);
}
