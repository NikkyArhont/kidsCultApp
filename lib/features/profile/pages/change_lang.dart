import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ChangeLangScreen extends StatefulWidget {
  const ChangeLangScreen({super.key});

  @override
  State<ChangeLangScreen> createState() => _ChangeLangScreenState();
}

class _ChangeLangScreenState extends State<ChangeLangScreen> {
  Locale? appLocale;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) appLocale = Localizations.localeOf(context);
      setState(() {});
    });
  }

  void onSubmit() {
    if (appLocale != null) {
      print('appLocale: $appLocale');
      context.read<LocaleCubit>().changeAppLocale(context, appLocale!.languageCode);

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(text: 'lang'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        appLocale = const Locale('en');
                      });
                    },
                    child: card('English', appLocale?.languageCode == 'en'),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        appLocale = const Locale('ru');
                      });
                    },
                    child: card('Русский', appLocale?.languageCode == 'ru'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  FilledAppButton(
                    text: 'apply'.tr(),
                    isActive: appLocale != null,
                    onTap: onSubmit,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget card(String lang, bool selected) {
    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? primary900 : greyscale200, width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              text: lang,
              fw: FontWeight.bold,
            ),
          ),
          if (selected) SvgPicture.asset('assets/images/checkmark.svg')
        ],
      ),
    );
  }
}
