import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PhoneOtpInput extends StatefulWidget {
  final String phone;
  const PhoneOtpInput({super.key, required this.phone});

  @override
  State<PhoneOtpInput> createState() => _PhoneOtpInputState();
}

class _PhoneOtpInputState extends State<PhoneOtpInput> {
  String? otp;
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhoneAuthCubit, PhoneAuthState>(
      listener: (context, state) {
        if (state is PhoneAuthSuccessRedirect) {
          context.go('/auth/role');
        } else if (state is PhoneAuthSuccess) {
          context.go('/${state.type}_bonus');
        } else if (state is PhoneAuthResendOTPSuccess) {
          SnackBarSerive.showNewCodeSendNotification();
        }
      },
      builder: (context, state) {
        String? errorText = state is PhoneAuthFailure ? state.errorMessage : null;
        bool isValid = ((otp ?? '').trim()).length == 6;
        String? code;
        if (state is PhoneAuthCodeSentSuccess) {
          code = state.code;
        } else if (state is PhoneAuthResendOTPSuccess) {
          code = state.code;
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom + 16.0
                        : 16.0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: MaskotMessage(
                            message: 'checkSmsMessage'.tr(),
                            maskot: '2177-min',
                            flip: true,
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (code != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 18, left: 24),
                            child: AppText(text: '${'testCodePrefix'.tr()}: $code', color: greyscale600),
                          ),
                        OtpInput(
                          errorText: errorText,
                          onCompleted: (v) {
                            setState(() {
                              otp = v;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: OtpTimer(
                            onResend: () {
                              context.read<PhoneAuthCubit>().sendCode(widget.phone, isResend: true);
                            },
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: FilledAppButton(
                                  text: 'apply'.tr(),
                                  isActive: ((otp ?? '').trim()).length == 6,
                                  onTap: (!isValid || state is PhoneAuthLoading)
                                      ? null
                                      : () => context.read<PhoneAuthCubit>().verifyOTP(widget.phone, otp!),
                                  isLoading: state is PhoneAuthLoading,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
