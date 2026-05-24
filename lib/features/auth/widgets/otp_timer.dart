import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OtpTimer extends StatefulWidget {
  final VoidCallback onResend;
  const OtpTimer({super.key, required this.onResend});

  @override
  State<OtpTimer> createState() => _OtpTimerState();
}

class _OtpTimerState extends State<OtpTimer> {
  int _remainingSeconds = 60;
  late Timer _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        _timer.cancel();
        if (mounted) setState(() => _canResend = true);
      }
    });
  }

  void handleResend() {
    widget.onResend();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'resendCodeMessage'.tr(),
                  style: const TextStyle(
                    color: greyscale700,
                    fontWeight: FontWeight.normal,
                    fontSize: 18,
                    fontFamily: Involve,
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(
                      text: ' $_remainingSeconds ',
                      style: const TextStyle(
                        color: greyscale700,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        fontFamily: Involve,
                        height: 1.6,
                      ),
                    ),
                     TextSpan(
                      text: 'secondsSuffix'.tr(),
                      style: const TextStyle(
                        color: greyscale700,
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        fontFamily: Involve,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _canResend ? handleResend : null,
          child: AppText(
            text: 'sendNewCodeButton'.tr(),
            color: _canResend ? primary900 : greyscale500,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
