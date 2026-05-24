part of 'phone_auth_cubit.dart';

@immutable
abstract class PhoneAuthState {}

class PhoneAuthInitial extends PhoneAuthState {}

class PhoneAuthLoading extends PhoneAuthState {}

class PhoneAuthCodeSentSuccess extends PhoneAuthState {
  final String code;
  PhoneAuthCodeSentSuccess({required this.code});
}

// class PhoneAuthCodeAutoRetrievalTimeout extends PhoneAuthState {}

class PhoneAuthResendOTPSuccess extends PhoneAuthState {
  final String code;
  PhoneAuthResendOTPSuccess({required this.code});
}

class PhoneAuthSuccess extends PhoneAuthState {
  final String type;

  PhoneAuthSuccess({required this.type});
}

class PhoneAuthSuccessRedirect extends PhoneAuthState {}

class PhoneAuthFailure extends PhoneAuthState {
  final String errorMessage;

  PhoneAuthFailure({required this.errorMessage});
}
