import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GamesTabScreen extends StatelessWidget {
  const GamesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: greyscale100,
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: white,
          leadingWidth: 62,
          automaticallyImplyLeading: false,
          leading: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              'assets/images/logo_min.svg',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          title: AppText(text: 'games'.tr(), size: 24, fw: FontWeight.w700),
          centerTitle: true,
          actions: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/points.svg'),
                const SizedBox(width: 8),
                BlocBuilder<UserCubit, UserModel?>(
                  builder: (context, me) {
                    final points = me?.gamePoints ?? 0;
                    return AppText(text: points.toString(), size: 20, fw: FontWeight.w700);
                  },
                ),
                const SizedBox(width: 24),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              height: 42,
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: greyscale100,
              ),
              child: TabBar(
                onTap: (value) {
                  // ReminderType type = value == 0 ? ReminderType.single : ReminderType.daily;
                  // context.read<KidTaskCreateCubit>().onChangeReminderType(type);
                },
                dividerHeight: 0,
                dividerColor: greyscale100,
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: greyscale900,
                  fontFamily: Involve,
                  height: 1.6,
                ),
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: white,
                  fontFamily: Involve,
                  height: 1.6,
                ),
                unselectedLabelColor: greyscale900,
                labelColor: white,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(6), color: primary900),
                indicatorPadding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                splashBorderRadius: BorderRadius.circular(6),
                tabs: [
                  Text('play'.tr()),
                  Text('learn'.tr()),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<UserCubit, UserModel?>(
          builder: (context, me) {
            if (me == null) return const SizedBox();
            return TabBarView(children: [GameTabWidget(me: me), const ArticleTabWidget()]);
          },
        ),
      ),
    );
  }
}
