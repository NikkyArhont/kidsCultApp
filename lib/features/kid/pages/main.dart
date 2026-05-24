import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class KidMainScreen extends StatefulWidget {
  final GoRouterState state;
  final Widget child;
  const KidMainScreen({super.key, required this.child, required this.state});

  @override
  State<KidMainScreen> createState() => _KidMainScreenState();
}

class _KidMainScreenState extends State<KidMainScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaginService service = sl<FirebaseMessaginService>();
    service.setupFCM(context);
  }

  void onTapTab(int index) async {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/kid_task');
      case 1:
        GoRouter.of(context).go('/kid_bonus');
      case 2:
        GoRouter.of(context).go('/kid_games');
      case 3:
        GoRouter.of(context).go('/kid_chat');
      case 4:
        GoRouter.of(context).go('/kid_profile');
    }
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/kid_bonus')) {
      return 1;
    }
    if (location.startsWith('/kid_task')) {
      return 0;
    }
    if (location.startsWith('/kid_games')) {
      return 2;
    }
    if (location.startsWith('/kid_chat')) {
      return 3;
    }
    if (location.startsWith('/kid_profile')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      backgroundColor: greyscale100,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: white,
          boxShadow: [
            BoxShadow(
              blurRadius: 60,
              offset: const Offset(0, 4),
              color: const Color(0xFF04060F).withOpacity(0.08),
            )
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _calculateSelectedIndex(context),
          onTap: onTapTab,
          enableFeedback: true,
          backgroundColor: white,
          selectedItemColor: secondary900,
          unselectedItemColor: greyscale500,
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: Involve,
            height: 1.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            fontFamily: Involve,
            height: 1.6,
          ),
          showUnselectedLabels: true,
          iconSize: 24,
          items: [
            BottomNavigationBarItem(
              activeIcon: SvgPicture.asset('assets/images/tracker_filled_tab.svg'),
              icon: SvgPicture.asset('assets/images/tracker_tab.svg'),
              label: 'tasks'.tr(),
            ),
            BottomNavigationBarItem(
              activeIcon: SvgPicture.asset('assets/images/bonus_filled_tab.svg'),
              icon: SvgPicture.asset('assets/images/bonus_tab.svg'),
              label: 'bonuses'.tr(),
            ),
            BottomNavigationBarItem(
              activeIcon: SvgPicture.asset('assets/images/game_filled_tab.svg'),
              icon: SvgPicture.asset('assets/images/game_tab.svg'),
              label: 'games'.tr(),
            ),
            BottomNavigationBarItem(
              activeIcon: SvgPicture.asset('assets/images/chat_filled_tab.svg'),
              icon: SvgPicture.asset('assets/images/chat_tab.svg'),
              label: 'chats'.tr(),
            ),
            BottomNavigationBarItem(
              activeIcon: SvgPicture.asset('assets/images/profile_filled_tab.svg'),
              icon: SvgPicture.asset('assets/images/profile_tab.svg'),
              label: 'profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
