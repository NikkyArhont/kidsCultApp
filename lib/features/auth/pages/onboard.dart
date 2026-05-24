import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  final _controller = PageController();
  late List<Widget> pages;

  int _currentPage = 0;

  @override
  void initState() {
    initOnboard();
    super.initState();
    redirectFunc(context);
  }

  void initOnboard() {
    pages = [
      _OnboardingPage(
        title: 'welcome_title'.tr(),
        description: 'welcomeScreenDescription1'.tr(),
        icon: '2186-min',
      ),
      _OnboardingPage(
        title: 'welcomeScreenTasksAndRewards'.tr(),
        description: 'welcomeScreenDescription2'.tr(),
        icon: '2194-min',
      ),
      _OnboardingPage(
        title: 'welcomeScreenConvenientTools'.tr(),
        description: 'welcomeScreenDescription3'.tr(args: [MASCOTNAME]),
        icon: '2192-min',
      ),
    ];
  }

  void onTap() async {
    if (_currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final StorageService service = sl<StorageService>();
      await service.setOnboardStatus(true);
      if (mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Stack(
        children: [
          const _OnboardBg(),
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PageView(
                      controller: _controller,
                      children: pages,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildPageIndicator(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                child: FilledAppButton(text: 'buttonNext'.tr(), onTap: onTap),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < pages.length; i++) {
      bool isActive = i == _currentPage;
      indicators.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 32 : 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.0),
            color: isActive ? primary900 : greyscale200,
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indicators,
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String icon;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/$icon.png',
                fit: BoxFit.contain,
                width: size.width * 0.75,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppText(
                  text: title,
                  size: 30,
                  fw: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                AppText(
                  text: description,
                  fw: FontWeight.normal,
                  color: greyscale700,
                  textAlign: TextAlign.center,
                  maxLine: 10,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardBg extends StatelessWidget {
  const _OnboardBg();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: ClipPath(
            clipper: CurveClipper(),
            child: Container(
              height: double.infinity,
              color: primary300,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: white,
          ),
        ),
      ],
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    int curveHeight = 50;
    Offset controlPoint = Offset(size.width / 2, size.height + curveHeight);
    Offset endPoint = Offset(size.width, size.height - curveHeight);

    Path path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy)
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
