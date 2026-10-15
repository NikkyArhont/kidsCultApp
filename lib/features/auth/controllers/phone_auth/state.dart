part of 'phone_auth_cubit.dart';

@immutable
abstract class PhoneAuthState {}

class PhoneAuthInitial extends PhoneAuthState {}

class PhoneAuthLoading extends PhoneAuthState {}

class PhoneAuthCodeSentSuccess extends PhoneAuthState {}

// class PhoneAuthCodeAutoRetrievalTimeout extends PhoneAuthState {}

class PhoneAuthResendOTPSuccess extends PhoneAuthState {}

class PhoneAuthSuccess extends PhoneAuthState {
  final String type;

  PhoneAuthSuccess({required this.type});
}

class PhoneAuthSuccessRedirect extends PhoneAuthState {}

class PhoneAuthFailure extends PhoneAuthState {
  final String errorMessage;

  PhoneAuthFailure({required this.errorMessage});
}
