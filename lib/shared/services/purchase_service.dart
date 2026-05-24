import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' as cf;

class PaymentService {
  final FirebaseFirestore _fs;
  final UserCubit _userCubit;
  final cf.FirebaseFunctions _functions;

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
    try {
      final newOrderRef = _fs.collection('orders').doc();

      final orderDoc = {
        "tariff": tariff.ref,
        "paid": false,
        "price": tariff.price,
        "user": _userCubit.state!.ref,
        "time": FieldValue.serverTimestamp(),
      };

      await newOrderRef.set(orderDoc);

      final callable = _functions.httpsCallable('initialPayment');
      final result = await callable.call({'order_id': newOrderRef.id});

      final data = {
        "url": result.data['url'],
        "order_id": newOrderRef.id,
      };

      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map?> sendGift({required SubscriptionModel tariff, required UserModel user}) async {
    try {
      final newOrderRef = _fs.collection('orders').doc();

      final orderDoc = {
        "tariff": tariff.ref,
        "paid": false,
        "price": tariff.price,
        "user": user.ref,
        "sender": _userCubit.state!.ref,
        "is_gift": true,
        "time": FieldValue.serverTimestamp(),
      };

      await newOrderRef.set(orderDoc);

      final callable = _functions.httpsCallable('initialPayment');
      final result = await callable.call({'order_id': newOrderRef.id});

      final data = {
        "url": result.data['url'],
        "order_id": newOrderRef.id,
      };

      return data;
    } catch (e) {
      rethrow;
    }
  }
}
