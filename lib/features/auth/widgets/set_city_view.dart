import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SetCityView extends StatelessWidget {
  const SetCityView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FillDataCubit, FillDataState>(
      builder: (context, state) {
        final valid = state.city != null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'cityInputQuestion'.tr(),
                maskot: '2177-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(text: 'cityInputPlaceholder'.tr()),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      context.push(
                        '/auth/city_search',
                        extra: context.read<FillDataCubit>().onChangeCity as Function(String),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: greyscale50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppText(
                        text: valid ? state.city! : 'cityInputEnter'.tr(),
                        fw: valid ? FontWeight.w600 : FontWeight.normal,
                        color: valid ? greyscale900 : greyscale500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FilledAppButton(
                      text: 'buttonNext'.tr(),
                      isActive: valid,
                      onTap: () {
                        if (valid) {
                          context.read<FillDataCubit>().nextPage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
