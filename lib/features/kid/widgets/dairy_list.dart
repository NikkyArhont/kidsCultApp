// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DairyListWidget extends StatelessWidget {
  final List<DairyModel> dairyList;
  final bool showMenu;
  const DairyListWidget({super.key, required this.dairyList, required this.showMenu});

  @override
  Widget build(BuildContext context) {
    if (dairyList.isEmpty) {
      return Expanded(
        child: Center(
          child: AppText(
            text: 'noDaries'.tr(),
            size: 14,
            fw: FontWeight.normal,
            color: greyscale500,
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: dairyList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _DairyCard(
          dairy: dairyList[index],
          showMenu: showMenu,
        ),
      ),
    );
  }
}

class _DairyCard extends StatelessWidget {
  final DairyModel dairy;
  final bool showMenu;
  const _DairyCard({required this.dairy, this.showMenu = true});

  @override
  Widget build(BuildContext context) {
    final em = dairy.emotion ?? DairyEmotion.normal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: greyscale200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/${dairyEmotionIcon(em)}.svg',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: dairyEmotionNameRus(em),
                      size: 16,
                      fw: FontWeight.w700,
                    ),
                    AppText(
                      text: taskDate(dairy.time),
                      size: 14,
                      fw: FontWeight.w400,
                      color: greyscale700,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (showMenu)
                _CustomGamePopupMenuButton(
                  onOption1Selected: () {
                    context.push('/dairy/edit', extra: dairy);
                  },
                  onOption2Selected: () async {
                    final bool confirm = await showConfirmModalBottomSheet(
                          context,
                          confirmText: 'yes_delete'.tr(),
                          title: 'delete'.tr(),
                          message: 'are_you_sure_delete'.tr(),
                          cancelText: 'cancel'.tr(),
                          isDestructive: true,
                        ) ??
                        false;

                    if (confirm && context.mounted) {
                      await context.read<DairyCubit>().deleteDairy(dairy);
                      SnackBarSerive.showSuccessSnackBar('review_deleted'.tr());
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          AppText(
            text: dairy.text ?? '',
            fw: FontWeight.w400,
            color: greyscale700,
            maxLine: 10,
          ),
        ],
      ),
    );
  }
}

class _CustomGamePopupMenuButton extends StatelessWidget {
  final VoidCallback onOption1Selected;
  final VoidCallback onOption2Selected;

  const _CustomGamePopupMenuButton({
    required this.onOption1Selected,
    required this.onOption2Selected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: 1,
          height: 60,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/edit.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              AppText(text: 'edit'.tr()),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<int>(
          value: 2,
          height: 60,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/delete.svg',
                width: 24,
                height: 24,
                color: error,
              ),
              const SizedBox(width: 12),
              AppText(text: 'delete'.tr()),
            ],
          ),
        ),
      ],
      onSelected: (int value) {
        if (value == 1) {
          onOption1Selected();
        } else if (value == 2) {
          onOption2Selected();
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
