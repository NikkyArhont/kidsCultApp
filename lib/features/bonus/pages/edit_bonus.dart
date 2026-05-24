import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class EditBonusScreen extends StatelessWidget {
  final BonusModel bonus;
  const EditBonusScreen({super.key, required this.bonus});

  void onChangeMode(BuildContext context, String path) {
    context.push('/edit_bonus/$path', extra: bonus);
  }

  void onDelete(BuildContext context) async {
    final confrim = await showConfirmModalBottomSheet(
      context,
      title: 'delete'.tr(),
      isDestructive: true,
      cancelText: 'cancel'.tr(),
      confirmText: 'yes_delete'.tr(),
      message: 'are_you_sure_delete'.tr(),
    );
    if (confrim == true && context.mounted) {
      final result = await context.read<BonusCubit>().deleteBonus(bonus);
      if (result && context.mounted) {
        context.replace('/bonus_delete_success');
      } else {
        SnackBarSerive.showErrorSnackBar('failed_to_delete_bonus'.tr());
      }
    }
  }

  void onOpenLink(String link) async {
    if (link.isEmpty) return;
    await launchUrl(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) {
          return Container(
            constraints: const BoxConstraints.expand(),
            color: white,
          );
        }
        return Builder(builder: (context) {
          return BlocConsumer<EditBonusCubit, EditBonusState>(
            listener: (context, state) {
              if (state.status == EditBonusStatus.error) {
                SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
              } else if (state.status == EditBonusStatus.success) {
                SnackBarSerive.showSuccessSnackBar('bonus_updated'.tr());
                context.pop(true);
              }
            },
            builder: (context, state) {
              bool isKidBonus = bonus.kid?.id == bonus.owner?.id;
              return Scaffold(
                backgroundColor: white,
                appBar: AppBar(
                  leadingWidth: 70,
                  leading: IconButton(
                    icon: const Icon(CupertinoIcons.arrow_left),
                    onPressed: () {
                      context.pop();
                    },
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/delete.svg',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () => onDelete(context),
                      ),
                    ),
                  ],
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: MaskotMessage(
                                    message: 'want_to_fix_something'.tr(),
                                    maskot: '2177-min',
                                    flip: true,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: greyscale200, width: 3),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              CachedClickableImage(
                                                width: 100,
                                                height: 100,
                                                circularRadius: 300,
                                                emojiFontSize: 60,
                                                onTap: () => onChangeMode(context, 'photo'),
                                                imageUrl: (state.photo == null && state.emoji == null)
                                                    ? state.photoUrl
                                                    : null,
                                                imageFile: state.photo != null ? File(state.photo!.path) : null,
                                                emoji: state.emoji,
                                              ),
                                              Align(
                                                alignment: Alignment.bottomRight,
                                                child: GestureDetector(
                                                  onTap: () => onChangeMode(context, 'photo'),
                                                  child: SvgPicture.asset('assets/images/edit_blue_fill.svg'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => onChangeMode(context, 'name'),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 24),
                                            Expanded(
                                              child: AppText(
                                                text: state.name ?? '-',
                                                size: 24,
                                                fw: FontWeight.bold,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            _leftArrow(),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 40, thickness: 1, color: greyscale200),
                                      GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          if (isKidBonus) return;
                                          onChangeMode(context, 'mentor_or_kid');
                                        },
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: AppText(
                                                text: '${'child'.tr()} ${isKidBonus ? 'creator'.tr() : ''}',
                                                size: 16,
                                                fw: FontWeight.w500,
                                                color: greyscale800,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            AppText(
                                              text: isKidBonus ? me.name : state.kid?.name ?? '-',
                                              size: 16,
                                              textAlign: TextAlign.end,
                                            ),
                                            const SizedBox(width: 2),
                                            _leftArrow(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          if (!isKidBonus) return;
                                          onChangeMode(context, 'mentor_or_kid');
                                        },
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: AppText(
                                                text:
                                                    '${'roleSelectionMentor'.tr()} ${!isKidBonus ? 'creator'.tr() : ''}',
                                                size: 16,
                                                fw: FontWeight.w500,
                                                color: greyscale800,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            AppText(
                                              text: !isKidBonus ? me.name : state.mentor?.name ?? '-',
                                              size: 16,
                                              textAlign: TextAlign.end,
                                            ),
                                            const SizedBox(width: 2),
                                            _leftArrow(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => onChangeMode(context, 'link'),
                                        child: Row(
                                          children: [
                                            AppText(
                                              text: 'link_opt'.tr(),
                                              size: 16,
                                              fw: FontWeight.w500,
                                              color: greyscale800,
                                            ),
                                            const SizedBox(width: 2),
                                            const Spacer(),
                                            if (state.link != null && state.link!.isNotEmpty)
                                              GestureDetector(
                                                onTap: () => onOpenLink(state.link!),
                                                child: Container(
                                                  height: 34,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(100),
                                                    border: Border.all(color: primary900, width: 1.5),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      SvgPicture.asset(
                                                        'assets/images/link.svg',
                                                        width: 14,
                                                        height: 14,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      AppText(
                                                        text: 'link'.tr(),
                                                        size: 14,
                                                        color: primary900,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            if (state.link == null || (state.link?.isEmpty ?? true))
                                              const AppText(text: '-'),
                                            const SizedBox(width: 2),
                                            _leftArrow(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (!isKidBonus)
                                        GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () => onChangeMode(context, 'point'),
                                          child: Row(
                                            children: [
                                              AppText(
                                                text: 'execution_conditions'.tr(),
                                                size: 16,
                                                fw: FontWeight.w500,
                                                color: greyscale800,
                                              ),
                                              const SizedBox(width: 2),
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/images/coin.svg',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  AppText(
                                                    text: state.point?.toString() ?? '0',
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 2),
                                              _leftArrow(),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(height: 24),
                                Container(
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: FilledAppButton(
                                          text: 'apply'.tr(),
                                          isLoading: state.status == EditBonusStatus.loading,
                                          onTap: () {
                                            if (state.status == EditBonusStatus.loading) return;
                                            context.read<EditBonusCubit>().editBonus();
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _leftArrow() {
    return const SizedBox(
      width: 24,
      child: Align(
        alignment: Alignment.centerRight,
        child: Icon(
          CupertinoIcons.chevron_right,
          color: dark5,
          size: 20,
        ),
      ),
    );
  }
}
