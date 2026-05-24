import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

String getTextByLocale(BuildContext context, String ru, String en) {
  final locale = context.locale.languageCode;

  return locale == 'en' ? en : ru;
}
