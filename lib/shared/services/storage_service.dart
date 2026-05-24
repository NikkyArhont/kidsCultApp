// ignore_for_file: non_constant_identifier_names

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences prefs;

  StorageService({required this.prefs});

  final String ONBOARDSHOW = 'ONBOARDSHOW';
  String LOCALE = 'LOCALE';

  bool isOnboardShowed() {
    return prefs.getBool(ONBOARDSHOW) ?? false;
  }

  Future<void> setOnboardStatus(bool status) async {
    await prefs.setBool(ONBOARDSHOW, status);
  }

  String? currentLocale() {
    return prefs.getString(LOCALE);
  }

  Future<bool> setLocale(String locale) async {
    return await prefs.setString(LOCALE, locale);
  }

  Future<bool> clearAllStorage() async {
    return await prefs.clear();
  }
}
