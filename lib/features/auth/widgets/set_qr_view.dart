import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetQRView extends StatelessWidget {
  const SetQRView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FillDataCubit, FillDataState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'qrCodeGenerateQuestion'.tr(),
                maskot: '2182-min',
                align: TextAlign.start,
                flip: false,
              ),
            ),
            const SizedBox(height: 40),
            AppText(text: 'myQrCodeTitle'.tr(), fw: FontWeight.w700),
            const SizedBox(height: 20),
            Expanded(
              child: GenerateQrCard(
                id: FirebaseAuth.instance.currentUser!.uid,
              ),
            ),
            const SizedBox(height: 40),
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
                      onTap: () {
                        if (state.status == FillDataStatus.loading) return;
                        context.read<FillDataCubit>().nextPage();
                      },
                      isLoading: state.status == FillDataStatus.loading,
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
