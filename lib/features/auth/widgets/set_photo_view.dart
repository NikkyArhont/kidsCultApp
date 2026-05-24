import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class SetPhotoView extends StatelessWidget {
  const SetPhotoView({super.key});

  void onPick(BuildContext context) async {
    final XFile? xfile = await CustomImagePicker.pickAvatarFromGallery(context);
    if (xfile != null && context.mounted) {
      context.read<FillDataCubit>().onChangePhoto(xfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FillDataCubit, FillDataState>(
      builder: (context, state) {
        final valid = state.photo != null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'photoInputQuestion'.tr(),
                maskot: '2188-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CachedClickableImage(
                      width: 120,
                      height: 120,
                      circularRadius: 100,
                      onTap: () => onPick(context),
                      imageFile: state.photo != null ? File(state.photo!.path) : null,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () => onPick(context),
                        child: SvgPicture.asset('assets/images/edit_blue_fill.svg'),
                      ),
                    ),
                  ],
                ),
              ],
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
                          if (state.status == FillDataStatus.loading) return;
                          context.read<FillDataCubit>().nextPage();
                        }
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
