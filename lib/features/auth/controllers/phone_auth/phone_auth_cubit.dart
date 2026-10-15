import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'state.dart';

class PhoneAuthCubit extends Cubit<PhoneAuthState> {
  final UserCubit _userCubit;
  final FirebaseAuth _auth;
  final FirebaseFirestore _fs;
  final FirebaseFunctions _ff;

  PhoneAuthCubit({
    required UserCubit userCubit,
    required FirebaseAuth auth,
    required FirebaseFirestore fs,
    required FirebaseFunctions ff,
  })  : _userCubit = userCubit,
        _auth = auth,
        _fs = fs,
        _ff = ff,
        super(PhoneAuthInitial());

  Future<void> sendCode(String phone, {bool isResend = false}) async {
    if (state is PhoneAuthLoading) return;
    emit(PhoneAuthLoading());
    try {
      final HttpsCallable callable = _ff.httpsCallable('sendCodeSecure');
      final Map<String, dynamic> dataToSend = {'phone': phone};
      final HttpsCallableResult result = await callable.call(dataToSend);
      if (result.data is! Map || result.data['sent'] != true) {
        throw StateError('SMS was not accepted for delivery');
      }
      if (isClosed) return;
      if (isResend) {
        emit(PhoneAuthResendOTPSuccess());
      } else {
        emit(PhoneAuthCodeSentSuccess());
      }
    } on FirebaseFunctionsException catch (e) {
      if (isClosed) return;
      // A quota error does not mean a usable SMS was sent.
      emit(PhoneAuthFailure(
          errorMessage: e.code == 'resource-exhausted' ? 'waitForResend'.tr() : 'cantSendToPhone'.tr()));
    } catch (_) {
      if (!isClosed) emit(PhoneAuthFailure(errorMessage: 'cantSendToPhone'.tr()));
    }
  }

  Future<void> verifyOTP(String phone, String otp) async {
    if (state is PhoneAuthLoading) return;
    emit(PhoneAuthLoading());
    try {
      final HttpsCallable callable = _ff.httpsCallable('verifyCodeSecure');
      final Map<String, dynamic> dataToSend = {'phone': phone, 'code': otp};
      final HttpsCallableResult result = await callable.call(dataToSend);

      final String? token = result.data['token'];

      if (token == null) {
        emit(PhoneAuthFailure(errorMessage: 'Token not found'));
        return;
      }

      await _signInWithCredential(token, phone);
    } on FirebaseFunctionsException catch (e) {
      if (isClosed) return;
      final message = e.code == 'permission-denied'
          ? 'userBanned'.tr()
          : e.code == 'resource-exhausted'
              ? 'waitForResend'.tr()
              : e.code == 'invalid-argument' || e.code == 'unauthenticated'
                  ? 'invalidCode'.tr()
                  : 'errorSigningIn'.tr();
      emit(PhoneAuthFailure(errorMessage: message));
    } catch (_) {
      if (!isClosed) emit(PhoneAuthFailure(errorMessage: 'errorSigningIn'.tr()));
    }
  }

  Future<void> _signInWithCredential(String customToken, String phone) async {
    try {
      final UserCredential userCredential = await _auth.signInWithCustomToken(customToken);

      if (userCredential.user != null) {
        final userCollection = _fs.collection('users');
        final userData = await userCollection.doc(userCredential.user!.uid).get();

        if (userData.exists) {
          //login

          final userModel = UserModel.fromFirestore(userData);
          if (userModel.banned) {
            await _auth.signOut();
            _userCubit.setUser(null);
            emit(PhoneAuthFailure(errorMessage: 'userBanned'.tr()));
            return;
          } else if (!userModel.profileFilled) {
            _userCubit.setUser(userModel);
            emit(PhoneAuthSuccessRedirect());
            return;
          } else {
            _userCubit.setUser(userModel);
            emit(PhoneAuthSuccess(type: (userModel.userType ?? UserType.kid).name));
            return;
          }
        } else {
          await _createNewUser(userCredential.user!, phone);
          await _userCubit.getAndSet(userCredential.user!);
          emit(PhoneAuthSuccessRedirect());
        }
      } else {
        emit(PhoneAuthFailure(errorMessage: 'errorSigningIn'.tr()));
      }
    } on FirebaseAuthException catch (e) {
      emit(PhoneAuthFailure(errorMessage: e.code));
    } catch (e) {
      emit(PhoneAuthFailure(errorMessage: e.toString()));
    }
  }

  Future<void> _createNewUser(User user, String phone) async {
    try {
      final userCollection = _fs.collection('users');
      Map<String, dynamic> userData = {
        'name': user.displayName ?? 'undefined'.tr(),
        'phone': '+$phone',
        'email': user.email,
        'type': null,
        'profile_filled': false,
        'banned': false,
        'deleted': false,
        'notification': true,
        'game_points': 0,
        'points': 0,
        'created_at': FieldValue.serverTimestamp(),
      };
      final docRef = userCollection.doc(user.uid);
      await docRef.set(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    emit(PhoneAuthInitial());
  }
}
