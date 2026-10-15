import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;

class PaymentService {
  final FirebaseFirestore _fs;
  final UserCubit _userCubit;
  final cf.FirebaseFunctions _functions;
  final Map<String, String> _pendingOrders = {};

  PaymentService({
    required FirebaseFirestore fs,
    required UserCubit appUserCubit,
    required cf.FirebaseFunctions functions,
  })  : _fs = fs,
        _userCubit = appUserCubit,
        _functions = functions;

  Future<bool> canAddKid() async {
    if (_userCubit.state?.isDemoAccount ?? false) return true;
    if (_userCubit.state?.hasSubscription() ?? false) {
      final currentPlanRef = _userCubit.state?.premiumSubscriptionRef;
      if (currentPlanRef == null) {
        if (_userCubit.state?.isSubscriptionTrial() ?? false) {
          return true;
        } else {
          return false;
        }
      }
      SubscriptionModel currentPlan = await getTariffByRef(_userCubit.state!.premiumSubscriptionRef!);
      final count = currentPlan.count;
      final myConnectionCount = _userCubit.state?.connections.length ?? 0;

      return (count > myConnectionCount);
    } else {
      return false;
    }
  }

  Future<List<SubscriptionModel>> getTariffs() async {
    final snapshot = await _fs.collection('tariffs').orderBy('price').get();
    return snapshot.docs.map((doc) => SubscriptionModel.fromFirestore(doc)).toList();
  }

  Future<SubscriptionModel> getTariffByRef(DocumentReference ref) async {
    return await ref.get().then((doc) => SubscriptionModel.fromFirestore(doc));
  }

  Stream<SubscriptionModel> getTariffStreamByRef(DocumentReference ref) {
    return ref.snapshots().map((doc) => SubscriptionModel.fromFirestore(doc));
  }

  Future<UserModel?> findUserForGift(String phone) async {
    final userRef = _fs.collection('users').doc('phone_$phone');
    final userDoc = await userRef.get();
    if (!userDoc.exists) return null;
    return UserModel.fromFirestore(userDoc);
  }

  Future<Map?> createPayment({required SubscriptionModel tariff}) async {
    final user = _userCubit.state;
    if (user == null) throw StateError('Необходимо войти в аккаунт.');
    return _createPayment(tariff: tariff, recipient: user);
  }

  Future<Map?> sendGift({required SubscriptionModel tariff, required UserModel user}) async {
    return _createPayment(tariff: tariff, recipient: user);
  }

  Future<Map<String, dynamic>> _createPayment({required SubscriptionModel tariff, required UserModel recipient}) async {
    final owner = _userCubit.state;
    if (owner == null) throw StateError('Необходимо войти в аккаунт.');
    final key = '${owner.id}:${recipient.id}:${tariff.id}';
    // Keep the same ID after an ambiguous network error so retrying cannot charge twice.
    final orderId = _pendingOrders.putIfAbsent(key, () => _fs.collection('orders').doc().id);
    final result = await _functions.httpsCallable('initialPayment').call({
      'order_id': orderId,
      'tariff_id': tariff.id,
      'recipient_uid': recipient.id,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['status'] == 'canceled') {
      _pendingOrders.remove(key);
      throw StateError('Оплата отменена. Можно начать новую оплату.');
    }
    if (data['fulfilled'] == true) _pendingOrders.remove(key);
    final url = data['url'];
    if (data['fulfilled'] != true && (url is! String || Uri.tryParse(url)?.scheme != 'https')) {
      throw StateError('Не удалось открыть оплату. Повторите попытку позже.');
    }
    return {'url': url ?? '', 'order_id': orderId};
  }

  Future<void> refreshPayment(String orderId) async {
    final result = await _functions.httpsCallable('initialPayment').call({'order_id': orderId, 'status_only': true});
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['fulfilled'] == true || data['status'] == 'canceled') {
      forgetPayment(orderId);
    }
  }

  void forgetPayment(String orderId) {
    _pendingOrders.removeWhere((_, value) => value == orderId);
  }
}
