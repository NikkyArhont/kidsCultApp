import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateBonusPreview extends StatelessWidget {
  final UserModel me;
  const CreateBonusPreview({super.key, required this.me});

  void onChangeMode(BuildContext context, int index) {
    context.read<CreateBonusCubit>().onChangeMode(true);
    context.read<CreateBonusCubit>().onJumpToPage(index);
  }

  void onOpenLink(String link) async {
    if (link.isEmpty) return;
    await launchUrl(Uri.parse(link));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateBonusCubit, CreateBonusState>(
      builder: (context, state) {
        bool isKidBonus = me.isKid;
        return LayoutBuilder(
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
                            message: 'check_bonus_detail'.tr(),
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
                                        onTap: () => onChangeMode(context, 1),
                                        imageFile: state.photo != null ? File(state.photo!.path) : null,
                                        emoji: state.emoji,
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: GestureDetector(
                                          onTap: () => onChangeMode(context, 1),
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
                                onTap: () => onChangeMode(context, 2),
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
                                  onChangeMode(context, 0);
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
                                  onChangeMode(context, 0);
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AppText(
                                        text: '${'roleSelectionMentor'.tr()} ${!isKidBonus ? 'creator'.tr() : ''}',
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
                                onTap: () => onChangeMode(context, 3),
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
                                    if (state.link == null || (state.link?.isEmpty ?? true)) const AppText(text: '-'),
                                    const SizedBox(width: 2),
                                    _leftArrow(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!isKidBonus)
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => onChangeMode(context, 4),
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
                                  text: isKidBonus ? 'create_request_for_bonus'.tr() : 'create_bonus'.tr(),
                                  isLoading: state.status == CreateBonusStatus.loading,
                                  onTap: () {
                                    if (state.status == CreateBonusStatus.loading) return;
                                    context.read<CreateBonusCubit>().createBonus();
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
        );
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
