import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomReactiveCheckbox extends StatelessWidget {
  final formControlName = 'privacy';
  const CustomReactiveCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.2,
          child: ReactiveCheckbox(
            formControlName: formControlName,
            activeColor: primary900,
            checkColor: white,
            side: const BorderSide(color: primary900, width: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'privacyPolicyAgreement'.tr(),
              style: const TextStyle(
                fontSize: 17,
                color: greyscale900,
                fontWeight: FontWeight.w500,
                fontFamily: Involve,
                height: 1.6,
              ),
              children: [
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(termsOfUse)),
                  text: 'privacyPolicy'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    color: primary900,
                    fontWeight: FontWeight.w500,
                    fontFamily: Involve,
                    height: 1.6,
                  ),
                ),
                 TextSpan(
                  text: 'andText'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    color: greyscale900,
                    fontWeight: FontWeight.w500,
                    fontFamily: Involve,
                    height: 1.6,
                  ),
                ),
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(privacyPolicy)),
                  text: 'termsOfUse'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    color: primary900,
                    fontWeight: FontWeight.w500,
                    fontFamily: Involve,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
