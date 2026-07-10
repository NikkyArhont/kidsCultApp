import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

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
    print('send code phone: $phone');
    emit(PhoneAuthLoading());
    try {
      final HttpsCallable callable = _ff.httpsCallable('sendCodeDev', options: HttpsCallableOptions());
      final Map<String, dynamic> dataToSend = {'phone': phone};
      print('Data being sent to Firebase Function: $dataToSend');
      final HttpsCallableResult result = await callable.call(dataToSend);
      print('Result: ${result.data}');
      final code = result.data['code'];
      
      try {
        final configDoc = await _fs.collection('config').doc('sms_settings').get();
        if (configDoc.exists) {
          final login = configDoc.data()?['login'];
          final apiKey = configDoc.data()?['api_key'];
          
          if (login != null && apiKey != null) {
            final ts = const Uuid().v4();
            final secret = md5.convert(utf8.encode(ts + apiKey)).toString();
            
            final dio = Dio();
            dio.options.headers['login'] = login;
            dio.options.headers['ts'] = ts;
            dio.options.headers['secret'] = secret;
            
            final response = await dio.post(
              'https://cp.redsms.ru/api/message',
              data: {
                'from': 'FamilyCult',
                'to': phone,
                'text': 'Код для входа в приложение KidsCult: $code',
                'route': 'sms',
              },
            );
            print('SMS successfully sent via RedSMS. Response: ${response.data}');
          } else {
            print('RedSMS config missing login or api_key');
          }
        } else {
          print('RedSMS config doc not found');
        }
      } on DioException catch (e) {
        print('RedSMS DioError: ${e.response?.data ?? e.message}');
      } catch (e) {
        print('RedSMS Error: $e');
      }

      if (isResend) {
        emit(PhoneAuthResendOTPSuccess(code: code));
      } else {
        emit(PhoneAuthCodeSentSuccess(code: code));
      }
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message} - ${e.details}');
      String message = e.message == 'Failed to send code due to an internal server error.'
          ? 'cantSendToPhone'.tr()
          : e.message == 'Wait before requesting another code.'
              ? 'waitForResend'.tr()
              : e.message ?? e.code;
      
      if (e.message == 'Wait before requesting another code.' && !isResend) {
        emit(PhoneAuthCodeSentSuccess(code: ''));
      } else {
        emit(PhoneAuthFailure(errorMessage: message));
      }
    } catch (e) {
      print('Error {sendCode}: $e');
      emit(PhoneAuthFailure(errorMessage: e.toString()));
    }
  }

  Future<void> verifyOTP(String phone, String otp) async {
    emit(PhoneAuthLoading());
    try {
      final HttpsCallable callable = _ff.httpsCallable('verifyCode', options: HttpsCallableOptions());
      final Map<String, dynamic> dataToSend = {'phone': phone, 'code': otp};
      print('Data being sent to Firebase Function: $dataToSend');
      final HttpsCallableResult result = await callable.call(dataToSend);
      print('Result: ${result.data}');

      final String? token = result.data['token'];

      if (token == null) {
        emit(PhoneAuthFailure(errorMessage: 'Token not found'));
        return;
      }

      _signInWithCredential(token, phone);
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Error: ${e.code} - ${e.message} - ${e.details}');
      String message = e.message == 'Invalid code provided.' ? 'invalidCode'.tr() : e.message ?? e.code;
      emit(PhoneAuthFailure(errorMessage: message));
    } catch (e) {
      print('Error {verifyOTP}: $e');
      emit(PhoneAuthFailure(errorMessage: e.toString()));
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
            emit(PhoneAuthFailure(errorMessage: 'userBanned'.tr()));
            return;
          } else if (!userModel.profileFilled) {
            emit(PhoneAuthSuccessRedirect());
            return;
          } else {
            emit(PhoneAuthSuccess(type: (userModel.userType ?? UserType.kid).name));
            _userCubit.setUser(userModel);
            return;
          }
        } else {
          print('Create new User');
          await _createNewUser(userCredential.user!, phone);
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
