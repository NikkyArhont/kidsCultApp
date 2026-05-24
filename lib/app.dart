import 'package:bot_toast/bot_toast.dart';
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final botToastBuilder = BotToastInit();
    const textScaleFactor = TextScaler.linear(1.0);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<UserCubit>()),
        BlocProvider(create: (context) => sl<PhoneAuthCubit>()),
        BlocProvider(create: (context) => sl<FillDataCubit>()),
        BlocProvider(create: (context) => sl<NewChatCubit>()),
        BlocProvider(create: (context) => sl<CurrentChatCubit>()),
        BlocProvider(create: (context) => sl<TaskCubit>()),
        BlocProvider(create: (context) => sl<BonusCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, Locale>(
        builder: (context, locale) {
          context.setLocale(locale);
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: primary900),
              useMaterial3: true,
              scaffoldBackgroundColor: white,
              appBarTheme: const AppBarTheme(
                backgroundColor: white,
                scrolledUnderElevation: 0.0,
              ),
              fontFamily: Involve,
              unselectedWidgetColor: primary900,
              progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary900),
            ),
            builder: (context, child) {
              child = botToastBuilder(context, child);
              final mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(textScaler: textScaleFactor),
                child: child,
              );
            },
            routerConfig: router,
          );
        },
      ),
    );
  }
}
