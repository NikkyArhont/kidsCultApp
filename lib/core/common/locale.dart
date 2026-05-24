import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({
    required StorageService storageService,
  })  : _storageService = storageService,
        super(const Locale('ru', 'RU'));

  final StorageService _storageService;

  static final supportedLocales = [const Locale('en'), const Locale('ru')];

  Future<void> initCurrentLocale() async {
    final langCode = _storageService.currentLocale();
    if (langCode != null) {
      final Locale newLocale = Locale.fromSubtags(languageCode: langCode);
      emit(newLocale);
    } else {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (supportedLocales.map((e) => e.languageCode).contains(deviceLocale)) {
        emit(Locale(deviceLocale));
      } else {
        emit(const Locale('ru'));
      }
    }
  }

  void changeAppLocale(BuildContext context, String languageCode) {
    _storageService.setLocale(languageCode);
    final Locale newLocale = Locale.fromSubtags(languageCode: languageCode);
    context.setLocale(newLocale);
    emit(newLocale);
  }

  String getLocaleLangCode(BuildContext context) {
    String locale = 'ru';
    final Locale appLocale = Localizations.localeOf(context);
    if (appLocale.languageCode.contains('en')) {
      locale = 'en';
    }
    return locale;
  }
}
