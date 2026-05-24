import 'dart:ui';

import 'package:child_tracker/app.dart';
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await EasyLocalization.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBRCanvg0-mpxH4YONsoxBhOmupl-q0MwA',
        appId: '1:419315761443:web:0000000000000000000000', // Имитируем web app id
        messagingSenderId: '419315761443',
        projectId: 'kidscult-a5d7e',
        storageBucket: 'kidscult-a5d7e.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await initializeDependencies();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) async {
    final localeCubit = sl<LocaleCubit>();
    await localeCubit.initCurrentLocale();

    runApp(EasyLocalization(
      supportedLocales: LocaleCubit.supportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      startLocale: localeCubit.state,
      child: BlocProvider.value(
        value: localeCubit,
        child: const App(),
      ),
    ));
  });
}
