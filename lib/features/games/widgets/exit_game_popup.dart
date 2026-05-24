import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExitGamePopupMenuButton extends StatelessWidget {
  final VoidCallback onExit;

  const ExitGamePopupMenuButton({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 1,
          height: 68,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/logout.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              AppText(text: 'exitGame'.tr(), color: error),
            ],
          ),
        ),
      ],
      onSelected: (int value) {
        if (value == 1) {
          onExit();
        }
      },
      tooltip: 'Menu',
      offset: const Offset(-10, 25),
      elevation: 20,
      shadowColor: const Color(0xFF04060F).withOpacity(0.25),
      menuPadding: const EdgeInsets.only(left: 20, right: 20),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      color: white,
      child: const Icon(Icons.more_vert, color: greyscale900),
    );
  }
}
